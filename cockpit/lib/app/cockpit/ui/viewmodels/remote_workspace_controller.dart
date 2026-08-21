import 'dart:async';

import 'package:cockpit/app/cockpit/data/remote/remote_git_adapter.dart';
import 'package:cockpit/app/cockpit/data/remote/remote_worktree_gateway.dart';
import 'package:cockpit/app/cockpit/domain/contracts/git_command_runner.dart';
import 'package:cockpit/app/cockpit/domain/contracts/worktree_manager.dart';
import 'package:cockpit/app/cockpit/domain/entities/git_file_status.dart';
import 'package:cockpit/app/cockpit/domain/entities/git_info.dart';
import 'package:cockpit/app/cockpit/domain/entities/project.dart';
import 'package:cockpit/app/cockpit/domain/entities/remote_host.dart';
import 'package:cockpit/app/cockpit/ui/remote/remote_hosts_controller.dart';
import 'package:cockpit/app/core/domain/result.dart';
import 'package:cockpit/app/core/utils/path_utils.dart';
import 'package:cockpit_core/cockpit_core.dart' show GitRunResult;
import 'package:cockpit_remote/cockpit_remote.dart' show RemoteGitService;
import 'package:flutter/foundation.dart';

/// Motor **remoto** do shell (plano 58), extraído do `CockpitViewModel`:
/// cache do `git status` por workspace de host, worktrees remotos e as ops de
/// git que rodam no host (`git.run` via SSH).
///
/// Segue o contrato do [GitController]: não conhece panes nem a lista de
/// projetos — o VM dono injeta os acessos que precisa pelos campos de callback
/// e é ele quem aplica a reconciliação de forks em `_projectList`/`_worktrees`.
class RemoteWorkspaceController extends ChangeNotifier {
  RemoteWorkspaceController(this._hosts);

  final RemoteHostsController _hosts;

  // ---- contexto injetado pelo VM dono (mesma vida page-scoped) -------------

  /// Projeto por id (inclui os workspaces remotos sintéticos), ou `null`.
  Project? Function(String? id)? resolveProject;

  /// Workspaces remotos top-level atualmente injetados no rail.
  List<Project> Function()? remoteWorkspaces;

  /// Workspace selecionado agora (guia o refresh do ativo).
  String? Function()? selectedId;

  /// Troca a seleção (após criar/remover um worktree remoto).
  void Function(String id)? selectProject;

  /// Root (pasta no host) que originou um fork remoto.
  String? Function(String forkId)? forkOrigin;

  /// Aplica a lista reconciliada de forks de [wsId] — o VM mexe em
  /// `_projectList`/`_worktrees`/`_forkOrigin` e encerra o runtime dos que
  /// sumiram (o controller não conhece sessões).
  void Function(String wsId, List<Project> forks, String origin)? applyForks;

  // ---- estado ---------------------------------------------------------------

  /// `git status` por workspace remoto. O painel de Source Control lê os
  /// getters git do VM; quando o workspace é remoto, eles caem aqui.
  final Map<String, GitInfo> _gitInfo = <String, GitInfo>{};

  /// Workspaces cujo git está carregando agora (evita disparo duplicado do
  /// lazy-load do badge).
  final Set<String> _loading = <String>{};

  /// Token do último refresh de worktrees por workspace (anti-corrida).
  final Map<String, int> _worktreeToken = <String, int>{};

  Project? _project(String? id) => resolveProject?.call(id);

  /// O [RemoteHost] dono do workspace [workspaceId], ou `null` se local.
  RemoteHost? hostForWorkspace(String? workspaceId) {
    final project = _project(workspaceId);
    final hostId = project?.remoteHostId;
    if (project == null || !project.isRemoteTerminal || hostId == null) {
      return null;
    }
    for (final h in _hosts.hosts) {
      if (h.id == hostId) return h;
    }
    return null;
  }

  /// O [RemoteHost] do workspace ativo, ou `null` se o ativo é local.
  RemoteHost? get activeHost => hostForWorkspace(selectedId?.call());

  /// GitInfo remoto da pasta do workspace ativo (ou `null`).
  GitInfo? get activeGitInfo {
    final id = selectedId?.call();
    return id == null ? null : _gitInfo[id];
  }

  /// GitInfo remoto de um workspace (badge do rail). `null` enquanto o
  /// lazy-load não terminou, ou se a pasta não é repo git.
  GitInfo? gitInfoOf(String wsId) => _gitInfo[wsId];

  /// Serviço git remoto do host ativo (para as mutações). Lança se não remoto.
  Future<RemoteGitService> activeGitService() =>
      _hosts.gitServiceFor(activeHost!);

  /// Status git (cor da árvore) de um caminho **absoluto no host**, relativo à
  /// pasta [rootPath] do workspace remoto ativo. Pasta agrega o status mais
  /// severo dos descendentes.
  GitFileStatus? statusForPath(String rootPath, String absolutePath) {
    final info = activeGitInfo;
    if (info == null) return null;
    if (absolutePath == rootPath) {
      return info.files.isEmpty ? null : GitFileStatus.modified;
    }
    final rel = relativeUnder(absolutePath, rootPath);
    final exact = info.files[rel];
    if (exact != null) return exact;
    GitFileStatus? agg;
    final prefix = '$rel/';
    for (final e in info.files.entries) {
      if (e.key.startsWith(prefix)) {
        agg = GitFileStatus.strongest(agg, e.value);
      }
    }
    if (agg != null) return agg;
    return info.isUntracked(rel) ? GitFileStatus.untracked : null;
  }

  /// Recarrega o `git status` remoto do workspace ativo (se remoto) e notifica.
  /// Chamado ao selecionar e após cada mutação.
  Future<void> refreshActive() async {
    final id = selectedId?.call();
    final p = _project(id);
    final host = activeHost;
    final root = p?.remotePath;
    if (p == null || host == null || root == null || root.isEmpty) return;
    try {
      final service = await _hosts.gitServiceFor(host);
      _gitInfo[p.id] = remoteGitInfo(await service.status(root));
    } catch (_) {
      // Pasta não é repo git (ou conexão caiu) → sem source control remoto.
      _gitInfo.remove(p.id);
    }
    notifyListeners();
  }

  /// Carrega o `git status` de UM workspace remoto (background, best-effort) e
  /// cacheia — é o que preenche o badge dos slots que não são o ativo. Host
  /// offline apenas não mostra badge (sem travar).
  Future<void> _loadGitFor(Project p) async {
    if (!p.isRemoteTerminal || _loading.contains(p.id)) return;
    final host = hostForWorkspace(p.id);
    final root = p.remotePath;
    if (host == null || root == null || root.isEmpty) return;
    _loading.add(p.id);
    try {
      final service = await _hosts.gitServiceFor(host);
      _gitInfo[p.id] = remoteGitInfo(await service.status(root));
    } catch (_) {
      _gitInfo.remove(p.id);
    } finally {
      _loading.remove(p.id);
      notifyListeners();
    }
  }

  /// Dispara o lazy-load do git de todos os workspaces remotos ainda sem info
  /// (badge) e lista os worktrees de cada um, na mesma janela.
  void ensureLoaded() {
    final workspaces = remoteWorkspaces?.call() ?? const <Project>[];
    for (final p in workspaces) {
      if (_gitInfo.containsKey(p.id) || _loading.contains(p.id)) continue;
      unawaited(_loadGitFor(p));
    }
    for (final p in workspaces) {
      unawaited(refreshWorktrees(p.id));
    }
  }

  /// Descarta o cache de um workspace que saiu do rail.
  void forget(String wsId) {
    _gitInfo.remove(wsId);
    _loading.remove(wsId);
    _worktreeToken.remove(wsId);
  }

  Future<GitRunResult> run(String wsId, List<String> args) async {
    final host = hostForWorkspace(wsId);
    if (host == null) {
      throw StateError('remoteGitRun em workspace não-remoto: $wsId');
    }
    final root = _project(wsId)?.remotePath ?? '';
    final service = await _hosts.gitServiceFor(host);
    return service.run(root, args);
  }

  // === Worktrees remotos (plano 58, Camada B) ==============================
  // Um worktree remoto é só mais um workspace remoto (isRemoteTerminal +
  // remoteHostId + remotePath) com parentId apontando pro workspace de origem,
  // derivado do `git worktree list` do host. Ops via `git.run` (sem RPC novo).

  Future<RemoteWorktreeGateway?> _gatewayFor(String wsId) async {
    final host = hostForWorkspace(wsId);
    if (host == null) return null;
    return RemoteWorktreeGateway(
      await _hosts.gitServiceFor(host),
      await _hosts.fileServiceFor(host),
    );
  }

  /// Lista e reconcilia os worktrees remotos de [wsId] (slots-fork do rail).
  /// Best-effort: host offline / pasta não-git → sem forks.
  Future<void> refreshWorktrees(String wsId) async {
    final parent = _project(wsId);
    final root = parent?.remotePath;
    if (parent == null ||
        !parent.isRemoteTerminal ||
        parent.parentId != null ||
        root == null ||
        root.isEmpty) {
      return;
    }
    final gw = await _gatewayFor(wsId);
    if (gw == null) return;
    // Token anti-corrida: a listagem SSH leva ~s. Um refresh disparado no boot
    // (lista vazia, antes do worktree existir) pode voltar DEPOIS do create e
    // sobrescrever, apagando o fork recém-criado. Só o resultado do refresh
    // mais recente por workspace é aplicado.
    final token = (_worktreeToken[wsId] ?? 0) + 1;
    _worktreeToken[wsId] = token;
    List<RemoteWorktreeEntry> entries;
    try {
      entries = await gw.list(root);
    } catch (_) {
      return;
    }
    if (_worktreeToken[wsId] != token) return; // obsoleto → descarta
    final forks = <Project>[
      for (final e in entries)
        Project(
          id: '$wsId::${e.path}',
          name: e.branch,
          path: '',
          colorValue: parent.colorValue,
          createdAt: parent.createdAt,
          realmId: parent.realmId,
          parentId: wsId,
          order: parent.order,
          kind: WorkspaceKind.remoteTerminal,
          remoteHostId: parent.remoteHostId,
          remotePath: e.path,
        ),
    ];
    applyForks?.call(wsId, forks, root);
    for (final f in forks) {
      if (!_gitInfo.containsKey(f.id) && !_loading.contains(f.id)) {
        unawaited(_loadGitFor(f));
      }
    }
    notifyListeners();
  }

  /// Namespace (branches/worktrees/base) do host — valida o dialog de criar.
  Future<WorktreeNamespace> worktreeNamespace(String wsId) async {
    final root = _project(wsId)?.remotePath;
    if (root == null || root.isEmpty) return const WorktreeNamespace.empty();
    final gw = await _gatewayFor(wsId);
    if (gw == null) return const WorktreeNamespace.empty();
    try {
      return await gw.namespace(root);
    } catch (_) {
      return const WorktreeNamespace.empty();
    }
  }

  /// Cria um worktree no host de [wsId] (branch nova [name], de [baseRef] no
  /// fork-of-fork). Devolve o handle ao vivo (a saída do `git.run` sai de uma
  /// vez); em sucesso, reconcilia, auto-seleciona o fork e o devolve.
  WorktreeAddRun<Project> createWorktree(
    String wsId,
    String name, {
    String? baseRef,
  }) {
    final controller = StreamController<String>();
    final result = () async {
      try {
        final root = _project(wsId)?.remotePath;
        if (root == null || root.isEmpty) {
          return const Failure<Project, WorktreeOpError>(
            WorktreeOpError('Workspace not found.'),
          );
        }
        final gw = await _gatewayFor(wsId);
        if (gw == null) {
          return const Failure<Project, WorktreeOpError>(
            WorktreeOpError('Host unavailable.'),
          );
        }
        final r = await gw.add(root, name, baseRef: baseRef);
        if (r.stdout.isNotEmpty) controller.add(r.stdout);
        if (r.stderr.isNotEmpty) controller.add(r.stderr);
        if (r.code != 0) {
          return Failure<Project, WorktreeOpError>(
            WorktreeOpError(
              r.stderr.isEmpty ? 'git worktree add failed.' : r.stderr,
            ),
          );
        }
        await refreshWorktrees(wsId);
        final fork = _project(
          '$wsId::${RemoteWorktreeGateway.pathFor(root, name)}',
        );
        if (fork == null) {
          return const Failure<Project, WorktreeOpError>(
            WorktreeOpError('Worktree created, but did not appear.'),
          );
        }
        selectProject?.call(fork.id);
        return Success<Project, WorktreeOpError>(fork);
      } catch (e) {
        controller.add('$e');
        return Failure<Project, WorktreeOpError>(WorktreeOpError('$e'));
      } finally {
        await controller.close();
      }
    }();
    return WorktreeAddRun<Project>(output: controller.stream, result: result);
  }

  /// Remove um worktree remoto (`git worktree remove` + `git branch -D` no
  /// host) e reconcilia; se era o selecionado, volta pro pai.
  Future<Result<void, WorktreeOpError>> removeWorktree(String forkId) async {
    final fork = _project(forkId);
    final parentId = fork?.parentId;
    final origin = forkOrigin?.call(forkId);
    final path = fork?.remotePath;
    if (fork == null || parentId == null || origin == null || path == null) {
      return const Failure(WorktreeOpError('Worktree not found.'));
    }
    final gw = await _gatewayFor(parentId);
    if (gw == null) return const Failure(WorktreeOpError('Host unavailable.'));
    final r = await gw.remove(origin, path, fork.name);
    if (r.code != 0) {
      return Failure(
        WorktreeOpError(
          r.stderr.isEmpty ? 'git worktree remove failed.' : r.stderr,
        ),
      );
    }
    if (selectedId?.call() == forkId) selectProject?.call(parentId);
    await refreshWorktrees(parentId);
    return const Success(null);
  }

  /// `true` se a branch do fork remoto já foi mergeada — aviso antes de remover.
  Future<bool> isWorktreeBranchMerged(String forkId) async {
    final fork = _project(forkId);
    final parentId = fork?.parentId;
    final origin = forkOrigin?.call(forkId);
    if (fork == null || parentId == null || origin == null) return false;
    final gw = await _gatewayFor(parentId);
    if (gw == null) return false;
    try {
      return await gw.isMerged(origin, fork.name);
    } catch (_) {
      return false;
    }
  }

  /// Mergeia a branch do fork remoto no pai (no host). Em sucesso, remove o
  /// worktree e volta pro pai. Bloqueia se o pai tem mudanças não commitadas.
  GitMergeOutcome mergeWorktreeToParent(Project fork) {
    final controller = StreamController<String>();
    final status = () async {
      final parentId = fork.parentId;
      final origin = parentId == null ? null : forkOrigin?.call(fork.id);
      if (parentId == null || origin == null) {
        controller.add('Not a worktree.');
        await controller.close();
        return GitMergeStatus.error;
      }
      if ((_gitInfo[parentId]?.dirtyCount ?? 0) > 0) {
        controller.add('Parent has uncommitted changes.');
        await controller.close();
        return GitMergeStatus.dirtyWorktree;
      }
      final gw = await _gatewayFor(parentId);
      if (gw == null) {
        controller.add('Host unavailable.');
        await controller.close();
        return GitMergeStatus.error;
      }
      final r = await gw.merge(origin, fork.name);
      if (r.stdout.isNotEmpty) controller.add(r.stdout);
      if (r.stderr.isNotEmpty) controller.add(r.stderr);
      await controller.close();
      if (r.code != 0) return GitMergeStatus.conflict;
      await removeWorktree(fork.id);
      selectProject?.call(parentId);
      unawaited(refreshActive());
      return GitMergeStatus.merged;
    }();
    return GitMergeOutcome(status: status, output: controller.stream);
  }

  /// "Update from parent" remoto: mergeia a branch do pai no checkout do fork
  /// (no host). Conflito fica no fork (exit ≠ 0), o pai nunca é tocado.
  GitRun updateWorktreeFromParent(Project fork) {
    final controller = StreamController<String>();
    final exit = () async {
      final parentId = fork.parentId;
      final parentBranch = parentId == null ? null : _gitInfo[parentId]?.branch;
      final root = fork.remotePath;
      final host = parentId == null ? null : hostForWorkspace(parentId);
      if (parentBranch == null ||
          parentBranch.isEmpty ||
          root == null ||
          host == null) {
        controller.add('Parent branch not found.');
        await controller.close();
        return 1;
      }
      try {
        final git = await _hosts.gitServiceFor(host);
        final r = await git.run(root, ['merge', '--no-edit', parentBranch]);
        if (r.stdout.isNotEmpty) controller.add(r.stdout);
        if (r.stderr.isNotEmpty) controller.add(r.stderr);
        await controller.close();
        if (r.code == 0) unawaited(refreshActive());
        return r.code;
      } catch (e) {
        controller.add('$e');
        await controller.close();
        return 1;
      }
    }();
    return GitRun(output: controller.stream, exitCode: exit);
  }
}

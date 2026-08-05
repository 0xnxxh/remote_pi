import 'dart:convert';
import 'dart:io';

import 'package:cockpit/app/cockpit/domain/contracts/claude_hook_installer.dart';
import 'package:cockpit/app/core/data/setup/remote_pi_resolver.dart';
import 'package:cockpit/app/core/domain/result.dart';
import 'package:flutter/foundation.dart';

/// Implementação do [ClaudeHookInstaller].
///
/// 1. Materializa a CLI `cockpit` empacotada no app em `~/.cockpit/bin/cockpit`
///    — o `settings.json` aponta pra cópia, não pro bundle (sobrevive a
///    update/move). Recopia quando o **conteúdo** difere (tamanho igual não
///    significa binário igual — ver [_sameContent]).
/// 2. Registra `<cli> hook` como comando de hook. A CLI em Rust absorveu o
///    antigo binário `cockpit-hook` como subcomando: um binário só, um
///    protocolo só. Enquanto alguma plataforma ainda empacotar a CLI Dart (que
///    não tem o subcomando), caímos no binário legado — ver [_resolveHookCommand].
/// 3. Faz **append idempotente** de um entry marcado (`_cockpit`) em cada evento
///    de hook, sem nunca reescrever a lista (preserva hooks do usuário/iTerm2/
///    plugins). Re-rodar remove o entry antigo nosso e re-adiciona — não duplica.
///    É por aqui que a migração acontece: o entry velho apontando pro
///    `cockpit-hook` é removido e substituído no boot seguinte ao update.
class ClaudeHookInstallerImpl implements ClaudeHookInstaller {
  ClaudeHookInstallerImpl();

  /// Marcador que identifica entries de nossa autoria (para idempotência/cleanup).
  static const String _marker = '_cockpit';
  static const String _markerValue = 'v1';

  /// Eventos de ciclo de vida que instrumentamos. working: UserPromptSubmit/
  /// PreToolUse/PostToolUse (exceto PreToolUse de ferramenta interativa —
  /// AskUserQuestion/ExitPlanMode — que vira waiting); waiting/idle:
  /// Notification; idle: Stop/SessionStart/SessionEnd. (Mapeamento real mora
  /// no `cockpit-hook`.)
  static const List<String> _events = <String>[
    'UserPromptSubmit',
    'PreToolUse',
    'PostToolUse',
    'Notification',
    'Stop',
    'SessionStart',
    'SessionEnd',
  ];

  @override
  Future<Result<void, String>> ensureInstalled() async {
    final home = remotePiHome();
    if (home == null) {
      return const Failure<void, String>('HOME não resolvido');
    }
    try {
      // A CLI vem primeiro: é dela que sai o comando do hook.
      final cliPath = await _ensureCli();
      final hookCommand = await _resolveHookCommand(cliPath);
      if (hookCommand == null) {
        return const Failure<void, String>('helper de hook não encontrado');
      }
      await _installHooks(home: home, command: hookCommand);
      return const Success<void, String>(null);
    } catch (e) {
      return Failure<void, String>('$e');
    }
  }

  /// Comando a registrar no `settings.json`.
  ///
  /// Preferimos `<cli> hook` (CLI em Rust, que absorveu o helper). Se a CLI
  /// empacotada ainda for a Dart — que não conhece o subcomando — caímos no
  /// binário `cockpit-hook` legado, senão o status de turno morreria em silêncio
  /// nessa plataforma. `null` = nenhum dos dois disponível.
  Future<String?> _resolveHookCommand(String? cliPath) async {
    if (cliPath != null && await _cliHandlesHook(cliPath)) {
      return '${_shellQuote(cliPath)} hook';
    }
    final name = Platform.isWindows ? 'cockpit-hook.exe' : 'cockpit-hook';
    final dir = cockpitHookDir();
    if (dir == null) return null;
    final legacy = await _materialize(dir, bundledName: name, destName: name);
    return legacy == null ? null : _shellQuote(legacy);
  }

  /// `true` quando a CLI materializada tem o subcomando `hook`.
  ///
  /// O sinal é o sufixo `r` da versão (`cockpit 0.6.0r`), que só a CLI em Rust
  /// emite — é exatamente pra isso que ele existe. Perguntar à CLI é mais
  /// confiável que inferir pela plataforma ou pela presença de arquivo no
  /// bundle, e custa um spawn de poucos ms no boot.
  Future<bool> _cliHandlesHook(String cliPath) async {
    try {
      final out = await Process.run(cliPath, <String>['--version']);
      if (out.exitCode != 0) return false;
      return '${out.stdout}'.trim().endsWith('r');
    } catch (_) {
      return false;
    }
  }

  /// Envolve em aspas duplas quando o caminho tem espaço.
  ///
  /// O Claude Code executa o `command` por um shell, então um caminho com espaço
  /// (`/Users/John Smith/...`) seria fatiado em dois argumentos. Isso já era
  /// latente com o comando de um token só; com `<cli> hook` passa a importar
  /// sempre. Só cita quando precisa, pra não churnar o `settings.json` de quem
  /// tem caminho simples.
  String _shellQuote(String path) => path.contains(' ') ? '"$path"' : path;

  /// Materializa a CLI interna `cockpit` em `~/.cockpit/bin[-debug]/cockpit[.exe]`
  /// (o fonte é empacotado como `cockpit-cli` pra não colidir com `cockpit.app`) e,
  /// se materializou, roda `cockpit install-skill` (idempotente) pra a skill
  /// nascer instalada. Silencioso: falha aqui não pode derrubar o boot.
  /// Devolve o caminho materializado, ou `null`.
  Future<String?> _ensureCli() async {
    final bundledName = Platform.isWindows ? 'cockpit-cli.exe' : 'cockpit-cli';
    final destName = Platform.isWindows ? 'cockpit.exe' : 'cockpit';
    final dir = cockpitCliDir();
    if (dir == null) return null;
    final path = await _materialize(
      dir,
      bundledName: bundledName,
      destName: destName,
    );
    if (path == null) return null;
    try {
      await Process.run(path, <String>['install-skill']);
    } catch (_) {
      /* best-effort */
    }
    return path;
  }

  /// Copia um binário empacotado ([bundledName]) para `[destDirPath]/[destName]`.
  /// Devolve o caminho, ou `null` se não está no bundle (ex.: dev sem o passo de
  /// build) e não há cópia prévia.
  ///
  /// **Tamanho não decide se está atualizado.** Dois exe AOT do Dart compilados
  /// de fontes diferentes saem com frequência com o byte count idêntico (o
  /// snapshot é padded), então a checagem antiga por `length()` deixava a cópia
  /// velha pra trás em silêncio — o app novo rodando com a CLI de semanas atrás.
  /// Comparamos o conteúdo e só recopiamos quando difere de verdade.
  Future<String?> _materialize(
    String destDirPath, {
    required String bundledName,
    required String destName,
  }) async {
    final destDir = Directory(destDirPath);
    final dest = File('${destDir.path}/$destName');

    final bundled = _bundledHelper(bundledName);
    if (bundled != null && await bundled.exists()) {
      if (!await _sameContent(bundled, dest)) {
        await destDir.create(recursive: true);
        await bundled.copy(dest.path);
        await _chmodExec(dest.path);
      }
      return _hookPath(dest.path);
    }

    // Dev / sem bundle: usa cópia pré-existente (colocada manualmente).
    if (await dest.exists()) return _hookPath(dest.path);
    return null;
  }

  /// `true` quando [dest] já é byte-a-byte igual a [src]. O tamanho é só o
  /// descarte barato; quem decide é a comparação de conteúdo.
  Future<bool> _sameContent(File src, File dest) async {
    if (!await dest.exists()) return false;
    if (await src.length() != await dest.length()) return false;
    try {
      final a = await src.readAsBytes();
      final b = await dest.readAsBytes();
      for (var i = 0; i < a.length; i++) {
        if (a[i] != b[i]) return false;
      }
      return true;
    } catch (_) {
      // Ilegível por qualquer motivo: trata como desatualizado e recopia — o
      // custo é uma cópia extra, o risco oposto é ficar com binário velho.
      return false;
    }
  }

  /// Normaliza o caminho para o `command` do hook usando **forward slashes**.
  ///
  /// O Claude Code executa os hooks via `bash` (git-bash/MSYS) mesmo no Windows.
  /// O `bash` trata `\` como escape, então um caminho com `\` (ex.:
  /// `C:\Users\x\.cockpit\bin\cockpit-hook.exe`) vira `C:Usersx.cockpit...` e dá
  /// `command not found`. Como `$home` (`USERPROFILE`) vem com `\` no Windows, o
  /// caminho montado ficava misto/quebrado. Convertendo tudo para `/`
  /// (`C:/Users/x/.cockpit/bin/cockpit-hook.exe`) o bash executa normalmente. Em
  /// POSIX é no-op.
  String _hookPath(String path) =>
      Platform.isWindows ? path.replaceAll(r'\', '/') : path;

  /// Caminho do helper empacotado no app, por plataforma:
  /// - macOS: `…/Contents/MacOS/<app>` → `…/Contents/Resources/cockpit-hook`
  /// - Windows/Linux: ao lado do executável (`<dir>/cockpit-hook[.exe]`)
  File? _bundledHelper(String name) {
    try {
      final exe = File(Platform.resolvedExecutable);
      if (Platform.isMacOS) {
        final contents = exe.parent.parent; // Contents/MacOS → Contents
        return File('${contents.path}/Resources/$name');
      }
      return File('${exe.parent.path}/$name');
    } catch (_) {
      return null;
    }
  }

  Future<void> _chmodExec(String path) async {
    if (Platform.isWindows) return;
    try {
      await Process.run('chmod', ['+x', path]);
    } catch (_) {
      /* best-effort */
    }
  }

  Future<void> _installHooks({
    required String home,
    required String command,
  }) async {
    final file = File('$home/.claude/settings.json');
    Map<String, dynamic> root = <String, dynamic>{};
    if (await file.exists()) {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is Map) root = Map<String, dynamic>.from(decoded);
    } else {
      await file.parent.create(recursive: true);
    }

    final hooksRaw = root['hooks'];
    final hooks = hooksRaw is Map
        ? Map<String, dynamic>.from(hooksRaw)
        : <String, dynamic>{};

    // `command` já vem com o caminho normalizado em forward slashes por
    // `_hookPath` (crítico no Windows: o Claude Code roda hooks via Git Bash,
    // que trata `\` como escape e quebraria o caminho) e citado quando tem
    // espaço.
    final ourGroup = <String, dynamic>{
      'matcher': '',
      'hooks': <Map<String, dynamic>>[
        <String, dynamic>{
          'type': 'command',
          'command': command,
          _marker: _markerValue,
        },
      ],
    };

    var changed = false;
    for (final event in _events) {
      final existing = hooks[event];
      final list = existing is List
          ? List<dynamic>.from(existing)
          : <dynamic>[];
      final before = list.length;
      list.removeWhere(_isOurs); // tira entries antigos nossos
      list.add(Map<String, dynamic>.from(ourGroup));
      // mudou se removeu algo diferente do que readicionamos ou se cresceu
      if (list.length != before || before == 0) changed = true;
      hooks[event] = list;
    }

    root['hooks'] = hooks;
    // Sempre regrava (idempotente no conteúdo lógico; barato).
    await file.writeAsString(
      '${const JsonEncoder.withIndent('  ').convert(root)}\n',
    );
    if (kDebugMode && changed) {
      debugPrint('[claude-hook] entries instalados em ${file.path}');
    }
  }

  /// Um matcher-group é nosso se algum hook interno carrega o marcador **ou**
  /// aponta pro helper (`cockpit-hook` legado ou `<cli> hook`). O segundo
  /// critério limpa entries legados (escritos por versões antigas do
  /// instalador, sem marcador, e/ou com caminho em barra invertida que o Git
  /// Bash não resolvia) — senão acumulam a cada boot. É também o que **migra**
  /// quem estava no binário separado: o entry velho sai aqui e o novo entra no
  /// lugar, no primeiro boot depois do update.
  bool _isOurs(dynamic group) {
    if (group is! Map) return false;
    final inner = group['hooks'];
    if (inner is! List) return false;
    return inner.any((h) {
      if (h is! Map) return false;
      if (h[_marker] == _markerValue) return true;
      final cmd = h['command'];
      if (cmd is! String) return false;
      return cmd.contains('cockpit-hook') ||
          cmd.contains('cockpit" hook') ||
          cmd.endsWith('cockpit hook');
    });
  }
}

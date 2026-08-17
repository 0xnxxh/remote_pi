import 'dart:async';

import 'package:cockpit/app/cockpit/data/remote/mobile_ssh_key_store.dart';
import 'package:cockpit/app/cockpit/data/remote/remote_host_connector.dart';
import 'package:cockpit/app/cockpit/data/remote/remote_host_password_store.dart';
import 'package:cockpit/app/cockpit/data/remote/remote_host_terminal_gateway.dart';
import 'package:cockpit/app/cockpit/domain/contracts/remote_hosts_store.dart';
import 'package:cockpit/app/cockpit/domain/contracts/terminal_gateway.dart';
import 'package:cockpit/app/cockpit/domain/entities/remote_host.dart';
import 'package:cockpit/app/cockpit/domain/entities/remote_workspace_pin.dart';
import 'package:cockpit/app/cockpit/data/terminal/sidecar/sidecar_terminal_connector.dart';
import 'package:cockpit_remote/cockpit_remote.dart';
import 'package:flutter/foundation.dart';

/// Estado app-scoped dos hosts remotos (plano 58, Wave 2/fecho): dono do
/// registro persistido + um [RemoteHostConnector] por host (uma conexão SSH
/// por host, reusada por todos os terminais daquele workspace).
///
/// A UI (rail) observa este controller pra listar os pins e o badge de estado;
/// o [CockpitViewModel] pede o gateway de terminal de um host por aqui.
class RemoteHostsController extends ChangeNotifier {
  RemoteHostsController(this._store);

  final RemoteHostsStore _store;
  final Map<String, RemoteHostConnector> _connectors = {};
  final MobileSshKeyStore _deviceKeys = MobileSshKeyStore();
  final RemoteHostPasswordStore _passwords = RemoteHostPasswordStore();

  /// Linha `authorized_keys` da chave deste dispositivo (mobile): o usuário cola
  /// no `~/.ssh/authorized_keys` do host pra autorizar o iPad/Android. Gera a
  /// chave na 1ª chamada (guardada no Keychain).
  Future<String> devicePublicKey() => _deviceKeys.publicKeyLine();

  List<RemoteHost> get hosts => _store.hosts();

  /// Status de turno (spinner/chime) de TODOS os hosts remotos, mesclado. A VM
  /// assina e roteia por `paneId` pro mesmo caminho do status local (Wave G).
  final _turnStatus = StreamController<RemoteTurnStatus>.broadcast();
  Stream<RemoteTurnStatus> get turnStatus => _turnStatus.stream;

  RemoteHostConnector _connectorFor(RemoteHost host) => _connectors.putIfAbsent(
    host.id,
    () {
      final connector = RemoteHostConnector(
        host,
        localServerBinaryResolver: _resolveLocalServerBinary,
        // Senha (auth por senha) lida do Keychain sob demanda; null pra auth por
        // chave. Fica fora do JSON de hosts (decisão A).
        passwordResolver: host.auth == RemoteHostAuth.password
            ? () => _passwords.read(host.id)
            : null,
      );
      connector.turnStatus.listen(_turnStatus.add);
      return connector;
    },
  );

  /// Fase de conexão atual de um host (pro badge do rail). `idle` se nunca
  /// conectou.
  RemoteHostPhase phaseOf(String hostId) =>
      _connectors[hostId]?.phase ?? RemoteHostPhase.idle;

  Stream<RemoteHostPhase>? phasesOf(String hostId) =>
      _connectors[hostId]?.phases;

  /// Gateway de terminal ligado ao [host] (via SSH). Reusa o connector do
  /// host; a UI é notificada das fases pra pintar loading/erro.
  TerminalGateway terminalGateway(RemoteHost host) {
    final connector = _connectorFor(host);
    connector.phases.listen((_) => notifyListeners());
    return RemoteHostTerminalGateway(connector);
  }

  /// Serviço de arquivos do host (picker de pasta remota). Conecta se preciso.
  Future<RemoteFileService> fileServiceFor(RemoteHost host) =>
      _connectorFor(host).fileService();

  /// Serviço git do host (source control remoto). Conecta se preciso.
  Future<RemoteGitService> gitServiceFor(RemoteHost host) =>
      _connectorFor(host).gitService();

  /// Serviço de terminal do host (Task Run remoto, plano 58). Conecta se
  /// preciso; mesma conexão SSH dos demais serviços.
  Future<RemoteTerminalService> terminalServiceFor(RemoteHost host) =>
      _connectorFor(host).ensure();

  /// Serviço de DB do host (queries remotas). Conecta se preciso.
  Future<RemoteDbService> dbServiceFor(RemoteHost host) =>
      _connectorFor(host).dbService();

  Future<void> addHost({
    required String name,
    required String sshTarget,
    int port = 22,
    RemoteHostAuth auth = RemoteHostAuth.key,
    String? password,
  }) async {
    final id = _nextId();
    final host = RemoteHost(
      id: id,
      name: name,
      sshTarget: sshTarget,
      port: port,
      auth: auth,
    );
    if (auth == RemoteHostAuth.password) {
      await _passwords.write(id, password);
    }
    await _store.save(host);
    notifyListeners();
  }

  /// Há senha guardada no Keychain para este host? (pro dialog de edição saber
  /// se pode manter a atual sem re-digitar.)
  Future<bool> hasStoredPassword(String hostId) async =>
      (await _passwords.read(hostId))?.isNotEmpty ?? false;

  /// Pins de workspace remoto (pastas fixadas).
  List<RemoteWorkspacePin> get pins => _store.pins();

  /// Fixa uma pasta [path] do host [hostId] como workspace (idempotente por
  /// (host, pasta)); devolve o pin.
  Future<RemoteWorkspacePin> addPin({
    required String hostId,
    required String path,
    String realmId = 'default',
    int order = 0,
  }) async {
    final name = _basename(path);
    final pin = RemoteWorkspacePin(
      id: RemoteWorkspacePin.idFor(hostId, path),
      hostId: hostId,
      path: path,
      name: name.isEmpty ? path : name,
      realmId: realmId,
      order: order,
    );
    await _store.savePin(pin);
    notifyListeners();
    return pin;
  }

  Future<void> removePin(String id) async {
    await _store.removePin(id);
    notifyListeners();
  }

  /// Atualiza a personalização de um pin (nome/cor/imagem de fundo) — o que as
  /// Configurações do workspace remoto editam. Nome vazio é ignorado; passar
  /// `imagePath: null` **remove** a imagem (a sentinela do copyWith distingue
  /// "não mexer" de "limpar"). Pin inexistente = no-op silencioso.
  Future<void> updatePin(
    String id, {
    String? name,
    int? colorValue,
    Object? imagePath = RemoteWorkspacePin.unsetImage,
    String? realmId,
    int? order,
  }) async {
    RemoteWorkspacePin? pin;
    for (final p in _store.pins()) {
      if (p.id == id) {
        pin = p;
        break;
      }
    }
    if (pin == null) return;
    final cleanName = name?.trim();
    await _store.savePin(
      pin.copyWith(
        name: (cleanName != null && cleanName.isNotEmpty) ? cleanName : null,
        colorValue: colorValue,
        imagePath: imagePath,
        realmId: realmId,
        order: order,
      ),
    );
    notifyListeners();
  }

  static String _basename(String path) {
    final trimmed = path.endsWith('/') && path.length > 1
        ? path.substring(0, path.length - 1)
        : path;
    final idx = trimmed.lastIndexOf('/');
    return idx < 0 ? trimmed : trimmed.substring(idx + 1);
  }

  /// Edita nome, endpoint (host/porta) e/ou auth de um host (mesmo id). Qualquer
  /// mudança de endpoint/auth derruba a conexão viva (recriada no próximo uso).
  /// [password] `null` mantém a senha guardada; string nova a substitui.
  Future<void> editHost(
    String id, {
    String? name,
    String? sshTarget,
    int? port,
    RemoteHostAuth? auth,
    String? password,
  }) async {
    RemoteHost? host;
    for (final h in _store.hosts()) {
      if (h.id == id) {
        host = h;
        break;
      }
    }
    if (host == null) return;
    final newName =
        (name?.trim().isNotEmpty ?? false) ? name!.trim() : host.name;
    final newTarget = (sshTarget?.trim().isNotEmpty ?? false)
        ? sshTarget!.trim()
        : host.sshTarget;
    final newPort = port ?? host.port;
    final newAuth = auth ?? host.auth;

    // Senha: aplica a nova se veio; some do Keychain ao trocar pra chave.
    if (newAuth == RemoteHostAuth.password) {
      if (password != null && password.isNotEmpty) {
        await _passwords.write(id, password);
      }
    } else {
      await _passwords.remove(id);
    }

    if (newTarget != host.sshTarget ||
        newPort != host.port ||
        newAuth != host.auth) {
      // Endpoint/auth mudou → a conexão atual não vale mais.
      await _connectors.remove(id)?.dispose();
    }
    await _store.save(
      host.copyWith(
        name: newName,
        sshTarget: newTarget,
        port: newPort,
        auth: newAuth,
      ),
    );
    notifyListeners();
  }

  /// Remove o host, seus workspaces (pins) e encerra a conexão.
  Future<void> removeHost(String id) async {
    for (final pin in _store.pins().where((p) => p.hostId == id).toList()) {
      await _store.removePin(pin.id);
    }
    await _connectors.remove(id)?.dispose();
    await _passwords.remove(id);
    await _store.remove(id);
    notifyListeners();
  }

  // id determinístico simples (Date.now/Random não estão disponíveis em alguns
  // caminhos; aqui é UI, mas mantemos previsível): maior sufixo + 1.
  String _nextId() {
    final existing = hosts
        .map((h) => int.tryParse(h.id) ?? 0)
        .fold<int>(0, (a, b) => a > b ? a : b);
    return '${existing + 1}';
  }

  String? _resolveLocalServerBinary() =>
      SidecarTerminalConnector.resolveServerBundleBinary();

  @override
  void dispose() {
    for (final connector in _connectors.values) {
      connector.dispose();
    }
    _connectors.clear();
    unawaited(_turnStatus.close());
    super.dispose();
  }
}

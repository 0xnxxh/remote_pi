import 'dart:async';
import 'dart:io';

import 'package:cockpit/app/cockpit/data/remote/ssh_tunnel.dart';
import 'package:cockpit/app/cockpit/domain/entities/remote_host.dart';
import 'package:cockpit_core/cockpit_core.dart';
import 'package:cockpit_remote/cockpit_remote.dart';

/// Estado observável da conexão com um host (badge/telas da UI, plano 58).
enum RemoteHostPhase {
  idle,
  openingTunnel,
  installingServer,
  connecting,
  connected,
  reconnecting,
  failed,
}

/// Falha tipada da abertura (a frase nasce na UI via context.t; `detail` é
/// texto cru de terceiros: stderr do ssh, mensagem de socket).
enum RemoteHostErrorKind {
  sshUnreachable,
  serverInstallFailed,
  versionMismatch,
  protocol,
}

class RemoteHostException implements Exception {
  const RemoteHostException(this.kind, [this.detail]);
  final RemoteHostErrorKind kind;
  final String? detail;

  @override
  String toString() => 'RemoteHostException(${kind.name}: $detail)';
}

/// Conecta a um [RemoteHost] via túnel SSH e entrega o [TerminalService]
/// remoto daquele host (plano 58, Wave 2).
///
/// Fluxo de abertura (as fases alimentam o loading progressivo da UI):
/// 1. túnel SSH pro socket do cockpit-server remoto;
/// 2. conexão + handshake; se o servidor não existe lá, **bootstrap pelo
///    próprio SSH** (Install server): sobe binário + dylib do bundle local e
///    inicia o servidor remoto;
/// 3. serviço pronto. Queda do túnel → [phase] = reconnecting e retry com
///    backoff; sessões sobrevivem no servidor remoto (semântica tmux).
class RemoteHostConnector {
  RemoteHostConnector(this.host, {required this.localServerBinaryResolver});

  final RemoteHost host;

  /// Resolve o binário local do cockpit-server (o mesmo do sidecar) usado
  /// como fonte do bootstrap. Mac→Mac de mesma arquitetura; a validação de
  /// arch remota é o `--version` pós-instalação falhar alto.
  final String? Function() localServerBinaryResolver;

  SshTunnel? _tunnel;
  RemoteConnection? _connection;
  RemoteTerminalService? _service;
  Future<RemoteTerminalService>? _inflight;

  final StreamController<RemoteHostPhase> _phases =
      StreamController.broadcast();
  RemoteHostPhase phase = RemoteHostPhase.idle;

  Stream<RemoteHostPhase> get phases => _phases.stream;

  void _setPhase(RemoteHostPhase value) {
    phase = value;
    _phases.add(value);
  }

  /// Serviço de terminais do host, abrindo (ou reabrindo) a conexão se
  /// preciso. Lança [RemoteHostException] tipada em falha de abertura.
  Future<RemoteTerminalService> ensure() {
    final connection = _connection;
    if (connection != null && connection.isOpen) {
      return Future.value(_service!);
    }
    return _inflight ??= _open().whenComplete(() => _inflight = null);
  }

  /// Serviço de arquivos do host (mesma conexão dos terminais). Conecta se
  /// preciso; usado pelo picker de pasta remota.
  Future<RemoteFileService> fileService() async {
    await ensure();
    return RemoteFileService(_connection!);
  }

  /// Serviço git do host (mesma conexão). Conecta se preciso.
  Future<RemoteGitService> gitService() async {
    await ensure();
    return RemoteGitService(_connection!);
  }

  /// Serviço de DB do host (mesma conexão). Conecta se preciso.
  Future<RemoteDbService> dbService() async {
    await ensure();
    return RemoteDbService(_connection!);
  }

  Future<RemoteTerminalService> _open() async {
    _setPhase(
      phase == RemoteHostPhase.connected
          ? RemoteHostPhase.reconnecting
          : RemoteHostPhase.openingTunnel,
    );
    final SshTunnel tunnel;
    try {
      tunnel = await SshTunnel.open(target: host.sshTarget);
    } on SshTunnelException catch (e) {
      _setPhase(RemoteHostPhase.failed);
      throw RemoteHostException(RemoteHostErrorKind.sshUnreachable, e.detail);
    }
    _tunnel = tunnel;
    unawaited(tunnel.closed.then((_) => _onTunnelClosed()));

    _setPhase(RemoteHostPhase.connecting);
    var connection = await _tryProtocol(tunnel);
    if (connection == null) {
      // Servidor ausente/parado no host: bootstrap pelo próprio SSH.
      _setPhase(RemoteHostPhase.installingServer);
      await _installAndStartServer();
      connection = await _tryProtocol(tunnel, attempts: 20);
      if (connection == null) {
        _setPhase(RemoteHostPhase.failed);
        throw const RemoteHostException(
          RemoteHostErrorKind.serverInstallFailed,
        );
      }
    }
    _connection = connection;
    _service = RemoteTerminalService(connection);
    _setPhase(RemoteHostPhase.connected);
    return _service!;
  }

  Future<RemoteConnection?> _tryProtocol(
    SshTunnel tunnel, {
    int attempts = 1,
  }) async {
    for (var i = 0; i < attempts; i++) {
      if (i > 0) {
        await Future<void>.delayed(Duration(milliseconds: 100 + i * 50));
      }
      try {
        return await RemoteConnection.connect(
          tunnel.localSocketPath,
          clientName: 'cockpit-gui-ssh',
        );
      } on TerminalException catch (e) {
        // Handshake respondeu com erro = servidor existe mas incompatível.
        if (e.detail == 'version_mismatch') {
          _setPhase(RemoteHostPhase.failed);
          throw RemoteHostException(RemoteHostErrorKind.versionMismatch);
        }
        // protocol/transport → servidor provavelmente ausente; tenta de novo.
      } catch (_) {
        // socket remoto sem listener; segue pro retry/bootstrap.
      }
    }
    return null;
  }

  /// "Install server": sobe binário + dylib pelo canal SSH (stdin → arquivo,
  /// sem depender de scp/rsync no host) e inicia o servidor remoto no socket
  /// padrão. `--exit-on-idle 120`: o servidor sobrevive a um blip de túnel
  /// (reconexão restabelece o cliente e rearma o timer), mas se encerra sozinho
  /// ~2min depois que o app fecha de vez — sem órfão no host. Persistência 24/7
  /// gerida por launchd/systemd fica pra Wave 3.
  static const _remoteIdleSeconds = 120;
  Future<void> _installAndStartServer() async {
    final binary = localServerBinaryResolver();
    if (binary == null) {
      throw const RemoteHostException(
        RemoteHostErrorKind.serverInstallFailed,
        'local cockpit-server binary not found',
      );
    }
    // Bundle: <root>/bin/cockpit-server + <root>/lib/*.dylib (anaki + pty). O
    // exe resolve as dylibs em @executable_path/../lib, então preservamos o
    // layout no host (~/.cockpit/server/{bin,lib}).
    final bundleRoot = File(binary).parent.parent.path;
    final libDir = Directory('$bundleRoot/lib');

    Future<void> push(String local, String remote) async {
      final bytes = await File(local).readAsBytes();
      final (code, stderrText) = await SshTunnel.run(
        host.sshTarget,
        'mkdir -p ~/.cockpit/server/bin ~/.cockpit/server/lib && '
        'cat > $remote && chmod +x $remote',
        stdinBytes: bytes,
      );
      if (code != 0) {
        throw RemoteHostException(
          RemoteHostErrorKind.serverInstallFailed,
          stderrText,
        );
      }
    }

    await push(binary, '~/.cockpit/server/bin/cockpit-server');
    if (libDir.existsSync()) {
      for (final f in libDir.listSync().whereType<File>()) {
        if (!f.path.endsWith('.dylib') && !f.path.endsWith('.so')) continue;
        await push(f.path, '~/.cockpit/server/lib/${f.uri.pathSegments.last}');
      }
    }

    final (code, stderrText) = await SshTunnel.run(
      host.sshTarget,
      // nohup + redirects: o servidor sobrevive ao fim desta sessão ssh. O pty
      // vem do ../lib do bundle; o anaki resolve por rpath.
      'COCKPIT_PTY_DYLIB=\$HOME/.cockpit/server/lib/libcockpit_pty.dylib '
      'nohup \$HOME/.cockpit/server/bin/cockpit-server '
      '--socket \$HOME/.cockpit/cockpit-server.sock '
      '--exit-on-idle $_remoteIdleSeconds '
      '>/dev/null 2>&1 & echo started',
    );
    if (code != 0) {
      throw RemoteHostException(
        RemoteHostErrorKind.serverInstallFailed,
        stderrText,
      );
    }
  }

  void _onTunnelClosed() {
    if (phase == RemoteHostPhase.connected) {
      _setPhase(RemoteHostPhase.reconnecting);
    }
  }

  Future<void> dispose() async {
    await _connection?.close();
    await _tunnel?.close();
    _connection = null;
    _service = null;
    await _phases.close();
  }
}

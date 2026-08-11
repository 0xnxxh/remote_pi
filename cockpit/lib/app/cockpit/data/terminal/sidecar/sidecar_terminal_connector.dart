import 'dart:async';
import 'dart:io';

import 'package:cockpit/app/core/utils/user_home.dart';
import 'package:cockpit_remote/cockpit_remote.dart';
import 'package:flutter/foundation.dart';

/// Garante um `cockpit-server` sidecar de pé e devolve o serviço de terminais
/// remoto conectado a ele via loopback (plano 58, Wave 1).
///
/// Ciclo de vida (decisões F/I do plano):
/// - **Descoberta antes de spawn**: se o socket responde, adota o servidor
///   existente — nunca dois servidores no mesmo estado.
/// - Se ninguém responde, spawna o binário como filho com `--exit-on-idle`,
///   que é o seguro contra órfão (GUI morreu sem matar o filho → o servidor
///   se encerra sozinho ao ficar sem clientes).
/// - `null` = sidecar indisponível (binário não empacotado/ambiente mínimo);
///   o chamador faz fallback pro PTY in-process e o app segue como antes.
class SidecarTerminalConnector {
  RemoteConnection? _connection;
  RemoteTerminalService? _service;
  Future<RemoteTerminalService?>? _inflight;
  Process? _child;

  /// Serviço conectado, reusando a conexão viva; reconecta (ou respawna) se
  /// o sidecar caiu. Nunca lança: falha vira `null` (fallback local).
  Future<RemoteTerminalService?> ensure() {
    final connection = _connection;
    if (connection != null && connection.isOpen) {
      return Future.value(_service);
    }
    return _inflight ??= _connect().whenComplete(() => _inflight = null);
  }

  Future<RemoteTerminalService?> _connect() async {
    try {
      final socketPath = _socketPath();
      if (socketPath == null) return null;

      // 1. Descoberta: já existe servidor atendendo este socket?
      final adopted = await _tryConnect(socketPath);
      if (adopted != null) return _adopt(adopted);

      // 2. Spawn do sidecar.
      final binary = _resolveServerBinary();
      if (binary == null) {
        debugPrint('sidecar: cockpit-server binary not found, using local PTY');
        return null;
      }
      final dylib = File('${File(binary).parent.path}/libcockpit_pty.dylib');
      _child = await Process.start(
        binary,
        ['--socket', socketPath, '--exit-on-idle', '15'],
        environment: {
          ...Platform.environment,
          if (dylib.existsSync()) 'COCKPIT_PTY_DYLIB': dylib.path,
        },
      );
      // Drena stdout/stderr: pipe cheio bloquearia o servidor (e SIGPIPE já
      // é tratado no AppDelegate, lição do fechamento silencioso).
      unawaited(_child!.stdout.drain<void>());
      unawaited(_child!.stderr.drain<void>());

      // 3. Retry com backoff curto até o listener subir.
      for (var attempt = 0; attempt < 20; attempt++) {
        await Future<void>.delayed(Duration(milliseconds: 50 + attempt * 25));
        final connection = await _tryConnect(socketPath);
        if (connection != null) return _adopt(connection);
      }
      debugPrint('sidecar: server did not come up, using local PTY');
      return null;
    } catch (e) {
      debugPrint('sidecar: unavailable ($e), using local PTY');
      return null;
    }
  }

  RemoteTerminalService _adopt(RemoteConnection connection) {
    _connection = connection;
    return _service = RemoteTerminalService(connection);
  }

  Future<RemoteConnection?> _tryConnect(String socketPath) async {
    if (!File(socketPath).existsSync()) return null;
    try {
      return await RemoteConnection.connect(
        socketPath,
        clientName: 'cockpit-gui',
      );
    } catch (_) {
      return null; // socket velho/morto; o bind do servidor novo o substitui.
    }
  }

  String? _socketPath() {
    final home = userHome();
    if (home == null) return null;
    final dir = Directory('$home/.cockpit');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return '${dir.path}/cockpit-server.sock';
  }

  /// Ordem: env de override → Resources do bundle (empacotado pelo
  /// `macos/build_server.sh`) → binário app-managed (`~/.cockpit/bin`, mesmo
  /// lar da CLI interna) → build de dev no cwd (fluxo `flutter run` no repo).
  String? _resolveServerBinary() {
    final candidates = <String?>[
      Platform.environment['COCKPIT_SERVER_BIN'],
      if (Platform.isMacOS)
        // .app/Contents/MacOS/<exe> → ../Resources/cockpit-server
        '${File(Platform.resolvedExecutable).parent.parent.path}'
            '/Resources/cockpit-server',
      () {
        final home = userHome();
        return home == null ? null : '$home/.cockpit/bin/cockpit-server';
      }(),
      '${Directory.current.path}/build/wave0/cockpit-server',
    ];
    for (final candidate in candidates) {
      if (candidate != null && File(candidate).existsSync()) return candidate;
    }
    return null;
  }

  Future<void> dispose() async {
    await _connection?.close();
    _connection = null;
    _service = null;
    // Cortesia: pede pro filho sair já; o --exit-on-idle é o fallback.
    _child?.kill(ProcessSignal.sigterm);
    _child = null;
  }
}

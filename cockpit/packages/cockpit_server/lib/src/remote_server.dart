import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cockpit_core/cockpit_core.dart';
import 'package:cockpit_protocol/cockpit_protocol.dart';

/// Servidor do protocolo Cockpit Remote sobre socket local (UDS).
///
/// Sessões pertencem ao [TerminalService], não às conexões: um cliente que
/// desconecta faz detach implícito e a sessão continua viva (reattach later).
class RemoteServer {
  RemoteServer(this._terminals, {this.serverVersion = '0.1.0'});

  final TerminalService _terminals;
  final String serverVersion;
  static const _codec = RemoteMessageCodec();

  ServerSocket? _listener;
  final Set<_Connection> _connections = {};

  /// Modo sidecar: quando > Duration.zero, o servidor se encerra sozinho se
  /// ficar esse tempo sem NENHUM cliente conectado (evita órfão quando a GUI
  /// morre sem conseguir matar o filho). Zero = nunca (modo serviço).
  Duration exitOnIdle = Duration.zero;
  Timer? _idleTimer;
  void Function()? onIdleExit;

  void _armIdleTimer() {
    _idleTimer?.cancel();
    if (exitOnIdle == Duration.zero || _connections.isNotEmpty) return;
    _idleTimer = Timer(exitOnIdle, () {
      if (_connections.isEmpty) onIdleExit?.call();
    });
  }

  Future<void> bind(String socketPath) async {
    final file = File(socketPath);
    if (file.existsSync()) file.deleteSync();
    _listener = await ServerSocket.bind(
      InternetAddress(socketPath, type: InternetAddressType.unix),
      0,
    );
    _listener!.listen(_accept);
    _armIdleTimer();
  }

  Future<void> close() async {
    for (final connection in _connections.toList()) {
      await connection.close();
    }
    await _listener?.close();
    await _terminals.dispose();
  }

  void _accept(Socket socket) {
    final connection = _Connection(socket, _terminals, serverVersion);
    _connections.add(connection);
    _idleTimer?.cancel();
    connection.done.whenComplete(() {
      _connections.remove(connection);
      _armIdleTimer();
    });
  }
}

class _Connection {
  _Connection(this._socket, this._terminals, this._serverVersion) {
    RemoteServer._codec
        .decodeStream(_socket)
        .listen(
          // Dispatch SERIALIZADO por conexão: o listen não espera handlers
          // async, então sem a corrente um pty.list ultrapassa um pty.kill
          // em andamento e a resposta observa estado antigo.
          (message) => _pending = _pending.then((_) => _dispatch(message)),
          onError: (Object _) => close(),
          onDone: close,
        );
  }

  Future<void> _pending = Future.value();

  final Socket _socket;
  final TerminalService _terminals;
  final String _serverVersion;

  final Map<String, StreamSubscription<PtyEvent>> _attachments = {};
  final Completer<void> _done = Completer();
  bool _handshaken = false;
  bool _closed = false;

  Future<void> get done => _done.future;

  void _send(RemoteMessage message) {
    if (_closed) return;
    _socket.add(utf8.encode(RemoteServer._codec.encode(message)));
  }

  Future<void> _dispatch(RemoteMessage message) async {
    try {
      if (!_handshaken) {
        if (message is! Hello) {
          _send(const RemoteError(code: 'handshake_required'));
          return close();
        }
        if (message.version != protocolVersion) {
          _send(
            RemoteError(
              code: 'version_mismatch',
              detail: 'server=$protocolVersion client=${message.version}',
            ),
          );
          return close();
        }
        _handshaken = true;
        _send(HelloAck(version: protocolVersion, server: _serverVersion));
        return;
      }

      switch (message) {
        case PtyOpen():
          final info = await _terminals.open(
            PtySpawnSpec(
              executable: message.executable,
              arguments: message.arguments,
              workingDirectory: message.workingDirectory,
              environment: message.environment,
              rows: message.rows,
              columns: message.columns,
            ),
          );
          _send(PtyOpened(sessionId: info.id, pid: info.pid));

        case PtyList():
          final sessions = await _terminals.sessions();
          _send(
            PtySessions(
              sessions: [
                for (final s in sessions)
                  {
                    'id': s.id,
                    'pid': s.pid,
                    'cmd': s.executable,
                    'rows': s.rows,
                    'cols': s.columns,
                    'len': s.scrollbackLength,
                    if (s.exitCode != null) 'exit': s.exitCode,
                  },
              ],
            ),
          );

        case PtyAttach():
          await _attachments.remove(message.sessionId)?.cancel();
          _attachments[message.sessionId] = _terminals
              .attach(message.sessionId, fromOffset: message.fromOffset)
              .listen(
                (event) => switch (event) {
                  PtyOutputEvent(:final chunk) => _send(
                    PtyOutput(
                      sessionId: message.sessionId,
                      offset: chunk.offset,
                      bytes: chunk.bytes,
                    ),
                  ),
                  PtyExitEvent(:final exitCode) => _send(
                    PtyExited(sessionId: message.sessionId, exitCode: exitCode),
                  ),
                },
              );

        case PtyDetach():
          await _attachments.remove(message.sessionId)?.cancel();

        case PtyInput():
          await _terminals.write(message.sessionId, message.bytes);

        case PtyAck():
          await _terminals.ack(message.sessionId, message.bytes);

        case PtyResize():
          await _terminals.resize(
            message.sessionId,
            message.rows,
            message.columns,
          );

        case PtyKill():
          await _attachments.remove(message.sessionId)?.cancel();
          await _terminals.kill(message.sessionId);

        case Hello() ||
            HelloAck() ||
            PtyOpened() ||
            PtySessions() ||
            PtyOutput() ||
            PtyExited() ||
            RemoteError():
          _send(const RemoteError(code: 'bad_message'));
      }
    } on TerminalException catch (e) {
      _send(RemoteError(code: e.kind.name, detail: e.detail));
    } catch (e) {
      _send(RemoteError(code: 'internal', detail: '$e'));
    }
  }

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    for (final sub in _attachments.values) {
      await sub.cancel();
    }
    _attachments.clear();
    _socket.destroy();
    if (!_done.isCompleted) _done.complete();
  }
}

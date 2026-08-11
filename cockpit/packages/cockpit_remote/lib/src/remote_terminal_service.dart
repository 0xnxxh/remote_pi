import 'dart:async';
import 'dart:typed_data';

import 'package:cockpit_core/cockpit_core.dart';
import 'package:cockpit_protocol/cockpit_protocol.dart';

import 'remote_connection.dart';

/// Proxy do [TerminalService] falando o protocolo com um cockpit-server.
///
/// A UI consome este e o nativo pelo MESMO contrato; a diferença é só a
/// composição (plano 58, "Arquitetura de pacotes").
class RemoteTerminalService implements TerminalService {
  RemoteTerminalService(this._connection);

  final RemoteConnection _connection;

  @override
  Future<PtySessionInfo> open(PtySpawnSpec spec) async {
    final reply = _firstReply((m) => m is PtyOpened || m is RemoteError);
    _connection.send(
      PtyOpen(
        executable: spec.executable,
        arguments: spec.arguments,
        workingDirectory: spec.workingDirectory,
        environment: spec.environment,
        rows: spec.rows,
        columns: spec.columns,
      ),
    );
    final message = await reply;
    if (message is RemoteError) throw _asException(message);
    final opened = message as PtyOpened;
    return PtySessionInfo(
      id: opened.sessionId,
      pid: opened.pid,
      executable: spec.executable,
      rows: spec.rows,
      columns: spec.columns,
      scrollbackLength: 0,
    );
  }

  @override
  Future<List<PtySessionInfo>> sessions() async {
    final reply = _firstReply((m) => m is PtySessions || m is RemoteError);
    _connection.send(const PtyList());
    final message = await reply;
    if (message is RemoteError) throw _asException(message);
    final sessions = (message as PtySessions).sessions;
    return [
      for (final s in sessions)
        PtySessionInfo(
          id: s['id'] as String,
          pid: s['pid'] as int,
          executable: s['cmd'] as String,
          rows: s['rows'] as int,
          columns: s['cols'] as int,
          scrollbackLength: s['len'] as int,
          exitCode: s['exit'] as int?,
        ),
    ];
  }

  @override
  Stream<PtyEvent> attach(String sessionId, {int fromOffset = 0}) {
    late StreamController<PtyEvent> controller;
    StreamSubscription<RemoteMessage>? sub;
    controller = StreamController<PtyEvent>(
      onListen: () {
        sub = _connection.messages.listen((message) {
          if (message is PtyOutput && message.sessionId == sessionId) {
            controller.add(
              PtyOutputEvent(
                PtyOutputChunk(offset: message.offset, bytes: message.bytes),
              ),
            );
          } else if (message is PtyExited && message.sessionId == sessionId) {
            controller.add(PtyExitEvent(message.exitCode));
          } else if (message is RemoteError && message.sessionId == sessionId) {
            controller.addError(_asException(message));
          }
        }, onDone: controller.close);
        _connection.send(
          PtyAttach(sessionId: sessionId, fromOffset: fromOffset),
        );
      },
      onCancel: () {
        _connection.send(PtyDetach(sessionId: sessionId));
        return sub?.cancel();
      },
    );
    return controller.stream;
  }

  @override
  Future<void> write(String sessionId, Uint8List data) async =>
      _connection.send(PtyInput(sessionId: sessionId, bytes: data));

  @override
  Future<void> resize(String sessionId, int rows, int columns) async =>
      _connection.send(
        PtyResize(sessionId: sessionId, rows: rows, columns: columns),
      );

  @override
  Future<void> kill(String sessionId) async =>
      _connection.send(PtyKill(sessionId: sessionId));

  @override
  Future<void> dispose() => _connection.close();

  Future<RemoteMessage> _firstReply(bool Function(RemoteMessage) test) =>
      _connection.messages.firstWhere(test);

  static TerminalException _asException(RemoteError error) {
    final kind =
        TerminalErrorKind.values.asNameMap()[error.code] ??
        TerminalErrorKind.protocol;
    return TerminalException(kind, error.detail);
  }
}

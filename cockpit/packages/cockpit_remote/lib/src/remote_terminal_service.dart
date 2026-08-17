import 'dart:async';
import 'dart:typed_data';

import 'package:cockpit_core/cockpit_core.dart';
import 'package:cockpit_protocol/cockpit_protocol.dart';

import 'remote_connection.dart';

/// Status de turno de um agente numa PTY do host (plano 60, Wave G), tipo
/// neutro pro cliente — não expõe a mensagem do protocolo. [paneId] é o
/// `COCKPIT_PANE_ID` da aba (roteamento); [status] é `working`/`idle`/`waiting`.
class RemoteTurnStatus {
  const RemoteTurnStatus({
    required this.paneId,
    required this.status,
    this.event,
    this.sid,
    this.transcriptPath,
    this.harness,
  });

  final String paneId;
  final String status;
  final String? event;
  final String? sid;
  final String? transcriptPath;
  final String? harness;
}

/// Proxy do [TerminalService] falando o protocolo com um cockpit-server.
///
/// A UI consome este e o nativo pelo MESMO contrato; a diferença é só a
/// composição (plano 58, "Arquitetura de pacotes").
class RemoteTerminalService implements TerminalService {
  RemoteTerminalService(this._connection);

  final RemoteConnection _connection;

  /// Eventos de status de turno vindos do host (broadcast do protocolo). Fora
  /// do contrato [TerminalService]; consumido pelo connector/gateway remoto.
  Stream<RemoteTurnStatus> get turnStatus => _connection.messages
      .where((m) => m is TurnStatus)
      .cast<TurnStatus>()
      .map(
        (m) => RemoteTurnStatus(
          paneId: m.paneId,
          status: m.status,
          event: m.event,
          sid: m.sid,
          transcriptPath: m.transcriptPath,
          harness: m.harness,
        ),
      );

  @override
  Future<PtySessionInfo> open(PtySpawnSpec spec) async {
    final rid = _nextRid();
    final reply = _firstReply(
      (m) =>
          (m is PtyOpened && m.rid == rid) ||
          (m is RemoteError && m.rid == rid),
    );
    _connection.send(
      PtyOpen(
        rid: rid,
        executable: spec.executable,
        arguments: spec.arguments,
        workingDirectory: spec.workingDirectory,
        environment: spec.environment,
        rows: spec.rows,
        columns: spec.columns,
        flowControlled: spec.flowControlled,
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
    final rid = _nextRid();
    final reply = _firstReply(
      (m) =>
          (m is PtySessions && m.rid == rid) ||
          (m is RemoteError && m.rid == rid),
    );
    _connection.send(PtyList(rid: rid));
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
  Future<void> ack(String sessionId, int bytes) async =>
      _connection.send(PtyAck(sessionId: sessionId, bytes: bytes));

  @override
  Future<void> kill(String sessionId) async =>
      _connection.send(PtyKill(sessionId: sessionId));

  @override
  Future<void> dispose() => _connection.close();

  Future<RemoteMessage> _firstReply(bool Function(RemoteMessage) test) =>
      _connection.messages.firstWhere(test);

  /// Id de correlação, crescente por conexão. O casamento request/response é
  /// por ele — NUNCA só pelo tipo da mensagem: `messages` é broadcast, então
  /// duas chamadas em voo ao mesmo tempo eram resolvidas as duas pela primeira
  /// resposta que chegasse (dois panes restaurados juntos adotavam o mesmo
  /// `sessionId` e espelhavam o mesmo PTY).
  int _nextRid() => ++_rid;
  int _rid = 0;

  static TerminalException _asException(RemoteError error) {
    final kind =
        TerminalErrorKind.values.asNameMap()[error.code] ??
        TerminalErrorKind.protocol;
    return TerminalException(kind, error.detail);
  }
}

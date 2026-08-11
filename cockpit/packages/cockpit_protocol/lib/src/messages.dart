import 'dart:convert';
import 'dart:typed_data';

/// Versão do protocolo. Incrementa em mudança incompatível; o handshake
/// rejeita versões diferentes (cliente decide se faz bootstrap/update).
const int protocolVersion = 1;

/// Mensagem do protocolo. Envelope JSON: `{"t": "<tipo>", ...campos}`.
sealed class RemoteMessage {
  const RemoteMessage();

  String get type;

  Map<String, Object?> toJson();

  static RemoteMessage fromJson(Map<String, Object?> json) {
    final t = json['t'];
    return switch (t) {
      Hello.kType => Hello.fromJson(json),
      HelloAck.kType => HelloAck.fromJson(json),
      PtyOpen.kType => PtyOpen.fromJson(json),
      PtyOpened.kType => PtyOpened.fromJson(json),
      PtyList.kType => const PtyList(),
      PtySessions.kType => PtySessions.fromJson(json),
      PtyAttach.kType => PtyAttach.fromJson(json),
      PtyDetach.kType => PtyDetach.fromJson(json),
      PtyInput.kType => PtyInput.fromJson(json),
      PtyAck.kType => PtyAck.fromJson(json),
      PtyOutput.kType => PtyOutput.fromJson(json),
      PtyResize.kType => PtyResize.fromJson(json),
      PtyKill.kType => PtyKill.fromJson(json),
      PtyExited.kType => PtyExited.fromJson(json),
      RemoteError.kType => RemoteError.fromJson(json),
      _ => throw FormatException('unknown message type: $t'),
    };
  }
}

// ---------------------------------------------------------------------------
// Handshake
// ---------------------------------------------------------------------------

class Hello extends RemoteMessage {
  const Hello({required this.version, required this.client});
  static const kType = 'hello';

  final int version;
  final String client;

  factory Hello.fromJson(Map<String, Object?> j) =>
      Hello(version: j['v'] as int, client: j['client'] as String);

  @override
  String get type => kType;
  @override
  Map<String, Object?> toJson() => {'t': kType, 'v': version, 'client': client};
}

class HelloAck extends RemoteMessage {
  const HelloAck({required this.version, required this.server});
  static const kType = 'hello.ack';

  final int version;
  final String server;

  factory HelloAck.fromJson(Map<String, Object?> j) =>
      HelloAck(version: j['v'] as int, server: j['server'] as String);

  @override
  String get type => kType;
  @override
  Map<String, Object?> toJson() => {'t': kType, 'v': version, 'server': server};
}

// ---------------------------------------------------------------------------
// Terminais
// ---------------------------------------------------------------------------

class PtyOpen extends RemoteMessage {
  const PtyOpen({
    required this.executable,
    this.arguments = const [],
    this.workingDirectory,
    this.environment = const {},
    this.rows = 24,
    this.columns = 80,
    this.flowControlled = false,
  });
  static const kType = 'pty.open';

  final String executable;
  final List<String> arguments;
  final String? workingDirectory;
  final Map<String, String> environment;
  final int rows;
  final int columns;

  /// Backpressure fim-a-fim: o servidor abre o PTY com `ackRead` e gate por
  /// janela de créditos; o cliente devolve `pty.ack` por chunk consumido.
  final bool flowControlled;

  factory PtyOpen.fromJson(Map<String, Object?> j) => PtyOpen(
    executable: j['cmd'] as String,
    arguments: (j['args'] as List? ?? const []).cast<String>(),
    workingDirectory: j['cwd'] as String?,
    environment: (j['env'] as Map? ?? const {}).cast<String, String>(),
    rows: j['rows'] as int? ?? 24,
    columns: j['cols'] as int? ?? 80,
    flowControlled: j['flow'] as bool? ?? false,
  );

  @override
  String get type => kType;
  @override
  Map<String, Object?> toJson() => {
    't': kType,
    'cmd': executable,
    'args': arguments,
    if (workingDirectory != null) 'cwd': workingDirectory,
    if (environment.isNotEmpty) 'env': environment,
    'rows': rows,
    'cols': columns,
    if (flowControlled) 'flow': true,
  };
}

/// Crédito de flow control: o cliente consumiu [bytes] de `pty.output` da
/// sessão. O servidor abate da janela pendente e libera a leitura nativa.
class PtyAck extends RemoteMessage {
  const PtyAck({required this.sessionId, required this.bytes});
  static const kType = 'pty.ack';

  final String sessionId;
  final int bytes;

  factory PtyAck.fromJson(Map<String, Object?> j) =>
      PtyAck(sessionId: j['id'] as String, bytes: j['n'] as int);

  @override
  String get type => kType;
  @override
  Map<String, Object?> toJson() => {'t': kType, 'id': sessionId, 'n': bytes};
}

class PtyOpened extends RemoteMessage {
  const PtyOpened({required this.sessionId, required this.pid});
  static const kType = 'pty.opened';

  final String sessionId;
  final int pid;

  factory PtyOpened.fromJson(Map<String, Object?> j) =>
      PtyOpened(sessionId: j['id'] as String, pid: j['pid'] as int);

  @override
  String get type => kType;
  @override
  Map<String, Object?> toJson() => {'t': kType, 'id': sessionId, 'pid': pid};
}

class PtyList extends RemoteMessage {
  const PtyList();
  static const kType = 'pty.list';

  @override
  String get type => kType;
  @override
  Map<String, Object?> toJson() => {'t': kType};
}

class PtySessions extends RemoteMessage {
  const PtySessions({required this.sessions});
  static const kType = 'pty.sessions';

  /// Cada item: {id, pid, cmd, rows, cols, len, exit?}
  final List<Map<String, Object?>> sessions;

  factory PtySessions.fromJson(Map<String, Object?> j) => PtySessions(
    sessions: (j['sessions'] as List)
        .cast<Map>()
        .map((m) => m.cast<String, Object?>())
        .toList(),
  );

  @override
  String get type => kType;
  @override
  Map<String, Object?> toJson() => {'t': kType, 'sessions': sessions};
}

class PtyAttach extends RemoteMessage {
  const PtyAttach({required this.sessionId, this.fromOffset = 0});
  static const kType = 'pty.attach';

  final String sessionId;
  final int fromOffset;

  factory PtyAttach.fromJson(Map<String, Object?> j) => PtyAttach(
    sessionId: j['id'] as String,
    fromOffset: j['from'] as int? ?? 0,
  );

  @override
  String get type => kType;
  @override
  Map<String, Object?> toJson() => {
    't': kType,
    'id': sessionId,
    'from': fromOffset,
  };
}

class PtyDetach extends RemoteMessage {
  const PtyDetach({required this.sessionId});
  static const kType = 'pty.detach';

  final String sessionId;

  factory PtyDetach.fromJson(Map<String, Object?> j) =>
      PtyDetach(sessionId: j['id'] as String);

  @override
  String get type => kType;
  @override
  Map<String, Object?> toJson() => {'t': kType, 'id': sessionId};
}

class PtyInput extends RemoteMessage {
  PtyInput({required this.sessionId, required this.bytes});
  static const kType = 'pty.input';

  final String sessionId;
  final Uint8List bytes;

  factory PtyInput.fromJson(Map<String, Object?> j) => PtyInput(
    sessionId: j['id'] as String,
    bytes: base64Decode(j['d'] as String),
  );

  @override
  String get type => kType;
  @override
  Map<String, Object?> toJson() => {
    't': kType,
    'id': sessionId,
    'd': base64Encode(bytes),
  };
}

class PtyOutput extends RemoteMessage {
  PtyOutput({
    required this.sessionId,
    required this.offset,
    required this.bytes,
  });
  static const kType = 'pty.output';

  final String sessionId;

  /// Offset absoluto do primeiro byte deste chunk no stream da sessão.
  final int offset;
  final Uint8List bytes;

  factory PtyOutput.fromJson(Map<String, Object?> j) => PtyOutput(
    sessionId: j['id'] as String,
    offset: j['off'] as int,
    bytes: base64Decode(j['d'] as String),
  );

  @override
  String get type => kType;
  @override
  Map<String, Object?> toJson() => {
    't': kType,
    'id': sessionId,
    'off': offset,
    'd': base64Encode(bytes),
  };
}

class PtyResize extends RemoteMessage {
  const PtyResize({
    required this.sessionId,
    required this.rows,
    required this.columns,
  });
  static const kType = 'pty.resize';

  final String sessionId;
  final int rows;
  final int columns;

  factory PtyResize.fromJson(Map<String, Object?> j) => PtyResize(
    sessionId: j['id'] as String,
    rows: j['rows'] as int,
    columns: j['cols'] as int,
  );

  @override
  String get type => kType;
  @override
  Map<String, Object?> toJson() => {
    't': kType,
    'id': sessionId,
    'rows': rows,
    'cols': columns,
  };
}

class PtyKill extends RemoteMessage {
  const PtyKill({required this.sessionId});
  static const kType = 'pty.kill';

  final String sessionId;

  factory PtyKill.fromJson(Map<String, Object?> j) =>
      PtyKill(sessionId: j['id'] as String);

  @override
  String get type => kType;
  @override
  Map<String, Object?> toJson() => {'t': kType, 'id': sessionId};
}

class PtyExited extends RemoteMessage {
  const PtyExited({required this.sessionId, required this.exitCode});
  static const kType = 'pty.exited';

  final String sessionId;
  final int exitCode;

  factory PtyExited.fromJson(Map<String, Object?> j) =>
      PtyExited(sessionId: j['id'] as String, exitCode: j['code'] as int);

  @override
  String get type => kType;
  @override
  Map<String, Object?> toJson() => {
    't': kType,
    'id': sessionId,
    'code': exitCode,
  };
}

// ---------------------------------------------------------------------------
// Erro
// ---------------------------------------------------------------------------

class RemoteError extends RemoteMessage {
  const RemoteError({required this.code, this.detail, this.sessionId});
  static const kType = 'err';

  /// Código estável (ex.: `session_not_found`, `spawn_failed`,
  /// `version_mismatch`, `bad_message`). A frase nasce na UI.
  final String code;
  final String? detail;
  final String? sessionId;

  factory RemoteError.fromJson(Map<String, Object?> j) => RemoteError(
    code: j['code'] as String,
    detail: j['detail'] as String?,
    sessionId: j['id'] as String?,
  );

  @override
  String get type => kType;
  @override
  Map<String, Object?> toJson() => {
    't': kType,
    'code': code,
    if (detail != null) 'detail': detail,
    if (sessionId != null) 'id': sessionId,
  };
}

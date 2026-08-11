import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:cockpit_core/cockpit_core.dart';
import 'package:ffi/ffi.dart';

import 'pty_bindings.dart';
import 'pty_dylib.dart';
import 'scrollback_buffer.dart';

class _Session {
  _Session({
    required this.info,
    required this.handle,
    required this.stdoutPort,
    required this.exitPort,
    required this.scrollback,
  });

  PtySessionInfo info;
  final Pointer<Void> handle;
  final ReceivePort stdoutPort;
  final ReceivePort exitPort;
  final ScrollbackBuffer scrollback;

  /// Broadcast dos eventos live; attach = replay do scrollback + este stream.
  final StreamController<PtyEvent> live = StreamController.broadcast();
}

/// Implementação nativa do [TerminalService] sobre a dylib do cockpit_pty.
///
/// Sessões pertencem ao serviço: sobrevivem a detach de qualquer cliente e
/// só morrem via [kill] (ou exit do processo, retendo scrollback).
class NativeTerminalService implements TerminalService {
  NativeTerminalService({
    DynamicLibrary? dylib,
    this.scrollbackCapacity = 4 * 1024 * 1024,
  }) : _bindings = PtyBindings(dylib ?? openPtyDylib()) {
    final rc = _bindings.initializeApiDL(NativeApi.initializeApiDLData);
    if (rc != 0) {
      throw const TerminalException(
        TerminalErrorKind.spawnFailed,
        'Dart_InitializeApiDL failed',
      );
    }
  }

  final PtyBindings _bindings;
  final int scrollbackCapacity;
  final Map<String, _Session> _sessions = {};
  int _nextId = 0;

  @override
  Future<PtySessionInfo> open(PtySpawnSpec spec) async {
    final id = 's${++_nextId}';
    final stdoutPort = ReceivePort();
    final exitPort = ReceivePort();

    final arena = Arena();
    final Pointer<Void> handle;
    try {
      final options = arena<PtyOptionsNative>();
      options.ref
        ..rows = spec.rows
        ..cols = spec.columns
        ..executable = spec.executable.toNativeUtf8(allocator: arena).cast()
        ..arguments = _stringArray(arena, [spec.executable, ...spec.arguments])
        ..environment = _stringArray(arena, [
          for (final e in {
            ...Platform.environment,
            ...spec.environment,
          }.entries)
            '${e.key}=${e.value}',
        ])
        ..workingDirectory = (spec.workingDirectory ?? '')
            .toNativeUtf8(allocator: arena)
            .cast()
        ..stdoutPort = stdoutPort.sendPort.nativePort
        ..exitPort = exitPort.sendPort.nativePort
        ..ackRead = false;

      handle = _bindings.create(options);
    } finally {
      arena.releaseAll();
    }

    if (handle == nullptr) {
      stdoutPort.close();
      exitPort.close();
      final err = _bindings.error();
      throw TerminalException(
        TerminalErrorKind.spawnFailed,
        err == nullptr ? null : err.cast<Utf8>().toDartString(),
      );
    }

    final session = _Session(
      info: PtySessionInfo(
        id: id,
        pid: _bindings.getPid(handle),
        executable: spec.executable,
        rows: spec.rows,
        columns: spec.columns,
        scrollbackLength: 0,
      ),
      handle: handle,
      stdoutPort: stdoutPort,
      exitPort: exitPort,
      scrollback: ScrollbackBuffer(capacity: scrollbackCapacity),
    );
    _sessions[id] = session;

    stdoutPort.listen((data) {
      final bytes = data as Uint8List;
      final offset = session.scrollback.totalLength;
      session.scrollback.add(bytes);
      session.info = _withLength(session.info, session.scrollback.totalLength);
      session.live.add(
        PtyOutputEvent(PtyOutputChunk(offset: offset, bytes: bytes)),
      );
    });

    exitPort.listen((code) {
      session.info = _withExit(session.info, code as int);
      session.live.add(PtyExitEvent(code));
      session.stdoutPort.close();
      session.exitPort.close();
    });

    return session.info;
  }

  @override
  Future<List<PtySessionInfo>> sessions() async => [
    for (final s in _sessions.values) s.info,
  ];

  @override
  Stream<PtyEvent> attach(String sessionId, {int fromOffset = 0}) {
    final session = _session(sessionId);

    late StreamController<PtyEvent> controller;
    StreamSubscription<PtyEvent>? liveSub;
    controller = StreamController<PtyEvent>(
      onListen: () {
        // Replay do scrollback retido; o live já está assinado ANTES da
        // leitura para não perder chunks entre replay e assinatura — o
        // filtro por offset descarta o que o replay já cobriu.
        final replay = session.scrollback.read(fromOffset: fromOffset);
        final replayEnd = replay.offset + replay.bytes.length;
        liveSub = session.live.stream.listen((event) {
          if (event is PtyOutputEvent && event.chunk.offset < replayEnd) {
            return;
          }
          controller.add(event);
        }, onDone: controller.close);
        if (replay.bytes.isNotEmpty) {
          controller.add(
            PtyOutputEvent(
              PtyOutputChunk(offset: replay.offset, bytes: replay.bytes),
            ),
          );
        }
        final exit = session.info.exitCode;
        if (exit != null) controller.add(PtyExitEvent(exit));
      },
      onCancel: () => liveSub?.cancel(),
    );
    return controller.stream;
  }

  @override
  Future<void> write(String sessionId, Uint8List data) async {
    final session = _session(sessionId);
    final arena = Arena();
    try {
      final buffer = arena<Uint8>(data.length);
      buffer.asTypedList(data.length).setAll(0, data);
      _bindings.write(session.handle, buffer.cast(), data.length);
    } finally {
      arena.releaseAll();
    }
  }

  @override
  Future<void> resize(String sessionId, int rows, int columns) async {
    final session = _session(sessionId);
    _bindings.resize(session.handle, rows, columns);
    session.info = _withSize(session.info, rows, columns);
  }

  @override
  Future<void> kill(String sessionId) async {
    final session = _session(sessionId);
    _sessions.remove(sessionId);
    if (session.info.isAlive) {
      Process.killPid(session.info.pid, ProcessSignal.sigkill);
    }
    session.stdoutPort.close();
    session.exitPort.close();
    await session.live.close();
  }

  @override
  Future<void> dispose() async {
    for (final id in _sessions.keys.toList()) {
      await kill(id);
    }
  }

  _Session _session(String id) {
    final session = _sessions[id];
    if (session == null) {
      throw TerminalException(TerminalErrorKind.sessionNotFound, id);
    }
    return session;
  }

  static Pointer<Pointer<Char>> _stringArray(Arena arena, List<String> items) {
    final array = arena<Pointer<Char>>(items.length + 1);
    for (var i = 0; i < items.length; i++) {
      array[i] = items[i].toNativeUtf8(allocator: arena).cast();
    }
    array[items.length] = nullptr;
    return array;
  }

  static PtySessionInfo _withLength(PtySessionInfo info, int length) =>
      PtySessionInfo(
        id: info.id,
        pid: info.pid,
        executable: info.executable,
        rows: info.rows,
        columns: info.columns,
        scrollbackLength: length,
        exitCode: info.exitCode,
      );

  static PtySessionInfo _withExit(PtySessionInfo info, int code) =>
      PtySessionInfo(
        id: info.id,
        pid: info.pid,
        executable: info.executable,
        rows: info.rows,
        columns: info.columns,
        scrollbackLength: info.scrollbackLength,
        exitCode: code,
      );

  static PtySessionInfo _withSize(PtySessionInfo info, int rows, int columns) =>
      PtySessionInfo(
        id: info.id,
        pid: info.pid,
        executable: info.executable,
        rows: rows,
        columns: columns,
        scrollbackLength: info.scrollbackLength,
        exitCode: info.exitCode,
      );
}

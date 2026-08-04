import 'package:flutter/scheduler.dart';

/// Acumula saída decodificada do PTY e libera um batch por frame.
///
/// Combina com `ackRead` no PTY nativo:
/// - enquanto o buffer está sob [maxPendingChars], chama [onAcknowledge] a
///   cada chunk para encher o batch até o próximo vsync;
/// - acima do cap, pausa o ack até o flush (backpressure real);
/// - no flush, entrega o batch via [onFlush] e retoma o ack se estava pausado.
///
/// [scheduleFlush] é injetável nos testes (default = um callback por frame).
class PtyOutputCoalescer {
  PtyOutputCoalescer({
    required this.onFlush,
    required this.onAcknowledge,
    this.maxPendingChars = 128 * 1024,
    void Function(void Function() flush)? scheduleFlush,
  }) : _scheduleFlush = scheduleFlush ?? _scheduleOnNextFrame;

  /// Cap do buffer pendente (~128 KiB). Acima disso o ack pausa até o flush.
  final int maxPendingChars;

  /// Recebe o texto coalescido (um batch por frame, em uso normal).
  final void Function(String batch) onFlush;

  /// Libera o próximo chunk do PTY (`TerminalGateway.acknowledgeOutput`).
  final void Function() onAcknowledge;

  final void Function(void Function() flush) _scheduleFlush;

  final StringBuffer _pending = StringBuffer();
  bool _flushScheduled = false;
  bool _ackPaused = false;
  bool _disposed = false;

  /// Caracteres ainda não flushados (exposto pra testes).
  int get pendingLength => _pending.length;

  /// `true` enquanto o ack está suspenso por cap (exposto pra testes).
  bool get ackPaused => _ackPaused;

  static void _scheduleOnNextFrame(void Function() flush) {
    SchedulerBinding.instance.scheduleFrameCallback((_) => flush());
    SchedulerBinding.instance.scheduleFrame();
  }

  /// Enfileira [data] e agenda flush se ainda não houver um pendente.
  void add(String data) {
    if (_disposed || data.isEmpty) return;
    _pending.write(data);
    if (_pending.length < maxPendingChars) {
      onAcknowledge();
    } else {
      _ackPaused = true;
    }
    if (_flushScheduled) return;
    _flushScheduled = true;
    _scheduleFlush(_flush);
  }

  void _flush() {
    if (_disposed) return;
    _flushScheduled = false;
    final batch = _pending.toString();
    _pending.clear();
    if (batch.isNotEmpty) onFlush(batch);
    if (_ackPaused) {
      _ackPaused = false;
      onAcknowledge();
    }
  }

  /// Descarta o agendamento; flusha o restante de forma síncrona.
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _flushScheduled = false;
    final batch = _pending.toString();
    _pending.clear();
    if (batch.isNotEmpty) onFlush(batch);
    _ackPaused = false;
  }
}

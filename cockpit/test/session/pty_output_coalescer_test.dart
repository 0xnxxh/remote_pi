import 'package:cockpit/app/cockpit/ui/session/pty_output_coalescer.dart';
import 'package:flutter_test/flutter_test.dart';

/// Agenda o flush sob controle do teste (não depende de vsync).
class _ManualScheduler {
  void Function()? pending;

  void schedule(void Function() flush) {
    pending = flush;
  }

  void run() {
    final fn = pending;
    pending = null;
    fn?.call();
  }
}

void main() {
  test('N chunks sob o cap → um flush + ack por chunk', () {
    final scheduler = _ManualScheduler();
    final flushes = <String>[];
    var acks = 0;

    final coalescer = PtyOutputCoalescer(
      maxPendingChars: 1024,
      onFlush: flushes.add,
      onAcknowledge: () => acks++,
      scheduleFlush: scheduler.schedule,
    );

    coalescer
      ..add('a')
      ..add('b')
      ..add('c');

    expect(flushes, isEmpty);
    expect(acks, 3);
    expect(coalescer.pendingLength, 3);
    expect(scheduler.pending, isNotNull);

    scheduler.run();

    expect(flushes, ['abc']);
    expect(coalescer.pendingLength, 0);
    expect(coalescer.ackPaused, isFalse);
    // Sem ack extra no flush (nunca pausou).
    expect(acks, 3);

    coalescer.dispose();
  });

  test('estouro do cap pausa ack até o flush', () {
    final scheduler = _ManualScheduler();
    final flushes = <String>[];
    var acks = 0;

    final coalescer = PtyOutputCoalescer(
      maxPendingChars: 4,
      onFlush: flushes.add,
      onAcknowledge: () => acks++,
      scheduleFlush: scheduler.schedule,
    );

    coalescer.add('ab'); // len 2 < 4 → ack
    expect(acks, 1);
    expect(coalescer.ackPaused, isFalse);

    coalescer.add('cd'); // len 4 >= 4 → pausa
    expect(acks, 1);
    expect(coalescer.ackPaused, isTrue);

    coalescer.add('e'); // ainda pausado, sem ack
    expect(acks, 1);

    scheduler.run();

    expect(flushes, ['abcde']);
    expect(coalescer.ackPaused, isFalse);
    // Flush retoma com um ack.
    expect(acks, 2);

    coalescer.dispose();
  });

  test('dispose flusha o restante síncrono', () {
    final scheduler = _ManualScheduler();
    final flushes = <String>[];

    final coalescer = PtyOutputCoalescer(
      onFlush: flushes.add,
      onAcknowledge: () {},
      scheduleFlush: scheduler.schedule,
    );

    coalescer.add('pending');
    expect(flushes, isEmpty);

    coalescer.dispose();
    expect(flushes, ['pending']);
    // Segundo dispose é no-op.
    coalescer.dispose();
    expect(flushes, ['pending']);
  });
}

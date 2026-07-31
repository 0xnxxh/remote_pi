import 'dart:async';

import 'package:cockpit/app/core/domain/contracts/automation_gateway.dart';
import 'package:cockpit/app/core/domain/entities/automation.dart';
import 'package:cockpit/app/core/domain/exceptions/automation_error.dart';
import 'package:cockpit/app/core/ui/automation_controller.dart';
import 'package:flutter_test/flutter_test.dart';

class _Gateway implements AutomationGateway {
  List<AutomationHarness> discovered = const <AutomationHarness>[];
  Completer<String>? generation;
  bool cancelled = false;

  @override
  Future<List<AutomationHarness>> discover() async => discovered;

  @override
  Future<String> generate({
    required AutomationSelection selection,
    required AutomationRequest request,
  }) => generation?.future ?? Future.value('fix: generated message');

  @override
  Future<void> cancel() async {
    cancelled = true;
  }

  @override
  Future<void> close() async {}
}

void main() {
  const harness = AutomationHarness(
    id: AutomationHarnessId.codex,
    executablePath: '/usr/bin/codex',
  );
  const selection = AutomationSelection(harnessId: AutomationHarnessId.codex);
  const request = AutomationRequest(prompt: 'prompt', repositoryPath: '/repo');

  test('discovers installed harnesses and exposes them by id', () async {
    final gateway = _Gateway()..discovered = const [harness];
    final controller = AutomationController(gateway);

    await controller.refresh();

    expect(controller.initialized, isTrue);
    expect(controller.harnessFor(AutomationHarnessId.codex), harness);
    expect(controller.discovering, isFalse);
    controller.dispose();
  });

  test('rejects generation when configured harness is unavailable', () async {
    final controller = AutomationController(_Gateway());

    final result = await controller.generate(
      selection: selection,
      request: request,
    );

    expect(result.isFailure, isTrue);
    result.fold<void>((_) => fail('expected failure'), (error) {
      expect(error.kind, AutomationErrorKind.unavailable);
    });
    controller.dispose();
  });

  test('prevents concurrent generations and forwards cancellation', () async {
    final gateway = _Gateway()
      ..discovered = const [harness]
      ..generation = Completer<String>();
    final controller = AutomationController(gateway);
    await controller.refresh();

    final first = controller.generate(selection: selection, request: request);
    await Future<void>.delayed(Duration.zero);
    final second = await controller.generate(
      selection: selection,
      request: request,
    );
    expect(second.isFailure, isTrue);

    await controller.cancelGeneration();
    expect(gateway.cancelled, isTrue);
    gateway.generation!.complete('fix: generated message');
    expect((await first).isSuccess, isTrue);
    controller.dispose();
  });
}

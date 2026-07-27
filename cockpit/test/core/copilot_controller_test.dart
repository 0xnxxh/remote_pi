import 'dart:async';

import 'package:cockpit/app/core/domain/contracts/copilot_gateway.dart';
import 'package:cockpit/app/core/domain/entities/copilot.dart';
import 'package:cockpit/app/core/domain/exceptions/copilot_error.dart';
import 'package:cockpit/app/core/ui/copilot_controller.dart';
import 'package:flutter_test/flutter_test.dart';

class _Gateway implements CopilotGateway {
  final _statuses = StreamController<CopilotStatus>.broadcast();

  CopilotStatus _current = const CopilotStatus.disconnected();
  CopilotError? authenticationError;
  bool connectBeforeAuthenticationError = false;

  @override
  CopilotStatus get currentStatus => _current;

  @override
  Stream<CopilotStatus> get status => _statuses.stream;

  void emit(CopilotStatus value) {
    _current = value;
    _statuses.add(value);
  }

  @override
  Future<void> start({required String workspacePath}) async {}

  @override
  Future<CopilotAuthentication> beginAuthentication() async {
    final error = authenticationError;
    if (error != null) {
      if (connectBeforeAuthenticationError) {
        emit(
          const CopilotStatus(
            CopilotState.connected,
            'Connected',
            account: 'octocat',
          ),
        );
      }
      throw error;
    }
    return const CopilotAuthentication(id: 'auth-1', userCode: 'ABCD-EFGH');
  }

  @override
  Future<void> completeAuthentication(
    CopilotAuthentication authentication,
  ) async {}

  @override
  Future<void> disconnect() async => emit(const CopilotStatus.disconnected());

  @override
  Future<String> generateCommitMessage({
    required String repositoryPath,
    required String diff,
    required List<String> recentCommitSubjects,
  }) async => 'fix: generated';

  @override
  Future<void> cancelGeneration() async {}

  @override
  Future<void> close() async {}

  @override
  void dispose() {}

  Future<void> disposeStream() => _statuses.close();
}

void main() {
  const missingDeviceCode = CopilotError(
    CopilotErrorKind.protocol,
    'GitHub Copilot did not provide a device code.',
  );

  test('connected status clears a stale device-flow error', () async {
    final gateway = _Gateway()..authenticationError = missingDeviceCode;
    final controller = CopilotController(gateway);

    await controller.connect(workspacePath: '/workspace');
    expect(controller.errorMessage, missingDeviceCode.message);

    gateway.emit(
      const CopilotStatus(
        CopilotState.connected,
        'Connected',
        account: 'octocat',
      ),
    );
    await pumpEventQueue();

    expect(controller.status.isConnected, isTrue);
    expect(controller.authentication, isNull);
    expect(controller.errorMessage, isNull);

    controller.dispose();
    await gateway.disposeStream();
  });

  test('does not publish a device-flow error after a connect race', () async {
    final gateway = _Gateway()
      ..authenticationError = missingDeviceCode
      ..connectBeforeAuthenticationError = true;
    final controller = CopilotController(gateway);

    await controller.connect(workspacePath: '/workspace');

    expect(controller.status.isConnected, isTrue);
    expect(controller.errorMessage, isNull);

    controller.dispose();
    await gateway.disposeStream();
  });
}

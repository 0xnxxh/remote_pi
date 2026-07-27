import 'dart:async';

import 'package:cockpit/app/core/domain/contracts/copilot_gateway.dart';
import 'package:cockpit/app/core/domain/entities/copilot.dart';
import 'package:cockpit/app/core/domain/exceptions/copilot_error.dart';
import 'package:cockpit/app/core/ui/copilot_controller.dart';
import 'package:flutter_test/flutter_test.dart';

class _Gateway implements CopilotGateway {
  final _statuses = StreamController<CopilotStatus>.broadcast();

  CopilotStatus _current = const CopilotStatus.disconnected();
  CopilotStatus? statusOnStart;
  CopilotError? authenticationError;
  bool connectBeforeAuthenticationError = false;
  final List<String> startedWorkspaces = <String>[];
  int authenticationRequests = 0;

  @override
  CopilotStatus get currentStatus => _current;

  @override
  Stream<CopilotStatus> get status => _statuses.stream;

  void emit(CopilotStatus value) {
    _current = value;
    _statuses.add(value);
  }

  @override
  Future<void> start({required String workspacePath}) async {
    startedWorkspaces.add(workspacePath);
    final restored = statusOnStart;
    if (restored != null) emit(restored);
  }

  @override
  Future<CopilotAuthentication> beginAuthentication() async {
    authenticationRequests++;
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

  test('initialize restores the saved session without device flow', () async {
    final gateway = _Gateway()
      ..statusOnStart = const CopilotStatus(
        CopilotState.connected,
        'Connected',
        account: 'octocat',
      );
    final controller = CopilotController(gateway);

    final result = await controller.initialize(workspacePath: '/workspace');

    expect(result.isSuccess, isTrue);
    expect(gateway.startedWorkspaces, <String>['/workspace']);
    expect(gateway.authenticationRequests, 0);
    expect(controller.status.isConnected, isTrue);
    expect(controller.status.account, 'octocat');
    expect(controller.errorMessage, isNull);

    controller.dispose();
    await gateway.disposeStream();
  });

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

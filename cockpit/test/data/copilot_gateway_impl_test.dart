import 'dart:async';

import 'package:cockpit/app/core/data/copilot/copilot_gateway_impl.dart';
import 'package:cockpit/app/core/data/copilot/copilot_server_resolver.dart';
import 'package:cockpit/app/core/domain/contracts/lsp_client.dart';
import 'package:cockpit/app/core/domain/entities/lsp_diagnostic.dart';
import 'package:cockpit/app/core/domain/exceptions/lsp_error.dart';
import 'package:cockpit/app/core/domain/result.dart';
import 'package:flutter_test/flutter_test.dart';

class _Resolver implements CopilotServerResolver {
  @override
  Future<CopilotServerCommand?> resolve() async =>
      const CopilotServerCommand('copilot-language-server', ['--stdio']);
}

class _Factory implements LspClientFactory {
  _Factory(this.client);
  final _Client client;

  @override
  LspClient create({required LspServerSpec spec, required String rootPath}) {
    client
      ..spec = spec
      ..rootPathValue = rootPath;
    return client;
  }
}

class _Client implements LspClient {
  final notificationController = StreamController<LspNotification>.broadcast();
  final exitController = StreamController<int>.broadcast();
  final diagnosticsController =
      StreamController<LspDiagnosticsBatch>.broadcast();
  final Map<String, Object?> responses = <String, Object?>{};
  final Map<String, List<Object?>> queuedResponses = <String, List<Object?>>{};
  final List<(String, Map<String, dynamic>)> sentNotifications = [];
  final List<(String, Map<String, dynamic>)> requests = [];
  String? openedText;
  String? openedLanguage;
  String? openedPath;
  late LspServerSpec spec;
  String rootPathValue = '';
  bool running = false;
  LspNotification? notificationOnStart;

  @override
  Stream<LspDiagnosticsBatch> get diagnostics => diagnosticsController.stream;
  @override
  Stream<LspNotification> get notifications => notificationController.stream;
  @override
  Stream<int> get exitCodes => exitController.stream;
  @override
  bool get isRunning => running;
  @override
  String get rootPath => rootPathValue;

  @override
  Future<Result<void, LspError>> start() async {
    running = true;
    final initial = notificationOnStart;
    if (initial != null) notificationController.add(initial);
    await Future<void>.delayed(Duration.zero);
    return const Success(null);
  }

  @override
  Future<void> didOpen({required String path, required String text}) async {
    openedPath = path;
    openedText = text;
  }

  @override
  Future<void> didOpenWithLanguage({
    required String path,
    required String text,
    required String languageId,
  }) async {
    await didOpen(path: path, text: text);
    openedLanguage = languageId;
  }

  @override
  Future<void> didChange({
    required String path,
    required String text,
    required int version,
  }) async {}

  @override
  Future<void> didClose({required String path}) async {}

  @override
  Future<Result<Object?, LspError>> request(
    String method,
    Map<String, dynamic> params,
  ) async {
    requests.add((method, params));
    final queued = queuedResponses[method];
    return Success(
      queued != null && queued.isNotEmpty
          ? queued.removeAt(0)
          : responses[method],
    );
  }

  @override
  Future<Result<Object?, LspError>> requestWithTimeout(
    String method,
    Map<String, dynamic> params,
    Duration timeout,
  ) => request(method, params);

  @override
  void notify(String method, Map<String, dynamic> params) {
    sentNotifications.add((method, params));
  }

  @override
  void cancelPendingRequests() {}

  @override
  Future<void> kill() async => running = false;

  @override
  void dispose() {}

  Future<void> closeControllers() async {
    await notificationController.close();
    await exitController.close();
    await diagnosticsController.close();
  }
}

void main() {
  test(
    'restores status and generates a validated git commit message',
    () async {
      final client = _Client()
        ..notificationOnStart = const LspNotification('didChangeStatus', {
          'kind': 'Normal',
          'message': 'Connected',
          'busy': false,
        })
        ..responses['textDocument/inlineCompletion'] = <String, dynamic>{
          'items': <Object?>[
            <String, dynamic>{'insertText': 'fix: avoid duplicate reconnects'},
          ],
        };
      final gateway = CopilotGatewayImpl(_Factory(client), _Resolver());

      await gateway.start(workspacePath: '/tmp/project');
      expect(gateway.currentStatus.isConnected, isTrue);

      final message = await gateway.generateCommitMessage(
        repositoryPath: '/tmp/project',
        diff: 'diff --git a/a.dart b/a.dart\n+password = do-not-send\n+safe',
        recentCommitSubjects: const [
          'fix: prior style',
          'chore: token = also-do-not-send',
        ],
      );

      expect(message, 'fix: avoid duplicate reconnects');
      expect(client.openedLanguage, 'git-commit');
      expect(client.openedPath, endsWith('.gitcommit'));
      expect(client.openedPath, isNot(contains('/.git/')));
      expect(client.openedText, contains('fix: prior style'));
      expect(client.openedText, endsWith('Commit message: '));
      expect(
        client.openedText,
        contains('[sensitive line redacted by Cockpit]'),
      );
      expect(client.openedText, isNot(contains('do-not-send')));
      expect(client.openedText, isNot(contains('also-do-not-send')));

      await gateway.close();
      gateway.dispose();
      await client.closeControllers();
    },
  );

  test('retries an empty completion and accepts StringValue', () async {
    final client = _Client()
      ..notificationOnStart = const LspNotification('didChangeStatus', {
        'kind': 'Normal',
        'message': 'Connected',
        'busy': false,
      })
      ..responses['textDocument/inlineCompletion'] = <String, dynamic>{
        'items': <Object?>[],
      }
      ..responses['textDocument/copilotPanelCompletion'] = <String, dynamic>{
        'items': <Object?>[
          <String, dynamic>{
            'insertText': <String, dynamic>{
              'value': 'Commit message: feat: generate staged summary',
            },
          },
        ],
      };
    final gateway = CopilotGatewayImpl(_Factory(client), _Resolver());
    await gateway.start(workspacePath: '/tmp/project');

    final message = await gateway.generateCommitMessage(
      repositoryPath: '/tmp/project',
      diff: 'diff --git a/a.dart b/a.dart\n+final enabled = true;',
      recentCommitSubjects: const <String>[],
    );

    expect(message, 'feat: generate staged summary');
    expect(
      client.requests.where(
        (request) => request.$1 == 'textDocument/inlineCompletion',
      ),
      hasLength(1),
    );
    expect(
      client.requests.where(
        (request) => request.$1 == 'textDocument/copilotPanelCompletion',
      ),
      hasLength(1),
    );

    await gateway.close();
    gateway.dispose();
    await client.closeControllers();
  });

  test('uses the documented device-flow command to authenticate', () async {
    final client = _Client()
      ..notificationOnStart = const LspNotification('didChangeStatus', {
        'kind': 'Error',
        'message': 'Not signed in',
        'busy': false,
      })
      ..responses['signIn'] = <String, dynamic>{
        'userCode': 'ABCD-EFGH',
        'command': <String, dynamic>{
          'command': 'github.copilot.finishDeviceFlow',
          'arguments': <Object?>[],
          'title': 'Sign in',
        },
      };
    final gateway = CopilotGatewayImpl(_Factory(client), _Resolver());
    await gateway.start(workspacePath: '/tmp/project');

    final authentication = await gateway.beginAuthentication();
    expect(authentication.userCode, 'ABCD-EFGH');

    final completing = gateway.completeAuthentication(authentication);
    await Future<void>.delayed(Duration.zero);
    client.notificationController.add(
      const LspNotification('didChangeStatus', {
        'kind': 'Normal',
        'message': 'Connected',
        'busy': false,
      }),
    );
    await completing;

    final execute = client.requests.singleWhere(
      (request) => request.$1 == 'workspace/executeCommand',
    );
    expect(execute.$2['command'], 'github.copilot.finishDeviceFlow');
    expect(gateway.currentStatus.isConnected, isTrue);

    await gateway.close();
    gateway.dispose();
    await client.closeControllers();
  });

  test('rejects malformed generated commit messages', () {
    expect(
      CopilotGatewayImpl.validateCommitMessage('fix: valid subject'),
      isNull,
    );
    expect(
      CopilotGatewayImpl.validateCommitMessage('fix: invalid.\nbody'),
      isNotNull,
    );
    expect(
      CopilotGatewayImpl.validateCommitMessage('```\nfix: markdown\n```'),
      isNotNull,
    );
  });
}

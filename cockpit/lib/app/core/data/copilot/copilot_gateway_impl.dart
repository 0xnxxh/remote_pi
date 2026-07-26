import 'dart:async';

import 'package:cockpit/app/core/data/copilot/copilot_server_resolver.dart';
import 'package:cockpit/app/core/domain/contracts/copilot_gateway.dart';
import 'package:cockpit/app/core/domain/contracts/lsp_client.dart';
import 'package:cockpit/app/core/domain/entities/copilot.dart';
import 'package:cockpit/app/core/domain/exceptions/copilot_error.dart';
import 'package:cockpit/app/core/domain/exceptions/lsp_error.dart';
import 'package:cockpit/app/core/domain/result.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:url_launcher/url_launcher.dart';

/// Adapter do protocolo público do GitHub Copilot Language Server.
///
/// O servidor não publica uma API de "commit message". A implementação usa um
/// documento virtual `git-commit` e as APIs públicas de completion do servidor.
/// Essa estratégia fica toda aqui para poder ser substituída sem tocar a UI.
class CopilotGatewayImpl implements CopilotGateway, LspServerRequestHandler {
  CopilotGatewayImpl(this._clientFactory, this._serverResolver);

  final LspClientFactory _clientFactory;
  final CopilotServerResolver _serverResolver;

  static const _generationTimeout = Duration(seconds: 30);
  static const _authenticationTimeout = Duration(minutes: 2);
  static const _initialStatusTimeout = Duration(milliseconds: 800);
  static const _completionWarmup = Duration(milliseconds: 120);
  static const _emptyCompletionRetryDelay = Duration(milliseconds: 350);
  // Inline completion tem uma janela de contexto bem menor que chat. Um diff
  // enorme fazia o servidor responder `items: []` sem erro de protocolo.
  static const _maxDiffChars = 48000;
  static final RegExp _sensitiveAssignment = RegExp(
    r'(?:password|passphrase|api[_-]?key|secret|token|authorization)\s*[:=]',
    caseSensitive: false,
  );

  final StreamController<CopilotStatus> _statuses =
      StreamController<CopilotStatus>.broadcast();
  final Map<String, Map<String, dynamic>> _authenticationCommands = {};
  final Set<String> _workspacePaths = {};

  LspClient? _client;
  StreamSubscription<LspNotification>? _notificationSub;
  StreamSubscription<int>? _exitSub;
  CopilotStatus _current = const CopilotStatus.disconnected();
  bool _receivedStatus = false;
  bool _authenticationInProgress = false;
  bool _closing = false;
  int _authenticationSequence = 0;
  int _generationSequence = 0;

  @override
  Stream<CopilotStatus> get status => _statuses.stream;

  @override
  CopilotStatus get currentStatus => _current;

  void _emit(CopilotStatus value) {
    _current = value;
    if (!_statuses.isClosed) _statuses.add(value);
  }

  @override
  Future<void> start({required String workspacePath}) async {
    final normalized = workspacePath.trim();
    if (normalized.isEmpty) {
      throw const CopilotError(
        CopilotErrorKind.unavailable,
        'No workspace is available for GitHub Copilot.',
      );
    }
    final running = _client;
    if (running != null && running.isRunning) {
      _addWorkspace(normalized);
      return;
    }

    _closing = false;
    _receivedStatus = false;
    _emit(
      const CopilotStatus(CopilotState.starting, 'Starting GitHub Copilot…'),
    );
    final command = await _serverResolver.resolve();
    if (command == null) {
      const error = CopilotError(
        CopilotErrorKind.unavailable,
        'GitHub Copilot Language Server requires Node.js and npm.',
      );
      _emit(
        const CopilotStatus(
          CopilotState.languageServerUnavailable,
          'GitHub Copilot Language Server is unavailable. Install Node.js to use it.',
        ),
      );
      throw error;
    }

    final client = _clientFactory.create(
      spec: LspServerSpec(
        languageId: 'plaintext',
        executable: command.executable,
        args: command.args,
        capabilities: const <String, dynamic>{
          'workspace': <String, dynamic>{
            'workspaceFolders': true,
            'configuration': true,
          },
          'textDocument': <String, dynamic>{
            'synchronization': <String, dynamic>{
              'dynamicRegistration': false,
              'didSave': false,
            },
            'inlineCompletion': <String, dynamic>{'dynamicRegistration': false},
          },
          'window': <String, dynamic>{
            'showDocument': <String, dynamic>{'support': true},
          },
        },
        initializationOptions: const <String, dynamic>{
          'editorInfo': <String, dynamic>{'name': 'Cockpit'},
          'editorPluginInfo': <String, dynamic>{
            'name': 'Cockpit GitHub Copilot',
            'version': '1.0.0',
          },
        },
        serverRequestHandler: this,
        logStderr: false,
      ),
      rootPath: normalized,
    );
    _client = client;
    _workspacePaths
      ..clear()
      ..add(normalized);
    _notificationSub = client.notifications.listen(_onNotification);
    _exitSub = client.exitCodes.listen(_onExit);

    final result = await client.start();
    if (result case Failure<void, LspError>(:final error)) {
      await _releaseClient();
      _emit(
        const CopilotStatus(
          CopilotState.languageServerUnavailable,
          'GitHub Copilot Language Server could not be started.',
        ),
      );
      throw CopilotError(
        CopilotErrorKind.unavailable,
        'GitHub Copilot Language Server could not be started.',
        cause: error,
      );
    }
    client.notify('workspace/didChangeConfiguration', const {
      'settings': {
        'telemetry': {'telemetryLevel': 'off'},
      },
    });
    // Sessões autenticadas são restauradas pelo servidor via didChangeStatus.
    // Dá uma janela curta pro evento pós-initialize chegar antes de iniciar um
    // device flow desnecessário.
    if (!_receivedStatus) {
      try {
        await status
            .firstWhere((_) => _receivedStatus)
            .timeout(_initialStatusTimeout);
      } on TimeoutException {
        if (_current.state == CopilotState.starting) {
          _emit(const CopilotStatus.disconnected());
        }
      }
    }
  }

  void _addWorkspace(String path) {
    if (!_workspacePaths.add(path)) return;
    _client?.notify('workspace/didChangeWorkspaceFolders', {
      'event': {
        'added': [
          {'uri': Uri.directory(path).toString(), 'name': _basename(path)},
        ],
        'removed': <Object?>[],
      },
    });
  }

  @override
  Future<CopilotAuthentication> beginAuthentication() async {
    final client = _requireClient();
    _authenticationInProgress = true;
    _emit(
      const CopilotStatus(
        CopilotState.connecting,
        'Preparing GitHub authentication…',
      ),
    );
    final Object? raw;
    try {
      raw = await _request(client, 'signIn', const {});
    } on CopilotError {
      _authenticationInProgress = false;
      rethrow;
    }
    if (raw is! Map) {
      _authenticationInProgress = false;
      throw const CopilotError(
        CopilotErrorKind.protocol,
        'GitHub Copilot returned an invalid authentication response.',
      );
    }
    final userCode = raw['userCode'];
    final command = raw['command'];
    if (userCode is! String || userCode.isEmpty || command is! Map) {
      _authenticationInProgress = false;
      throw const CopilotError(
        CopilotErrorKind.protocol,
        'GitHub Copilot did not provide a device code.',
      );
    }
    final id = 'auth-${++_authenticationSequence}';
    _authenticationCommands[id] = Map<String, dynamic>.from(command);
    _emit(
      const CopilotStatus(
        CopilotState.waitingForAuthentication,
        'Device code ready. Open GitHub to continue.',
      ),
    );
    return CopilotAuthentication(id: id, userCode: userCode);
  }

  @override
  Future<void> completeAuthentication(
    CopilotAuthentication authentication,
  ) async {
    final command = _authenticationCommands.remove(authentication.id);
    if (command == null) {
      throw const CopilotError(
        CopilotErrorKind.authentication,
        'This authentication request is no longer valid.',
      );
    }
    final name = command['command'];
    if (name is! String || name.isEmpty) {
      throw const CopilotError(
        CopilotErrorKind.protocol,
        'GitHub Copilot returned an invalid sign-in command.',
      );
    }
    final arguments = command['arguments'];
    _emit(
      const CopilotStatus(
        CopilotState.waitingForAuthentication,
        'Waiting for authentication in your browser…',
      ),
    );
    try {
      await _request(
        _requireClient(),
        'workspace/executeCommand',
        <String, dynamic>{
          'command': name,
          'arguments': arguments is List ? arguments : const <Object?>[],
        },
      );

      // `status` é broadcast. O evento Normal pode chegar enquanto o execute
      // ainda aguarda a resposta; nesse caso não devemos assinar tarde e esperar
      // dois minutos por um evento que já passou.
      if (_current.isConnected) return;

      try {
        final terminal = await status
            .firstWhere(
              (value) =>
                  value.isConnected ||
                  value.state == CopilotState.authenticationFailed ||
                  value.state == CopilotState.subscriptionUnavailable ||
                  value.state == CopilotState.quotaReached,
            )
            .timeout(_authenticationTimeout);
        if (!terminal.isConnected) {
          throw CopilotError(CopilotErrorKind.authentication, terminal.message);
        }
      } on TimeoutException catch (error) {
        _emit(
          const CopilotStatus(
            CopilotState.authenticationFailed,
            'Authentication timed out. Please try again.',
          ),
        );
        throw CopilotError(
          CopilotErrorKind.timeout,
          'Authentication timed out. Please try again.',
          cause: error,
        );
      }
    } finally {
      _authenticationInProgress = false;
    }
  }

  @override
  Future<void> disconnect() async {
    final client = _client;
    if (client == null || !client.isRunning) {
      _emit(const CopilotStatus.disconnected());
      return;
    }
    await _request(client, 'signOut', const {});
    _authenticationInProgress = false;
    _authenticationCommands.clear();
    _emit(const CopilotStatus.disconnected());
  }

  @override
  Future<String> generateCommitMessage({
    required String repositoryPath,
    required String diff,
    required List<String> recentCommitSubjects,
  }) async {
    if (!_current.isConnected) {
      throw const CopilotError(
        CopilotErrorKind.authentication,
        'Connect GitHub Copilot in Settings first.',
      );
    }
    if (diff.trim().isEmpty) {
      throw const CopilotError(
        CopilotErrorKind.noChanges,
        'There are no changes to describe.',
      );
    }
    await start(workspacePath: repositoryPath);
    final client = _requireClient();
    final generation = ++_generationSequence;
    final prompt = _buildCommitPrompt(diff, recentCommitSubjects);
    // Documentos sob `.git/` são ignorados pelo servidor e resultam em uma
    // completion vazia. A URI continua virtual (nenhum arquivo é criado), mas
    // vive na raiz observável do workspace.
    final virtualPath =
        '$repositoryPath/.cockpit-copilot-commit-message.gitcommit';

    await client.didOpenWithLanguage(
      path: virtualPath,
      text: prompt,
      languageId: 'git-commit',
    );
    client.notify('textDocument/didFocus', {
      'textDocument': {'uri': Uri.file(virtualPath).toString()},
    });
    try {
      final position = _endPosition(prompt);
      Object? lastResponse;
      for (var attempt = 0; attempt < 2; attempt++) {
        await Future<void>.delayed(
          attempt == 0 ? _completionWarmup : _emptyCompletionRetryDelay,
        );
        if (generation != _generationSequence) {
          throw const CopilotError(
            CopilotErrorKind.cancelled,
            'Commit message generation was cancelled.',
          );
        }
        final method = attempt == 0
            ? 'textDocument/inlineCompletion'
            : 'textDocument/copilotPanelCompletion';
        lastResponse = await _request(client, method, <String, dynamic>{
          'textDocument': <String, dynamic>{
            'uri': Uri.file(virtualPath).toString(),
            'version': 1,
          },
          'position': <String, dynamic>{
            'line': position.$1,
            'character': position.$2,
          },
          if (attempt == 0) ...<String, dynamic>{
            'context': const <String, dynamic>{'triggerKind': 1},
            'formattingOptions': const <String, dynamic>{
              'tabSize': 2,
              'insertSpaces': true,
            },
          },
        }, timeout: _generationTimeout);
        if (generation != _generationSequence) {
          throw const CopilotError(
            CopilotErrorKind.cancelled,
            'Commit message generation was cancelled.',
          );
        }
        if (_completionText(lastResponse).trim().isNotEmpty) {
          return _parseCommitMessage(lastResponse);
        }
      }
      return _parseCommitMessage(lastResponse);
    } finally {
      await client.didClose(path: virtualPath);
      client.notify('textDocument/didFocus', const {});
    }
  }

  @override
  Future<void> cancelGeneration() async {
    _generationSequence++;
    _client?.cancelPendingRequests();
  }

  Future<Object?> _request(
    LspClient client,
    String method,
    Map<String, dynamic> params, {
    Duration timeout = const Duration(seconds: 15),
  }) async {
    final result = await client.requestWithTimeout(method, params, timeout);
    return result.fold<Object?>((value) => value, (error) {
      final text = error.message.toLowerCase();
      if (text.contains('cancel')) {
        throw CopilotError(CopilotErrorKind.cancelled, error.message);
      }
      if (text.contains('timed out')) {
        throw CopilotError(CopilotErrorKind.timeout, error.message);
      }
      throw CopilotError(
        CopilotErrorKind.protocol,
        'GitHub Copilot could not complete the request.',
        cause: error,
      );
    });
  }

  LspClient _requireClient() {
    final client = _client;
    if (client == null || !client.isRunning) {
      throw const CopilotError(
        CopilotErrorKind.unavailable,
        'GitHub Copilot Language Server is not running.',
      );
    }
    return client;
  }

  void _onNotification(LspNotification notification) {
    if (notification.method != 'didChangeStatus') return;
    final params = notification.params;
    if (params is! Map) return;
    _receivedStatus = true;
    final kind = '${params['kind'] ?? ''}';
    final busy = params['busy'] == true;
    final rawMessage = '${params['message'] ?? ''}'.trim();
    final message = rawMessage.isEmpty
        ? 'GitHub Copilot is ready.'
        : rawMessage;
    final lower = message.toLowerCase();

    if (kind == 'Normal') {
      _authenticationInProgress = false;
      _emit(
        CopilotStatus(
          CopilotState.connected,
          busy ? 'GitHub Copilot is working…' : 'Connected',
        ),
      );
      return;
    }
    if (_containsAny(lower, const ['quota', 'rate limit', 'usage limit'])) {
      _emit(
        CopilotStatus(
          CopilotState.quotaReached,
          'GitHub Copilot quota has been reached.',
        ),
      );
    } else if (_containsAny(lower, const [
      'subscription',
      'not entitled',
      'not eligible',
    ])) {
      _emit(
        const CopilotStatus(
          CopilotState.subscriptionUnavailable,
          'A GitHub Copilot subscription is not available for this account.',
        ),
      );
    } else if (_containsAny(lower, const [
      'network',
      'connect',
      'offline',
      'socket',
      'proxy',
    ])) {
      _emit(
        const CopilotStatus(
          CopilotState.networkUnavailable,
          'GitHub Copilot cannot reach the network.',
        ),
      );
    } else if (_authenticationInProgress) {
      _emit(
        const CopilotStatus(
          CopilotState.authenticationFailed,
          'GitHub Copilot authentication failed. Please try again.',
        ),
      );
    } else if (kind == 'Error') {
      _emit(const CopilotStatus.disconnected());
    } else {
      _emit(CopilotStatus(CopilotState.error, message));
    }
  }

  void _onExit(int code) {
    if (_closing) return;
    _emit(
      CopilotStatus(
        CopilotState.languageServerUnavailable,
        'GitHub Copilot Language Server stopped unexpectedly (code $code).',
      ),
    );
  }

  @override
  Future<Object?> handle(String method, Object? params) async {
    if (method == 'workspace/configuration') {
      final count = params is Map && params['items'] is List
          ? (params['items'] as List).length
          : 1;
      return List<Object?>.filled(count, null);
    }
    if (method == 'window/showDocument' && params is Map) {
      final uri = Uri.tryParse('${params['uri'] ?? ''}');
      var success = false;
      if (uri != null) {
        try {
          success = await launchUrl(uri, mode: LaunchMode.externalApplication);
        } on PlatformException {
          success = false;
        }
      }
      return <String, dynamic>{'success': success};
    }
    if (method == 'window/showMessageRequest' && params is Map) {
      final message = '${params['message'] ?? ''}'.trim();
      if (message.isNotEmpty) _classifyServerMessage(message);
      return null;
    }
    return null;
  }

  void _classifyServerMessage(String message) {
    final lower = message.toLowerCase();
    if (_containsAny(lower, const ['quota', 'usage limit'])) {
      _emit(
        const CopilotStatus(
          CopilotState.quotaReached,
          'GitHub Copilot quota has been reached.',
        ),
      );
    } else if (lower.contains('subscription')) {
      _emit(
        const CopilotStatus(
          CopilotState.subscriptionUnavailable,
          'A GitHub Copilot subscription is not available for this account.',
        ),
      );
    }
  }

  String _buildCommitPrompt(String diff, List<String> recentSubjects) {
    final safeDiff = _prepareDiff(diff);
    final subjects = recentSubjects
        .map((value) => value.replaceAll(RegExp(r'[\r\n]+'), ' ').trim())
        .where((value) => value.isNotEmpty)
        .map(
          (value) => _sensitiveAssignment.hasMatch(value)
              ? '[sensitive subject redacted by Cockpit]'
              : value,
        )
        .take(8)
        .join('\n# - ');
    return '# Write a Git commit message for the file diff below.\n'
        '# Match recent repository style; otherwise use Conventional Commits.\n'
        '# Subject: at most 72 characters, no trailing period.\n'
        '# Add a body only when useful, separated by one blank line.\n'
        '# Return only the commit message, without Markdown or explanation.\n'
        '# Recent commit subjects:\n'
        '# - ${subjects.isEmpty ? '(none)' : subjects}\n'
        '# File diff:\n'
        '${_comment(safeDiff)}\n'
        // Não pode ser comentário: o cursor precisa estar numa linha editável.
        // Em `# Commit message:\n` o LS entendia que só havia comentários e
        // frequentemente devolvia `items: []`.
        'Commit message: ';
  }

  String _prepareDiff(String input) {
    var value = _redactSensitiveDiff(input);
    if (value.length <= _maxDiffChars) return value;
    const marker = '\n... [file diff truncated by Cockpit] ...\n';
    final remaining = _maxDiffChars - marker.length;
    final head = (remaining * .7).floor();
    final tail = remaining - head;
    value =
        '${value.substring(0, head)}$marker${value.substring(value.length - tail)}';
    return value;
  }

  String _redactSensitiveDiff(String input) {
    final output = <String>[];
    var skipSensitiveFile = false;
    for (final line in input.split('\n')) {
      if (line.startsWith('diff --git ')) {
        final lower = line.toLowerCase();
        skipSensitiveFile = _containsAny(lower, const [
          '/.env',
          'credentials',
          'id_rsa',
          '.pem',
          '.p12',
          '.key ',
        ]);
        output.add(
          skipSensitiveFile ? '$line\n[content redacted by Cockpit]' : line,
        );
        continue;
      }
      if (skipSensitiveFile) continue;
      final lower = line.toLowerCase();
      if (_sensitiveAssignment.hasMatch(line) ||
          lower.contains('begin private key')) {
        output.add('[sensitive line redacted by Cockpit]');
      } else {
        output.add(line);
      }
    }
    return output.join('\n');
  }

  String _comment(String value) =>
      value.split('\n').map((line) => '# $line').join('\n');

  String _completionText(Object? raw) {
    if (raw is! Map || raw['items'] is! List) return '';
    for (final item in raw['items'] as List) {
      if (item is! Map) continue;
      final insertText = item['insertText'];
      final candidate = switch (insertText) {
        String value => value,
        Map value when value['value'] is String => value['value'] as String,
        _ =>
          item['textEdit'] is Map &&
                  (item['textEdit'] as Map)['newText'] is String
              ? (item['textEdit'] as Map)['newText'] as String
              : '',
      };
      if (candidate.trim().isNotEmpty) return candidate;
    }
    return '';
  }

  String _parseCommitMessage(Object? raw) {
    if (raw is! Map || raw['items'] is! List) {
      throw const CopilotError(
        CopilotErrorKind.invalidResponse,
        'GitHub Copilot did not return a usable commit message.',
      );
    }
    final message = _completionText(raw)
        .replaceAll('\r\n', '\n')
        .replaceFirst(RegExp(r'^commit message:\s*', caseSensitive: false), '')
        .trim();
    final error = validateCommitMessage(message);
    if (error != null) {
      throw CopilotError(CopilotErrorKind.invalidResponse, error);
    }
    return message;
  }

  static String? validateCommitMessage(String message) {
    if (message.isEmpty) {
      return 'GitHub Copilot returned an empty commit message.';
    }
    if (message.contains('```')) {
      return 'GitHub Copilot returned Markdown instead of a commit message.';
    }
    final lines = message.split('\n');
    final subject = lines.first.trim();
    if (subject.length < 3 || subject.length > 72) {
      return 'GitHub Copilot returned a commit subject outside the 3–72 character limit.';
    }
    if (subject.endsWith('.')) {
      return 'GitHub Copilot returned a commit subject ending with a period.';
    }
    if (subject.codeUnits.any((value) => value < 0x20)) {
      return 'GitHub Copilot returned invalid control characters.';
    }
    if (lines.length > 1 && lines[1].trim().isNotEmpty) {
      return 'GitHub Copilot returned an invalid subject/body separator.';
    }
    return null;
  }

  (int, int) _endPosition(String text) {
    final lines = text.split('\n');
    return (lines.length - 1, lines.last.length);
  }

  bool _containsAny(String value, List<String> needles) =>
      needles.any(value.contains);

  String _basename(String path) {
    final normalized = path.replaceAll('\\', '/');
    return normalized.split('/').where((part) => part.isNotEmpty).lastOrNull ??
        path;
  }

  Future<void> _releaseClient() async {
    final client = _client;
    _client = null;
    await _notificationSub?.cancel();
    await _exitSub?.cancel();
    _notificationSub = null;
    _exitSub = null;
    if (client != null) {
      await client.kill();
      client.dispose();
    }
  }

  @override
  Future<void> close() async {
    _closing = true;
    await cancelGeneration();
    await _releaseClient();
    _workspacePaths.clear();
    _authenticationCommands.clear();
    _emit(const CopilotStatus.disconnected());
  }

  @override
  void dispose() {
    _closing = true;
    _notificationSub?.cancel();
    _exitSub?.cancel();
    _client?.dispose();
    _client = null;
    if (!_statuses.isClosed) _statuses.close();
  }
}

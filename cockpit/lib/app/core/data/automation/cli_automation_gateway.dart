import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cockpit/app/core/data/setup/remote_pi_resolver.dart';
import 'package:cockpit/app/core/domain/contracts/automation_gateway.dart';
import 'package:cockpit/app/core/domain/entities/automation.dart';
import 'package:cockpit/app/core/domain/exceptions/automation_error.dart';
import 'package:cockpit/app/core/domain/services/commit_message_prompt.dart';
import 'package:cockpit/app/core/utils/executable_resolver.dart';

class CliAutomationGateway implements AutomationGateway {
  CliAutomationGateway({this.timeout = const Duration(seconds: 60)});

  final Duration timeout;
  Process? _activeProcess;
  bool _cancelRequested = false;

  @override
  Future<List<AutomationHarness>> discover() async {
    final discovered = await Future.wait(
      AutomationHarnessId.values.map(_discoverHarness),
    );
    return discovered.whereType<AutomationHarness>().toList();
  }

  Future<AutomationHarness?> _discoverHarness(AutomationHarnessId id) async {
    try {
      final executable = await resolveExecutable(id.executableName);
      if (!await isExecutableAvailable(executable)) return null;
      return AutomationHarness(
        id: id,
        executablePath: executable,
        models: await _discoverModels(id, executable),
      );
    } catch (_) {
      return null;
    }
  }

  Future<List<AutomationModel>> _discoverModels(
    AutomationHarnessId id,
    String executable,
  ) async {
    try {
      final discovered = switch (id) {
        AutomationHarnessId.pi => parsePiModels(
          await _runForDiscovery(executable, const ['--list-models']),
        ),
        AutomationHarnessId.codex => await _discoverCodexModels(executable),
        AutomationHarnessId.opencode => parseOpenCodeModels(
          await _runForDiscovery(executable, const ['models']),
        ),
        // Copilot help is prose, not a model catalog — use the CLI default.
        AutomationHarnessId.copilot ||
        AutomationHarnessId.claude ||
        AutomationHarnessId.gemini => const <AutomationModel>[],
      };
      return _uniqueModels([...discovered, ...id.builtInModels]);
    } catch (_) {
      // Descoberta de modelos é best-effort. O default do próprio CLI continua
      // disponível mesmo se uma versão antiga não oferecer listagem.
      return id.builtInModels;
    }
  }

  Future<String> _runForDiscovery(String executable, List<String> args) async {
    final result = await Process.run(
      executable,
      args,
      environment: await envWithNodeOnPath(),
      runInShell: Platform.isWindows,
    ).timeout(const Duration(seconds: 12));
    if (result.exitCode != 0) return '';
    return result.stdout?.toString() ?? '';
  }

  Future<List<AutomationModel>> _discoverCodexModels(String executable) async {
    final process = await Process.start(
      executable,
      const ['app-server'],
      environment: await envWithNodeOnPath(),
      runInShell: Platform.isWindows,
    );
    unawaited(process.stderr.drain<void>());
    final result = Completer<List<AutomationModel>>();
    late final StreamSubscription<String> subscription;
    subscription = process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
          try {
            final value = jsonDecode(line);
            if (value is! Map) return;
            if (value['id'] == 1) {
              process.stdin.writeln(jsonEncode({'method': 'initialized'}));
              process.stdin.writeln(
                jsonEncode({
                  'method': 'model/list',
                  'id': 2,
                  'params': {'limit': 100, 'includeHidden': false},
                }),
              );
            } else if (value['id'] == 2 && !result.isCompleted) {
              final data = (value['result'] as Map?)?['data'];
              final models = <AutomationModel>[];
              if (data is List) {
                for (final raw in data.whereType<Map>()) {
                  final id = raw['id']?.toString().trim() ?? '';
                  if (id.isEmpty) continue;
                  models.add(
                    AutomationModel(
                      id: id,
                      label:
                          raw['displayName']?.toString().trim().isNotEmpty ==
                              true
                          ? raw['displayName'].toString().trim()
                          : id,
                    ),
                  );
                }
              }
              result.complete(models);
            }
          } catch (_) {
            // Linhas que não sejam respostas JSON-RPC são ignoradas.
          }
        });
    process.stdin.writeln(
      jsonEncode({
        'method': 'initialize',
        'id': 1,
        'params': {
          'clientInfo': {'name': 'Cockpit', 'version': '1'},
        },
      }),
    );
    try {
      return await result.future.timeout(const Duration(seconds: 12));
    } finally {
      await subscription.cancel();
      process.kill();
    }
  }

  @override
  Future<GeneratedCommitMessage> generate({
    required AutomationSelection selection,
    required AutomationRequest request,
  }) async {
    if (_activeProcess != null) {
      throw const AutomationError(
        AutomationErrorKind.process,
        'Another commit message is already being generated.',
      );
    }
    final executable = await resolveExecutable(
      selection.harnessId.executableName,
    );
    if (!await isExecutableAvailable(executable)) {
      throw AutomationError(
        AutomationErrorKind.unavailable,
        '${selection.harnessId.label} is not installed or is not on PATH.',
      );
    }

    Directory? systemPromptDirectory;
    String? codexSystemPromptPath;
    if (selection.harnessId == AutomationHarnessId.codex) {
      systemPromptDirectory = await Directory.systemTemp.createTemp(
        'cockpit_commit_message_',
      );
      final systemPromptFile = File(
        '${systemPromptDirectory.path}${Platform.pathSeparator}SYSTEM.md',
      );
      await systemPromptFile.writeAsString(CommitMessagePrompt.systemPrompt);
      codexSystemPromptPath = systemPromptFile.path;
    }

    final command = buildCommand(
      selection,
      request.prompt,
      codexSystemPromptPath: codexSystemPromptPath,
    );
    _cancelRequested = false;
    Process process;
    try {
      process = await Process.start(
        executable,
        command.args,
        workingDirectory: request.repositoryPath,
        environment: await envWithNodeOnPath(),
        runInShell: Platform.isWindows,
      );
    } on ProcessException catch (error) {
      await _deleteTemporaryDirectory(systemPromptDirectory);
      throw AutomationError(
        AutomationErrorKind.unavailable,
        'Could not start ${selection.harnessId.label}.',
        cause: error,
      );
    }
    _activeProcess = process;

    try {
      final stdoutFuture = process.stdout.transform(utf8.decoder).join();
      final stderrFuture = process.stderr.transform(utf8.decoder).join();
      if (command.stdin != null) process.stdin.write(command.stdin);
      await process.stdin.close();

      final exitCode = await process.exitCode.timeout(timeout);
      final stdout = await stdoutFuture;
      final stderr = await stderrFuture;
      if (_cancelRequested) {
        throw const AutomationError(
          AutomationErrorKind.cancelled,
          'Commit message generation was cancelled.',
        );
      }
      if (exitCode != 0) throw _processError(selection.harnessId, stderr);
      final message = parseOutput(selection.harnessId, stdout);
      if (message.isEmpty) {
        throw const AutomationError(
          AutomationErrorKind.invalidResponse,
          'The automation returned an empty commit message.',
        );
      }
      // Convenções (72 chars, ponto final, …) viram aviso — o rascunho fica
      // editável. Só mensagem vazia é hard-fail acima.
      return GeneratedCommitMessage(
        message: message,
        warning: CommitMessagePrompt.validate(message),
      );
    } on TimeoutException catch (error) {
      process.kill();
      throw AutomationError(
        AutomationErrorKind.timeout,
        '${selection.harnessId.label} did not respond within ${timeout.inSeconds} seconds.',
        cause: error,
      );
    } finally {
      if (identical(_activeProcess, process)) _activeProcess = null;
      await _deleteTemporaryDirectory(systemPromptDirectory);
    }
  }

  static ({List<String> args, String? stdin}) buildCommand(
    AutomationSelection selection,
    String prompt, {
    String? codexSystemPromptPath,
  }) {
    final model = selection.modelId?.trim();
    final modelArgs = model == null || model.isEmpty
        ? const <String>[]
        : <String>['--model', model];
    final promptWithInstructions = CommitMessagePrompt.withSystemPrompt(prompt);
    return switch (selection.harnessId) {
      AutomationHarnessId.pi => (
        args: <String>[
          '-p',
          '--mode',
          'json',
          '--no-session',
          '--no-tools',
          '--no-extensions',
          '--no-skills',
          '--no-context-files',
          '--no-approve',
          '--system-prompt',
          CommitMessagePrompt.systemPrompt,
          ...modelArgs,
          prompt,
        ],
        stdin: null,
      ),
      AutomationHarnessId.claude => (
        args: <String>[
          '-p',
          '--output-format',
          'json',
          '--tools',
          '',
          '--no-session-persistence',
          '--disable-slash-commands',
          '--system-prompt',
          CommitMessagePrompt.systemPrompt,
          ...modelArgs,
        ],
        stdin: prompt,
      ),
      AutomationHarnessId.codex => (
        args: <String>[
          'exec',
          '--ephemeral',
          '--sandbox',
          'read-only',
          '--skip-git-repo-check',
          '--json',
          '-c',
          'model_instructions_file=${jsonEncode(_requiredCodexSystemPromptPath(codexSystemPromptPath))}',
          ...modelArgs,
          '-',
        ],
        stdin: prompt,
      ),
      AutomationHarnessId.gemini => (
        args: <String>[
          '-p',
          promptWithInstructions,
          '--output-format',
          'json',
          ...modelArgs,
        ],
        stdin: null,
      ),
      AutomationHarnessId.opencode => (
        args: <String>[
          'run',
          '--format',
          'json',
          ...modelArgs,
          promptWithInstructions,
        ],
        stdin: null,
      ),
      AutomationHarnessId.copilot => (
        args: <String>[
          '-p',
          promptWithInstructions,
          '-s',
          '--no-remote-export',
          ...modelArgs,
        ],
        stdin: null,
      ),
    };
  }

  static String _requiredCodexSystemPromptPath(String? path) {
    if (path == null || path.isEmpty) {
      throw ArgumentError(
        'codexSystemPromptPath is required for the Codex harness.',
      );
    }
    return path;
  }

  static Future<void> _deleteTemporaryDirectory(Directory? directory) async {
    if (directory == null) return;
    try {
      await directory.delete(recursive: true);
    } on FileSystemException {
      // Best-effort cleanup must not hide the automation result.
    }
  }

  static String parseOutput(AutomationHarnessId id, String stdout) {
    String message;
    switch (id) {
      case AutomationHarnessId.claude:
        final value = _decodeSingleJson(stdout);
        message = value is Map ? value['result']?.toString() ?? '' : '';
      case AutomationHarnessId.gemini:
        final value = _decodeSingleJson(stdout);
        message = value is Map ? value['response']?.toString() ?? '' : '';
      case AutomationHarnessId.pi:
        message = _lastJsonText(stdout, pi: true);
      case AutomationHarnessId.codex:
        message = _lastJsonText(stdout, codex: true);
      case AutomationHarnessId.opencode:
        message = _lastJsonText(stdout, openCode: true);
      case AutomationHarnessId.copilot:
        message = stdout;
    }
    return normalizeCommitMessage(message);
  }

  /// Alguns CLIs obedecem ao conteúdo mas ainda envolvem a resposta inteira
  /// em um fence. Desembrulhamos apenas esse caso inequívoco; Markdown misturado
  /// à mensagem continua sendo rejeitado pelo validador.
  static String normalizeCommitMessage(String raw) {
    var value = raw
        .replaceAll('\r\n', '\n')
        .replaceFirst(RegExp(r'^commit message:\s*', caseSensitive: false), '')
        .trim();
    final fenced = RegExp(
      r'^```[^\n]*\n([\s\S]*?)\n```[ \t]*$',
    ).firstMatch(value);
    if (fenced != null) value = fenced.group(1)!.trim();
    return value;
  }

  static Object? _decodeSingleJson(String value) {
    try {
      return jsonDecode(value.trim());
    } catch (_) {
      return null;
    }
  }

  static String _lastJsonText(
    String stdout, {
    bool pi = false,
    bool codex = false,
    bool openCode = false,
  }) {
    var result = '';
    for (final line in stdout.split('\n')) {
      final raw = _decodeSingleJson(line);
      if (raw is! Map) continue;
      if (pi && raw['type'] == 'message_end') {
        result = _contentText((raw['message'] as Map?)?['content']);
      } else if (codex && raw['type'] == 'item.completed') {
        final item = raw['item'];
        if (item is Map && item['type'] == 'agent_message') {
          result = item['text']?.toString() ?? '';
        }
      } else if (openCode) {
        final part = raw['part'];
        final candidate = part is Map
            ? part['text']?.toString()
            : raw['text']?.toString();
        if (candidate != null && candidate.isNotEmpty) result += candidate;
      }
    }
    return result;
  }

  static String _contentText(Object? content) {
    if (content is String) return content;
    if (content is! List) return '';
    return content
        .whereType<Map>()
        .where((part) => part['type'] == 'text')
        .map((part) => part['text']?.toString() ?? '')
        .join();
  }

  static List<AutomationModel> parsePiModels(String output) {
    final models = <AutomationModel>[];
    for (final line in output.split('\n').skip(1)) {
      final columns = line.trim().split(RegExp(r'\s{2,}'));
      if (columns.length < 2 || columns[0].isEmpty || columns[1].isEmpty) {
        continue;
      }
      final id = '${columns[0]}/${columns[1]}';
      models.add(AutomationModel(id: id, label: id));
    }
    return _uniqueModels(models);
  }

  static List<AutomationModel> parseOpenCodeModels(String output) {
    return _uniqueModels([
      for (final line in output.split('\n'))
        if (RegExp(r'^[^\s/]+/[^\s]+$').hasMatch(line.trim()))
          AutomationModel(id: line.trim(), label: line.trim()),
    ]);
  }

  /// Copilot CLI não expõe um catálogo machine-readable estável. O scrape de
  /// `copilot help` capturava palavras da prosa — preferimos o default do CLI.
  static List<AutomationModel> parseCopilotModels(String output) {
    return const <AutomationModel>[];
  }

  static List<AutomationModel> _uniqueModels(List<AutomationModel> values) {
    final byId = <String, AutomationModel>{};
    for (final value in values) {
      byId[value.id] = value;
    }
    return byId.values.toList();
  }

  AutomationError _processError(AutomationHarnessId id, String stderr) {
    final clean = stderr.replaceAll(RegExp(r'\s+'), ' ').trim();
    final detail = clean.length > 300 ? '${clean.substring(0, 300)}…' : clean;
    final lower = clean.toLowerCase();
    final authentication = const [
      'auth',
      'login',
      'credential',
      'subscription',
      'api key',
    ].any(lower.contains);
    return AutomationError(
      authentication
          ? AutomationErrorKind.authentication
          : AutomationErrorKind.process,
      detail.isEmpty
          ? '${id.label} could not generate a commit message.'
          : '${id.label}: $detail',
    );
  }

  @override
  Future<void> cancel() async {
    _cancelRequested = true;
    _activeProcess?.kill();
  }

  @override
  Future<void> close() async => cancel();
}

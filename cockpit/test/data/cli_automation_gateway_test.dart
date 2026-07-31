import 'package:cockpit/app/core/data/automation/cli_automation_gateway.dart';
import 'package:cockpit/app/core/domain/entities/automation.dart';
import 'package:cockpit/app/core/domain/services/commit_message_prompt.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'builds read-only ephemeral Codex command and sends prompt over stdin',
    () {
      const selection = AutomationSelection(
        harnessId: AutomationHarnessId.codex,
        modelId: 'gpt-5.4-mini',
      );

      final command = CliAutomationGateway.buildCommand(selection, 'prompt');

      expect(
        command.args,
        containsAll(['--ephemeral', '--sandbox', 'read-only']),
      );
      expect(command.args, containsAll(['--model', 'gpt-5.4-mini']));
      expect(command.stdin, 'prompt');
    },
  );

  test('parses provider-specific structured outputs', () {
    expect(
      CliAutomationGateway.parseOutput(
        AutomationHarnessId.claude,
        '{"result":"fix: claude output"}',
      ),
      'fix: claude output',
    );
    expect(
      CliAutomationGateway.parseOutput(
        AutomationHarnessId.claude,
        '{"result":"```gitcommit\\nrefactor: unwrap Claude output\\n```"}',
      ),
      'refactor: unwrap Claude output',
    );
    expect(
      CliAutomationGateway.parseOutput(
        AutomationHarnessId.gemini,
        '{"response":"fix: gemini output"}',
      ),
      'fix: gemini output',
    );
    expect(
      CliAutomationGateway.parseOutput(
        AutomationHarnessId.codex,
        '{"type":"item.completed","item":{"type":"agent_message","text":"fix: codex output"}}',
      ),
      'fix: codex output',
    );
    expect(
      CliAutomationGateway.parseOutput(
        AutomationHarnessId.pi,
        '{"type":"message_end","message":{"content":[{"type":"text","text":"fix: pi output"}]}}',
      ),
      'fix: pi output',
    );
  });

  test('parses model discovery output', () {
    final pi = CliAutomationGateway.parsePiModels(
      'provider  model  context  max-out\nopenai  gpt-5  200000  32000\n',
    );
    final openCode = CliAutomationGateway.parseOpenCodeModels(
      'anthropic/claude-sonnet-4\ninvalid line\n',
    );

    expect(pi.single.id, 'openai/gpt-5');
    expect(openCode.single.id, 'anthropic/claude-sonnet-4');
    expect(
      AutomationHarnessId.claude.builtInModels.map((model) => model.id),
      containsAll(<String>['sonnet', 'opus']),
    );
    expect(AutomationHarnessId.codex.recommendedModelId, 'gpt-5.6-terra');
    expect(AutomationHarnessId.gemini.recommendedModelId, 'flash');
  });

  test('redacts credentials and validates generated messages', () {
    final prompt = CommitMessagePrompt.build(
      'diff --git a/app.dart b/app.dart\n+api_key=secret-value',
      const ['feat: recent'],
    );

    expect(prompt, isNot(contains('secret-value')));
    expect(prompt, contains('[sensitive line redacted by Cockpit]'));
    expect(prompt, contains('intent and meaningful outcome'));
    expect(prompt, contains('1–3 lines'));
    expect(CommitMessagePrompt.validate('fix: safe subject'), isNull);
    expect(CommitMessagePrompt.validate('fix: invalid.'), isNotNull);
  });
}

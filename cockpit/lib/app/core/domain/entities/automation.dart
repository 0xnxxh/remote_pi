enum AutomationHarnessId { pi, claude, codex, gemini, opencode, copilot }

extension AutomationHarnessIdLabel on AutomationHarnessId {
  String get label => switch (this) {
    AutomationHarnessId.pi => 'Pi',
    AutomationHarnessId.claude => 'Claude Code',
    AutomationHarnessId.codex => 'Codex CLI',
    AutomationHarnessId.gemini => 'Gemini CLI',
    AutomationHarnessId.opencode => 'OpenCode',
    AutomationHarnessId.copilot => 'Copilot CLI',
  };

  String get executableName => switch (this) {
    AutomationHarnessId.pi => 'pi',
    AutomationHarnessId.claude => 'claude',
    AutomationHarnessId.codex => 'codex',
    AutomationHarnessId.gemini => 'gemini',
    AutomationHarnessId.opencode => 'opencode',
    AutomationHarnessId.copilot => 'copilot',
  };

  /// Modelo equilibrado para a tarefa curta e bem definida de escrever commits.
  /// Aliases dos CLIs são preferidos quando eles acompanham a linha atual.
  String? get recommendedModelId => switch (this) {
    AutomationHarnessId.claude => 'sonnet',
    AutomationHarnessId.codex => 'gpt-5.6-terra',
    AutomationHarnessId.gemini => 'flash',
    _ => null,
  };

  List<AutomationModel> get builtInModels => switch (this) {
    AutomationHarnessId.claude => const <AutomationModel>[
      AutomationModel(id: 'sonnet', label: 'Sonnet'),
      AutomationModel(id: 'opus', label: 'Opus'),
    ],
    AutomationHarnessId.codex => const <AutomationModel>[
      AutomationModel(id: 'gpt-5.6-terra', label: 'GPT-5.6 Terra'),
      AutomationModel(id: 'gpt-5.6-sol', label: 'GPT-5.6 Sol'),
      AutomationModel(id: 'gpt-5.6-luna', label: 'GPT-5.6 Luna'),
    ],
    AutomationHarnessId.gemini => const <AutomationModel>[
      AutomationModel(id: 'flash', label: 'Flash'),
      AutomationModel(id: 'auto', label: 'Auto'),
      AutomationModel(id: 'pro', label: 'Pro'),
      AutomationModel(id: 'flash-lite', label: 'Flash Lite'),
    ],
    _ => const <AutomationModel>[],
  };
}

class AutomationModel {
  const AutomationModel({required this.id, required this.label});

  final String id;
  final String label;
}

class AutomationHarness {
  const AutomationHarness({
    required this.id,
    required this.executablePath,
    this.models = const <AutomationModel>[],
  });

  final AutomationHarnessId id;
  final String executablePath;
  final List<AutomationModel> models;

  String get label => id.label;
}

class AutomationSelection {
  const AutomationSelection({required this.harnessId, this.modelId});

  final AutomationHarnessId harnessId;
  final String? modelId;
}

class AutomationRequest {
  const AutomationRequest({required this.prompt, required this.repositoryPath});

  final String prompt;
  final String repositoryPath;
}

/// Mensagem gerada pelo harness. [warning] é um aviso de convenção (subject
/// longo, ponto final, etc.) — a mensagem ainda é um rascunho editável.
class GeneratedCommitMessage {
  const GeneratedCommitMessage({required this.message, this.warning});

  final String message;
  final String? warning;
}

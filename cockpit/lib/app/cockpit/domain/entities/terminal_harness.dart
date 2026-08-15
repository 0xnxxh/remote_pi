enum TerminalHarnessKind {
  antigravity,
  claudeCode,
  codex,
  cursor,
  gitHubCopilot,
  openCode,
  pi,
}

class TerminalHarnessSpec {
  final TerminalHarnessKind kind;
  final String label;
  final String primaryEntryPoint;
  final List<String> aliases;
  final String assetPath;
  final bool isMonochrome;

  const TerminalHarnessSpec({
    required this.kind,
    required this.label,
    required this.primaryEntryPoint,
    required this.aliases,
    required this.assetPath,
    required this.isMonochrome,
  });

  /// All entry point names that can trigger this harness.
  List<String> get allEntryPoints => [primaryEntryPoint, ...aliases];
}

abstract class TerminalHarnessCatalog {
  static const Map<TerminalHarnessKind, TerminalHarnessSpec> specs = {
    TerminalHarnessKind.antigravity: TerminalHarnessSpec(
      kind: TerminalHarnessKind.antigravity,
      label: 'Antigravity',
      primaryEntryPoint: 'agy',
      aliases: ['antigravity'],
      assetPath: 'assets/harness_icons/antigravity.svg',
      isMonochrome: false,
    ),
    TerminalHarnessKind.claudeCode: TerminalHarnessSpec(
      kind: TerminalHarnessKind.claudeCode,
      label: 'Claude Code',
      primaryEntryPoint: 'claude',
      aliases: ['claude-code'],
      assetPath: 'assets/harness_icons/claudecode.svg',
      isMonochrome: true,
    ),
    TerminalHarnessKind.codex: TerminalHarnessSpec(
      kind: TerminalHarnessKind.codex,
      label: 'Codex',
      primaryEntryPoint: 'codex',
      aliases: [],
      assetPath: 'assets/harness_icons/codex.svg',
      isMonochrome: false,
    ),
    TerminalHarnessKind.cursor: TerminalHarnessSpec(
      kind: TerminalHarnessKind.cursor,
      label: 'Cursor',
      primaryEntryPoint: 'cursor-agent',
      // `agent` is the published symlink/launcher name (`exec -a` keeps it in argv0).
      aliases: ['cursor', 'agent'],
      assetPath: 'assets/harness_icons/cursor.svg',
      isMonochrome: true,
    ),
    TerminalHarnessKind.gitHubCopilot: TerminalHarnessSpec(
      kind: TerminalHarnessKind.gitHubCopilot,
      label: 'GitHub Copilot',
      primaryEntryPoint: 'copilot',
      aliases: ['github-copilot'],
      assetPath: 'assets/harness_icons/githubcopilot.svg',
      isMonochrome: true,
    ),
    TerminalHarnessKind.openCode: TerminalHarnessSpec(
      kind: TerminalHarnessKind.openCode,
      label: 'OpenCode',
      primaryEntryPoint: 'opencode',
      aliases: [],
      assetPath: 'assets/harness_icons/opencode.svg',
      isMonochrome: true,
    ),
    TerminalHarnessKind.pi: TerminalHarnessSpec(
      kind: TerminalHarnessKind.pi,
      label: 'Pi',
      primaryEntryPoint: 'pi',
      aliases: [],
      assetPath: 'assets/harness_icons/pi.svg',
      isMonochrome: true,
    ),
  };

  static TerminalHarnessSpec? getSpec(TerminalHarnessKind kind) => specs[kind];
}

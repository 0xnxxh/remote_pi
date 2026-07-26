import 'package:cockpit/app/core/utils/executable_resolver.dart';

class CopilotServerCommand {
  const CopilotServerCommand(this.executable, this.args);
  final String executable;
  final List<String> args;
}

abstract class CopilotServerResolver {
  Future<CopilotServerCommand?> resolve();
}

/// Distribuição oficial documentada pelo projeto do Copilot Language Server.
/// `npx -y` instala/atualiza o pacote pinado sem exigir Copilot CLI ou setup
/// manual. O pin impede mudanças silenciosas de protocolo.
class NpxCopilotServerResolver implements CopilotServerResolver {
  const NpxCopilotServerResolver();

  static const version = '1.526.0';

  @override
  Future<CopilotServerCommand?> resolve() async {
    if (!await isExecutableAvailable('npx')) return null;
    final executable = await resolveExecutable(
      'npx',
      windowsExtraDirs: const [r'C:\Program Files\nodejs'],
    );
    return CopilotServerCommand(executable, const [
      '-y',
      '@github/copilot-language-server@$version',
      '--stdio',
    ]);
  }
}

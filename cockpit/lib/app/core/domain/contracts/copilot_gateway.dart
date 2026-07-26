import 'package:cockpit/app/core/domain/entities/copilot.dart';

/// Fachada do domínio para o Copilot. Detalhes de processo, LSP, autenticação e
/// da adaptação de commit ficam exclusivamente na implementação em `data/`.
abstract class CopilotGateway {
  Stream<CopilotStatus> get status;
  CopilotStatus get currentStatus;

  Future<void> start({required String workspacePath});
  Future<CopilotAuthentication> beginAuthentication();
  Future<void> completeAuthentication(CopilotAuthentication authentication);
  Future<void> disconnect();

  Future<String> generateCommitMessage({
    required String repositoryPath,
    required String diff,
    required List<String> recentCommitSubjects,
  });

  Future<void> cancelGeneration();
  Future<void> close();
  void dispose();
}

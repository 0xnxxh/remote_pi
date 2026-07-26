/// Estado observável da integração com GitHub Copilot.
enum CopilotState {
  starting,
  connecting,
  waitingForAuthentication,
  connected,
  disconnected,
  authenticationFailed,
  subscriptionUnavailable,
  quotaReached,
  networkUnavailable,
  languageServerUnavailable,
  error,
}

class CopilotStatus {
  const CopilotStatus(this.state, this.message, {this.account});

  const CopilotStatus.disconnected()
    : this(CopilotState.disconnected, 'GitHub Copilot is not connected.');

  final CopilotState state;
  final String message;
  final String? account;

  bool get isConnected => state == CopilotState.connected;
  bool get isBusy =>
      state == CopilotState.starting ||
      state == CopilotState.connecting ||
      state == CopilotState.waitingForAuthentication;

  CopilotStatus copyWith({
    CopilotState? state,
    String? message,
    String? account,
  }) => CopilotStatus(
    state ?? this.state,
    message ?? this.message,
    account: account ?? this.account,
  );
}

/// Dados não sensíveis mostrados durante o device flow. O comando oficial do
/// protocolo permanece guardado dentro do gateway, nunca chega à UI.
class CopilotAuthentication {
  const CopilotAuthentication({required this.id, required this.userCode});

  final String id;
  final String userCode;
}

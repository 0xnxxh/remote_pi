enum CopilotErrorKind {
  unavailable,
  authentication,
  subscription,
  quota,
  network,
  timeout,
  cancelled,
  protocol,
  invalidResponse,
  noChanges,
}

class CopilotError implements Exception {
  const CopilotError(this.kind, this.message, {this.cause});

  final CopilotErrorKind kind;
  final String message;
  final Object? cause;

  @override
  String toString() => message;
}

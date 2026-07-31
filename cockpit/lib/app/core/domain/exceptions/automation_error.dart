enum AutomationErrorKind {
  unavailable,
  authentication,
  timeout,
  cancelled,
  process,
  invalidResponse,
}

class AutomationError implements Exception {
  const AutomationError(this.kind, this.message, {this.cause});

  final AutomationErrorKind kind;
  final String message;
  final Object? cause;

  @override
  String toString() => message;
}

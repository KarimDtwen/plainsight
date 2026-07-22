enum ApiErrorKind { timeout, offline, unauthorized, server }

class ApiException implements Exception {
  const ApiException(this.kind, this.message);

  final ApiErrorKind kind;
  final String message;

  @override
  String toString() => message;
}

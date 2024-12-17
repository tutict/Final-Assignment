class ApiException implements Exception {
  final int code;
  final String message;
  final Exception? innerException;
  final StackTrace? stackTrace;

  ApiException(this.code, this.message)
      : innerException = null,
        stackTrace = null;

  ApiException.withInner(
      this.code, this.message, this.innerException, this.stackTrace);

  @override
  String toString() {
    String result = "ApiException $code: $message";

    if (innerException != null) {
      result += " (Inner exception: $innerException)";
    }

    if (stackTrace != null) {
      result += "\n\n$stackTrace";
    }

    return result;
  }
}

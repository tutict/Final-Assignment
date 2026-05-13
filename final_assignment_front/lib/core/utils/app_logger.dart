import 'dart:developer' as developer;

class AppLogger {
  static void debug(String message, {String name = 'App'}) {
    assert(() {
      developer.log(message, name: name);
      return true;
    }());
  }

  static void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    String name = 'AppError',
  }) {
    developer.log(
      message,
      name: name,
      error: error,
      stackTrace: stackTrace,
    );
  }
}

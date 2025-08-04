import 'package:flutter/foundation.dart';

/// Logger interface for weight scale operations
abstract class WeightScaleLogger {
  void debug(String message);
  void info(String message);
  void warning(String message);
  void error(String message, [Object? error, StackTrace? stackTrace]);
}

/// Default console logger implementation
class ConsoleLogger implements WeightScaleLogger {
  final String prefix;
  final bool enabled;

  const ConsoleLogger({
    this.prefix = 'WeightScale',
    this.enabled = kDebugMode,
  });

  @override
  void debug(String message) {
    if (enabled) debugPrint('[$prefix] DEBUG: $message');
  }

  @override
  void info(String message) {
    if (enabled) debugPrint('[$prefix] INFO: $message');
  }

  @override
  void warning(String message) {
    if (enabled) debugPrint('[$prefix] WARNING: $message');
  }

  @override
  void error(String message, [Object? error, StackTrace? stackTrace]) {
    if (enabled) {
      debugPrint('[$prefix] ERROR: $message');
      if (error != null) debugPrint('[$prefix] Error details: $error');
      if (stackTrace != null) debugPrint('[$prefix] Stack trace: $stackTrace');
    }
  }
}

/// Silent logger for production/testing
class SilentLogger implements WeightScaleLogger {
  const SilentLogger();

  @override
  void debug(String message) {}

  @override
  void info(String message) {}

  @override
  void warning(String message) {}

  @override
  void error(String message, [Object? error, StackTrace? stackTrace]) {}
}

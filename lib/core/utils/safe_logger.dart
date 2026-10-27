import 'package:flutter/foundation.dart';

/// Logger that only emits in debug mode, so PHI never reaches release logs.
class SafeLogger {
  const SafeLogger._();

  static void debug(String message) {
    if (kDebugMode) debugPrint('[BloomCare] $message');
  }
}

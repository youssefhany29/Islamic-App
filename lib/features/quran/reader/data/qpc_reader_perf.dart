import 'package:flutter/foundation.dart';

class QpcReaderPerf {
  QpcReaderPerf._();

  static const bool _forceEnabled = bool.fromEnvironment('QPC_PERF_LOGS');

  static bool get _enabled => kDebugMode || _forceEnabled;

  static Stopwatch? start() {
    if (!_enabled) {
      return null;
    }

    return Stopwatch()..start();
  }

  static void end(String label, Stopwatch? stopwatch) {
    if (!_enabled || stopwatch == null) {
      return;
    }

    stopwatch.stop();
    debugPrint('[QPC perf] $label ${stopwatch.elapsedMilliseconds}ms');
  }

  static void mark(String label) {
    if (!_enabled) {
      return;
    }

    debugPrint('[QPC perf] $label');
  }

  static Future<T> timeAsync<T>(
    String label,
    Future<T> Function() action,
  ) async {
    if (!_enabled) {
      return action();
    }

    final Stopwatch stopwatch = Stopwatch()..start();
    try {
      return await action();
    } finally {
      stopwatch.stop();
      debugPrint('[QPC perf] $label ${stopwatch.elapsedMilliseconds}ms');
    }
  }
}

import 'dart:async';

import 'package:flutter/foundation.dart';

class RecitationSleepTimerState {
  final bool active;
  final int remainingSeconds;
  final int totalSeconds;

  const RecitationSleepTimerState({
    required this.active,
    required this.remainingSeconds,
    required this.totalSeconds,
  });

  static const inactive = RecitationSleepTimerState(
    active: false,
    remainingSeconds: 0,
    totalSeconds: 0,
  );

  String get remainingText {
    if (!active || remainingSeconds <= 0) return 'غير مفعل';

    final minutes = remainingSeconds ~/ 60;
    final seconds = remainingSeconds % 60;

    if (minutes <= 0) return '$seconds ثانية';

    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

class RecitationSleepTimerService {
  RecitationSleepTimerService._internal();

  static final RecitationSleepTimerService instance =
  RecitationSleepTimerService._internal();

  final ValueNotifier<RecitationSleepTimerState> stateNotifier =
  ValueNotifier<RecitationSleepTimerState>(
    RecitationSleepTimerState.inactive,
  );

  Timer? _timer;
  VoidCallback? _onFinished;

  void start({
    required Duration duration,
    required VoidCallback onFinished,
  }) {
    cancel();

    final totalSeconds = duration.inSeconds;

    if (totalSeconds <= 0) return;

    _onFinished = onFinished;

    stateNotifier.value = RecitationSleepTimerState(
      active: true,
      remainingSeconds: totalSeconds,
      totalSeconds: totalSeconds,
    );

    _timer = Timer.periodic(
      const Duration(seconds: 1),
          (timer) {
        final current = stateNotifier.value;

        final nextSeconds = current.remainingSeconds - 1;

        if (nextSeconds <= 0) {
          cancel();
          _onFinished?.call();
          return;
        }

        stateNotifier.value = RecitationSleepTimerState(
          active: true,
          remainingSeconds: nextSeconds,
          totalSeconds: totalSeconds,
        );
      },
    );
  }

  void cancel() {
    _timer?.cancel();
    _timer = null;
    _onFinished = null;

    stateNotifier.value = RecitationSleepTimerState.inactive;
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
    stateNotifier.dispose();
  }
}
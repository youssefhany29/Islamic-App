import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:islamic_app/features/settings/notifications_settings_provider.dart';
import 'package:provider/provider.dart';

class AppHaptics {
  AppHaptics._();

  static void tap(BuildContext context) {
    final bool enabled = context
        .read<NotificationsSettingsProvider>()
        .hapticFeedbackEnabled;

    if (!enabled) return;

    HapticFeedback.selectionClick();
  }

  static void light(BuildContext context) {
    final bool enabled = context
        .read<NotificationsSettingsProvider>()
        .hapticFeedbackEnabled;

    if (!enabled) return;

    HapticFeedback.lightImpact();
  }

  static void medium(BuildContext context) {
    final bool enabled = context
        .read<NotificationsSettingsProvider>()
        .hapticFeedbackEnabled;

    if (!enabled) return;

    HapticFeedback.mediumImpact();
  }
}
import 'package:flutter/material.dart';

enum RecitationCustomGoalType {
  dailyListeningMinutes,
  weeklyListeningMinutes,
  monthlyListeningHours,
  totalListeningHours,
  uniqueSurahs,
  uniqueReciters,
  streakDays,
  completedDailyGoals,
}

class RecitationCustomGoal {
  final String id;
  final String title;
  final RecitationCustomGoalType type;
  final int targetValue;

  /// للأهداف الرقمية العادية مثل الوقت / الستريك / عدد الأهداف المكتملة.
  final int startValue;

  /// للأهداف التي تعتمد على عناصر مختلفة مثل:
  /// - سور مختلفة
  /// - قراء مختلفون
  ///
  /// نخزن هنا عدد ثواني الاستماع لكل سورة/قارئ وقت إنشاء الهدف.
  /// بعد كده لو نفس العنصر زادت ثوانيه، نعتبره اتحسب في الهدف.
  final Map<String, int> startTargetSeconds;

  final int createdAtMs;

  const RecitationCustomGoal({
    required this.id,
    required this.title,
    required this.type,
    required this.targetValue,
    this.startValue = 0,
    this.startTargetSeconds = const <String, int>{},
    required this.createdAtMs,
  });

  RecitationCustomGoal copyWith({
    String? id,
    String? title,
    RecitationCustomGoalType? type,
    int? targetValue,
    int? startValue,
    Map<String, int>? startTargetSeconds,
    int? createdAtMs,
  }) {
    return RecitationCustomGoal(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      targetValue: targetValue ?? this.targetValue,
      startValue: startValue ?? this.startValue,
      startTargetSeconds: startTargetSeconds ?? this.startTargetSeconds,
      createdAtMs: createdAtMs ?? this.createdAtMs,
    );
  }

  factory RecitationCustomGoal.fromJson(Map<String, dynamic> json) {
    final rawStartTargetSeconds = json['startTargetSeconds'];
    final Map<String, int> parsedStartTargetSeconds = {};

    if (rawStartTargetSeconds is Map) {
      rawStartTargetSeconds.forEach((key, value) {
        parsedStartTargetSeconds[key.toString()] =
        value is int ? value : int.tryParse(value.toString()) ?? 0;
      });
    }

    return RecitationCustomGoal(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'هدف شخصي',
      type: RecitationCustomGoalType.values.firstWhere(
            (item) => item.name == json['type']?.toString(),
        orElse: () => RecitationCustomGoalType.dailyListeningMinutes,
      ),
      targetValue: int.tryParse(json['targetValue'].toString()) ?? 1,
      startValue: int.tryParse(json['startValue']?.toString() ?? '0') ?? 0,
      startTargetSeconds: parsedStartTargetSeconds,
      createdAtMs: int.tryParse(json['createdAtMs'].toString()) ??
          DateTime.now().millisecondsSinceEpoch,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'type': type.name,
      'targetValue': targetValue,
      'startValue': startValue,
      'startTargetSeconds': startTargetSeconds,
      'createdAtMs': createdAtMs,
    };
  }
}

class RecitationCustomGoalTypeInfo {
  final String title;
  final String description;
  final String unit;
  final IconData icon;
  final int defaultTarget;

  const RecitationCustomGoalTypeInfo({
    required this.title,
    required this.description,
    required this.unit,
    required this.icon,
    required this.defaultTarget,
  });
}

extension RecitationCustomGoalTypeX on RecitationCustomGoalType {
  RecitationCustomGoalTypeInfo get info {
    switch (this) {
      case RecitationCustomGoalType.dailyListeningMinutes:
        return const RecitationCustomGoalTypeInfo(
          title: 'استماع يومي',
          description: 'استمع لعدد دقائق معين اليوم',
          unit: 'دقيقة',
          icon: Icons.today_rounded,
          defaultTarget: 20,
        );

      case RecitationCustomGoalType.weeklyListeningMinutes:
        return const RecitationCustomGoalTypeInfo(
          title: 'استماع أسبوعي',
          description: 'استمع لعدد دقائق معين خلال آخر ٧ أيام',
          unit: 'دقيقة',
          icon: Icons.view_week_rounded,
          defaultTarget: 120,
        );

      case RecitationCustomGoalType.monthlyListeningHours:
        return const RecitationCustomGoalTypeInfo(
          title: 'استماع شهري',
          description: 'استمع لعدد ساعات معين هذا الشهر',
          unit: 'ساعة',
          icon: Icons.calendar_month_rounded,
          defaultTarget: 5,
        );

      case RecitationCustomGoalType.totalListeningHours:
        return const RecitationCustomGoalTypeInfo(
          title: 'إجمالي الاستماع',
          description: 'وصل لإجمالي ساعات استماع معين',
          unit: 'ساعة',
          icon: Icons.all_inclusive_rounded,
          defaultTarget: 10,
        );

      case RecitationCustomGoalType.uniqueSurahs:
        return const RecitationCustomGoalTypeInfo(
          title: 'سور مختلفة',
          description: 'استمع لعدد سور مختلفة',
          unit: 'سورة',
          icon: Icons.menu_book_rounded,
          defaultTarget: 10,
        );

      case RecitationCustomGoalType.uniqueReciters:
        return const RecitationCustomGoalTypeInfo(
          title: 'قراء مختلفون',
          description: 'استمع لعدد قراء مختلفين',
          unit: 'قارئ',
          icon: Icons.record_voice_over_rounded,
          defaultTarget: 5,
        );

      case RecitationCustomGoalType.streakDays:
        return const RecitationCustomGoalTypeInfo(
          title: 'أيام متتالية',
          description: 'حافظ على سلسلة استماع لعدد أيام',
          unit: 'يوم',
          icon: Icons.local_fire_department_rounded,
          defaultTarget: 7,
        );

      case RecitationCustomGoalType.completedDailyGoals:
        return const RecitationCustomGoalTypeInfo(
          title: 'أهداف يومية مكتملة',
          description: 'أكمل هدف الاستماع اليومي عدة مرات',
          unit: 'هدف',
          icon: Icons.flag_rounded,
          defaultTarget: 7,
        );
    }
  }
}
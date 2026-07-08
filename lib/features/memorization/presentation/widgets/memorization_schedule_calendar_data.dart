part of 'memorization_schedule_calendar_card.dart';

class _ScheduleData {
  final int plansCount;
  final List<_ScheduleItem> items;

  const _ScheduleData({required this.plansCount, required this.items});
}

class _ScheduleDay {
  final int offset;
  final DateTime date;
  final List<_ScheduleItem> items;

  const _ScheduleDay({
    required this.offset,
    required this.date,
    required this.items,
  });
}

class _ScheduleItem {
  final DateTime date;
  final String title;
  final String subtitle;
  final String badge;
  final String timeLabel;
  final IconData icon;
  final int priority;
  final MemorizationTodayTaskModel task;
  final bool isRescue;

  const _ScheduleItem({
    required this.date,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.timeLabel,
    required this.icon,
    required this.priority,
    required this.task,
    this.isRescue = false,
  });

  factory _ScheduleItem.fromJourney(MemorizationJourneyTask item) {
    return _ScheduleItem.fromTask(
      task: item.task,
      date: item.date,
      timeLabel: item.timeLabel,
      priority: item.priority,
      isRescue: false,
    );
  }

  factory _ScheduleItem.fromTask({
    required MemorizationTodayTaskModel task,
    required DateTime date,
    required String timeLabel,
    required int priority,
    required bool isRescue,
  }) {
    final type = task.type;
    final isNew = type == 'dailyNew';
    final isTest = type == 'selfTest';
    final isWeak = type == 'weakReview' || isRescue;

    return _ScheduleItem(
      date: DateTime(date.year, date.month, date.day),
      title: task.title,
      subtitle: isTest
          ? 'اختبار مجدول حسب الخطة. تفاصيل الموضع تظهر عند فتح الاختبار.'
          : task.scopeTitle.trim().isEmpty
          ? task.subtitle
          : '${task.scopeTitle} • ${task.subtitle}',
      badge: isWeak
          ? 'إنقاذ'
          : isTest
          ? 'اختبار'
          : isNew
          ? 'حفظ'
          : 'مراجعة',
      timeLabel: timeLabel,
      icon: isWeak
          ? Icons.healing_rounded
          : isTest
          ? Icons.fact_check_rounded
          : isNew
          ? Icons.menu_book_rounded
          : Icons.repeat_rounded,
      priority: priority,
      task: task,
      isRescue: isWeak,
    );
  }
}

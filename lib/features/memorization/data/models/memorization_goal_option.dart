import 'memorization_user_type.dart';

enum MemorizationGoalOptionType {
  dailyAmount,
  finishByDate,
  comfortableSuggestion,
  reviewSurahs,
  reviewJuz,
  reviewPages,
  reviewWholeQuran,
  maintainSevenDays,
  maintainFifteenDays,
  maintainMonth,
  maintainThreeMonths,
}

class MemorizationGoalOption {
  final MemorizationGoalOptionType type;
  final String title;
  final String subtitle;
  final String badge;

  const MemorizationGoalOption({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.badge,
  });

  static List<MemorizationGoalOption> optionsForUserType(
      MemorizationUserType userType,
      ) {
    switch (userType) {
      case MemorizationUserType.beginner:
        return const [
          MemorizationGoalOption(
            type: MemorizationGoalOptionType.dailyAmount,
            title: 'مقدار يومي',
            subtitle: 'حدد كام آية أو صفحة يوميًا حسب طاقتك.',
            badge: 'يومي',
          ),
          MemorizationGoalOption(
            type: MemorizationGoalOptionType.finishByDate,
            title: 'موعد نهاية',
            subtitle: 'حدد مدة، والتطبيق يحسب مقدارك اليومي.',
            badge: 'موعد',
          ),
          MemorizationGoalOption(
            type: MemorizationGoalOptionType.comfortableSuggestion,
            title: 'اقتراح ذكي',
            subtitle: 'التطبيق يقترح خطة مريحة حسب النطاق.',
            badge: 'مقترح',
          ),
        ];

      case MemorizationUserType.returning:
        return const [
          MemorizationGoalOption(
            type: MemorizationGoalOptionType.dailyAmount,
            title: 'ورد يومي ثابت',
            subtitle: 'حدد مقدار مراجعة يومي يسير.',
            badge: 'ورد',
          ),
          MemorizationGoalOption(
            type: MemorizationGoalOptionType.finishByDate,
            title: 'تثبيت في مدة',
            subtitle: 'حدد مدة، والتطبيق يوزع المحفوظ عليها.',
            badge: 'مدة',
          ),
          MemorizationGoalOption(
            type: MemorizationGoalOptionType.comfortableSuggestion,
            title: 'اقتراح ذكي',
            subtitle: 'خطة مراجعة موزونة تراعي وقتك ومستوى ثباتك.',
            badge: 'مقترح',
          ),
        ];

      case MemorizationUserType.strong:
        return const [
          MemorizationGoalOption(
            type: MemorizationGoalOptionType.maintainSevenDays,
            title: 'دورة قوية',
            subtitle: 'مراجعة مكثفة للحافظ المتمكن.',
            badge: 'قوي',
          ),
          MemorizationGoalOption(
            type: MemorizationGoalOptionType.maintainMonth,
            title: 'دورة شهرية',
            subtitle: 'مراجعة متوازنة للمحافظة على الحفظ.',
            badge: 'شهر',
          ),
          MemorizationGoalOption(
            type: MemorizationGoalOptionType.maintainThreeMonths,
            title: 'دورة طويلة',
            subtitle: 'مراجعة هادئة مع اختبار ذكي.',
            badge: 'هادئ',
          ),
        ];
    }
  }
}
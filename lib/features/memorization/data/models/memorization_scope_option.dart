import 'memorization_action_type.dart';
import 'memorization_user_type.dart';

enum MemorizationScopeType {
  surah,
  juz,
  hizb,
  pages,
  ayahs,
  wholeQuran,
  knownMemorized,
  weakSpots,
}

class MemorizationScopeOption {
  final MemorizationScopeType type;
  final String title;
  final String subtitle;
  final String badge;

  const MemorizationScopeOption({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.badge,
  });

  static List<MemorizationScopeOption> optionsFor({
    required MemorizationUserType userType,
    required MemorizationActionType actionType,
  }) {
    final bool isReview = actionType == MemorizationActionType.reviewOnly ||
        actionType == MemorizationActionType.strengthenAndTest;

    if (isReview) {
      return const [
        MemorizationScopeOption(
          type: MemorizationScopeType.surah,
          title: 'مراجعة سورة',
          subtitle: 'اختر سورة كاملة، والتطبيق يقسم مراجعتها تلقائيًا.',
          badge: 'سورة',
        ),
        MemorizationScopeOption(
          type: MemorizationScopeType.juz,
          title: 'مراجعة جزء',
          subtitle: 'راجع جزءًا كاملًا بورد منتظم يناسب قدرتك اليومية.',
          badge: 'جزء',
        ),
        MemorizationScopeOption(
          type: MemorizationScopeType.hizb,
          title: 'مراجعة حزب',
          subtitle: 'مراجعة متوسطة الحجم بإيقاع مناسب.',
          badge: 'حزب',
        ),
        MemorizationScopeOption(
          type: MemorizationScopeType.pages,
          title: 'صفحات محددة',
          subtitle: 'حدد من صفحة إلى صفحة بدقة.',
          badge: 'صفحات',
        ),
        MemorizationScopeOption(
          type: MemorizationScopeType.wholeQuran,
          title: 'مراجعة القرآن كاملًا',
          subtitle: 'دورة مراجعة كاملة موزعة على أيام بشكل متوازن.',
          badge: 'كامل',
        ),
        MemorizationScopeOption(
          type: MemorizationScopeType.weakSpots,
          title: 'مواضع ضعيفة',
          subtitle: 'ركز فقط على المقاطع التي تحتاج تثبيتًا.',
          badge: 'ضعيف',
        ),
      ];
    }

    return const [
      MemorizationScopeOption(
        type: MemorizationScopeType.surah,
        title: 'حفظ سورة',
        subtitle: 'اختر سورة كاملة، والتطبيق يقسمها تلقائيًا حسب خطتك.',
        badge: 'سورة',
      ),
      MemorizationScopeOption(
        type: MemorizationScopeType.juz,
        title: 'حفظ جزء',
        subtitle: 'خطة طويلة لحفظ جزء كامل بتدرج ومراجعة يومية.',
        badge: 'جزء',
      ),
      MemorizationScopeOption(
        type: MemorizationScopeType.hizb,
        title: 'حفظ حزب',
        subtitle: 'اختيار متوسط بين السورة والجزء.',
        badge: 'حزب',
      ),
      MemorizationScopeOption(
        type: MemorizationScopeType.pages,
        title: 'صفحات محددة',
        subtitle: 'حدد بداية ونهاية الصفحات بدقة.',
        badge: 'صفحات',
      ),
      MemorizationScopeOption(
        type: MemorizationScopeType.wholeQuran,
        title: 'القرآن كامل',
        subtitle: 'خطة طويلة جدًا لحفظ القرآن كاملًا بدون استعجال.',
        badge: 'كامل',
      ),
    ];
  }
}

extension MemorizationScopeTypeX on MemorizationScopeType {
  String get title {
    switch (this) {
      case MemorizationScopeType.surah:
        return 'سورة';
      case MemorizationScopeType.juz:
        return 'جزء';
      case MemorizationScopeType.hizb:
        return 'حزب';
      case MemorizationScopeType.pages:
        return 'صفحات محددة';
      case MemorizationScopeType.ayahs:
        return 'آيات محددة';
      case MemorizationScopeType.wholeQuran:
        return 'القرآن كامل';
      case MemorizationScopeType.knownMemorized:
        return 'محفوظي كاملًا';
      case MemorizationScopeType.weakSpots:
        return 'مواضع ضعيفة';
    }
  }
}
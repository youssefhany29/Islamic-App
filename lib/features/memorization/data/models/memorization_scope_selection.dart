import 'memorization_scope_option.dart';

class MemorizationScopeSelection {
  final MemorizationScopeType type;
  final String title;

  final int? surahNumber;
  final String? surahName;
  final int? fromAyah;
  final int? toAyah;

  final int? juzNumber;
  final int? hizbNumber;

  final int? fromPage;
  final int? toPage;

  final int totalAyahs;
  final int totalPages;

  const MemorizationScopeSelection({
    required this.type,
    required this.title,
    required this.totalAyahs,
    required this.totalPages,
    this.surahNumber,
    this.surahName,
    this.fromAyah,
    this.toAyah,
    this.juzNumber,
    this.hizbNumber,
    this.fromPage,
    this.toPage,
  });

  bool get isAyahBased => totalAyahs > 0;

  bool get isPageBased => totalPages > 0;

  String get sizeText {
    final ayahText = totalAyahs > 0 ? '$totalAyahs آية' : '';
    final pageText = totalPages > 0 ? _formatPages(totalPages) : '';

    if (ayahText.isNotEmpty && pageText.isNotEmpty) {
      return '$ayahText / $pageText';
    }

    if (ayahText.isNotEmpty) return ayahText;
    if (pageText.isNotEmpty) return pageText;

    return 'نطاق غير محدد';
  }

  String get rangeText {
    switch (type) {
      case MemorizationScopeType.surah:
        if (fromAyah != null &&
            toAyah != null &&
            !(fromAyah == 1 && totalAyahs == (toAyah ?? 0))) {
          return '$title من آية $fromAyah إلى آية $toAyah';
        }
        return title;
      case MemorizationScopeType.ayahs:
        return '$title من آية $fromAyah إلى آية $toAyah';
      case MemorizationScopeType.pages:
        return 'من صفحة $fromPage إلى صفحة $toPage';
      default:
        return title;
    }
  }

  String _formatPages(int pages) {
    if (pages <= 0) return '0 صفحة';
    if (pages == 1) return 'صفحة واحدة';
    if (pages == 2) return 'صفحتين';
    if (pages >= 3 && pages <= 10) return '$pages صفحات';
    return '$pages صفحة';
  }
}

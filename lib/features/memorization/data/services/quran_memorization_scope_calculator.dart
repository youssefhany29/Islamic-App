import 'dart:math' as math;

import '../../../quran/reader/quran_page_mapper.dart';
import '../../../quran/reader/quran_reader_helpers.dart';
import '../models/memorization_scope_option.dart';
import '../models/memorization_scope_selection.dart';
import 'quran_memorization_hizb_boundaries.dart';

class QuranScopeCalculator {
  const QuranScopeCalculator();

  static const List<String> surahNames = [
    'الفاتحة',
    'البقرة',
    'آل عمران',
    'النساء',
    'المائدة',
    'الأنعام',
    'الأعراف',
    'الأنفال',
    'التوبة',
    'يونس',
    'هود',
    'يوسف',
    'الرعد',
    'إبراهيم',
    'الحجر',
    'النحل',
    'الإسراء',
    'الكهف',
    'مريم',
    'طه',
    'الأنبياء',
    'الحج',
    'المؤمنون',
    'النور',
    'الفرقان',
    'الشعراء',
    'النمل',
    'القصص',
    'العنكبوت',
    'الروم',
    'لقمان',
    'السجدة',
    'الأحزاب',
    'سبأ',
    'فاطر',
    'يس',
    'الصافات',
    'ص',
    'الزمر',
    'غافر',
    'فصلت',
    'الشورى',
    'الزخرف',
    'الدخان',
    'الجاثية',
    'الأحقاف',
    'محمد',
    'الفتح',
    'الحجرات',
    'ق',
    'الذاريات',
    'الطور',
    'النجم',
    'القمر',
    'الرحمن',
    'الواقعة',
    'الحديد',
    'المجادلة',
    'الحشر',
    'الممتحنة',
    'الصف',
    'الجمعة',
    'المنافقون',
    'التغابن',
    'الطلاق',
    'التحريم',
    'الملك',
    'القلم',
    'الحاقة',
    'المعارج',
    'نوح',
    'الجن',
    'المزمل',
    'المدثر',
    'القيامة',
    'الإنسان',
    'المرسلات',
    'النبأ',
    'النازعات',
    'عبس',
    'التكوير',
    'الانفطار',
    'المطففين',
    'الانشقاق',
    'البروج',
    'الطارق',
    'الأعلى',
    'الغاشية',
    'الفجر',
    'البلد',
    'الشمس',
    'الليل',
    'الضحى',
    'الشرح',
    'التين',
    'العلق',
    'القدر',
    'البينة',
    'الزلزلة',
    'العاديات',
    'القارعة',
    'التكاثر',
    'العصر',
    'الهمزة',
    'الفيل',
    'قريش',
    'الماعون',
    'الكوثر',
    'الكافرون',
    'النصر',
    'المسد',
    'الإخلاص',
    'الفلق',
    'الناس',
  ];

  static const List<int> surahAyahCounts = [
    7, 286, 200, 176, 120, 165, 206, 75, 129, 109, 123, 111, 43, 52, 99, 128,
    111, 110, 98, 135, 112, 78, 118, 64, 77, 227, 93, 88, 69, 60, 34, 30, 73,
    54, 45, 83, 182, 88, 75, 85, 54, 53, 89, 59, 37, 35, 38, 29, 18, 45, 60,
    49, 62, 55, 78, 96, 29, 22, 24, 13, 14, 11, 11, 18, 12, 12, 30, 52, 52, 44,
    28, 28, 20, 56, 40, 31, 50, 40, 46, 42, 29, 19, 36, 25, 22, 17, 19, 26, 30,
    20, 15, 21, 11, 8, 8, 19, 5, 8, 8, 11, 11, 8, 3, 9, 5, 4, 7, 3, 6, 3, 5, 4,
    5, 6,
  ];

  /// صفحات بداية السور في مصحف المدينة 604 صفحة.
  /// نستخدمها في شاشة الاختيار فقط حتى لا نعتمد على متوسط آيات/صفحات.
  static const List<int> surahStartPages = [
    1, 2, 50, 77, 106, 128, 151, 177, 187, 208, 221, 235, 249, 255, 262,
    267, 282, 293, 305, 312, 322, 332, 342, 350, 359, 367, 377, 385, 396,
    404, 411, 415, 418, 428, 434, 440, 446, 453, 458, 467, 477, 483, 489,
    496, 499, 502, 507, 511, 515, 518, 520, 523, 526, 528, 531, 534, 537,
    542, 545, 549, 551, 553, 554, 556, 558, 560, 562, 564, 566, 568, 570,
    572, 574, 575, 577, 578, 580, 582, 583, 585, 586, 587, 587, 589, 590,
    591, 591, 592, 593, 594, 595, 595, 596, 596, 597, 597, 598, 598, 599,
    599, 600, 600, 601, 601, 601, 602, 602, 602, 603, 603, 603, 604, 604,
    604,
  ];

  /// صفحات نهاية السور في مصحف المدينة 604 صفحة.
  /// بعض السور تشترك في الصفحة نفسها، لذلك لا يمكن الاعتماد على بداية السورة التالية - 1.
  static const List<int> surahEndPages = [
    1, 49, 76, 106, 127, 150, 176, 186, 207, 221, 235, 248, 255, 261, 267,
    281, 293, 304, 312, 321, 331, 341, 349, 359, 366, 376, 385, 396, 404,
    410, 414, 417, 427, 434, 440, 445, 452, 458, 467, 476, 482, 489, 495,
    498, 502, 506, 510, 515, 517, 520, 523, 525, 528, 531, 534, 537, 541,
    545, 548, 551, 552, 554, 555, 557, 559, 561, 564, 566, 568, 570, 571,
    573, 575, 577, 578, 580, 581, 583, 584, 586, 586, 587, 589, 590, 590,
    591, 592, 593, 594, 595, 595, 596, 596, 597, 597, 598, 598, 599, 599,
    600, 600, 600, 601, 601, 601, 602, 602, 602, 603, 603, 603, 604, 604,
    604,
  ];

  /// بدايات الأجزاء في مصحف المدينة 604 صفحة.
  static const List<int> juzStartPages = [
    1, 22, 42, 62, 82, 102, 121, 142, 162, 182, 201, 222, 242, 262, 282,
    302, 322, 342, 362, 382, 402, 422, 442, 462, 482, 502, 522, 542, 562, 582,
  ];

  int surahAyahCount(int surahNumber) {
    return surahAyahCounts[(surahNumber - 1).clamp(0, 113).toInt()];
  }

  String surahName(int surahNumber) {
    return surahNames[(surahNumber - 1).clamp(0, 113).toInt()];
  }

  int startPageForSurah(int surahNumber) {
    return surahStartPages[(surahNumber - 1).clamp(0, 113).toInt()];
  }

  int endPageForSurah(int surahNumber) {
    return surahEndPages[(surahNumber - 1).clamp(0, 113).toInt()];
  }

  int pagesForSurah(int surahNumber) {
    final start = startPageForSurah(surahNumber);
    final end = endPageForSurah(surahNumber);
    return math.max(1, end - start + 1);
  }

  int pagesForJuz(int juzNumber) {
    final int safeJuz = juzNumber.clamp(1, 30).toInt();
    final int start = juzStartPages[safeJuz - 1];
    final int end = safeJuz == 30 ? 604 : juzStartPages[safeJuz] - 1;
    return end - start + 1;
  }

  MemorizationScopeSelection buildSurah({
    required int surahNumber,
    int? fromAyah,
    int? toAyah,
  }) {
    final int safeSurah = surahNumber.clamp(1, 114).toInt();
    final int ayahCount = surahAyahCount(safeSurah);
    final int safeFrom = (fromAyah ?? 1).clamp(1, ayahCount).toInt();
    final int safeTo = (toAyah ?? ayahCount).clamp(safeFrom, ayahCount).toInt();
    final int totalAyahs = safeTo - safeFrom + 1;

    final bool isFullSurah = safeFrom == 1 && safeTo == ayahCount;

    return MemorizationScopeSelection(
      type: MemorizationScopeType.surah,
      title: 'سورة ${surahName(safeSurah)}',
      surahNumber: safeSurah,
      surahName: surahName(safeSurah),
      fromAyah: safeFrom,
      toAyah: safeTo,
      fromPage: isFullSurah ? startPageForSurah(safeSurah) : null,
      toPage: isFullSurah ? endPageForSurah(safeSurah) : null,
      totalAyahs: totalAyahs,
      totalPages: isFullSurah
          ? pagesForSurah(safeSurah)
          : estimatePagesFromAyahs(totalAyahs),
    );
  }

  MemorizationScopeSelection buildAyahs({
    required int surahNumber,
    required int fromAyah,
    required int toAyah,
  }) {
    final result = buildSurah(
      surahNumber: surahNumber,
      fromAyah: fromAyah,
      toAyah: toAyah,
    );

    return MemorizationScopeSelection(
      type: MemorizationScopeType.ayahs,
      title: 'سورة ${result.surahName}',
      surahNumber: result.surahNumber,
      surahName: result.surahName,
      fromAyah: result.fromAyah,
      toAyah: result.toAyah,
      fromPage: result.fromPage,
      toPage: result.toPage,
      totalAyahs: result.totalAyahs,
      totalPages: result.totalPages,
    );
  }

  MemorizationScopeSelection buildJuz(int juzNumber) {
    final int safeJuz = juzNumber.clamp(1, 30).toInt();

    return MemorizationScopeSelection(
      type: MemorizationScopeType.juz,
      title: 'الجزء $safeJuz',
      juzNumber: safeJuz,
      fromPage: juzStartPages[safeJuz - 1],
      toPage: safeJuz == 30 ? 604 : juzStartPages[safeJuz] - 1,
      totalAyahs: 0,
      totalPages: pagesForJuz(safeJuz),
    );
  }

  MemorizationScopeSelection buildHizb(int hizbNumber) {
    final int safeHizb = hizbNumber.clamp(1, 60).toInt();
    final hizbRange = QuranMemorizationHizbBoundaries.rangeForHizb(safeHizb);

    int fromPage = 1;
    int toPage = 1;

    if (hizbRange.isValid) {
      fromPage = QuranPageMapper.getPageNumberForGlobalAyah(
        hizbRange.startGlobalAyahIndex,
      );
      toPage = QuranPageMapper.getPageNumberForGlobalAyah(
        hizbRange.endGlobalAyahIndex,
      );
    } else {
      fromPage = (((safeHizb - 1) * 604) / 60).floor() + 1;
      toPage = ((safeHizb * 604) / 60).floor().clamp(fromPage, 604).toInt();
    }

    return MemorizationScopeSelection(
      type: MemorizationScopeType.hizb,
      title: 'الحزب $safeHizb',
      hizbNumber: safeHizb,
      fromPage: fromPage,
      toPage: toPage,
      totalAyahs: hizbRange.isValid ? hizbRange.endGlobalAyahIndex - hizbRange.startGlobalAyahIndex + 1 : 0,
      totalPages: math.max(1, toPage - fromPage + 1),
    );
  }

  MemorizationScopeSelection buildPages({
    required int fromPage,
    required int toPage,
  }) {
    final int safeFrom = fromPage.clamp(1, 604).toInt();
    final int safeTo = toPage.clamp(safeFrom, 604).toInt();

    return MemorizationScopeSelection(
      type: MemorizationScopeType.pages,
      title: 'صفحات محددة',
      fromPage: safeFrom,
      toPage: safeTo,
      totalAyahs: 0,
      totalPages: safeTo - safeFrom + 1,
    );
  }

  MemorizationScopeSelection buildWholeQuran() {
    return const MemorizationScopeSelection(
      type: MemorizationScopeType.wholeQuran,
      title: 'القرآن كامل',
      fromPage: 1,
      toPage: 604,
      totalAyahs: 6236,
      totalPages: 604,
    );
  }

  MemorizationScopeSelection buildWeakSpots() {
    return const MemorizationScopeSelection(
      type: MemorizationScopeType.weakSpots,
      title: 'المواضع الضعيفة',
      totalAyahs: 0,
      totalPages: 0,
    );
  }

  int estimatePagesFromAyahs(int ayahs) {
    if (ayahs <= 0) return 0;
    return math.max(1, (ayahs / 10.3).ceil());
  }
}

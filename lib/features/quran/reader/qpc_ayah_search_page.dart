import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../main_quraan_components/constant.dart';
import 'models/qpc_models.dart';
import 'quran_reader_helpers.dart';
import 'theme/quran_reader_theme.dart';

class QpcAyahSearchPage extends StatefulWidget {
  const QpcAyahSearchPage({
    super.key,
    required this.readerTheme,
    this.currentAyahKey,
  });

  final QuranReaderTheme readerTheme;
  final QpcAyahKey? currentAyahKey;

  @override
  State<QpcAyahSearchPage> createState() => _QpcAyahSearchPageState();
}

class _QpcAyahSearchPageState extends State<QpcAyahSearchPage> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  late final Future<List<_SearchIndexItem>> _indexFuture;
  List<_SearchIndexItem> _allItems = <_SearchIndexItem>[];
  List<_SearchIndexItem> _results = <_SearchIndexItem>[];
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _indexFuture = _buildIndex();
    _controller.addListener(_onQueryChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.removeListener(_onQueryChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<List<_SearchIndexItem>> _buildIndex() async {
    final List<dynamic> quranData = await readJson();
    final dynamic arabicSource = quranData.isNotEmpty ? quranData.first : null;
    final List<_SearchIndexItem> items = <_SearchIndexItem>[];

    for (int suraIndex = 0; suraIndex < noOfVerses.length; suraIndex++) {
      final String surahName = QuranReaderHelpers.getSuraName(suraIndex);
      final String normalizedSurahName = _normalizeArabic(surahName);

      for (int ayahIndex = 0; ayahIndex < noOfVerses[suraIndex]; ayahIndex++) {
        final int globalAyahIndex = QuranReaderHelpers.getGlobalAyahIndex(
          suraIndex: suraIndex,
          ayahIndex: ayahIndex,
        );

        final String displayText = _QuranSearchTextReader.readSmartHafsDisplayText(
          source: arabicSource,
          suraIndex: suraIndex,
          ayahIndex: ayahIndex,
        );

        final String searchableText = _QuranSearchTextReader.readSearchableText(
          source: arabicSource,
          suraIndex: suraIndex,
          ayahIndex: ayahIndex,
        );

        final String normalizedText = _normalizeArabic(
          searchableText.isNotEmpty ? searchableText : displayText,
        );

        items.add(
          _SearchIndexItem(
            ayahKey: QpcAyahKey(
              surah: suraIndex + 1,
              ayah: ayahIndex + 1,
            ),
            globalAyahIndex: globalAyahIndex,
            surahName: surahName,
            text: displayText,
            normalizedText: normalizedText,
            normalizedSurahName: normalizedSurahName,
            compactText: _compact(normalizedText),
          ),
        );
      }
    }

    _allItems = items;

    final String pendingQuery = _controller.text.trim();
    if (pendingQuery.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _runSearch(pendingQuery);
      });
    }

    return items;
  }

  void _onQueryChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 90), () {
      if (mounted) _runSearch(_controller.text);
    });
  }

  void _runSearch(String rawQuery) {
    final String query = rawQuery.trim();

    if (query.isEmpty) {
      setState(() => _results = <_SearchIndexItem>[]);
      return;
    }

    if (_allItems.isEmpty) return;

    final QpcAyahKey? directAyah = _parseDirectAyah(query);
    if (directAyah != null) {
      final _SearchIndexItem? directItem = _findItem(directAyah);
      setState(() {
        _results = directItem == null
            ? <_SearchIndexItem>[]
            : <_SearchIndexItem>[directItem];
      });
      return;
    }

    final String normalizedQuery = _normalizeArabic(query);
    final String effectiveQuery = normalizedQuery
        .replaceFirst(
      RegExp(r'^سوره\s+'),
      '',
    )
        .trim();

    final String compactQuery = _compact(effectiveQuery);
    final List<String> queryWords = effectiveQuery
        .split(' ')
        .where((word) => word.trim().length >= 2)
        .toList(growable: false);

    if (effectiveQuery.length < 2 || queryWords.isEmpty) {
      setState(() => _results = <_SearchIndexItem>[]);
      return;
    }

    final bool explicitSurahSearch = normalizedQuery.startsWith('سوره ');
    final List<_ScoredSearchItem> scored = <_ScoredSearchItem>[];

    for (final _SearchIndexItem item in _allItems) {
      int score = 0;

      if (item.normalizedText.contains(effectiveQuery)) score += 220;
      if (compactQuery.length >= 3 && item.compactText.contains(compactQuery)) {
        score += 130;
      }

      int matchedWords = 0;
      for (final String word in queryWords) {
        final Iterable<String> variants = _searchWordVariants(word);
        final bool wordMatched = variants.any((variant) {
          final String compactWord = _compact(variant);
          return item.normalizedText.contains(variant) ||
              item.compactText.contains(compactWord);
        });

        if (wordMatched) {
          matchedWords++;
          score += word.length >= 4 ? 45 : 24;
        }
      }

      if (queryWords.length > 1 && matchedWords == queryWords.length) {
        score += 90;
      }

      if (explicitSurahSearch &&
          item.normalizedSurahName.contains(effectiveQuery)) {
        score += 40;
      }

      if (score > 0) {
        scored.add(_ScoredSearchItem(item: item, score: score));
      }
    }

    scored.sort((a, b) {
      final int scoreCompare = b.score.compareTo(a.score);
      if (scoreCompare != 0) return scoreCompare;
      return a.item.globalAyahIndex.compareTo(b.item.globalAyahIndex);
    });

    setState(() {
      _results = scored.take(100).map((e) => e.item).toList(growable: false);
    });
  }

  _SearchIndexItem? _findItem(QpcAyahKey ayahKey) {
    for (final _SearchIndexItem item in _allItems) {
      if (item.ayahKey == ayahKey) return item;
    }
    return null;
  }

  QpcAyahKey? _parseDirectAyah(String rawInput) {
    final String normalized = _normalizeArabic(
      rawInput
          .replaceAll('٠', '0')
          .replaceAll('١', '1')
          .replaceAll('٢', '2')
          .replaceAll('٣', '3')
          .replaceAll('٤', '4')
          .replaceAll('٥', '5')
          .replaceAll('٦', '6')
          .replaceAll('٧', '7')
          .replaceAll('٨', '8')
          .replaceAll('٩', '9'),
    );

    final List<int> numbers = RegExp(r'\d+')
        .allMatches(normalized)
        .map((match) => int.tryParse(match.group(0) ?? ''))
        .whereType<int>()
        .toList(growable: false);

    if (numbers.length >= 2) {
      final int surah = numbers[0];
      final int ayah = numbers[1];
      return _validAyahKey(surah, ayah);
    }

    if (numbers.length == 1) {
      final int number = numbers.first;
      final int? surahFromName = _surahNumberFromQuery(normalized);

      if (surahFromName != null) {
        return _validAyahKey(surahFromName, number);
      }

      final QpcAyahKey? current = widget.currentAyahKey;
      if (current != null) {
        return _validAyahKey(current.surah, number);
      }
    }

    return null;
  }

  QpcAyahKey? _validAyahKey(int surah, int ayah) {
    if (surah < 1 || surah > 114) return null;
    if (ayah < 1 || ayah > noOfVerses[surah - 1]) return null;
    return QpcAyahKey(surah: surah, ayah: ayah);
  }

  int? _surahNumberFromQuery(String normalizedQuery) {
    for (int i = 0; i < arabicName.length; i++) {
      final String name = _normalizeArabic(arabicName[i]['name'].toString());
      if (normalizedQuery.contains(name)) return i + 1;
    }
    return null;
  }

  static String _normalizeArabic(String input) {
    return input
        .replaceAll(
        RegExp(r'[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06ED]'), '')
        .replaceAll('ـ', '')
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ٱ', 'ا')
        .replaceAll('ى', 'ي')
        .replaceAll('ؤ', 'و')
        .replaceAll('ئ', 'ي')
        .replaceAll('ة', 'ه')
        .replaceAll(RegExp(r'[۝۞﴿﴾۩ۣۚۖۗۘۙۛۜ۟۠ۡۢۤۥۦۭۧۨ۬]'), ' ')
        .replaceAll(RegExp(r'[^\u0600-\u06FF0-9 ]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static String _compact(String input) => input.replaceAll(' ', '');

  static Iterable<String> _searchWordVariants(String word) sync* {
    final String trimmed = word.trim();
    if (trimmed.isEmpty) return;

    yield trimmed;

    if (trimmed.startsWith('ال') && trimmed.length > 3) {
      yield trimmed.substring(2);
    }
  }

  @override
  Widget build(BuildContext context) {
    final QuranReaderTheme theme = widget.readerTheme;

    return Scaffold(
      backgroundColor: theme.pageBackground,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bool isLargeScreen = constraints.maxWidth >= 600;
            final Widget searchContent = Directionality(
              textDirection: TextDirection.rtl,
              child: Column(
                children: [
                  _SearchHeader(
                    controller: _controller,
                    focusNode: _focusNode,
                    readerTheme: theme,
                    onClose: () => Navigator.of(context).maybePop(),
                  ),
                  FutureBuilder<List<_SearchIndexItem>>(
                    future: _indexFuture,
                    builder: (context, snapshot) {
                      final bool loading =
                          snapshot.connectionState != ConnectionState.done;
                      final String query = _controller.text.trim();

                      if (loading) {
                        return Expanded(
                          child: Center(
                            child: SizedBox(
                              width: 22.w,
                              height: 22.w,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: theme.selectedWordTextColor,
                              ),
                            ),
                          ),
                        );
                      }

                      if (snapshot.hasError || !snapshot.hasData) {
                        return Expanded(
                          child: Center(
                            child: Text(
                              'تعذر تجهيز البحث',
                              style: TextStyle(
                                fontFamily: 'cairo',
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w700,
                                color: theme.secondaryTextColor,
                              ),
                            ),
                          ),
                        );
                      }

                      return Expanded(
                        child: query.isEmpty
                            ? const SizedBox.shrink()
                            : ListView.builder(
                          keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                          padding: MediaQuery.sizeOf(context).width >= 600
                              ? const EdgeInsets.fromLTRB(18, 4, 18, 18)
                              : EdgeInsets.fromLTRB(12.w, 4.h, 12.w, 18.h),
                          itemCount: _results.length,
                          itemBuilder: (context, index) {
                            final _SearchIndexItem item = _results[index];
                            return _SearchResultTile(
                              item: item,
                              readerTheme: theme,
                              onTap: () =>
                                  Navigator.of(context).pop(item.ayahKey),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ],
              ),
            );

            if (!isLargeScreen) {
              return searchContent;
            }

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: searchContent,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SearchHeader extends StatelessWidget {
  const _SearchHeader({
    required this.controller,
    required this.focusNode,
    required this.readerTheme,
    required this.onClose,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final QuranReaderTheme readerTheme;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final bool isLargeScreen = MediaQuery.sizeOf(context).width >= 600;

    return Container(
      margin: isLargeScreen
          ? const EdgeInsets.fromLTRB(18, 12, 18, 8)
          : EdgeInsets.fromLTRB(14.w, 8.h, 14.w, 4.h),
      padding: isLargeScreen
          ? const EdgeInsets.symmetric(horizontal: 6, vertical: 2)
          : EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: readerTheme.controlsBackgroundColor,
        borderRadius: BorderRadius.circular(isLargeScreen ? 14 : 15.r),
        border: Border.all(color: readerTheme.dividerColor),
      ),
      child: Row(
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: onClose,
            icon: Icon(
              Icons.close_rounded,
              color: readerTheme.controlsTextColor,
              size: isLargeScreen ? 18 : 18.sp,
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              autofocus: true,
              textDirection: TextDirection.rtl,
              textInputAction: TextInputAction.search,
              style: TextStyle(
                fontFamily: 'cairo',
                fontSize: isLargeScreen ? 11.5 : 12.5.sp,
                fontWeight: FontWeight.w600,
                color: readerTheme.textColor,
              ),
              decoration: InputDecoration(
                hintText: 'ابحث باسم السورة أو نص الآية... مثل: الكرسي أو البقرة ٢٥٥',
                hintTextDirection: TextDirection.rtl,
                border: InputBorder.none,
                isDense: true,
                hintStyle: TextStyle(
                  fontFamily: 'cairo',
                  fontSize: isLargeScreen ? 9 : 9.8.sp,
                  fontWeight: FontWeight.w500,
                  color: readerTheme.secondaryTextColor,
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isLargeScreen ? 8 : 8.w),
            child: Icon(
              Icons.search_rounded,
              color: readerTheme.selectedWordTextColor,
              size: isLargeScreen ? 18 : 18.sp,
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  const _SearchResultTile({
    required this.item,
    required this.readerTheme,
    required this.onTap,
  });

  final _SearchIndexItem item;
  final QuranReaderTheme readerTheme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool isLargeScreen = MediaQuery.sizeOf(context).width >= 600;

    return InkWell(
      borderRadius: BorderRadius.circular(isLargeScreen ? 12 : 13.r),
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: isLargeScreen ? 6 : 6.h),
        padding: isLargeScreen
            ? const EdgeInsets.symmetric(horizontal: 10, vertical: 7)
            : EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: readerTheme.controlsBackgroundColor.withValues(
            alpha: readerTheme.isDarkLike ? 0.24 : 0.72,
          ),
          borderRadius: BorderRadius.circular(isLargeScreen ? 12 : 13.r),
          border: Border.all(color: readerTheme.dividerColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${item.surahName} • آية ${item.ayahKey.ayah}',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontFamily: 'cairo',
                fontSize: isLargeScreen ? 8.8 : 9.5.sp,
                fontWeight: FontWeight.w700,
                color: readerTheme.selectedWordTextColor,
              ),
            ),
            SizedBox(height: isLargeScreen ? 4 : 6.h),
            Text(
              item.text,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontFamily: 'quran',
                fontSize: isLargeScreen ? 12 : 13.sp,
                height: isLargeScreen ? 1.35 : 1.5,
                fontWeight: FontWeight.w400,
                color: readerTheme.textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchIndexItem {
  const _SearchIndexItem({
    required this.ayahKey,
    required this.globalAyahIndex,
    required this.surahName,
    required this.text,
    required this.normalizedText,
    required this.normalizedSurahName,
    required this.compactText,
  });

  final QpcAyahKey ayahKey;
  final int globalAyahIndex;
  final String surahName;
  final String text;
  final String normalizedText;
  final String normalizedSurahName;
  final String compactText;
}

class _ScoredSearchItem {
  const _ScoredSearchItem({required this.item, required this.score});

  final _SearchIndexItem item;
  final int score;
}

class _QuranSearchTextReader {
  const _QuranSearchTextReader._();

  static String readSmartHafsDisplayText({
    required dynamic source,
    required int suraIndex,
    required int ayahIndex,
  }) {
    final int globalIndex = QuranReaderHelpers.getGlobalAyahIndex(
      suraIndex: suraIndex,
      ayahIndex: ayahIndex,
    );

    final dynamic value = _readAyahValue(
      source: source,
      suraIndex: suraIndex,
      ayahIndex: ayahIndex,
      globalIndex: globalIndex,
      preferSmartHafs: true,
    );

    return _cleanDisplayText(value?.toString() ?? '');
  }

  static String readSearchableText({
    required dynamic source,
    required int suraIndex,
    required int ayahIndex,
  }) {
    final int globalIndex = QuranReaderHelpers.getGlobalAyahIndex(
      suraIndex: suraIndex,
      ayahIndex: ayahIndex,
    );

    final dynamic value = _readAyahValue(
      source: source,
      suraIndex: suraIndex,
      ayahIndex: ayahIndex,
      globalIndex: globalIndex,
      preferSmartHafs: false,
    );

    return _cleanSearchText(value?.toString() ?? '');
  }

  static dynamic _readAyahValue({
    required dynamic source,
    required int suraIndex,
    required int ayahIndex,
    required int globalIndex,
    required bool preferSmartHafs,
  }) {
    if (source == null) return null;

    if (source is List) {
      if (source.length > 114 &&
          globalIndex >= 0 &&
          globalIndex < source.length) {
        final dynamic flatValue = _extractText(
          source[globalIndex],
          preferSmartHafs: preferSmartHafs,
        );
        if (flatValue != null) return flatValue;
      }

      if (suraIndex >= 0 && suraIndex < source.length) {
        final dynamic surahValue = _readFromSurahSource(
          surahSource: source[suraIndex],
          ayahIndex: ayahIndex,
          preferSmartHafs: preferSmartHafs,
        );
        if (surahValue != null) return surahValue;
      }
    }

    if (source is Map) {
      final dynamic quran = source['quran'];
      if (quran != null) {
        return _readAyahValue(
          source: quran,
          suraIndex: suraIndex,
          ayahIndex: ayahIndex,
          globalIndex: globalIndex,
          preferSmartHafs: preferSmartHafs,
        );
      }

      final dynamic surahSource = source['${suraIndex + 1}'] ??
          source[suraIndex + 1] ??
          source[suraIndex];

      return _readFromSurahSource(
        surahSource: surahSource,
        ayahIndex: ayahIndex,
        preferSmartHafs: preferSmartHafs,
      );
    }

    return null;
  }

  static dynamic _readFromSurahSource({
    required dynamic surahSource,
    required int ayahIndex,
    required bool preferSmartHafs,
  }) {
    if (surahSource == null) return null;

    if (surahSource is List) {
      if (ayahIndex >= 0 && ayahIndex < surahSource.length) {
        return _extractText(
          surahSource[ayahIndex],
          preferSmartHafs: preferSmartHafs,
        );
      }
      return null;
    }

    if (surahSource is Map) {
      final dynamic ayahs = surahSource['ayahs'] ??
          surahSource['ayas'] ??
          surahSource['verses'] ??
          surahSource['data'];

      if (ayahs != null) {
        return _readFromSurahSource(
          surahSource: ayahs,
          ayahIndex: ayahIndex,
          preferSmartHafs: preferSmartHafs,
        );
      }

      final dynamic directValue = surahSource['${ayahIndex + 1}'] ??
          surahSource[ayahIndex + 1] ??
          surahSource[ayahIndex];

      return _extractText(directValue, preferSmartHafs: preferSmartHafs);
    }

    return _extractText(surahSource, preferSmartHafs: preferSmartHafs);
  }

  static dynamic _extractText(
      dynamic value, {
        required bool preferSmartHafs,
      }) {
    if (value == null) return null;
    if (value is String) return value;

    if (value is Map) {
      if (preferSmartHafs) {
        return value['aya_text'] ??
            value['uthmani'] ??
            value['text_uthmani'] ??
            value['text'] ??
            value['ayah_text'] ??
            value['arabic_text'] ??
            value['verse'] ??
            value['ayah'] ??
            value['aya'] ??
            value['aya_text_emlaey'] ??
            value['text_emlaey'] ??
            value['imlaei'] ??
            value['imlaey'] ??
            value['simple'] ??
            value['clean'];
      }

      return value['aya_text_emlaey'] ??
          value['text_emlaey'] ??
          value['imlaei'] ??
          value['imlaey'] ??
          value['simple'] ??
          value['clean'] ??
          value['aya_text'] ??
          value['uthmani'] ??
          value['text_uthmani'] ??
          value['text'] ??
          value['ayah_text'] ??
          value['arabic_text'] ??
          value['verse'] ??
          value['ayah'] ??
          value['aya'];
    }

    return value;
  }

  static String _cleanDisplayText(String text) {
    return text
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'[۝۞﴿﴾]+'), '')
        .trim();
  }

  static String _cleanSearchText(String text) {
    return text
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'[۝۞﴿﴾]+'), '')
        .replaceAll('ـ', '')
        .trim();
  }
}

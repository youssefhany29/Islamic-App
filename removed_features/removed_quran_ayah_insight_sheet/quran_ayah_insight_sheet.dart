import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../irab/quran_irab_repository.dart';
import '../models/quran_selection.dart';
import '../tafsir/quran_tafsir_repository.dart';
import '../theme/quran_reader_theme.dart';

enum QuranInsightTab { tafsir, irab }

Future<void> showQuranAyahInsightSheet({
  required BuildContext context,
  required QuranSelection selection,
  required QuranReaderTheme readerTheme,
  required QuranInsightTab initialTab,
}) {
  return showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: readerTheme.pageBackground,
    barrierColor: Colors.black.withValues(alpha: 0.30),
    clipBehavior: Clip.antiAlias,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
    ),
    builder: (context) {
      return _QuranAyahInsightSheet(
        selection: selection,
        readerTheme: readerTheme,
        initialTab: initialTab,
      );
    },
  );
}

class _QuranAyahInsightSheet extends StatefulWidget {
  const _QuranAyahInsightSheet({
    required this.selection,
    required this.readerTheme,
    required this.initialTab,
  });

  final QuranSelection selection;
  final QuranReaderTheme readerTheme;
  final QuranInsightTab initialTab;

  @override
  State<_QuranAyahInsightSheet> createState() => _QuranAyahInsightSheetState();
}

class _QuranAyahInsightSheetState extends State<_QuranAyahInsightSheet> {
  final QuranTafsirRepository _tafsirRepository =
      QuranTafsirRepository.instance;
  final QuranIrabRepository _irabRepository = QuranIrabRepository.instance;
  final _QuranAyahTextRepository _ayahTextRepository =
      _QuranAyahTextRepository.instance;

  late QuranInsightTab _activeTab;
  late QuranTafsirSource _selectedSource;
  late Future<QuranTafsirEntry?> _tafsirFuture;
  late Future<QuranIrabEntry?> _irabFuture;
  late Future<String?> _ayahTextFuture;

  @override
  void initState() {
    super.initState();
    _activeTab = widget.initialTab;
    _selectedSource = QuranTafsirRepository.sources.first;
    _tafsirFuture = _loadTafsir();
    _irabFuture = _loadIrab();
    _ayahTextFuture = _ayahTextRepository.getAyahText(
      surah: widget.selection.surah,
      ayah: widget.selection.ayah,
    );
  }

  Future<QuranTafsirEntry?> _loadTafsir() {
    return _tafsirRepository.getTafsir(
      source: _selectedSource,
      surah: widget.selection.surah,
      ayah: widget.selection.ayah,
    );
  }

  Future<QuranIrabEntry?> _loadIrab() {
    return _irabRepository.getIrab(
      surah: widget.selection.surah,
      ayah: widget.selection.ayah,
    );
  }

  void _selectTab(QuranInsightTab tab) {
    if (_activeTab == tab) {
      return;
    }

    setState(() {
      _activeTab = tab;
    });
  }

  void _selectSource(QuranTafsirSource source) {
    if (_selectedSource.id == source.id) {
      return;
    }

    setState(() {
      _selectedSource = source;
      _tafsirFuture = _loadTafsir();
    });
  }

  @override
  Widget build(BuildContext context) {
    final QuranReaderTheme theme = widget.readerTheme;
    final Size size = MediaQuery.sizeOf(context);
    final bool isLargeScreen = size.width >= 600;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: FractionallySizedBox(
        heightFactor: isLargeScreen ? 0.70 : 0.82,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isLargeScreen ? 720 : double.infinity,
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: theme.pageBackground,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(isLargeScreen ? 24 : 24.r),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    isLargeScreen ? 20 : 18.w,
                    isLargeScreen ? 8 : 8.h,
                    isLargeScreen ? 20 : 18.w,
                    isLargeScreen ? 16 : 18.h,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(child: _SheetHandle(theme: theme)),
                      SizedBox(height: isLargeScreen ? 12 : 13.h),
                      _InsightHeader(
                        selection: widget.selection,
                        theme: theme,
                        isLargeScreen: isLargeScreen,
                        ayahTextFuture: _ayahTextFuture,
                      ),
                      SizedBox(height: isLargeScreen ? 14 : 14.h),
                      _InsightTabs(
                        activeTab: _activeTab,
                        theme: theme,
                        isLargeScreen: isLargeScreen,
                        onSelected: _selectTab,
                      ),
                      if (_activeTab == QuranInsightTab.tafsir) ...[
                        SizedBox(height: isLargeScreen ? 12 : 12.h),
                        _TafsirSourceSelector(
                          selectedSource: _selectedSource,
                          theme: theme,
                          isLargeScreen: isLargeScreen,
                          onSelected: _selectSource,
                        ),
                      ],
                      SizedBox(height: isLargeScreen ? 12 : 12.h),
                      Expanded(
                        child: _activeTab == QuranInsightTab.tafsir
                            ? _InsightFutureContent<QuranTafsirEntry>(
                                future: _tafsirFuture,
                                theme: theme,
                                isLargeScreen: isLargeScreen,
                                emptyMessage:
                                    'لا يوجد تفسير متاح لهذه الآية في هذا المصدر حاليا',
                                textOf: (entry) => entry.text,
                              )
                            : _InsightFutureContent<QuranIrabEntry>(
                                future: _irabFuture,
                                theme: theme,
                                isLargeScreen: isLargeScreen,
                                emptyMessage:
                                    'لا يوجد إعراب متاح لهذه الآية حاليا',
                                textOf: (entry) => entry.text,
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle({required this.theme});

  final QuranReaderTheme theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 4,
      decoration: BoxDecoration(
        color: theme.secondaryTextColor.withValues(alpha: 0.34),
        borderRadius: BorderRadius.circular(99),
      ),
    );
  }
}

class _InsightHeader extends StatelessWidget {
  const _InsightHeader({
    required this.selection,
    required this.theme,
    required this.isLargeScreen,
    required this.ayahTextFuture,
  });

  final QuranSelection selection;
  final QuranReaderTheme theme;
  final bool isLargeScreen;
  final Future<String?> ayahTextFuture;

  @override
  Widget build(BuildContext context) {
    final String reference =
        'سورة ${selection.surahName} - آية ${_arabicNumber(selection.ayah)}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                reference,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontFamily: 'cairo',
                  fontSize: isLargeScreen ? 13 : 13.4.sp,
                  fontWeight: FontWeight.w900,
                  color: theme.textColor,
                  height: 1.2,
                ),
              ),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: 'إغلاق',
              icon: Icon(
                Icons.close_rounded,
                color: theme.secondaryTextColor,
                size: isLargeScreen ? 20 : 21.sp,
              ),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ],
        ),
        SizedBox(height: isLargeScreen ? 8 : 8.h),
        FutureBuilder<String?>(
          future: ayahTextFuture,
          builder: (context, snapshot) {
            final String? ayahText = snapshot.data?.trim();
            if (ayahText == null || ayahText.isEmpty) {
              return const SizedBox.shrink();
            }

            return DecoratedBox(
              decoration: BoxDecoration(
                color: theme.controlsBackgroundColor.withValues(
                  alpha: theme.isDarkLike ? 0.22 : 0.08,
                ),
                borderRadius: BorderRadius.circular(isLargeScreen ? 14 : 16.r),
                border: Border.all(
                  color: theme.dividerColor.withValues(alpha: 0.34),
                  width: 0.8,
                ),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isLargeScreen ? 14 : 14.w,
                  vertical: isLargeScreen ? 10 : 10.h,
                ),
                child: Text(
                  ayahText,
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    fontFamily: 'cairo',
                    fontSize: isLargeScreen ? 14.5 : 14.2.sp,
                    fontWeight: FontWeight.w700,
                    height: 1.75,
                    color: theme.textColor,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _InsightTabs extends StatelessWidget {
  const _InsightTabs({
    required this.activeTab,
    required this.theme,
    required this.isLargeScreen,
    required this.onSelected,
  });

  final QuranInsightTab activeTab;
  final QuranReaderTheme theme;
  final bool isLargeScreen;
  final ValueChanged<QuranInsightTab> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: isLargeScreen ? 40 : 42.h,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: theme.controlsBackgroundColor.withValues(
          alpha: theme.isDarkLike ? 0.26 : 0.10,
        ),
        borderRadius: BorderRadius.circular(isLargeScreen ? 14 : 16.r),
      ),
      child: Row(
        children: [
          _InsightTabButton(
            label: 'التفسير',
            icon: Icons.menu_book_rounded,
            selected: activeTab == QuranInsightTab.tafsir,
            theme: theme,
            isLargeScreen: isLargeScreen,
            onTap: () => onSelected(QuranInsightTab.tafsir),
          ),
          _InsightTabButton(
            label: 'الإعراب',
            icon: Icons.auto_stories_rounded,
            selected: activeTab == QuranInsightTab.irab,
            theme: theme,
            isLargeScreen: isLargeScreen,
            onTap: () => onSelected(QuranInsightTab.irab),
          ),
        ],
      ),
    );
  }
}

class _InsightTabButton extends StatelessWidget {
  const _InsightTabButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.theme,
    required this.isLargeScreen,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final QuranReaderTheme theme;
  final bool isLargeScreen;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(isLargeScreen ? 12 : 14.r),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? theme.controlsBackgroundColor.withValues(alpha: 0.92)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(isLargeScreen ? 12 : 14.r),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: isLargeScreen ? 17 : 17.sp,
                color: selected ? theme.controlsTextColor : theme.textColor,
              ),
              SizedBox(width: isLargeScreen ? 6 : 6.w),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'cairo',
                  fontSize: isLargeScreen ? 11 : 11.2.sp,
                  fontWeight: FontWeight.w900,
                  color: selected ? theme.controlsTextColor : theme.textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TafsirSourceSelector extends StatelessWidget {
  const _TafsirSourceSelector({
    required this.selectedSource,
    required this.theme,
    required this.isLargeScreen,
    required this.onSelected,
  });

  final QuranTafsirSource selectedSource;
  final QuranReaderTheme theme;
  final bool isLargeScreen;
  final ValueChanged<QuranTafsirSource> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: isLargeScreen ? 34 : 38.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: QuranTafsirRepository.sources.length,
        separatorBuilder: (_, _) => SizedBox(width: isLargeScreen ? 8 : 8.w),
        itemBuilder: (context, index) {
          final QuranTafsirSource source = QuranTafsirRepository.sources[index];
          final bool selected = source.id == selectedSource.id;

          return InkWell(
            borderRadius: BorderRadius.circular(isLargeScreen ? 12 : 14.r),
            onTap: () => onSelected(source),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              alignment: Alignment.center,
              padding: EdgeInsets.symmetric(
                horizontal: isLargeScreen ? 12 : 12.w,
              ),
              decoration: BoxDecoration(
                color: selected
                    ? theme.selectedWordTextColor.withValues(alpha: 0.16)
                    : theme.controlsBackgroundColor.withValues(
                        alpha: theme.isDarkLike ? 0.20 : 0.06,
                      ),
                borderRadius: BorderRadius.circular(isLargeScreen ? 12 : 14.r),
                border: Border.all(
                  color: selected
                      ? theme.selectedWordTextColor.withValues(alpha: 0.45)
                      : theme.dividerColor.withValues(alpha: 0.24),
                ),
              ),
              child: Text(
                source.label,
                style: TextStyle(
                  fontFamily: 'cairo',
                  fontSize: isLargeScreen ? 9.3 : 10.sp,
                  fontWeight: FontWeight.w800,
                  color: selected ? theme.textColor : theme.secondaryTextColor,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _InsightFutureContent<T> extends StatelessWidget {
  const _InsightFutureContent({
    required this.future,
    required this.theme,
    required this.isLargeScreen,
    required this.emptyMessage,
    required this.textOf,
  });

  final Future<T?> future;
  final QuranReaderTheme theme;
  final bool isLargeScreen;
  final String emptyMessage;
  final String Function(T entry) textOf;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.controlsBackgroundColor.withValues(
          alpha: theme.isDarkLike ? 0.18 : 0.045,
        ),
        borderRadius: BorderRadius.circular(isLargeScreen ? 16 : 18.r),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.28),
          width: 0.8,
        ),
      ),
      child: FutureBuilder<T?>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _InsightStateMessage(
              theme: theme,
              isLargeScreen: isLargeScreen,
              icon: Icons.hourglass_top_rounded,
              message: 'جاري تحميل المحتوى...',
              loading: true,
            );
          }

          if (snapshot.hasError || snapshot.data == null) {
            return _InsightStateMessage(
              theme: theme,
              isLargeScreen: isLargeScreen,
              icon: Icons.info_outline_rounded,
              message: emptyMessage,
            );
          }

          final T entry = snapshot.data as T;
          final String text = textOf(entry).trim();
          if (text.isEmpty) {
            return _InsightStateMessage(
              theme: theme,
              isLargeScreen: isLargeScreen,
              icon: Icons.info_outline_rounded,
              message: emptyMessage,
            );
          }

          return Scrollbar(
            thumbVisibility: false,
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                isLargeScreen ? 18 : 16.w,
                isLargeScreen ? 16 : 16.h,
                isLargeScreen ? 18 : 16.w,
                isLargeScreen ? 20 : 20.h,
              ),
              child: SelectableText(
                text,
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  fontFamily: 'cairo',
                  fontSize: isLargeScreen ? 12.5 : 13.sp,
                  height: isLargeScreen ? 1.72 : 1.82,
                  fontWeight: FontWeight.w600,
                  color: theme.textColor,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _InsightStateMessage extends StatelessWidget {
  const _InsightStateMessage({
    required this.theme,
    required this.isLargeScreen,
    required this.icon,
    required this.message,
    this.loading = false,
  });

  final QuranReaderTheme theme;
  final bool isLargeScreen;
  final IconData icon;
  final String message;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(isLargeScreen ? 22 : 22.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (loading)
              SizedBox(
                width: isLargeScreen ? 22 : 24.w,
                height: isLargeScreen ? 22 : 24.w,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: theme.selectedWordTextColor,
                ),
              )
            else
              Icon(
                icon,
                color: theme.secondaryTextColor.withValues(alpha: 0.72),
                size: isLargeScreen ? 24 : 26.sp,
              ),
            SizedBox(height: isLargeScreen ? 12 : 12.h),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'cairo',
                fontSize: isLargeScreen ? 11 : 12.sp,
                height: 1.6,
                fontWeight: FontWeight.w700,
                color: theme.secondaryTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuranAyahTextRepository {
  _QuranAyahTextRepository._();

  static final _QuranAyahTextRepository instance = _QuranAyahTextRepository._();

  Future<Map<String, String>>? _cacheFuture;

  Future<String?> getAyahText({required int surah, required int ayah}) async {
    final Map<String, String> cache = await (_cacheFuture ??= _load());
    return cache['$surah:$ayah'];
  }

  Future<Map<String, String>> _load() async {
    final String rawJson = await rootBundle.loadString(
      'assets/hafs_smart_v8.json',
    );
    final Map<String, dynamic> decoded =
        jsonDecode(rawJson) as Map<String, dynamic>;
    final List<dynamic> rows = (decoded['quran'] as List?) ?? const <dynamic>[];
    final Map<String, String> result = <String, String>{};

    for (final dynamic row in rows) {
      if (row is! Map) {
        continue;
      }

      final int? surah = _jsonInt(row['sura_no']);
      final int? ayah = _jsonInt(row['aya_no']);
      final String text = row['aya_text_emlaey']?.toString().trim() ?? '';

      if (surah == null || ayah == null || text.isEmpty) {
        continue;
      }

      result['$surah:$ayah'] = text;
    }

    return result;
  }

  int? _jsonInt(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is int) {
      return value;
    }
    return int.tryParse(value.toString());
  }
}

String _arabicNumber(int value) {
  const List<String> digits = <String>[
    '٠',
    '١',
    '٢',
    '٣',
    '٤',
    '٥',
    '٦',
    '٧',
    '٨',
    '٩',
  ];

  return value.toString().split('').map((char) {
    final int? digit = int.tryParse(char);
    return digit == null ? char : digits[digit];
  }).join();
}

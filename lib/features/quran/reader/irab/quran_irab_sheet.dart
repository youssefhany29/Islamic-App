import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../models/quran_ayah_sheet_text.dart';
import '../models/quran_selection.dart';
import '../theme/quran_reader_theme.dart';
import 'quran_irab_repository.dart';

Future<void> showQuranIrabSheet({
  required BuildContext context,
  required QuranSelection selection,
  required QuranReaderTheme readerTheme,
}) {
  return showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: readerTheme.pageBackground,
    barrierColor: Colors.black.withValues(alpha: 0.30),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22.r)),
    ),
    builder: (context) {
      return _QuranIrabSheet(selection: selection, readerTheme: readerTheme);
    },
  );
}

class _QuranIrabSheet extends StatefulWidget {
  const _QuranIrabSheet({required this.selection, required this.readerTheme});

  final QuranSelection selection;
  final QuranReaderTheme readerTheme;

  @override
  State<_QuranIrabSheet> createState() => _QuranIrabSheetState();
}

class _QuranIrabSheetState extends State<_QuranIrabSheet> {
  final QuranIrabRepository _repository = QuranIrabRepository.instance;
  final QuranAyahSheetTextRepository _ayahTextRepository =
      QuranAyahSheetTextRepository.instance;

  late QuranIrabSource _selectedSource;
  late Future<QuranIrabEntry?> _entryFuture;
  late Future<QuranAyahSheetText?> _ayahTextFuture;

  @override
  void initState() {
    super.initState();
    _selectedSource = QuranIrabRepository.sources.first;
    _entryFuture = _loadEntry();
    _ayahTextFuture = _ayahTextRepository.getAyahText(
      surah: widget.selection.surah,
      ayah: widget.selection.ayah,
    );
  }

  Future<QuranIrabEntry?> _loadEntry() {
    return _repository.getIrab(
      source: _selectedSource,
      surah: widget.selection.surah,
      ayah: widget.selection.ayah,
    );
  }

  void _selectSource(QuranIrabSource source) {
    if (source.id == _selectedSource.id) {
      return;
    }

    setState(() {
      _selectedSource = source;
      _entryFuture = _loadEntry();
    });
  }

  @override
  Widget build(BuildContext context) {
    final QuranReaderTheme theme = widget.readerTheme;
    final bool isLargeScreen = MediaQuery.sizeOf(context).width >= 600;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: FractionallySizedBox(
        heightFactor: isLargeScreen ? 0.90 : 0.94,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isLargeScreen ? 720 : double.infinity,
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                isLargeScreen ? 18 : 16.w,
                isLargeScreen ? 2 : 2.h,
                isLargeScreen ? 18 : 16.w,
                isLargeScreen ? 16 : 18.h,
              ),
              child: Column(
                children: [
                  _SheetTitleBar(
                    title: 'إعراب ${widget.selection.readableArabicLabel}',
                    readerTheme: theme,
                    isLargeScreen: isLargeScreen,
                  ),
                  SizedBox(height: isLargeScreen ? 4 : 5.h),
                  _AyahTextPreview(
                    future: _ayahTextFuture,
                    readerTheme: theme,
                    isLargeScreen: isLargeScreen,
                  ),
                  SizedBox(height: isLargeScreen ? 6 : 7.h),
                  _IrabSourceSelector(
                    selectedSource: _selectedSource,
                    readerTheme: theme,
                    isLargeScreen: isLargeScreen,
                    onSelected: _selectSource,
                  ),
                  SizedBox(height: isLargeScreen ? 10 : 12.h),
                  Expanded(
                    child: FutureBuilder<QuranIrabEntry?>(
                      future: _entryFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(
                            child: CircularProgressIndicator(
                              color: theme.selectedWordTextColor,
                            ),
                          );
                        }

                        final QuranIrabEntry? entry = snapshot.data;
                        if (snapshot.hasError || entry == null) {
                          return _EmptySheetState(
                            message:
                                'لا يوجد إعراب متاح لهذه الآية في هذا المصدر حاليا',
                            readerTheme: theme,
                            isLargeScreen: isLargeScreen,
                          );
                        }

                        return SingleChildScrollView(
                          physics: const ClampingScrollPhysics(),
                          child: SelectableText(
                            entry.text,
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontFamily: 'cairo',
                              fontSize: isLargeScreen ? 12 : 14.sp,
                              height: isLargeScreen ? 1.65 : 1.8,
                              fontWeight: FontWeight.w600,
                              color: theme.textColor,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SheetTitleBar extends StatelessWidget {
  const _SheetTitleBar({
    required this.title,
    required this.readerTheme,
    required this.isLargeScreen,
  });

  final String title;
  final QuranReaderTheme readerTheme;
  final bool isLargeScreen;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'cairo',
              fontSize: isLargeScreen ? 13 : 15.sp,
              fontWeight: FontWeight.w900,
              color: readerTheme.textColor,
            ),
          ),
        ),
        IconButton(
          tooltip: 'إغلاق',
          icon: const Icon(Icons.close_rounded),
          color: readerTheme.secondaryTextColor,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ],
    );
  }
}

class _AyahTextPreview extends StatelessWidget {
  const _AyahTextPreview({
    required this.future,
    required this.readerTheme,
    required this.isLargeScreen,
  });

  final Future<QuranAyahSheetText?> future;
  final QuranReaderTheme readerTheme;
  final bool isLargeScreen;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<QuranAyahSheetText?>(
      future: future,
      builder: (context, snapshot) {
        final QuranAyahSheetText? text = snapshot.data;
        final String displayText = text?.hafsText.trim().isNotEmpty == true
            ? text!.hafsText
            : text?.plainText ?? '';

        if (displayText.trim().isEmpty) {
          return const SizedBox.shrink();
        }

        return Text(
          displayText,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
          style: TextStyle(
            fontFamily: text?.hasHafsText == true ? 'quran' : 'cairo',
            fontSize: isLargeScreen ? 17 : 18.sp,
            height: 1.45,
            fontWeight: FontWeight.w500,
            color: readerTheme.textColor,
          ),
        );
      },
    );
  }
}

class _IrabSourceSelector extends StatelessWidget {
  const _IrabSourceSelector({
    required this.selectedSource,
    required this.readerTheme,
    required this.isLargeScreen,
    required this.onSelected,
  });

  final QuranIrabSource selectedSource;
  final QuranReaderTheme readerTheme;
  final bool isLargeScreen;
  final ValueChanged<QuranIrabSource> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: isLargeScreen ? 34 : 40.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: QuranIrabRepository.sources.length,
        separatorBuilder: (context, index) =>
            SizedBox(width: isLargeScreen ? 7 : 8.w),
        itemBuilder: (context, index) {
          final QuranIrabSource source = QuranIrabRepository.sources[index];
          final bool selected = source.id == selectedSource.id;

          return ChoiceChip(
            label: Text(
              source.label,
              style: TextStyle(
                fontFamily: 'cairo',
                fontSize: isLargeScreen ? 9.2 : 10.5.sp,
                fontWeight: FontWeight.w800,
                color: selected
                    ? readerTheme.pageBackground
                    : readerTheme.textColor,
              ),
            ),
            selected: selected,
            selectedColor: readerTheme.selectedWordTextColor,
            backgroundColor: readerTheme.controlsBackgroundColor.withValues(
              alpha: readerTheme.isDarkLike ? 0.30 : 0.14,
            ),
            side: BorderSide(
              color: selected
                  ? readerTheme.selectedWordTextColor
                  : readerTheme.dividerColor,
            ),
            onSelected: (_) => onSelected(source),
          );
        },
      ),
    );
  }
}

class _EmptySheetState extends StatelessWidget {
  const _EmptySheetState({
    required this.message,
    required this.readerTheme,
    required this.isLargeScreen,
  });

  final String message;
  final QuranReaderTheme readerTheme;
  final bool isLargeScreen;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'cairo',
          fontSize: isLargeScreen ? 11 : 12.5.sp,
          fontWeight: FontWeight.w700,
          color: readerTheme.secondaryTextColor,
        ),
      ),
    );
  }
}

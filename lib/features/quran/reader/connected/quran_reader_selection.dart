part of '../qpc_connected_mushaf_page.dart';

extension _QuranReaderSelectionMethods on _QpcConnectedMushafPageState {
  Future<void> _onWordTap(QpcLineTapResult result) async {
    final QuranSelection selection = QuranSelection(ayahKey: result.ayahKey);

    setState(() {
      _previewAyahKey = null;
      _anchorAyahKey = result.ayahKey;
      _selection = selection;
      _controlsVisible = true;
      _audioPanelVisible = true;
    });

    unawaited(
      _saveReadingPosition(
        ayahKey: result.ayahKey,
        mushafPageNumber: _selectedPageNumber,
      ),
    );

    _restartControlsAutoHideTimer();
    await _showSelectionActions(selection);
  }

  Future<void> _showSelectionActions(QuranSelection selection) async {
    final QuranReaderTheme theme = _themeController.theme;
    final Future<QuranAyahSheetText?> ayahTextFuture =
        QuranAyahSheetTextRepository.instance.getAyahText(
          surah: selection.surah,
          ayah: selection.ayah,
        );

    final _QuranSelectionAction?
    action = await showModalBottomSheet<_QuranSelectionAction>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: theme.controlsBackgroundColor,
      barrierColor: Colors.black.withOpacity(0.18),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22.r)),
      ),
      builder: (context) {
        final bool isLargeSheet = MediaQuery.sizeOf(context).width >= 600;
        final double maxSheetHeight =
            MediaQuery.sizeOf(context).height * (isLargeSheet ? 0.52 : 0.78);
        final EdgeInsetsGeometry sheetPadding = isLargeSheet
            ? const EdgeInsets.fromLTRB(16, 4, 16, 14)
            : EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 18.h);

        return Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            decoration: BoxDecoration(
              color: theme.controlsBackgroundColor,
              borderRadius: BorderRadius.vertical(top: Radius.circular(22.r)),
            ),
            child: SafeArea(
              top: false,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxSheetHeight),
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: sheetPadding,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        selection.readableArabicLabel,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'cairo',
                          fontSize: isLargeSheet ? 12 : 14.sp,
                          fontWeight: FontWeight.w900,
                          color: theme.textColor,
                        ),
                      ),
                      SizedBox(height: isLargeSheet ? 8 : 12.h),
                      _SelectionAyahTextPreview(
                        future: ayahTextFuture,
                        readerTheme: theme,
                        isLargeSheet: isLargeSheet,
                      ),
                      SizedBox(height: isLargeSheet ? 8 : 12.h),
                      _SelectionActionTile(
                        icon: Icons.play_circle_fill_rounded,
                        title: 'تشغيل الآية',
                        subtitle:
                            'استماع للآية بالقارئ المختار مع تمييز موضع القراءة',
                        readerTheme: theme,
                        onTap: () {
                          Navigator.of(context).pop(_QuranSelectionAction.play);
                        },
                      ),
                      _SelectionActionTile(
                        icon: Icons.menu_book_rounded,
                        title: 'التفسير',
                        subtitle: 'الوسيط، ابن كثير، الطبري، القرطبي...',
                        readerTheme: theme,
                        onTap: () {
                          Navigator.of(
                            context,
                          ).pop(_QuranSelectionAction.tafsir);
                        },
                      ),
                      _SelectionActionTile(
                        icon: Icons.auto_stories_rounded,
                        title: 'الإعراب',
                        subtitle: 'الدرويش، الإعراب الميسر، ومصادر أخرى',
                        readerTheme: theme,
                        onTap: () {
                          Navigator.of(context).pop(_QuranSelectionAction.irab);
                        },
                      ),
                      _SelectionActionTile(
                        icon: Icons.close_rounded,
                        title: 'إلغاء التحديد',
                        subtitle: 'إزالة تحديد الآية',
                        readerTheme: theme,
                        onTap: () {
                          Navigator.of(context).pop();
                          setState(() {
                            _selection = null;
                            _activeAudioWord = null;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    if (!mounted || action == null) {
      return;
    }

    switch (action) {
      case _QuranSelectionAction.play:
        await _playAyah(selection.ayahKey);
        break;
      case _QuranSelectionAction.tafsir:
        await showQuranTafsirSheet(
          context: context,
          selection: selection,
          readerTheme: theme,
        );
        break;
      case _QuranSelectionAction.irab:
        await showQuranIrabSheet(
          context: context,
          selection: selection,
          readerTheme: theme,
        );
        break;
      case _QuranSelectionAction.clear:
        setState(() {
          _selection = null;
          _activeAudioWord = null;
          _audioPanelVisible = false;
        });
        break;
    }
  }
}

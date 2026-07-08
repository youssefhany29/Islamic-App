part of '../qpc_connected_mushaf_page.dart';

extension _QuranReaderHelperMethods on _QpcConnectedMushafPageState {
  void _showInfoSnackBar(String message, {bool isError = false}) {
    if (!mounted) {
      return;
    }

    final QuranReaderTheme theme = _themeController.theme;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 1400),
        backgroundColor: isError
            ? Colors.red.shade700
            : theme.controlsBackgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14.r),
        ),
        content: Text(
          message,
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'cairo',
            color: theme.controlsTextColor,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

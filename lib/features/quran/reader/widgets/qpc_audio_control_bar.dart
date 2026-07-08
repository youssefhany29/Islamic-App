import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../models/qpc_models.dart';
import '../quran_reader_helpers.dart';
import '../theme/quran_reader_theme.dart';

const String _nextAyahTooltip =
    '\u0627\u0644\u0622\u064a\u0629 \u0627\u0644\u062a\u0627\u0644\u064a\u0629';
const String _previousAyahTooltip =
    '\u0627\u0644\u0622\u064a\u0629 \u0627\u0644\u0633\u0627\u0628\u0642\u0629';

class QpcAudioControlBar extends StatelessWidget {
  const QpcAudioControlBar({
    super.key,
    required this.readerTheme,
    required this.reciterName,
    required this.volume,
    required this.isLoading,
    required this.isPlaying,
    required this.ayahKey,
    required this.activeWord,
    required this.onVolumeChanged,
    required this.onPlay,
    required this.onPrevious,
    required this.onNext,
    required this.onReplay,
    required this.onStop,
    this.vertical = false,
  });

  final QuranReaderTheme readerTheme;
  final String reciterName;
  final double volume;
  final bool isLoading;
  final bool isPlaying;
  final QpcAyahKey? ayahKey;
  final QpcWordKey? activeWord;
  final ValueChanged<double> onVolumeChanged;
  final VoidCallback onPlay;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onReplay;
  final VoidCallback onStop;
  final bool vertical;

  @override
  Widget build(BuildContext context) {
    final QpcAyahKey? currentAyah = ayahKey;
    final String title = currentAyah == null
        ? 'الصوت'
        : activeWord == null || activeWord != null
        ? _ayahLabel(currentAyah)
        : '${_ayahLabel(currentAyah)} • كلمة ${activeWord!.word}';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        width: vertical ? double.infinity : double.infinity,
        padding: EdgeInsets.fromLTRB(
          vertical ? 8 : 10.w,
          vertical ? 10 : 7.h,
          vertical ? 8 : 10.w,
          vertical ? 10 : 7.h,
        ),
        decoration: BoxDecoration(
          color: readerTheme.controlsBackgroundColor,
          borderRadius: BorderRadius.circular(vertical ? 20 : 18.r),
          border: Border.all(color: readerTheme.dividerColor.withOpacity(0.72)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 12,
              offset: Offset(0, vertical ? 3 : 4.h),
            ),
          ],
        ),
        child: vertical
            ? SizedBox.expand(
                child: _VerticalAudioBody(
                  title: title,
                  reciterName: reciterName,
                  volume: volume,
                  isPlaying: isPlaying,
                  readerTheme: readerTheme,
                  onVolumeChanged: onVolumeChanged,
                  onPlay: onPlay,
                  onPrevious: onPrevious,
                  onNext: onNext,
                  onReplay: onReplay,
                  onStop: onStop,
                ),
              )
            : _HorizontalAudioBody(
                title: title,
                reciterName: reciterName,
                volume: volume,
                isPlaying: isPlaying,
                readerTheme: readerTheme,
                onVolumeChanged: onVolumeChanged,
                onPlay: onPlay,
                onPrevious: onPrevious,
                onNext: onNext,
                onReplay: onReplay,
                onStop: onStop,
              ),
      ),
    );
  }

  String _ayahLabel(QpcAyahKey ayahKey) {
    final int suraIndex = (ayahKey.surah - 1).clamp(0, 113).toInt();
    final String surahName = QuranReaderHelpers.getSuraName(suraIndex);
    return 'سورة $surahName | آية ${ayahKey.ayah}';
  }
}

class _HorizontalAudioBody extends StatelessWidget {
  const _HorizontalAudioBody({
    required this.title,
    required this.reciterName,
    required this.volume,
    required this.isPlaying,
    required this.readerTheme,
    required this.onVolumeChanged,
    required this.onPlay,
    required this.onPrevious,
    required this.onNext,
    required this.onReplay,
    required this.onStop,
  });

  final String title;
  final String reciterName;
  final double volume;
  final bool isPlaying;
  final QuranReaderTheme readerTheme;
  final ValueChanged<double> onVolumeChanged;
  final VoidCallback onPlay;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onReplay;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: _AudioTitleBlock(
                title: title,
                reciterName: reciterName,
                readerTheme: readerTheme,
                alignRight: false,
              ),
            ),
            SizedBox(width: 8.w),
            _AudioIconButton(
              icon: Icons.close_rounded,
              tooltip: 'إيقاف الصوت',
              readerTheme: readerTheme,
              onTap: onStop,
            ),
          ],
        ),
        SizedBox(height: 6.h),
        Row(
          children: [
            _AudioIconButton(
              icon: Icons.skip_previous_rounded,
              tooltip: 'الآية التالية',
              readerTheme: readerTheme,
              onTap: onPrevious,
              rotateHalfTurn: true,
            ),
            _AudioIconButton(
              icon: isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              tooltip: isPlaying ? 'إيقاف مؤقت' : 'تشغيل الآية',
              readerTheme: readerTheme,
              onTap: onPlay,
              emphasize: true,
            ),
            _AudioIconButton(
              icon: Icons.skip_next_rounded,
              tooltip: 'الآية السابقة',
              readerTheme: readerTheme,
              onTap: onNext,
              rotateHalfTurn: true,
            ),
            _AudioIconButton(
              icon: Icons.replay_rounded,
              tooltip: 'إعادة الآية',
              readerTheme: readerTheme,
              onTap: onReplay,
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: _VolumeSlider(
                readerTheme: readerTheme,
                volume: volume,
                onChanged: onVolumeChanged,
                vertical: false,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _VerticalAudioBody extends StatelessWidget {
  const _VerticalAudioBody({
    required this.title,
    required this.reciterName,
    required this.volume,
    required this.isPlaying,
    required this.readerTheme,
    required this.onVolumeChanged,
    required this.onPlay,
    required this.onPrevious,
    required this.onNext,
    required this.onReplay,
    required this.onStop,
  });

  final String title;
  final String reciterName;
  final double volume;
  final bool isPlaying;
  final QuranReaderTheme readerTheme;
  final ValueChanged<double> onVolumeChanged;
  final VoidCallback onPlay;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onReplay;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            _AudioTitleBlock(
              title: title,
              reciterName: reciterName,
              readerTheme: readerTheme,
              alignRight: true,
            ),
            const SizedBox(height: 12),
            _AudioIconButton(
              icon: isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              tooltip: isPlaying ? 'إيقاف مؤقت' : 'تشغيل الآية',
              readerTheme: readerTheme,
              onTap: onPlay,
              emphasize: true,
              fixedSize: 48,
              iconSize: 28,
            ),
            const SizedBox(height: 10),
            _VerticalControlButton(
              icon: Icons.skip_next_rounded,
              label: 'التالي',
              readerTheme: readerTheme,
              onTap: onNext,
              rotateHalfTurn: true,
            ),
            const SizedBox(height: 7),
            _VerticalControlButton(
              icon: Icons.skip_previous_rounded,
              label: 'السابق',
              readerTheme: readerTheme,
              onTap: onPrevious,
              rotateHalfTurn: true,
            ),
            const SizedBox(height: 7),
            _VerticalControlButton(
              icon: Icons.replay_rounded,
              label: 'إعادة',
              readerTheme: readerTheme,
              onTap: onReplay,
            ),
            const SizedBox(height: 7),
            _VerticalControlButton(
              icon: Icons.close_rounded,
              label: 'إيقاف',
              readerTheme: readerTheme,
              onTap: onStop,
            ),
            const Spacer(),
            _VolumeSlider(
              readerTheme: readerTheme,
              volume: volume,
              onChanged: onVolumeChanged,
              vertical: false,
            ),
          ],
        );
      },
    );
  }
}

class _VerticalControlButton extends StatelessWidget {
  const _VerticalControlButton({
    required this.icon,
    required this.label,
    required this.readerTheme,
    required this.onTap,
    this.rotateHalfTurn = false,
  });

  final IconData icon;
  final String label;
  final QuranReaderTheme readerTheme;
  final VoidCallback onTap;
  final bool rotateHalfTurn;

  @override
  Widget build(BuildContext context) {
    final Widget iconWidget = Icon(
      icon,
      color: readerTheme.controlsTextColor,
      size: 18,
    );

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: readerTheme.controlsTextColor.withOpacity(0.075),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: readerTheme.dividerColor.withOpacity(0.42)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            rotateHalfTurn
                ? RotatedBox(quarterTurns: 2, child: iconWidget)
                : iconWidget,
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  fontFamily: 'cairo',
                  fontSize: 8.5,
                  fontWeight: FontWeight.w900,
                  color: readerTheme.controlsTextColor,
                  height: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AudioTitleBlock extends StatelessWidget {
  const _AudioTitleBlock({
    required this.title,
    required this.reciterName,
    required this.readerTheme,
    required this.alignRight,
  });

  final String title;
  final String reciterName;
  final QuranReaderTheme readerTheme;
  final bool alignRight;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignRight
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          maxLines: alignRight ? 2 : 1,
          overflow: TextOverflow.ellipsis,
          textAlign: alignRight ? TextAlign.right : TextAlign.left,
          textDirection: TextDirection.rtl,
          style: TextStyle(
            fontFamily: 'cairo',
            fontSize: alignRight ? 10.5 : 10.5.sp,
            fontWeight: FontWeight.w900,
            color: readerTheme.controlsTextColor,
            height: 1.12,
          ),
        ),
        SizedBox(height: alignRight ? 4 : 3.h),
        Text(
          reciterName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: alignRight ? TextAlign.right : TextAlign.left,
          textDirection: TextDirection.rtl,
          style: TextStyle(
            fontFamily: 'cairo',
            fontSize: alignRight ? 8.5 : 8.2.sp,
            fontWeight: FontWeight.w700,
            color: readerTheme.controlsTextColor.withOpacity(0.76),
            height: 1,
          ),
        ),
      ],
    );
  }
}

class _VolumeSlider extends StatelessWidget {
  const _VolumeSlider({
    required this.readerTheme,
    required this.volume,
    required this.onChanged,
    required this.vertical,
  });

  final QuranReaderTheme readerTheme;
  final double volume;
  final ValueChanged<double> onChanged;
  final bool vertical;

  @override
  Widget build(BuildContext context) {
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: vertical ? 2.0 : 2.2.h,
        thumbShape: RoundSliderThumbShape(
          enabledThumbRadius: vertical ? 4 : 4.5.r,
        ),
        overlayShape: SliderComponentShape.noOverlay,
      ),
      child: Slider(value: volume, min: 0, max: 1, onChanged: onChanged),
    );
  }
}

class _AudioIconButton extends StatelessWidget {
  const _AudioIconButton({
    required this.icon,
    required this.tooltip,
    required this.readerTheme,
    required this.onTap,
    this.emphasize = false,
    this.large = false,
    this.fixedSize,
    this.iconSize,
    this.rotateHalfTurn = false,
  });

  final IconData icon;
  final String tooltip;
  final QuranReaderTheme readerTheme;
  final VoidCallback? onTap;
  final bool emphasize;
  final bool large;
  final double? fixedSize;
  final double? iconSize;
  final bool rotateHalfTurn;

  @override
  Widget build(BuildContext context) {
    final Color color = onTap == null
        ? readerTheme.controlsTextColor.withOpacity(0.38)
        : readerTheme.controlsTextColor;
    final double size = fixedSize ?? (large ? 42 : (emphasize ? 34.w : 30.w));
    final Widget iconWidget = Icon(
      icon,
      color: color,
      size: iconSize ?? (large ? 25 : (emphasize ? 22.sp : 19.sp)),
    );
    final String effectiveTooltip = _navigationTooltip(icon) ?? tooltip;

    return Tooltip(
      message: effectiveTooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(22.r),
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: emphasize
              ? BoxDecoration(
                  color: readerTheme.controlsTextColor.withOpacity(0.14),
                  shape: BoxShape.circle,
                )
              : null,
          child: rotateHalfTurn
              ? RotatedBox(quarterTurns: 2, child: iconWidget)
              : iconWidget,
        ),
      ),
    );
  }
}

String? _navigationTooltip(IconData icon) {
  if (icon == Icons.skip_next_rounded) {
    return _nextAyahTooltip;
  }
  if (icon == Icons.skip_previous_rounded) {
    return _previousAyahTooltip;
  }
  return null;
}

import '../models/qpc_models.dart';
import '../../audio/quran_ayah_audio_service.dart';

class QuranWordSyncResult {
  const QuranWordSyncResult({
    required this.activeWordKey,
    required this.activeSegmentIndex,
  });

  final QpcWordKey? activeWordKey;
  final int activeSegmentIndex;

  bool get hasActiveWord => activeWordKey != null;
}

class QuranWordSyncController {
  const QuranWordSyncController();

  QuranWordSyncResult resolveActiveWord({
    required Duration position,
    required QpcAyahKey ayahKey,
    required List<QpcWord> visibleAyahWords,
    required List<QuranWordAudioSegment> segments,
  }) {
    if (visibleAyahWords.isEmpty || segments.isEmpty) {
      return const QuranWordSyncResult(
        activeWordKey: null,
        activeSegmentIndex: -1,
      );
    }

    final int positionMs = position.inMilliseconds;
    final int activeSegmentIndex = _findActiveSegmentIndex(
      positionMs: positionMs,
      segments: segments,
    );

    if (activeSegmentIndex < 0) {
      return const QuranWordSyncResult(
        activeWordKey: null,
        activeSegmentIndex: -1,
      );
    }

    final int safeWordIndex = activeSegmentIndex.clamp(
      0,
      visibleAyahWords.length - 1,
    );

    final QpcWord activeWord = visibleAyahWords[safeWordIndex];

    if (activeWord.surah != ayahKey.surah || activeWord.ayah != ayahKey.ayah) {
      return const QuranWordSyncResult(
        activeWordKey: null,
        activeSegmentIndex: -1,
      );
    }

    return QuranWordSyncResult(
      activeWordKey: activeWord.wordKey,
      activeSegmentIndex: activeSegmentIndex,
    );
  }

  int _findActiveSegmentIndex({
    required int positionMs,
    required List<QuranWordAudioSegment> segments,
  }) {
    for (int index = 0; index < segments.length; index++) {
      final QuranWordAudioSegment segment = segments[index];

      if (positionMs >= segment.startMs && positionMs <= segment.endMs) {
        return index;
      }
    }

    if (segments.isNotEmpty && positionMs > segments.last.endMs) {
      return segments.length - 1;
    }

    return -1;
  }
}
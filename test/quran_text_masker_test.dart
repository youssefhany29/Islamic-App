import 'package:flutter_test/flutter_test.dart';
import 'package:islamic_app/features/quran/reader/hiding/quran_hide_mode.dart';
import 'package:islamic_app/features/quran/reader/hiding/quran_text_masker.dart';

void main() {
  group('QuranTextMasker textual ayah display', () {
    test('keeps ayah number marker outside ayah words', () {
      final String ayahMarker = '\u200F${String.fromCharCode(0xE959 + 207)}';
      final List<String> words = QuranTextMasker.splitAyahWords(
        'مَرْضَاةِ اللَّهِ $ayahMarker',
        ayahNumber: 207,
      );

      expect(words, <String>['مَرْضَاةِ', 'اللَّهِ']);
      expect(words.join(' '), isNot(contains(ayahMarker)));
      expect(
        QuranTextMasker.isStandaloneAyahMarker(ayahMarker, ayahNumber: 207),
        isTrue,
      );
    });

    test('does not hide or split the separate ayah number marker', () {
      final String ayahMarker = '\u200F${String.fromCharCode(0xE959 + 2)}';

      expect(
        QuranTextMasker.maskWord(
          text: ayahMarker,
          hideMode: QuranHideMode.full,
          wordIndexInAyah: 0,
        ),
        ayahMarker,
      );
    });

    test('full hide masks the last ayah word too', () {
      expect(
        QuranTextMasker.shouldHideWord(
          hideMode: QuranHideMode.full,
          wordIndexInAyah: 99,
        ),
        isTrue,
      );

      final String masked = QuranTextMasker.maskWord(
        text: 'الرَّحِيمِ',
        hideMode: QuranHideMode.full,
        wordIndexInAyah: 99,
      );

      expect(masked, isNot(contains('الر')));
      expect(masked, isNot(contains('م')));
      expect(masked, contains(QuranTextMasker.hiddenGlyph));
    });
  });
}

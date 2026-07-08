import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:islamic_app/features/quran/audio/quran_ayah_audio_service.dart';
import 'package:islamic_app/features/quran/reader/irab/quran_irab_repository.dart';
import 'package:islamic_app/features/quran/reader/svg/svg_mushaf_geometry_repository.dart';
import 'package:islamic_app/features/quran/reader/svg/svg_mushaf_page_metadata.dart';
import 'package:islamic_app/features/quran/reader/svg/svg_mushaf_page_layout.dart';
import 'package:islamic_app/features/quran/reader/tafsir/quran_tafsir_repository.dart';
import 'package:islamic_app/features/quran/reader/widgets/qpc_mushaf_page_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('mushaf page view maps page indexes in RTL order', () {
    expect(QpcMushafPageView.pageNumberFromIndex(0), 604);
    expect(QpcMushafPageView.pageNumberFromIndex(603), 1);

    expect(QpcMushafPageView.pageNumberFromIndex(548), 56);
    expect(QpcMushafPageView.pageNumberFromIndex(547), 57);
    expect(QpcMushafPageView.pageNumberFromIndex(549), 55);
  });

  test('mushaf page view maps page numbers back to indexes', () {
    expect(QpcMushafPageView.indexFromPageNumber(604), 0);
    expect(QpcMushafPageView.indexFromPageNumber(1), 603);

    expect(QpcMushafPageView.indexFromPageNumber(56), 548);
    expect(QpcMushafPageView.indexFromPageNumber(57), 547);
    expect(QpcMushafPageView.indexFromPageNumber(55), 549);
  });

  test(
    'svg displayed page rect stays inside reader frame for sampled pages',
    () async {
      const Size viewportSize = Size(390, 720);
      const List<int> pages = <int>[1, 2, 3, 56, 255, 604];

      for (final int page in pages) {
        final geometry = await SvgMushafGeometryRepository.instance.loadPage(
          page,
        );
        final Rect rect = calculateDisplayedPageRect(
          viewportSize,
          Size(geometry.imageWidth, geometry.imageHeight),
        );

        expect(rect.left >= 0, isTrue, reason: 'page $page');
        expect(rect.right <= viewportSize.width, isTrue, reason: 'page $page');
        expect(rect.top >= 0, isTrue, reason: 'page $page');
        expect(
          rect.bottom <= viewportSize.height,
          isTrue,
          reason: 'page $page',
        );
        expect(rect.center.dx, moreOrLessEquals(viewportSize.width / 2));
        expect(rect.center.dy, moreOrLessEquals(viewportSize.height / 2));
        expect(
          rect.width / rect.height,
          moreOrLessEquals(geometry.imageWidth / geometry.imageHeight),
        );

        for (final ayah in geometry.ayahs) {
          for (final word in ayah.textWords) {
            final Rect wordRect = word.toRect(rect.size).shift(rect.topLeft);
            expect(wordRect.left >= 0, isTrue, reason: 'page $page');
            expect(
              wordRect.right <= viewportSize.width,
              isTrue,
              reason: 'page $page',
            );
          }
        }
      }
    },
  );

  testWidgets('page 56 swipes in RTL reading order', (tester) async {
    final controller = PageController(
      initialPage: QpcMushafPageView.indexFromPageNumber(56),
    );
    addTearDown(controller.dispose);

    int currentPage = 56;
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(
          width: 400,
          height: 600,
          child: PageView.builder(
            reverse: false,
            controller: controller,
            itemCount: QpcMushafPageView.totalPages,
            onPageChanged: (index) {
              currentPage = QpcMushafPageView.pageNumberFromIndex(index);
            },
            itemBuilder: (context, index) {
              final pageNumber = QpcMushafPageView.pageNumberFromIndex(index);
              return Center(
                child: Text('p${pageNumber.toString().padLeft(3, '0')}'),
              );
            },
          ),
        ),
      ),
    );

    expect(find.text('p056'), findsOneWidget);

    await tester.fling(find.byType(PageView), const Offset(420, 0), 1000);
    await tester.pumpAndSettle();
    expect(currentPage, 57);
    expect(find.text('p057'), findsOneWidget);

    controller.jumpToPage(QpcMushafPageView.indexFromPageNumber(56));
    currentPage = 56;
    await tester.pumpAndSettle();

    await tester.fling(find.byType(PageView), const Offset(-420, 0), 1000);
    await tester.pumpAndSettle();
    expect(currentPage, 55);
    expect(find.text('p055'), findsOneWidget);
  });

  test('page 56 uses p056 assets and geometry hit testing', () async {
    await rootBundle.load(
      'assets/quran/svg_pages_quran_only_webp/p056_quran_only_transparent.webp',
    );

    final geometry = await SvgMushafGeometryRepository.instance.loadPage(56);
    expect(geometry.page, 56);

    final ayah = geometry.ayahs.firstWhere((ayah) => ayah.textWords.isNotEmpty);
    final word = ayah.textWords.first;
    final hit = geometry.hitTest(
      Offset(
        (word.x + word.w / 2) * geometry.imageWidth,
        (word.y + word.h / 2) * geometry.imageHeight,
      ),
      Size(geometry.imageWidth, geometry.imageHeight),
    );

    expect(hit?.ayahKey, ayah.ayahKey);
    expect(hit?.wordKey.surah, ayah.surah);
    expect(hit?.wordKey.ayah, ayah.ayah);
  });

  test('quran-only page metadata covers sampled reader pages', () async {
    final metadata = await SvgMushafPageMetadataRepository.instance.loadAll();

    expect(metadata.length, 604);
    expect(metadata[1]?.surahs.map((surah) => surah.id), <int>[1]);
    expect(metadata[1]?.juz, 1);
    expect(metadata[2]?.surahs.map((surah) => surah.id), <int>[2]);
    expect(metadata[3]?.juz, 1);

    expect(metadata[56]?.surahs.map((surah) => surah.id), <int>[3]);
    expect(metadata[56]?.juz, 3);

    expect(metadata[255]?.surahs.map((surah) => surah.id), <int>[13, 14]);
    expect(metadata[255]?.juz, 13);

    expect(metadata[604]?.surahs.map((surah) => surah.id), <int>[
      112,
      113,
      114,
    ]);
    expect(metadata[604]?.juz, 30);
    expect(metadata[604]?.surahSummary, contains('الناس'));
  });

  test('reader audio reciter list covers bundled ayah audio assets', () async {
    const Map<String, String> expectedNamesById = <String, String>{
      'alnufais': 'أحمد النفيس',
      'yasser_al_dosari': 'ياسر الدوسري',
      'minshawi': 'محمد صديق المنشاوي',
      'sudais': 'عبد الرحمن السديس',
      'husary': 'محمود خليل الحصري',
      'abdul_basit': 'عبد الباسط عبد الصمد',
      'maher_al_muaiqly': 'ماهر المعيقلي',
    };

    final reciters = QuranAyahAudioService.reciters;

    expect(
      reciters.map((reciter) => reciter.id),
      unorderedEquals(expectedNamesById.keys),
    );
    expect(
      reciters.map((reciter) => reciter.name),
      unorderedEquals(expectedNamesById.values),
    );

    for (final reciter in reciters) {
      final ByteData data = await rootBundle.load(reciter.assetDbPath);
      expect(data.lengthInBytes, greaterThan(0), reason: reciter.name);
    }
  });

  test('tafsir and irab selectors cover bundled source assets', () async {
    expect(
      QuranTafsirRepository.sources.map((source) => source.id),
      containsAll(<String>[
        'wasit',
        'qurtubi',
        'ibn_kathir',
        'tabari',
        'ibn_al_jawzi',
        'jamia_al_bayan_aliji',
        'ibn_al_qayyim',
      ]),
    );
    expect(
      QuranTafsirRepository.sources.map((source) => source.id),
      isNot(contains('muyassar_gharib')),
    );

    expect(
      QuranIrabRepository.sources.map((source) => source.id),
      containsAll(<String>['darwish', 'da_as', 'muyassar']),
    );

    for (final source in QuranTafsirRepository.sources) {
      final ByteData data = await rootBundle.load(source.assetPath);
      expect(data.lengthInBytes, greaterThan(0), reason: source.label);
    }

    for (final source in QuranIrabRepository.sources) {
      final ByteData data = await rootBundle.load(source.assetPath);
      expect(data.lengthInBytes, greaterThan(0), reason: source.label);
    }
  });

  test(
    'svg geometry preserves standalone waqf marks for highlighting',
    () async {
      final geometry = await SvgMushafGeometryRepository.instance.loadPage(56);
      final waqfWords = geometry.ayahs
          .expand((ayah) => ayah.textWords)
          .where((word) => word.isWaqfMark)
          .toList(growable: false);

      expect(waqfWords, isNotEmpty);
      expect(
        waqfWords.map((word) => word.hafs).toSet(),
        contains(anyOf('\u06d6', '\u06da')),
      );

      final waqfWord = waqfWords.first;
      final hit = geometry.hitTest(
        Offset(
          (waqfWord.x + waqfWord.w / 2) * geometry.imageWidth,
          (waqfWord.y + waqfWord.h / 2) * geometry.imageHeight,
        ),
        Size(geometry.imageWidth, geometry.imageHeight),
      );

      expect(hit?.word?.isWaqfMark, isTrue);
      expect(hit?.wordKey.surah, waqfWord.surah);
      expect(hit?.wordKey.ayah, waqfWord.ayah);
    },
  );
}

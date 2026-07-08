import 'package:flutter_test/flutter_test.dart';
import 'package:islamic_app/features/home/presentation/phone/widgets/prayer_hero_background_resolver.dart';
import 'package:islamic_app/features/settings/prayer_background_style_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('PrayerBackgroundStyle', () {
    test('only exposes global and automatic as user choices', () {
      expect(
        PrayerBackgroundStyle.userSelectableValues,
        <PrayerBackgroundStyle>[
          PrayerBackgroundStyle.global,
          PrayerBackgroundStyle.automatic,
        ],
      );
    });

    test('normalizes legacy Egypt and Syria storage values to global', () {
      expect(
        PrayerBackgroundStyle.fromStorage('egypt'),
        PrayerBackgroundStyle.global,
      );
      expect(
        PrayerBackgroundStyle.fromStorage('syria'),
        PrayerBackgroundStyle.global,
      );
    });

    test('rewrites a legacy regional preference as global', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        PrayerBackgroundStyleService.storageKey: 'egypt',
      });

      final PrayerBackgroundStyle loaded =
          await const PrayerBackgroundStyleService().load();
      final SharedPreferences prefs = await SharedPreferences.getInstance();

      expect(loaded, PrayerBackgroundStyle.global);
      expect(
        prefs.getString(PrayerBackgroundStyleService.storageKey),
        PrayerBackgroundStyle.global.storageValue,
      );
    });
  });

  group('automatic prayer background pack', () {
    final DateTime ordinaryDay = DateTime(2025, 1, 15, 12);
    final List<Map<String, String>> prayerWeek = <Map<String, String>>[
      <String, String>{
        'date': '2025-01-15',
        'fajr': '05:00',
        'sunrise': '06:30',
        'asr': '15:30',
        'maghrib': '17:30',
      },
    ];

    test('uses Egypt pack for Egypt', () {
      final PrayerHeroBackgroundChoice choice =
          PrayerHeroBackgroundResolver.resolveChoice(
            prayerWeek: prayerWeek,
            countryIso: 'EG',
            now: ordinaryDay,
          );

      expect(choice.pack, PrayerBackgroundPack.egypt);
    });

    test('uses Syria pack for Syria', () {
      final PrayerHeroBackgroundChoice choice =
          PrayerHeroBackgroundResolver.resolveChoice(
            prayerWeek: prayerWeek,
            countryIso: 'SY',
            now: ordinaryDay,
          );

      expect(choice.pack, PrayerBackgroundPack.syria);
    });

    test('uses global pack for other or unavailable locations', () {
      for (final String? countryIso in <String?>['SA', null]) {
        final PrayerHeroBackgroundChoice choice =
            PrayerHeroBackgroundResolver.resolveChoice(
              prayerWeek: prayerWeek,
              countryIso: countryIso,
              now: ordinaryDay,
            );

        expect(choice.pack, PrayerBackgroundPack.global);
      }
    });
  });
}

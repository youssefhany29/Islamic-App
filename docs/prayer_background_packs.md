# Prayer Background Packs

This manifest classifies the generated prayer hero backgrounds for "رفيق المسلم".
The runtime catalog is implemented in `lib/features/home/presentation/phone/widgets/prayer_hero_background_resolver.dart`.

## Priority

1. Eid Pack
2. Ramadan Pack
3. Egypt Pack
4. Syria Pack
5. Gulf Pack
6. Global Pack

## Global Pack

- Fajr: `Fajr.png`, `fajr_01.png`, `FoggyFajr.png`, `MountainMosque.png`, `WinterFajr.png`
- Sunrise: `FridaySunrise.png`, `PinkSunrise.png`, `Sunrise.png`, `sunrise_01.png`
- Dhuhr: `CloudyDay.png`, `CoastalDhuhr.png`, `dhuhr_01.png`, `FridayMorning.png`, `SummerDhuhr.png`
- Asr: `asr_01.png`, `CloudyDay.png`, `MountainAsr.png`, `PeacefulAsr.png`
- Maghrib: `GoldenCityMaghrib.png`, `Maghrib.png`, `maghrib_01.png`, `StormyMaghrib.png`, `SummerMaghrib.png`
- Isha: `Isha.png`, `isha_01.png`, `RainyPrayerTime.png`, `SacredBlueNight.png`

## Egypt Pack

- Fajr: `fajr_1.png`, `fajr_2.png`, `fajr_3.png`, `fajr_4.png`
- Sunrise: `sunrise_1 (1).png`, `sunrise_1 (2).png`
- Dhuhr: `dhuhur_1.png`
- Asr: `asr_1.png`, `asr_2.png`
- Maghrib: `maghrib_1.png`, `maghrib_2.png`, `maghrib_3.png`
- Isha: `isha_1 (1).png`, `isha_3.png`, `isha_4.png`, `isha_5.png`

## Syria Pack

- Fajr: `fajr_1.png`, `fajr_2.png`, `fajr_3.png`, `fajr_4.png`
- Sunrise: `sunrise_1.png`, `sunrise_2.png`, `sunrise_3.png`, `sunrise_4.png`
- Dhuhr: `dhuhur_1.png`, `dhuhur_2.png`, `dhuhur_3.png`, `dhuhur_4.png`
- Asr: `asr_1.png`, `asr_2.png`, `asr_3.png`, `asr_4.png`
- Maghrib: `maghrib_1 (1).png`, `maghrib_2.png`, `maghrib_3.png`, `maghrib_4.png`
- Isha: `isha_1.png`, `isha_2.png`, `isha_3.png`, `isha_4.png`

## Gulf Pack

- No generated Gulf-specific prayer backgrounds were found.
- Runtime behavior: Gulf countries fall back to the Global Pack until Gulf artwork is added.
- Country codes reserved for Gulf routing: `SA`, `AE`, `QA`, `KW`, `BH`, `OM`.

## Ramadan Pack

- Fajr: `r_1 (1).png`, `r_2.png`
- Sunrise: `1.png`, `2.png`
- Dhuhr: `1.png`, `2.png`
- Asr: `1.png`, `2.png`
- Maghrib: `1.png`, `2.png`
- Isha: `1.png`, `2.png`

## Eid Pack

- Fajr: `1.png`, `2.png`
- Sunrise: `1.png`, `2.png`
- Dhuhr: `1.png`, `2.png`
- Asr: no generated Eid Asr backgrounds found, falls back to Global Asr
- Maghrib: no generated Eid Maghrib backgrounds found, falls back to Global Maghrib
- Isha: `EidNight.png`

## Excluded Images

- `assets/background/ramadan/*` and `assets/background/eid/*`: excluded because they are framed greeting/event card templates, not Samsung Weather-style atmospheric prayer backgrounds.
- `egypt/maghrip/maghrib_ramdan_*.png`: excluded from Egypt because Ramadan is global and must override country packs.
- Extra Ramadan/Eid variants beyond two per prayer were left out to avoid duplicates and keep the holiday packs tightly curated.

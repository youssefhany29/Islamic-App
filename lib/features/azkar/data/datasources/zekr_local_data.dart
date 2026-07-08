import 'package:flutter/material.dart';

import '../models/zekr_category_model.dart';
import '../models/zekr_item_model.dart';
part 'zekr_local_data_morning_evening.dart';
part 'zekr_local_data_morning.dart';
part 'zekr_local_data_evening.dart';
part 'zekr_local_data_daily.dart';
part 'zekr_local_data_duas.dart';

class ZekrLocalData {
  static const String morningId = 'morning';
  static const String eveningId = 'evening';
  static const String afterPrayerId = 'after_prayer';
  static const String sleepId = 'sleep';
  static const String wakeUpId = 'wake_up';
  static const String wuduId = 'wudu';
  static const String homeId = 'home';
  static const String restroomId = 'restroom';
  static const String foodId = 'food';
  static const String hajjUmrahId = 'hajj_umrah';
  static const String namesId = 'names';
  static const String duasId = 'duas';
  static const String customId = 'custom';

  static const List<ZekrCategoryModel> categories = [
    ZekrCategoryModel(
      id: morningId,
      title: "أذكار الصباح",
      subtitle: "ابدأ يومك بطمأنينة وذكر",
      icon: Icons.wb_sunny_outlined,
      isDailyTarget: true,
    ),
    ZekrCategoryModel(
      id: eveningId,
      title: "أذكار المساء",
      subtitle: "اختم يومك بسكينة وحفظ",
      icon: Icons.nightlight_round,
      isDailyTarget: true,
    ),
    ZekrCategoryModel(
      id: afterPrayerId,
      title: "أذكار بعد الصلاة",
      subtitle: "ورد قصير بعد كل صلاة",
      icon: Icons.mosque_outlined,
      isDailyTarget: true,
    ),
    ZekrCategoryModel(
      id: sleepId,
      title: "أذكار النوم",
      subtitle: "نم على ذكر وطمأنينة",
      icon: Icons.bedtime_outlined,
      isDailyTarget: true,
    ),
    ZekrCategoryModel(
      id: wakeUpId,
      title: "أذكار الاستيقاظ",
      subtitle: "ابدأ لحظتك الأولى بالحمد",
      icon: Icons.wb_twilight_outlined,
      isDailyTarget: false,
    ),
    ZekrCategoryModel(
      id: wuduId,
      title: "أذكار الوضوء",
      subtitle: "قبل الوضوء وبعده",
      icon: Icons.water_drop_outlined,
      isDailyTarget: false,
    ),
    ZekrCategoryModel(
      id: homeId,
      title: "أذكار المنزل",
      subtitle: "دخول وخروج المنزل",
      icon: Icons.home_outlined,
      isDailyTarget: false,
    ),
    ZekrCategoryModel(
      id: restroomId,
      title: "أذكار الخلاء",
      subtitle: "دخول وخروج الخلاء",
      icon: Icons.meeting_room_outlined,
      isDailyTarget: false,
    ),
    ZekrCategoryModel(
      id: foodId,
      title: "أذكار الطعام والشراب",
      subtitle: "الطعام والضيف والشراب",
      icon: Icons.restaurant_outlined,
      isDailyTarget: false,
    ),
    ZekrCategoryModel(
      id: hajjUmrahId,
      title: "أذكار الحج والعمرة",
      subtitle: "أدعية المناسك والطواف والسعي",
      icon: Icons.hiking_rounded,
      isDailyTarget: false,
    ),
    ZekrCategoryModel(
      id: namesId,
      title: "أسماء الله الحسنى",
      subtitle: "تأمل ودعاء بأسماء الله",
      icon: Icons.auto_awesome_rounded,
      isDailyTarget: false,
    ),
    ZekrCategoryModel(
      id: duasId,
      title: "الأدعية المتفرقة",
      subtitle: "أدعية جامعة للمواقف اليومية",
      icon: Icons.volunteer_activism_outlined,
      isDailyTarget: false,
    ),
    ZekrCategoryModel(
      id: customId,
      title: "أذكاري الخاصة",
      subtitle: "أضف أذكارك وأدعيتك المفضلة",
      icon: Icons.edit_note_rounded,
      isDailyTarget: false,
    ),
  ];

  static ZekrCategoryModel getCategoryById(String id) {
    return categories.firstWhere(
      (category) => category.id == id,
      orElse: () => categories.first,
    );
  }

  static List<ZekrItemModel> getBuiltInItems(String categoryId) {
    switch (categoryId) {
      case morningId:
        return morningAzkar;
      case eveningId:
        return eveningAzkar;
      case afterPrayerId:
        return afterPrayerAzkar;
      case sleepId:
        return sleepAzkar;
      case wakeUpId:
        return wakeUpAzkar;
      case wuduId:
        return wuduAzkar;
      case homeId:
        return homeAzkar;
      case restroomId:
        return restroomAzkar;
      case foodId:
        return foodAzkar;
      case hajjUmrahId:
        return hajjUmrahAzkar;
      case namesId:
        return namesAzkar;
      case duasId:
        return duas;
      default:
        return const [];
    }
  }

  static List<ZekrItemModel> get allBuiltInItems {
    return [
      ...morningAzkar,
      ...eveningAzkar,
      ...afterPrayerAzkar,
      ...sleepAzkar,
      ...wakeUpAzkar,
      ...wuduAzkar,
      ...homeAzkar,
      ...restroomAzkar,
      ...foodAzkar,
      ...hajjUmrahAzkar,
      ...namesAzkar,
      ...duas,
    ];
  }

  static const List<ZekrItemModel> morningAzkar = _morningAzkar;

  static const List<ZekrItemModel> eveningAzkar = _eveningAzkar;

  static const List<ZekrItemModel> afterPrayerAzkar = _afterPrayerAzkar;

  static const List<ZekrItemModel> sleepAzkar = _sleepAzkar;

  static const List<ZekrItemModel> wakeUpAzkar = _wakeUpAzkar;

  static const List<ZekrItemModel> wuduAzkar = _wuduAzkar;

  static const List<ZekrItemModel> homeAzkar = _homeAzkar;

  static const List<ZekrItemModel> restroomAzkar = _restroomAzkar;

  static const List<ZekrItemModel> foodAzkar = _foodAzkar;

  static const List<ZekrItemModel> hajjUmrahAzkar = _hajjUmrahAzkar;

  static const List<ZekrItemModel> namesAzkar = _namesAzkar;

  static const List<ZekrItemModel> duas = _duas;
}

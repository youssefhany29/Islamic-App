import 'package:flutter/material.dart';

import '../models/hadith_category_model.dart';
import '../models/hadith_item_model.dart';

class HadithLocalData {
  const HadithLocalData._();

  static const String allId = 'all_hadith';
  static const String imanId = 'iman';
  static const String akhlaqId = 'akhlaq';
  static const String ibadahId = 'ibadah';
  static const String quranId = 'quran';
  static const String intentionsId = 'intentions';
  static const String mercyId = 'mercy';
  static const String familyId = 'family';
  static const String societyId = 'society';
  static const String dailyLifeId = 'daily_life';
  static const String qudsiId = 'qudsi';
  static const String customId = 'custom_hadith';

  static const List<HadithCategoryModel> categories = [
    HadithCategoryModel(
      id: imanId,
      title: 'الإيمان واليقين',
      subtitle: 'أحاديث تقوّي القلب واليقين بالله.',
      icon: Icons.favorite_rounded,
      isDailyTarget: true,
    ),
    HadithCategoryModel(
      id: intentionsId,
      title: 'النية والإخلاص',
      subtitle: 'أحاديث تعلّمك تصحيح النية قبل العمل.',
      icon: Icons.center_focus_strong_rounded,
      isDailyTarget: true,
    ),
    HadithCategoryModel(
      id: akhlaqId,
      title: 'الأخلاق والآداب',
      subtitle: 'أحاديث عملية لتحسين الخلق والتعامل.',
      icon: Icons.handshake_rounded,
      isDailyTarget: true,
    ),
    HadithCategoryModel(
      id: ibadahId,
      title: 'العبادة والعمل',
      subtitle: 'أحاديث عن الصلاة والذكر والعمل الصالح.',
      icon: Icons.mosque_rounded,
      isDailyTarget: true,
    ),
    HadithCategoryModel(
      id: quranId,
      title: 'القرآن والعلم',
      subtitle: 'أحاديث عن فضل القرآن وطلب العلم.',
      icon: Icons.auto_stories_rounded,
      isDailyTarget: true,
    ),
    HadithCategoryModel(
      id: mercyId,
      title: 'الرحمة والتيسير',
      subtitle: 'أحاديث تفتح باب الرحمة وحسن الظن.',
      icon: Icons.volunteer_activism_rounded,
      isDailyTarget: false,
    ),
    HadithCategoryModel(
      id: familyId,
      title: 'البيت والأسرة',
      subtitle: 'أحاديث عن حسن المعاشرة والمسؤولية.',
      icon: Icons.home_rounded,
      isDailyTarget: false,
    ),
    HadithCategoryModel(
      id: societyId,
      title: 'المجتمع والمعاملات',
      subtitle: 'أحاديث عن الأمانة والحقوق والتعامل.',
      icon: Icons.groups_rounded,
      isDailyTarget: false,
    ),
    HadithCategoryModel(
      id: dailyLifeId,
      title: 'حياة المسلم اليومية',
      subtitle: 'أحاديث قصيرة تُترجم إلى عادة يومية.',
      icon: Icons.wb_sunny_rounded,
      isDailyTarget: false,
    ),
    HadithCategoryModel(
      id: qudsiId,
      title: 'أحاديث قدسية',
      subtitle: 'معانٍ عظيمة عن القرب من الله.',
      icon: Icons.light_mode_rounded,
      isDailyTarget: false,
    ),
    HadithCategoryModel(
      id: customId,
      title: 'أحاديثي الخاصة',
      subtitle: 'أضف أحاديث أو فوائد تريد مراجعتها.',
      icon: Icons.edit_note_rounded,
      isDailyTarget: false,
    ),
  ];

  static List<HadithItemModel> getBuiltInItems(String categoryId) {
    return _items.where((item) => item.categoryId == categoryId).toList();
  }

  static List<HadithItemModel> get allBuiltInItems => List.unmodifiable(_items);

  static const List<HadithItemModel> _items = [
    HadithItemModel(
      id: 'intentions_001',
      categoryId: intentionsId,
      title: 'إنما الأعمال بالنيات',
      text: 'إنما الأعمال بالنيات، وإنما لكل امرئ ما نوى.',
      source: 'صحيح البخاري وصحيح مسلم',
      reference: 'حديث عمر بن الخطاب رضي الله عنه',
      grade: 'متفق عليه',
      benefit:
          'يجعل المستخدم يبدأ كل عمل بسؤال: لماذا أفعل هذا؟ فيتحول العمل العادي إلى عبادة بالنية الصالحة.',
      lesson: 'صحّح نيتك قبل الدراسة والعمل والعبادة، فالنية تغيّر قيمة العمل.',
      count: 1,
      type: HadithType.hadith,
    ),
    HadithItemModel(
      id: 'intentions_002',
      categoryId: intentionsId,
      title: 'الدين النصيحة',
      text: 'الدين النصيحة.',
      source: 'صحيح مسلم',
      reference: 'عن تميم الداري رضي الله عنه',
      grade: 'صحيح',
      benefit: 'يعلمنا أن حب الخير للناس جزء من الدين، وليس مجرد خلق اجتماعي.',
      lesson: 'انصح برحمة، واقبل النصيحة بتواضع.',
      count: 1,
      type: HadithType.hadith,
    ),
    HadithItemModel(
      id: 'iman_001',
      categoryId: imanId,
      title: 'حلاوة الإيمان',
      text:
          'ثلاث من كن فيه وجد بهن حلاوة الإيمان: أن يكون الله ورسوله أحب إليه مما سواهما، وأن يحب المرء لا يحبه إلا لله، وأن يكره أن يعود في الكفر كما يكره أن يقذف في النار.',
      source: 'صحيح البخاري وصحيح مسلم',
      reference: 'عن أنس رضي الله عنه',
      grade: 'متفق عليه',
      benefit:
          'يعطي مقياسًا عمليًا لقوة الإيمان: الحب لله، وتقديم محبة الله ورسوله، والثبات على الحق.',
      lesson: 'راجع علاقاتك ومحبتك للأشياء: هل تقرّبك من الله أم تضعفك؟',
      count: 1,
      type: HadithType.hadith,
    ),
    HadithItemModel(
      id: 'iman_002',
      categoryId: imanId,
      title: 'لا يؤمن أحدكم حتى يحب لأخيه',
      text: 'لا يؤمن أحدكم حتى يحب لأخيه ما يحب لنفسه.',
      source: 'صحيح البخاري وصحيح مسلم',
      reference: 'عن أنس رضي الله عنه',
      grade: 'متفق عليه',
      benefit:
          'يبني قلبًا سليمًا لا يحسد الناس، بل يفرح بخيرهم كما يفرح لنفسه.',
      lesson: 'عامل نجاح غيرك كأنه خير تتمناه لنفسك.',
      count: 1,
      type: HadithType.hadith,
    ),
    HadithItemModel(
      id: 'akhlaq_001',
      categoryId: akhlaqId,
      title: 'الكلمة الطيبة صدقة',
      text: 'والكلمة الطيبة صدقة.',
      source: 'صحيح البخاري وصحيح مسلم',
      reference: 'من حديث أبي هريرة رضي الله عنه',
      grade: 'متفق عليه',
      benefit:
          'يجعل الكلام اللطيف عبادة يومية سهلة، لا تحتاج مالًا ولا وقتًا طويلًا.',
      lesson: 'اختر كلمة ترفع بها قلب إنسان اليوم.',
      count: 1,
      type: HadithType.adab,
    ),
    HadithItemModel(
      id: 'akhlaq_002',
      categoryId: akhlaqId,
      title: 'من كان يؤمن بالله واليوم الآخر',
      text: 'من كان يؤمن بالله واليوم الآخر فليقل خيرًا أو ليصمت.',
      source: 'صحيح البخاري وصحيح مسلم',
      reference: 'عن أبي هريرة رضي الله عنه',
      grade: 'متفق عليه',
      benefit: 'ينظم اللسان ويقلل الندم والمشاكل؛ فليس كل ما يُعرف يُقال.',
      lesson: 'قبل أن تتكلم اسأل: هل هذا خير؟ هل وقته مناسب؟',
      count: 1,
      type: HadithType.adab,
    ),
    HadithItemModel(
      id: 'akhlaq_003',
      categoryId: akhlaqId,
      title: 'تبسمك في وجه أخيك',
      text: 'تبسمك في وجه أخيك لك صدقة.',
      source: 'سنن الترمذي',
      reference: 'عن أبي ذر رضي الله عنه',
      grade: 'حسن',
      benefit:
          'يجعل اللطف والبشاشة جزءًا من العبادة، ويخفف ثقل الحياة على الناس.',
      lesson: 'ابدأ يومك بوجه سمح، فرب ابتسامة تكون صدقة.',
      count: 1,
      type: HadithType.adab,
    ),
    HadithItemModel(
      id: 'ibadah_001',
      categoryId: ibadahId,
      title: 'أحب الأعمال إلى الله',
      text: 'أحب الأعمال إلى الله أدومها وإن قل.',
      source: 'صحيح البخاري وصحيح مسلم',
      reference: 'عن عائشة رضي الله عنها',
      grade: 'متفق عليه',
      benefit:
          'يشجع المستخدم على الاستمرار بدل الحماس المؤقت، وهذا مناسب جدًا لخطة الحفظ والمراجعة.',
      lesson: 'اختر عملًا صغيرًا ثابتًا أفضل من عمل كبير ينقطع.',
      count: 1,
      type: HadithType.hadith,
    ),
    HadithItemModel(
      id: 'ibadah_002',
      categoryId: ibadahId,
      title: 'الطهور شطر الإيمان',
      text: 'الطهور شطر الإيمان، والحمد لله تملأ الميزان.',
      source: 'صحيح مسلم',
      reference: 'عن أبي مالك الأشعري رضي الله عنه',
      grade: 'صحيح',
      benefit:
          'يربط النظافة والطهارة بالإيمان، ويجعل الذكر اليومي ذا أثر عظيم في الميزان.',
      lesson: 'اجعل الوضوء والذكر بداية واعية قبل الصلاة والعمل.',
      count: 1,
      type: HadithType.hadith,
    ),
    HadithItemModel(
      id: 'quran_001',
      categoryId: quranId,
      title: 'خيركم من تعلم القرآن',
      text: 'خيركم من تعلم القرآن وعلمه.',
      source: 'صحيح البخاري',
      reference: 'عن عثمان بن عفان رضي الله عنه',
      grade: 'صحيح',
      benefit: 'يرفع قيمة تعلم القرآن وتعليمه، ولو بآية أو معنى صغير.',
      lesson: 'تعلم آية واعمل بها وشارك معناها مع غيرك.',
      count: 1,
      type: HadithType.hadith,
    ),
    HadithItemModel(
      id: 'quran_002',
      categoryId: quranId,
      title: 'من سلك طريقًا يلتمس فيه علمًا',
      text: 'من سلك طريقًا يلتمس فيه علمًا سهّل الله له به طريقًا إلى الجنة.',
      source: 'صحيح مسلم',
      reference: 'عن أبي هريرة رضي الله عنه',
      grade: 'صحيح',
      benefit:
          'يعطي معنى تعب الدراسة والتعلم: الطريق إلى العلم طريق إلى الجنة إذا صلحت النية.',
      lesson: 'حوّل تعلمك إلى عبادة بنية نافعة.',
      count: 1,
      type: HadithType.hadith,
    ),
    HadithItemModel(
      id: 'mercy_001',
      categoryId: mercyId,
      title: 'من لا يَرحم لا يُرحم',
      text: 'من لا يَرحم لا يُرحم.',
      source: 'صحيح البخاري وصحيح مسلم',
      reference: 'عن جرير بن عبد الله رضي الله عنه',
      grade: 'متفق عليه',
      benefit: 'يربي القلب على اللين مع الضعفاء والأهل والناس.',
      lesson: 'عامل الناس برحمة، فالرحمة سبب لرحمة الله.',
      count: 1,
      type: HadithType.adab,
    ),
    HadithItemModel(
      id: 'mercy_002',
      categoryId: mercyId,
      title: 'يسروا ولا تعسروا',
      text: 'يسّروا ولا تعسّروا، وبشّروا ولا تنفّروا.',
      source: 'صحيح البخاري وصحيح مسلم',
      reference: 'عن أنس رضي الله عنه',
      grade: 'متفق عليه',
      benefit:
          'يعلمنا أن الدعوة والتعامل والتربية تحتاج تيسيرًا ورحمة لا قسوة منفّرة.',
      lesson: 'كن سببًا في تقريب الناس من الخير لا تنفيرهم منه.',
      count: 1,
      type: HadithType.adab,
    ),
    HadithItemModel(
      id: 'family_001',
      categoryId: familyId,
      title: 'خيركم خيركم لأهله',
      text: 'خيركم خيركم لأهله، وأنا خيركم لأهلي.',
      source: 'سنن الترمذي',
      reference: 'عن عائشة رضي الله عنها',
      grade: 'صحيح لغيره أو حسن عند عدد من أهل العلم',
      benefit:
          'ينقل معيار الخيرية إلى البيت؛ فالأخلاق الحقيقية تظهر مع الأقربين.',
      lesson: 'ابدأ حسن الخلق من أهلك قبل الغرباء.',
      count: 1,
      type: HadithType.adab,
    ),
    HadithItemModel(
      id: 'society_001',
      categoryId: societyId,
      title: 'المسلم من سلم المسلمون',
      text: 'المسلم من سلم المسلمون من لسانه ويده.',
      source: 'صحيح البخاري وصحيح مسلم',
      reference: 'عن عبد الله بن عمرو رضي الله عنهما',
      grade: 'متفق عليه',
      benefit: 'يجعل كف الأذى علامة أساسية من علامات الإسلام العملي.',
      lesson: 'لا تؤذِ بلسانك في الواقع أو على الإنترنت.',
      count: 1,
      type: HadithType.adab,
    ),
    HadithItemModel(
      id: 'society_002',
      categoryId: societyId,
      title: 'لا ضرر ولا ضرار',
      text: 'لا ضرر ولا ضرار.',
      source: 'سنن ابن ماجه وموطأ مالك',
      reference: 'حديث مشهور عند أهل العلم',
      grade: 'حسن بمجموع طرقه',
      benefit:
          'قاعدة عظيمة تمنع إلحاق الضرر بالنفس أو بالناس في المعاملات والعلاقات.',
      lesson: 'راجع قراراتك: هل فيها أذى مباشر أو غير مباشر؟',
      count: 1,
      type: HadithType.hadith,
    ),
    HadithItemModel(
      id: 'daily_001',
      categoryId: dailyLifeId,
      title: 'اتق الله حيثما كنت',
      text:
          'اتق الله حيثما كنت، وأتبع السيئة الحسنة تمحها، وخالق الناس بخلق حسن.',
      source: 'سنن الترمذي',
      reference: 'عن أبي ذر ومعاذ رضي الله عنهما',
      grade: 'حسن',
      benefit: 'حديث جامع لخطة يومية: تقوى، تصحيح خطأ، وحسن تعامل.',
      lesson: 'إذا أخطأت فبادر بحسنة، ولا تجعل الخطأ يوقفك.',
      count: 1,
      type: HadithType.hadith,
    ),
    HadithItemModel(
      id: 'daily_002',
      categoryId: dailyLifeId,
      title: 'احفظ الله يحفظك',
      text: 'احفظ الله يحفظك، احفظ الله تجده تجاهك.',
      source: 'سنن الترمذي',
      reference: 'من وصية النبي ﷺ لابن عباس رضي الله عنهما',
      grade: 'صحيح',
      benefit:
          'يبني الثقة بالله والالتزام بحدوده، خصوصًا في الخلوة والقرارات الصعبة.',
      lesson: 'احفظ أوامر الله في يومك، وثق أن حفظ الله أعظم.',
      count: 1,
      type: HadithType.hadith,
    ),
    HadithItemModel(
      id: 'qudsi_001',
      categoryId: qudsiId,
      title: 'أنا عند ظن عبدي بي',
      text: 'قال الله تعالى: أنا عند ظن عبدي بي، وأنا معه إذا ذكرني.',
      source: 'صحيح البخاري وصحيح مسلم',
      reference: 'حديث قدسي عن أبي هريرة رضي الله عنه',
      grade: 'متفق عليه',
      benefit: 'يدعو لحسن الظن بالله وكثرة ذكره، خصوصًا وقت القلق والخوف.',
      lesson: 'املأ قلبك بحسن الظن بالله ولا تقطع صلتك بالذكر.',
      count: 1,
      type: HadithType.qudsi,
    ),
    HadithItemModel(
      id: 'qudsi_002',
      categoryId: qudsiId,
      title: 'يا عبادي إني حرمت الظلم',
      text:
          'يا عبادي إني حرمت الظلم على نفسي وجعلته بينكم محرّمًا فلا تظالموا.',
      source: 'صحيح مسلم',
      reference: 'حديث قدسي عن أبي ذر رضي الله عنه',
      grade: 'صحيح',
      benefit:
          'يرسخ العدل في القلب ويجعل الظلم خطًا أحمر في البيت والعمل والمعاملات.',
      lesson: 'لا تبرر الظلم حتى لو كنت قادرًا عليه.',
      count: 1,
      type: HadithType.qudsi,
    ),
  ];
}

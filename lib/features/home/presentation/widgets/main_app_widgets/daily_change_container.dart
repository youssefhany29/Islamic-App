import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:islamic_app/shared/widgets/common_components/app_layout_constants.dart';

class DailyChangeContainer extends StatelessWidget {
  const DailyChangeContainer({super.key});

  static const Color _innerCardColor = Color(0xff171B26);
  static const Color _greenColor = Color(0xff21C58E);
  static const Color _goldColor = Color(0xffffb300);

  static const List<String> _dailyDhikr = [
    'سبحان الله وبحمده، سبحان الله العظيم.',
    'لا إله إلا الله وحده لا شريك له، له الملك وله الحمد وهو على كل شيء قدير.',
    'أستغفر الله العظيم وأتوب إليه.',
    'اللهم صلِّ وسلم على نبينا محمد.',
    'سبحان الله، والحمد لله، ولا إله إلا الله، والله أكبر.',
    'لا حول ولا قوة إلا بالله.',
    'حسبي الله لا إله إلا هو عليه توكلت وهو رب العرش العظيم.',
    'اللهم أعنّي على ذكرك وشكرك وحسن عبادتك.',
    'رب اغفر لي وتب عليّ إنك أنت التواب الرحيم.',
    'سبحان الله عدد خلقه ورضا نفسه وزنة عرشه ومداد كلماته.',
    'اللهم إنك عفو تحب العفو فاعف عني.',
    'ربنا آتنا في الدنيا حسنة وفي الآخرة حسنة وقنا عذاب النار.',
    'يا حي يا قيوم برحمتك أستغيث، أصلح لي شأني كله.',
    'اللهم اهدني وسددني.',
    'اللهم إني أسألك الهدى والتقى والعفاف والغنى.',
    'سبحان الملك القدوس.',
    'اللهم اجعل قلبي مطمئنًا بذكرك.',
    'أعوذ بكلمات الله التامات من شر ما خلق.',
    'رضيت بالله ربًا، وبالإسلام دينًا، وبمحمد ﷺ نبيًا.',
    'اللهم بارك لي في وقتي وعملي ونيتي.',
    'لا إله إلا أنت سبحانك إني كنت من الظالمين.',
    'اللهم اغفر لي ذنبي كله دقه وجله وأوله وآخره.',
    'اللهم إني أعوذ بك من الهم والحزن.',
    'اللهم إني أعوذ بك من العجز والكسل.',
    'اللهم إني أعوذ بك من الجبن والبخل.',
    'اللهم اجعل القرآن ربيع قلبي ونور صدري.',
    'اللهم ثبت قلبي على دينك.',
    'يا مقلب القلوب ثبت قلبي على طاعتك.',
    'اللهم ارزقني قلبًا شاكرًا ولسانًا ذاكرًا.',
    'الحمد لله على نعمة الإسلام.',
    'الحمد لله على كل حال.',
    'اللهم لك الحمد حتى ترضى ولك الحمد إذا رضيت.',
    'اللهم إني أسألك علمًا نافعًا ورزقًا طيبًا وعملًا متقبلًا.',
    'اللهم افتح لي أبواب رحمتك.',
    'اللهم إني أسألك من فضلك ورحمتك.',
    'رب اشرح لي صدري ويسر لي أمري.',
    'اللهم طهّر قلبي من الرياء ولساني من الكذب.',
    'اللهم اجعل عملي خالصًا لوجهك الكريم.',
    'اللهم إني أستودعك قلبي فلا تجعل فيه غيرك.',
    'اللهم قربني إليك قرب المحبين.',
    'اللهم اجعلني من التوابين واجعلني من المتطهرين.',
    'اللهم اجعلني لك شاكرًا، لك ذاكرًا، لك مخبتًا.',
    'اللهم انفعني بما علمتني وعلمني ما ينفعني.',
    'رب زدني علمًا.',
    'اللهم اجعلني من أهل الفجر وأهل القرآن.',
    'اللهم ارزقني صلاة خاشعة وقلبًا حاضرًا.',
    'اللهم لا تكلني إلى نفسي طرفة عين.',
    'اللهم إني أعوذ بك من قلب لا يخشع.',
    'اللهم إني أعوذ بك من دعاء لا يسمع.',
    'اللهم إني أسألك حسن الخاتمة.',
    'اللهم اجعل خير أيامي يوم ألقاك.',
    'اللهم اجعلني ممن طال عمره وحسن عمله.',
    'اللهم ارزقني التوبة قبل الموت والشهادة عند الموت.',
    'اللهم اجعل قبري روضة من رياض الجنة.',
    'اللهم قني عذابك يوم تبعث عبادك.',
    'اللهم آت نفسي تقواها وزكها أنت خير من زكاها.',
    'اللهم إني أعوذ بك من شر نفسي.',
    'اللهم إني أعوذ بك من فتنة الدنيا.',
    'اللهم إني أعوذ بك من فتنة المحيا والممات.',
    'اللهم اجعلني مفتاحًا للخير مغلاقًا للشر.',
    'اللهم أصلح لي ديني الذي هو عصمة أمري.',
    'اللهم أصلح لي دنياي التي فيها معاشي.',
    'اللهم أصلح لي آخرتي التي إليها معادي.',
    'اللهم اجعل الحياة زيادة لي في كل خير.',
    'اللهم اجعل الموت راحة لي من كل شر.',
    'اللهم إني أسألك الجنة وما قرب إليها من قول وعمل.',
    'اللهم إني أعوذ بك من النار وما قرب إليها من قول وعمل.',
    'اللهم اجعلني من عبادك الصالحين.',
    'اللهم اجعلني من الذاكرين الله كثيرًا والذاكرات.',
    'اللهم اجعل لساني رطبًا بذكرك.',
    'اللهم ارزقني صحبة صالحة تعينني على طاعتك.',
    'اللهم اجعل بيتي عامرًا بذكرك.',
    'اللهم اجعل يومي هذا بركة وخيرًا.',
    'اللهم اكتب لي الخير حيث كان ثم رضني به.',
    'اللهم إني أسألك راحة القلب وطمأنينة النفس.',
    'اللهم عافني في بدني وعافني في سمعي وعافني في بصري.',
    'اللهم أنت ربي لا إله إلا أنت، عليك توكلت.',
    'اللهم اكفني بحلالك عن حرامك وأغنني بفضلك عمن سواك.',
    'اللهم اجعل رزقي مباركًا وقلبي راضيًا.',
    'اللهم إني أسألك العفو والعافية.',
    'اللهم استر عوراتي وآمن روعاتي.',
    'اللهم احفظني من بين يدي ومن خلفي وعن يميني وعن شمالي.',
    'اللهم إني أعوذ بعظمتك أن أغتال من تحتي.',
    'اللهم صلِّ على محمد وعلى آل محمد.',
    'سبحان ربي العظيم وبحمده.',
    'سبحان ربي الأعلى وبحمده.',
    'الله أكبر كبيرًا، والحمد لله كثيرًا.',
    'الحمد لله الذي بنعمته تتم الصالحات.',
    'الحمد لله الذي هدانا لهذا وما كنا لنهتدي لولا أن هدانا الله.',
    'ربنا لا تؤاخذنا إن نسينا أو أخطأنا.',
    'ربنا ظلمنا أنفسنا وإن لم تغفر لنا وترحمنا لنكونن من الخاسرين.',
    'ربنا اغفر لنا وارحمنا وأنت خير الراحمين.',
    'ربنا لا تزغ قلوبنا بعد إذ هديتنا.',
    'ربنا هب لنا من لدنك رحمة إنك أنت الوهاب.',
    'ربنا تقبل منا إنك أنت السميع العليم.',
    'رب اجعلني مقيم الصلاة ومن ذريتي.',
    'رب أعوذ بك من همزات الشياطين.',
    'رب اغفر وارحم وأنت خير الراحمين.',
    'اللهم اجعل ذكرك أحب إليّ من كل شاغل.',
    'اللهم اجعلني من عبادك الذين لا خوف عليهم ولا هم يحزنون.',
  ];

  static const List<String> _dailyThoughts = [
    'ابدأ يومك بعبادة صغيرة، فالقلوب تثبت بالتدرج لا بالاندفاع.',
    'الصلاة في وقتها ليست مهمة عابرة، بل موعد يتجدد فيه قلبك مع الله.',
    'كل مرة تعود فيها بعد تقصير هي بداية جديدة لا تقلل من قيمتها.',
    'القليل الدائم أقوى من الكثير المنقطع، فاختر عبادة تثبت عليها اليوم.',
    'ليس المطلوب أن تكون كاملًا، المطلوب أن لا تتوقف عن الرجوع إلى الله.',
    'الذكر لا يحتاج وقتًا طويلًا، لكنه يغير حال القلب في لحظة صادقة.',
    'اجعل للقرآن نصيبًا يوميًا ولو آية، فالاستمرار يصنع الفرق.',
    'من أعظم الانتصارات أن تغلب انشغالك وتقوم للصلاة في وقتها.',
    'لا تؤجل الخير حتى تتحسن ظروفك، الخير هو الذي يحسن ظروف القلب.',
    'العبادة عادة تبدأ بقرار صغير ثم تصير نورًا ملازمًا ليومك.',
    'إذا فترت همتك، فابدأ من جديد بلا قسوة على نفسك.',
    'كل سجدة صادقة تترك أثرًا لا تراه فورًا لكنك تحتاجه دائمًا.',
    'اجعل نيتك حاضرة، فالعمل الصغير يكبر بصدق النية.',
    'الطريق إلى الله ليس سباقًا مع الناس، بل صدق وثبات بينك وبين ربك.',
    'حين تضيق بك الدنيا، افتح باب الصلاة؛ فهو أوسع مما تظن.',
    'الوقت الذي تعطيه لله يعود على قلبك سكينة وبركة.',
    'لا تجعل كثرة المهام تنسيك أعظم موعد في يومك.',
    'تكرار الذكر يصنع ألفة بين القلب والطمأنينة.',
    'ابدأ بما تقدر عليه، فالله يحب الصدق ولو كان العمل قليلًا.',
    'كل صلاة في وقتها إعلان أنك تختار رضا الله قبل انشغالك.',
    'عاداتك اليومية هي التي ترسم شكل قلبك على المدى الطويل.',
    'لا تنتظر الخشوع كاملًا لتبدأ، ابدأ وسيأتي الخشوع بالتدريب.',
    'من رحمته أن باب الرجوع مفتوح دائمًا، فلا تطل الوقوف خارج الباب.',
    'الصلاة لا تأخذ من وقتك، بل تعيد ترتيب وقتك.',
    'لحظة ذكر صادقة قد ترفع عنك ثقل يوم كامل.',
    'المؤمن لا يعيش بلا ضعف، لكنه لا يجعل الضعف نهاية الطريق.',
    'اجعل لك عبادة خفية لا يعلمها إلا الله.',
    'كل يوم جديد فرصة لتثبت عادة طيبة واحدة.',
    'لا تقارن بدايتك بثبات غيرك، فكل قلب له رحلته.',
    'إذا فاتك وردك، فلا تترك اليوم كله؛ خذ منه ما تستطيع.',
    'القلب يحتاج غذاءً كما يحتاج الجسد، وغذاؤه ذكر الله.',
    'ابدأ بالصلاة، ثم ستجد أن بقية اليوم أهدأ وأكثر اتزانًا.',
    'حين تحافظ على الصلاة، أنت تحمي قلبك من التشتت.',
    'العبادة لا تحتاج مزاجًا مثاليًا، بل تحتاج قرارًا صادقًا.',
    'اجعل تذكير الصلاة بداية توقف لطيف لا مصدر ضغط.',
    'كل مرة تقوم فيها رغم الكسل تربي في نفسك قوة خفية.',
    'ليس المهم أن لا تسقط، المهم أن تقوم أسرع كل مرة.',
    'القرآن لا يُقرأ فقط للإنجاز، بل للأنس والشفاء والهداية.',
    'خمس دقائق مع القرآن قد تغير زاوية نظرك ليوم كامل.',
    'الاستغفار يمسح غبار القلب ويعيد له صفاءه.',
    'كل عبادة تحفظها في يوم مزدحم لها وزن خاص.',
    'لا تستهين بدقيقة ذكر؛ فالدقيقة إذا صدقت بارك الله فيها.',
    'قلبك يهدأ حين يعرف أن له بابًا يعود إليه دائمًا.',
    'الثبات لا يعني عدم التعب، بل الاستمرار رغم التعب.',
    'اليوم الذي تبدأه بذكر الله لا يشبه غيره.',
    'اجعل الصلاة أولويتك، ثم رتّب حولها بقية يومك.',
    'من علامات الرحمة أن تتذكر الله وسط انشغالك.',
    'لا تؤجل التوبة حتى تبتعد أكثر، عد الآن ولو بخطوة.',
    'العمل الصالح لا يضيع، حتى لو لم تر أثره سريعًا.',
    'النية الطيبة تحوّل العادة إلى عبادة.',
    'تعلّم أن تحتفل بالثبات الصغير، فهو بداية الثبات الكبير.',
    'كل يوم تصلي فيه في وقتها هو بناء جديد في شخصيتك.',
    'لا تجعل التقصير القديم يمنعك من خير اليوم.',
    'القلب الذي يذكر الله كثيرًا يقل خوفه من الدنيا.',
    'التدرج في العبادة حكمة، فلا تحمل نفسك فوق طاقتها ثم تنقطع.',
    'ركعتان في هدوء قد تكونان بداية إصلاح طويل.',
    'الصحبة الصالحة تعين القلب حين تضعف الهمة.',
    'كل باب خير تفتحه اليوم قد يكون سببًا لبركة لا تعرفها.',
    'إذا تعبت، فقل: يا رب، فالدعاء بداية القوة.',
    'المداومة على الذكر تجعل قلبك أسرع رجوعًا عند الغفلة.',
    'لا تنتظر يومًا مثاليًا لتبدأ عادة صالحة.',
    'اختر عبادة واحدة اليوم وأتمها بإتقان.',
    'كل صلاة تؤديها في وقتها تقول لنفسك: أنا أستطيع الثبات.',
    'الخلوة القصيرة مع الله تعالج ضجيج اليوم.',
    'من صدق مع الله في القليل فتح الله له أبواب الكثير.',
    'سجدة واحدة بصدق خير من ساعات بلا حضور قلب.',
    'العبادة ليست قائمة مهام فقط، بل علاقة تُبنى بالحب والرجاء.',
    'احفظ قلبك من القسوة بكثرة الذكر والاستغفار.',
    'ما دمت تعود إلى الله فأنت لم تخسر الطريق.',
    'اجعل هاتفك وسيلة تذكير بالخير لا سببًا للغفلة.',
    'عندما تسمع الأذان، تذكر أن الله يدعوك لما يحييك.',
    'الانضباط في الصلاة ينعكس على بقية حياتك.',
    'كل خطوة إلى المسجد أو المصلى هي خطوة نحو طمأنينة أكبر.',
    'لا تحقر عملًا صالحًا؛ فقد يفتح الله به بابًا عظيمًا.',
    'القلب الذاكر أكثر قدرة على الصبر.',
    'اقرأ القرآن وكأن الآية تخاطبك أنت اليوم.',
    'اجعل لك موعدًا ثابتًا مع المصحف، ولو قصيرًا.',
    'لا تجعل الكمال شرطًا للبداية؛ ابدأ بما تستطيع.',
    'أقوى عادة دينية هي التي تناسب يومك فتستطيع الاستمرار عليها.',
    'حين يضعف قلبك، لا تعاتبه فقط؛ اسقه بالذكر والقرآن.',
    'كل طاعة تحفظها في السر تزيد صدقك في العلن.',
    'ليس كل تقدم ظاهرًا، بعضه يحدث في قلبك بهدوء.',
    'تذكر أن الله يرى مجاهدتك حتى لو لم يرها الناس.',
    'القيام بعد التقصير عبادة عظيمة، فلا تؤجلها.',
    'اجعل نهاية يومك استغفارًا، وبداية يومك حمدًا.',
    'الخير الذي تكرره يوميًا يصير جزءًا من هويتك.',
    'لا تجعل يومك يخلو من دعاء صادق.',
    'الذكر القصير مع حضور القلب خير من كلمات كثيرة بلا انتباه.',
    'كلما زاد انشغالك، زادت حاجتك للصلاة لا بعدها عنها.',
    'ثباتك اليوم قد يكون سبب ثباتك غدًا.',
    'العبادة تعلمك أن تبدأ من جديد كل يوم.',
    'لا تتعامل مع الصلاة كواجب ثقيل، بل كراحة متكررة.',
    'في كل يوم فرصة لقلب أن يلين ولسان أن يذكر وعمل أن يُقبل.',
    'استعن بالله ولا تعجز، وخذ من الخير ما تقدر عليه.',
    'إذا لم تستطع الكثير، فلا تترك القليل.',
    'الطاعة الصغيرة إذا داومت عليها صارت بابًا كبيرًا.',
    'طمأنينة القلب لا تُشترى، لكنها تُطلب بالصلاة والذكر.',
    'كل يوم تحفظ فيه صلاتك هو يوم ربحت فيه شيئًا عظيمًا.',
    'اجعل هدفك اليوم أن تكون أقرب إلى الله ولو بخطوة واحدة.',
    'كل عبادة تحفظها اليوم تزرع في قلبك ثقة أن الغد يمكن أن يكون أفضل.',
  ];

  String _todayItem(List<String> items, {int offset = 0}) {
    final now = DateTime.now();
    final index =
        (now.difference(DateTime(now.year)).inDays + offset) % items.length;
    return items[index];
  }

  @override
  Widget build(BuildContext context) {
    final dhikr = _todayItem(_dailyDhikr);
    final thought = _todayItem(_dailyThoughts, offset: 37);

    final size = MediaQuery.sizeOf(context);
    final bool isPhone = size.width < 600;
    final bool isFoldOrTablet = !isPhone;

    final double cardHorizontalPadding = isPhone ? 12.w : 16;
    final double cardVerticalPadding = isPhone ? 12.h : 14;

    final double titleSize = isPhone
        ? 14.sp
        : isFoldOrTablet
        ? 22
        : 14.sp;

    final double subtitleSize = isPhone
        ? 9.5.sp
        : isFoldOrTablet
        ? 14
        : 9.5.sp;

    final double titleSubtitleGap = isPhone ? 4.h : 6;
    final double headerBottomGap = isPhone ? 10.h : 14;
    final double itemGap = isPhone ? 8.h : 12;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: SizedBox(
        width: AppLayoutConstants.mainCardWidth,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bool hasBoundedHeight =
                constraints.hasBoundedHeight && constraints.maxHeight.isFinite;

            return Container(
              height: hasBoundedHeight && isFoldOrTablet
                  ? constraints.maxHeight
                  : null,
              padding: EdgeInsets.symmetric(
                horizontal: cardHorizontalPadding,
                vertical: cardVerticalPadding,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(
                  AppLayoutConstants.mainCardRadius,
                ),
                color: Theme.of(context).colorScheme.primary,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: hasBoundedHeight && isFoldOrTablet
                    ? MainAxisSize.max
                    : MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: Text(
                      'زاد يومك',
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'cairo',
                        fontSize: titleSize,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.1,
                      ),
                    ),
                  ),

                  SizedBox(height: titleSubtitleGap),

                  SizedBox(
                    width: double.infinity,
                    child: Text(
                      'ذكر وخاطرة يتجددان كل يوم لتثبيت عبادتك.',
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                      maxLines: isPhone ? 2 : 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'cairo',
                        fontSize: subtitleSize,
                        fontWeight: FontWeight.w600,
                        height: 1.25,
                        color: Colors.white.withOpacity(0.82),
                      ),
                    ),
                  ),

                  SizedBox(height: headerBottomGap),

                  if (hasBoundedHeight && isFoldOrTablet)
                    Expanded(
                      child: _DailyChangeItemsArea(
                        dhikr: dhikr,
                        thought: thought,
                        itemGap: itemGap,
                        isPhone: isPhone,
                      ),
                    )
                  else
                    _DailyChangeItemsArea(
                      dhikr: dhikr,
                      thought: thought,
                      itemGap: itemGap,
                      isPhone: isPhone,
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _DailyChangeItemsArea extends StatelessWidget {
  final String dhikr;
  final String thought;
  final double itemGap;
  final bool isPhone;

  const _DailyChangeItemsArea({
    required this.dhikr,
    required this.thought,
    required this.itemGap,
    required this.isPhone,
  });

  @override
  Widget build(BuildContext context) {
    if (isPhone) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _DailyChangeItem(
            title: 'ذكر اليوم',
            subtitle: dhikr,
            icon: Icons.auto_awesome_rounded,
            iconColor: DailyChangeContainer._greenColor,
            isPhone: true,
          ),
          SizedBox(height: itemGap),
          _DailyChangeItem(
            title: 'خاطرة اليوم',
            subtitle: thought,
            icon: Icons.lightbulb_rounded,
            iconColor: DailyChangeContainer._goldColor,
            isPhone: true,
          ),
        ],
      );
    }

    return Column(
      children: [
        Expanded(
          child: _DailyChangeItem(
            title: 'ذكر اليوم',
            subtitle: dhikr,
            icon: Icons.auto_awesome_rounded,
            iconColor: DailyChangeContainer._greenColor,
            isPhone: false,
          ),
        ),
        SizedBox(height: itemGap),
        Expanded(
          child: _DailyChangeItem(
            title: 'خاطرة اليوم',
            subtitle: thought,
            icon: Icons.lightbulb_rounded,
            iconColor: DailyChangeContainer._goldColor,
            isPhone: false,
          ),
        ),
      ],
    );
  }
}

class _DailyChangeItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final bool isPhone;

  const _DailyChangeItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.isPhone,
  });

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.sizeOf(context);
    final bool isFoldLandscape = size.width >= 600 && size.shortestSide < 600;
    final bool isTablet = size.shortestSide >= 600;

    final double horizontalPadding = isPhone
        ? 12.w
        : isFoldLandscape
        ? 12
        : 16;

    final double verticalPadding = isPhone
        ? 11.h
        : isFoldLandscape
        ? 10
        : 14;

    final double titleSize = isPhone
        ? 11.sp
        : isFoldLandscape
        ? 13
        : 16;

    final double subtitleSize = isPhone
        ? 9.5.sp
        : isFoldLandscape
        ? 11.5
        : 14;

    final double titleSubtitleGap = isPhone
        ? 5.h
        : isFoldLandscape
        ? 4
        : 6;

    final double radius = isPhone
        ? 16.r
        : isFoldLandscape
        ? 14
        : 16;

    final int subtitleLines = isPhone
        ? 3
        : isFoldLandscape
        ? 2
        : 3;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      decoration: BoxDecoration(
        color: const Color(0xff171B26),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: Colors.white.withOpacity(0.12),
          width: isPhone ? 0.8.w : 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            child: Text(
              title,
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'cairo',
                fontSize: titleSize,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                height: 1.15,
              ),
            ),
          ),

          SizedBox(height: titleSubtitleGap),

          SizedBox(
            width: double.infinity,
            child: Text(
              subtitle,
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              maxLines: subtitleLines,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'cairo',
                fontSize: subtitleSize,
                fontWeight: FontWeight.w600,
                height: isPhone ? 1.45 : 1.3,
                color: Colors.white.withOpacity(0.72),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
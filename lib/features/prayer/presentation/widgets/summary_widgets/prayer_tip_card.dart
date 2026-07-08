import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:islamic_app/shared/widgets/common_components/app_layout_constants.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';
class PrayerTipCard extends StatelessWidget {
  const PrayerTipCard({super.key, this.large = false});

  final bool large;

  static const List<String> _tips = [
    'الصلاة نور وطمأنينة، حافظ عليها في وقتها.',
    'ابدأ بالصلاة ولو بخطوة صغيرة، فالثبات يأتي بالتدرج.',
    'كل صلاة في وقتها فرصة جديدة للقرب من الله.',
    'اجعل صلاتك موعدًا ثابتًا لا تؤجله.',
    'أقرب ما يكون العبد من ربه وهو ساجد.',
    'الصلاة راحة للقلب قبل أن تكون واجبًا على الجسد.',
    'حافظ على صلاة الفجر، فهي بداية مباركة ليومك.',
    'ما فاتك من الصلاة لا تيأس منه، سجله وابدأ من جديد.',
    'الصلاة تُرتّب يومك وتُهدئ قلبك.',
    'لا تجعل زحمة اليوم تُنسيك أعظم موعد في يومك.',
    'إذا ضاق صدرك، فالصلاة باب واسع للسكينة.',
    'حافظ على الوضوء، فهو يعينك على المبادرة للصلاة.',
    'صلاتك اليوم قد تكون سببًا في بركة لا تراها الآن.',
    'لا تنتظر الفراغ للصلاة، بل اجعل الصلاة أولويتك.',
    'من حافظ على الصلاة وجد أثرها في قلبه ويومه.',
    'السجود لحظة صدق، فاجعل لك فيها دعاءً لا تتركه.',
    'الصلاة في وقتها عادة عظيمة تبدأ بقرار صغير.',
    'كلما سمعت الأذان، تذكر أن الله يدعوك للراحة.',
    'لا تجعل التأخير عادة، فالصلاة أجمل في أول وقتها.',
    'ركعتان بخشوع قد تغيّر حال قلبك كله.',
    'استعد للصلاة قبل وقتها بدقائق، فهذا يعينك على الخشوع.',
    'الصلاة ليست انقطاعًا عن يومك، بل شحنٌ لقلبك.',
    'حافظ على السنن قدر استطاعتك، فهي تزيد قربك من الله.',
    'ابدأ بالفرض، ثم زد من النوافل شيئًا فشيئًا.',
    'لا تحزن من التقصير، المهم أن تعود ولا تنقطع.',
    'اجعل لكل صلاة نية جديدة وقلبًا حاضرًا.',
    'الصلاة تعلّمك النظام، والصبر، والطمأنينة.',
    'وقت الصلاة فرصة لتترك هموم الدنيا قليلًا.',
    'كل سجدة ترفعك، فلا تحرم نفسك هذا الخير.',
    'إذا فاتتك صلاة، فبادر بقضائها ولا تؤخرها.',
    'الصلاة تحفظ القلب من الغفلة.',
    'اجعل أذكار ما بعد الصلاة جزءًا ثابتًا من يومك.',
    'خشوعك يبدأ من استعدادك قبل الصلاة.',
    'لا تستصغر صلاة واحدة، فقد تكون سببًا في هداية قلبك.',
    'الصلاة صلة بينك وبين ربك، فلا تقطعها.',
    'كل يوم تحافظ فيه على الصلاة هو انتصار جميل.',
    'ذكر نفسك دائمًا: الصلاة أولًا ثم كل شيء بعدها.',
    'الصلاة ليست عبئًا، بل رحمة وراحة ونجاة.',
    'حاول أن تصلي في مكان هادئ يساعدك على الخشوع.',
    'ثباتك على الصلاة اليوم يبني عادة قوية للغد.',
  ];

  String _todayTip() {
    final int index = DateTime.now().day % _tips.length;
    return _tips[index];
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: SizedBox(
        width: large ? double.infinity : AppLayoutConstants.mainCardWidth,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: large ? 12 : 12.w,
            vertical: large ? 10 : 11.h,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(
              large ? 18 : AppLayoutConstants.mainCardRadius,
            ),
          ),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: large ? 12 : 12.w,
              vertical: large ? 10 : 11.h,
            ),
            decoration: BoxDecoration(
              color: const Color(0xff171B26),
              borderRadius: BorderRadius.circular(large ? 15 : 16.r),
              border: Border.all(
                color: Colors.white.withOpacity(0.12),
                width: large ? 0.8 : 0.8.w,
              ),
            ),
            child: Row(
              textDirection: TextDirection.rtl,
              children: [
                Icon(
                  Icons.lightbulb_rounded,
                  color: const Color(0xffffb300),
                  size: large ? 18 : 20.sp,
                ),

                SizedBox(width: large ? 10 : 10.w),

                Expanded(
                  child: Directionality(
                    textDirection: TextDirection.rtl,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'رسالة اليوم',
                          textAlign: TextAlign.right,
                          textDirection: TextDirection.rtl,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w800,
                            color: Colors.white
),
                        ),

                        SizedBox(height: large ? 5 : 5.h),

                        Text(
                          _todayTip(),
                          textAlign: TextAlign.right,
                          textDirection: TextDirection.rtl,
                          style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w500,
                            color: Colors.white.withOpacity(0.72),
                            height: 1.45
),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
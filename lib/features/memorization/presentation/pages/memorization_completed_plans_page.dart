import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';
import 'package:islamic_app/features/memorization/data/models/memorization_active_plan_model.dart';
import 'package:islamic_app/features/memorization/data/services/memorization_plan_storage.dart';
import 'package:islamic_app/features/memorization/data/services/memorization_session_result_storage.dart';
import 'package:islamic_app/features/memorization/data/services/quran_range_label_resolver.dart';
import 'package:islamic_app/features/memorization/presentation/pages/memorization_manual_test_page.dart';
import 'package:islamic_app/features/memorization/presentation/pages/memorization_weak_spots_page.dart';
import 'package:islamic_app/features/memorization/presentation/pages/results/memorization_course_certificate_page.dart';
import 'package:islamic_app/features/memorization/results/models/memorization_course_certificate.dart';
import 'package:islamic_app/features/memorization/results/services/memorization_course_certificate_service.dart';
import 'package:islamic_app/shared/widgets/app_main_components/custom_app_bar.dart';

class MemorizationCompletedPlansPage extends StatefulWidget {
  const MemorizationCompletedPlansPage({super.key});

  @override
  State<MemorizationCompletedPlansPage> createState() =>
      _MemorizationCompletedPlansPageState();
}

class _MemorizationCompletedPlansPageState
    extends State<MemorizationCompletedPlansPage> {
  late Future<List<MemorizationActivePlanModel>> plansFuture;

  @override
  void initState() {
    super.initState();
    plansFuture = MemorizationPlanStorage.getCompletedPlans();
  }

  void _reload() {
    setState(() {
      plansFuture = MemorizationPlanStorage.getCompletedPlans();
    });
  }

  Future<void> _openCertificate(MemorizationActivePlanModel plan) async {
    final certificate = await _buildCertificate(plan);
    if (!mounted) return;

    if (certificate == null) {
      await _showCertificateError();
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            MemorizationCourseCertificatePage(certificate: certificate),
      ),
    );
  }

  Future<void> _openDetails(MemorizationActivePlanModel plan) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MemorizationCompletedPlanDetailsPage(plan: plan),
      ),
    );
    _reload();
  }

  Future<void> _openWeakSpots() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const MemorizationWeakSpotsPage(),
      ),
    );
  }

  Future<void> _openManualTest() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const MemorizationManualTestPage(),
      ),
    );
  }

  Future<MemorizationCourseCertificate?> _buildCertificate(
    MemorizationActivePlanModel plan,
  ) async {
    final results = await MemorizationSessionResultStorage.getResults();
    return const MemorizationCourseCertificateService().buildForPlan(
      plan: plan,
      results: results,
    );
  }

  Future<void> _showCertificateError() {
    final colors = Theme.of(context).colorScheme;
    return showDialog<void>(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: colors.background,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22.r),
            ),
            title: Text(
              'تعذر تجهيز الشهادة الآن',
              textAlign: TextAlign.right,
              style: AppTextStyles.body(
                context,
              ).copyWith(color: colors.surface, fontWeight: FontWeight.w900),
            ),
            content: Text(
              'الخطة مكتملة، لكن بيانات الشهادة غير جاهزة الآن. جرّب مرة أخرى لاحقًا.',
              textAlign: TextAlign.right,
              style: AppTextStyles.caption(
                context,
              ).copyWith(color: colors.surface.withOpacity(0.68), height: 1.5),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('حسناً'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            const CustomAppBar(
              category: CustomAppBarCategory(text: 'الخطط المكتملة'),
            ),
            Expanded(
              child: FutureBuilder<List<MemorizationActivePlanModel>>(
                future: plansFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final plans = snapshot.data ?? const [];
                  if (plans.isEmpty) {
                    return const _CompletedPlansEmptyState();
                  }

                  return ListView.separated(
                    padding: EdgeInsets.fromLTRB(14.w, 10.h, 14.w, 24.h),
                    itemCount: plans.length,
                    separatorBuilder: (_, __) => SizedBox(height: 12.h),
                    itemBuilder: (context, index) {
                      final plan = plans[index];
                      return _CompletedPlanCard(
                        plan: plan,
                        onDetailsTap: () => _openDetails(plan),
                        onCertificateTap: () => _openCertificate(plan),
                        onWeakSpotsTap: _openWeakSpots,
                        onRetestTap: _openManualTest,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MemorizationCompletedPlanDetailsPage extends StatelessWidget {
  const MemorizationCompletedPlanDetailsPage({super.key, required this.plan});

  final MemorizationActivePlanModel plan;

  Future<MemorizationCourseCertificate?> _certificate() async {
    final results = await MemorizationSessionResultStorage.getResults();
    return const MemorizationCourseCertificateService().buildForPlan(
      plan: plan,
      results: results,
    );
  }

  Future<void> _openCertificate(BuildContext context) async {
    final certificate = await _certificate();
    if (certificate == null || !context.mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            MemorizationCourseCertificatePage(certificate: certificate),
      ),
    );
  }

  Future<void> _openManualTest(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const MemorizationManualTestPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            const CustomAppBar(
              category: CustomAppBarCategory(text: 'تفاصيل الخطة المكتملة'),
            ),
            Expanded(
              child: FutureBuilder<MemorizationCourseCertificate?>(
                future: _certificate(),
                builder: (context, snapshot) {
                  final certificate = snapshot.data;
                  return SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(14.w, 10.h, 14.w, 24.h),
                    child: _CompletedPlanDetailsCard(
                      plan: plan,
                      certificate: certificate,
                      onCertificateTap: certificate == null
                          ? null
                          : () => _openCertificate(context),
                      onRetestTap: () => _openManualTest(context),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompletedPlansEmptyState extends StatelessWidget {
  const _CompletedPlansEmptyState();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(22.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.workspace_premium_outlined,
              color: colors.primary,
              size: 42.sp,
            ),
            SizedBox(height: 12.h),
            Text(
              'لم تُكمل أي خطة بعد',
              textAlign: TextAlign.center,
              style: AppTextStyles.body(context).copyWith(
                color: colors.surface,
                fontSize: 17.sp,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              'عند إتمام خطة حفظ، ستظهر هنا مع نتائجها وشهادة الإتمام الرمزية.',
              textAlign: TextAlign.center,
              style: AppTextStyles.caption(context).copyWith(
                color: colors.surface.withOpacity(0.62),
                fontSize: 13.sp,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompletedPlanCard extends StatelessWidget {
  const _CompletedPlanCard({
    required this.plan,
    required this.onDetailsTap,
    required this.onCertificateTap,
    required this.onWeakSpotsTap,
    required this.onRetestTap,
  });

  final MemorizationActivePlanModel plan;
  final VoidCallback onDetailsTap;
  final VoidCallback onCertificateTap;
  final VoidCallback onWeakSpotsTap;
  final VoidCallback onRetestTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? colors.surface : const Color(0xFF18385F);
    final cardColor = isDark ? colors.secondary : Colors.white;
    final borderColor = isDark
        ? colors.outline.withOpacity(0.12)
        : const Color(0xFFE7EDF5);
    final completedAt = plan.completedAt ?? plan.updatedAt;
    final durationDays = completedAt.difference(plan.createdAt).inDays + 1;

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: borderColor, width: 0.8.w),
      ),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              plan.planName,
              textAlign: TextAlign.right,
              style: AppTextStyles.body(context).copyWith(
                color: textColor,
                fontSize: 16.sp,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 7.h),
            Text(
              const QuranRangeLabelResolver()
                  .resolveAyahs(
                    startGlobalAyahIndex: plan.scopeStartGlobalAyahIndex,
                    endGlobalAyahIndex: plan.scopeEndGlobalAyahIndex,
                  )
                  .displayLabel,
              textAlign: TextAlign.right,
              softWrap: true,
              style: AppTextStyles.caption(context).copyWith(
                color: textColor.withOpacity(0.68),
                fontSize: 13.sp,
                height: 1.45,
              ),
            ),
            SizedBox(height: 12.h),
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              alignment: WrapAlignment.end,
              children: [
                _InfoChip(label: 'البداية', value: _formatDate(plan.createdAt)),
                _InfoChip(label: 'الإتمام', value: _formatDate(completedAt)),
                _InfoChip(label: 'المدة', value: '$durationDays يوم'),
                const _InfoChip(label: 'الإنجاز', value: '100%'),
                _InfoChip(
                  label: 'الدرجة',
                  value: '${plan.finalCourseScore ?? 100}%',
                ),
              ],
            ),
            SizedBox(height: 13.h),
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              alignment: WrapAlignment.end,
              children: [
                _PlanActionChip(label: 'عرض التفاصيل', onTap: onDetailsTap),
                _PlanActionChip(label: 'عرض الشهادة', onTap: onCertificateTap),
                _PlanActionChip(
                  label: 'مراجعة المواضع الضعيفة',
                  onTap: onWeakSpotsTap,
                ),
                _PlanActionChip(label: 'اختبار مرة أخرى', onTap: onRetestTap),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CompletedPlanDetailsCard extends StatelessWidget {
  const _CompletedPlanDetailsCard({
    required this.plan,
    required this.certificate,
    required this.onCertificateTap,
    required this.onRetestTap,
  });

  final MemorizationActivePlanModel plan;
  final MemorizationCourseCertificate? certificate;
  final VoidCallback? onCertificateTap;
  final VoidCallback onRetestTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? colors.surface : const Color(0xFF18385F);
    final cardColor = isDark ? colors.secondary : Colors.white;
    final borderColor = isDark
        ? colors.outline.withOpacity(0.12)
        : const Color(0xFFE7EDF5);
    final completedAt = plan.completedAt ?? plan.updatedAt;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: borderColor, width: 0.8.w),
      ),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              plan.planName,
              textAlign: TextAlign.right,
              style: AppTextStyles.body(context).copyWith(
                color: textColor,
                fontSize: 17.sp,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 12.h),
            _DetailLine('النطاق المحفوظ', plan.scopeTitle),
            _DetailLine('تاريخ البداية', _formatDate(plan.createdAt)),
            _DetailLine('تاريخ الإتمام', _formatDate(completedAt)),
            _DetailLine('إجمالي الأيام', '${plan.targetLearningDays} يوم'),
            _DetailLine('نسبة إنجاز الحفظ', '100%'),
            _DetailLine(
              'نسبة الالتزام',
              '${certificate?.commitmentPercent ?? 100}%',
            ),
            _DetailLine(
              'متوسط الاختبارات',
              certificate == null
                  ? 'غير متاح الآن'
                  : (certificate!.testsEnabled
                        ? '${certificate!.testsAveragePercent}%'
                        : 'لم تكن الاختبارات مفعّلة في هذه الخطة'),
            ),
            _DetailLine('نسبة المراجعة', '${certificate?.reviewPercent ?? 0}%'),
            _DetailLine(
              'الدرجة النهائية',
              '${certificate?.finalScore ?? plan.finalCourseScore ?? 100}%',
            ),
            SizedBox(height: 14.h),
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              alignment: WrapAlignment.end,
              children: [
                _PlanActionChip(label: 'عرض الشهادة', onTap: onCertificateTap),
                _PlanActionChip(
                  label: 'إعادة اختبار نفس النطاق',
                  onTap: onRetestTap,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 7.h),
      decoration: BoxDecoration(
        color: colors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Text(
        '$label: $value',
        textDirection: TextDirection.rtl,
        style: AppTextStyles.caption(context).copyWith(
          color: colors.surface,
          fontSize: 12.sp,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _PlanActionChip extends StatelessWidget {
  const _PlanActionChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final enabled = onTap != null;
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: enabled
            ? colors.primary
            : colors.primary.withOpacity(0.35),
        side: BorderSide(color: colors.primary.withOpacity(0.22)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
      ),
      child: Text(
        label,
        textDirection: TextDirection.rtl,
        style: AppTextStyles.caption(
          context,
        ).copyWith(fontSize: 14.sp, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(bottom: 9.h),
      child: Row(
        textDirection: TextDirection.rtl,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112.w,
            child: Text(
              label,
              textAlign: TextAlign.right,
              style: AppTextStyles.caption(context).copyWith(
                color: colors.primary,
                fontSize: 13.sp,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              softWrap: true,
              style: AppTextStyles.caption(context).copyWith(
                color: colors.surface,
                fontSize: 13.sp,
                height: 1.45,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatDate(DateTime date) {
  return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
}

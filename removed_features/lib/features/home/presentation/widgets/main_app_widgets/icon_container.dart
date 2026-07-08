import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:islamic_app/features/prayer/pray_page.dart';
import 'package:islamic_app/shared/widgets/common_components/app_layout_constants.dart';
import 'package:islamic_app/features/home/presentation/dashboard_customizer/dashboard_customize_service.dart';
import 'package:islamic_app/core/services/app_haptics.dart';

import ' hijrii_date.dart';
import 'package:islamic_app/features/hadith/ahadeth_page.dart';
import 'package:islamic_app/features/islamic_events/pages/islamic_events_page.dart';
import 'package:islamic_app/features/night_pray/night_pray_page.dart';
import 'package:islamic_app/features/azkar/zekr_page.dart';
import 'package:islamic_app/features/quran/quran_page.dart';
import 'hijri_calendar_bottom_sheet.dart';
import 'icons_main_widget.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';
class IconContainer extends StatelessWidget {
  IconContainer({
    super.key,
    this.isEditMode = false,
    this.worshipOrder = DashboardCustomizeService.defaultWorshipOrder,
    this.onWorshipReorder,
  });

  final bool isEditMode;
  final List<String> worshipOrder;
  final void Function(String draggedId, String targetId)? onWorshipReorder;

  final hijriArabic = HijriiDate.getTodayHijri();

  static const List<String> _fallbackOrder =
      DashboardCustomizeService.defaultWorshipOrder;

  @override
  Widget build(BuildContext context) {
    final orderedItems = _orderedWorshipItems(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: SizedBox(
        width: AppLayoutConstants.mainCardWidth,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: 12.w,
            vertical: 12.h,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(
              AppLayoutConstants.mainCardRadius,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                textDirection: TextDirection.rtl,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: Text(
                            'ثبت عبادتك',
                            textAlign: TextAlign.right,
                            textDirection: TextDirection.rtl,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w800,
                              color: Colors.white
),
                          ),
                        ),

                        SizedBox(height: 4.h),

                        SizedBox(
                          width: double.infinity,
                          child: Text(
                            'اختر القسم الذي تريد متابعته اليوم.',
                            textAlign: TextAlign.right,
                            textDirection: TextDirection.rtl,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w600,
                              height: 1.45,
                              color: Colors.white.withOpacity(0.82)
),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 8.w),
                  InkWell(
                    borderRadius: BorderRadius.circular(12.r),
                    onTap: isEditMode
                        ? null
                        : () {
                            HijriCalendarBottomSheet.show(context);
                          },
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 9.w,
                        vertical: 6.h,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xff171B26),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Text(
                        hijriArabic,
                        textAlign: TextAlign.center,
                        textDirection: TextDirection.rtl,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 12.h),

              _WorshipRow(
                children: orderedItems.take(3).toList(growable: false),
              ),

              SizedBox(height: 8.h),

              _WorshipRow(
                children: orderedItems.skip(3).take(3).toList(growable: false),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _orderedWorshipItems(BuildContext context) {
    final safeOrder = <String>[];

    for (final id in worshipOrder) {
      if (_fallbackOrder.contains(id) && !safeOrder.contains(id)) {
        safeOrder.add(id);
      }
    }

    for (final id in _fallbackOrder) {
      if (!safeOrder.contains(id)) {
        safeOrder.add(id);
      }
    }

    return safeOrder.map((id) {
      final item = _buildWorshipItem(context, id);

      if (!isEditMode) return item;

      return _EditableWorshipTile(
        id: id,
        title: DashboardCustomizeService.worshipTitle(id),
        onDropped: (draggedId) {
          onWorshipReorder?.call(draggedId, id);
        },
        child: item,
      );
    }).toList(growable: false);
  }

  Widget _buildWorshipItem(BuildContext context, String id) {
    switch (id) {
      case WorshipTileIds.prayer:
        return IconsMainWidget(
          category: const Category(
            image: 'assets/icons/pray (3).png',
            text: 'الصلاة',
          ),
          onTap: () {
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    const PrayPage(),
                transitionDuration: Duration.zero,
                reverseTransitionDuration: Duration.zero,
              ),
            );
          },
        );
      case WorshipTileIds.quran:
        return IconsMainWidget(
          category: const Category(
            image: 'assets/icons/QuRan.png',
            text: 'قرآن',
          ),
          onTap: () {
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    const QuranPage(),
                transitionDuration: Duration.zero,
                reverseTransitionDuration: Duration.zero,
              ),
            );
          },
        );
      case WorshipTileIds.nightPrayer:
        return IconsMainWidget(
          category: const Category(
            image: 'assets/icons/prayerMat.png',
            text: 'قيام الليل',
          ),
          onTap: () {
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    const NightPrayPage(),
                transitionDuration: Duration.zero,
                reverseTransitionDuration: Duration.zero,
              ),
            );
          },
        );
      case WorshipTileIds.azkar:
        return IconsMainWidget(
          category: const Category(
            image: 'assets/icons/bead.png',
            text: 'أذكار',
          ),
          onTap: () {
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    const ZekrPage(),
                transitionDuration: Duration.zero,
                reverseTransitionDuration: Duration.zero,
              ),
            );
          },
        );
      case WorshipTileIds.hadith:
        return IconsMainWidget(
          category: const Category(
            image: 'assets/icons/boook.png',
            text: 'أحاديث',
          ),
          onTap: () {
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    const Ahadethpage(),
                transitionDuration: Duration.zero,
                reverseTransitionDuration: Duration.zero,
              ),
            );
          },
        );
      case WorshipTileIds.events:
      default:
        return IconsMainWidget(
          category: const Category(
            image: 'assets/icons/calendar.png',
            text: 'مناسبات',
          ),
          onTap: () {
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    const IslamicEventsPage(),
                transitionDuration: Duration.zero,
                reverseTransitionDuration: Duration.zero,
              ),
            );
          },
        );
    }
  }
}

class _WorshipRow extends StatelessWidget {
  const _WorshipRow({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Row(
      textDirection: TextDirection.rtl,
      children: [
        for (int index = 0; index < children.length; index++) ...[
          Expanded(child: children[index]),
          if (index != children.length - 1) SizedBox(width: 8.w),
        ],
      ],
    );
  }
}

class _EditableWorshipTile extends StatefulWidget {
  const _EditableWorshipTile({
    required this.id,
    required this.title,
    required this.onDropped,
    required this.child,
  });

  final String id;
  final String title;
  final ValueChanged<String> onDropped;
  final Widget child;

  @override
  State<_EditableWorshipTile> createState() => _EditableWorshipTileState();
}

class _EditableWorshipTileState extends State<_EditableWorshipTile> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return DragTarget<String>(
      onWillAcceptWithDetails: (details) {
        if (!details.data.startsWith('worship::')) return false;
        final draggedId = details.data.substring('worship::'.length);
        final accept = draggedId != widget.id;
        if (accept && !_hovering) {
          setState(() => _hovering = true);
        }
        return accept;
      },
      onLeave: (_) {
        if (_hovering) setState(() => _hovering = false);
      },
      onAcceptWithDetails: (details) {
        if (_hovering) setState(() => _hovering = false);
        AppHaptics.medium(context);
        final draggedId = details.data.substring('worship::'.length);
        widget.onDropped(draggedId);
      },
      builder: (context, candidateData, rejectedData) {
        return LongPressDraggable<String>(
          data: 'worship::${widget.id}',
          hapticFeedbackOnStart: true,
          feedback: Material(
            color: Colors.transparent,
            child: SizedBox(
              width: 82.w,
              child: Opacity(
                opacity: 0.92,
                child: widget.child,
              ),
            ),
          ),
          childWhenDragging: Opacity(
            opacity: 0.35,
            child: _decoratedChild(),
          ),
          child: _decoratedChild(),
        );
      },
    );
  }

  Widget _decoratedChild() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: _hovering
              ? const Color(0xff21C58E)
              : Colors.white.withOpacity(0.22),
          width: _hovering ? 1.4.w : 0.8.w,
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          IgnorePointer(child: widget.child),
          PositionedDirectional(
            top: -7.h,
            end: -4.w,
            child: Container(
              width: 20.w,
              height: 20.h,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Color(0xff21C58E),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.drag_indicator_rounded,
                color: Colors.white,
                size: 12.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

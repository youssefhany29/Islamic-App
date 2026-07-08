import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:islamic_app/core/services/app_haptics.dart';

import 'dashboard_customize_service.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';
class EditableDashboardShell extends StatefulWidget {
  const EditableDashboardShell({
    super.key,
    required this.id,
    required this.title,
    required this.isEditMode,
    required this.isHidden,
    required this.isWideVideo,
    required this.canHide,
    required this.canResize,
    required this.onSwap,
    required this.onHide,
    required this.onToggleVideoSize,
    this.allowChildInteractionInEditMode = false,
    required this.child,
  });

  final String id;
  final String title;
  final bool isEditMode;
  final bool isHidden;
  final bool isWideVideo;
  final bool canHide;
  final bool canResize;
  final ValueChanged<String> onSwap;
  final VoidCallback onHide;
  final VoidCallback onToggleVideoSize;
  final bool allowChildInteractionInEditMode;
  final Widget child;

  @override
  State<EditableDashboardShell> createState() => _EditableDashboardShellState();
}

class _EditableDashboardShellState extends State<EditableDashboardShell> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    if (widget.isHidden) return const SizedBox.shrink();

    final content = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      padding: widget.isEditMode ? EdgeInsets.all(3.w) : EdgeInsets.zero,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.r),
        border: widget.isEditMode
            ? Border.all(
                color: _hovering
                    ? const Color(0xff21C58E)
                    : Colors.white.withOpacity(0.20),
                width: _hovering ? 1.5.w : 1.w,
              )
            : null,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          IgnorePointer(
            ignoring: widget.isEditMode && !widget.allowChildInteractionInEditMode,
            child: AnimatedOpacity(
              opacity: widget.isEditMode ? 0.96 : 1,
              duration: const Duration(milliseconds: 160),
              child: widget.child,
            ),
          ),
          if (widget.isEditMode)
            PositionedDirectional(
              top: -8.h,
              start: 6.w,
              child: _DragHandle(
                title: widget.title,
                dragId: widget.id,
              ),
            ),
          if (widget.isEditMode)
            PositionedDirectional(
              top: -8.h,
              end: 6.w,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.canResize)
                    _EditChipButton(
                      icon: widget.isWideVideo
                          ? Icons.view_agenda_rounded
                          : Icons.view_week_rounded,
                      tooltip: widget.isWideVideo ? 'نصف عرض' : 'عرض كامل',
                      onTap: widget.onToggleVideoSize,
                    ),
                  if (widget.canResize) SizedBox(width: 6.w),
                  if (widget.canHide)
                    _EditChipButton(
                      icon: Icons.visibility_off_rounded,
                      tooltip: 'إخفاء',
                      onTap: widget.onHide,
                    ),
                ],
              ),
            ),
        ],
      ),
    );

    if (!widget.isEditMode) return content;

    return DragTarget<String>(
      onWillAcceptWithDetails: (details) {
        if (!details.data.startsWith('main::')) return false;
        final draggedId = details.data.substring('main::'.length);
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
        final draggedId = details.data.substring('main::'.length);
        widget.onSwap(draggedId);
      },
      builder: (context, candidateData, rejectedData) => content,
    );
  }
}

class _DragHandle extends StatelessWidget {
  const _DragHandle({
    required this.title,
    required this.dragId,
  });

  final String title;
  final String dragId;

  @override
  Widget build(BuildContext context) {
    return LongPressDraggable<String>(
      data: 'main::$dragId',
      hapticFeedbackOnStart: true,
      feedback: Material(
        color: Colors.transparent,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 7.h),
          decoration: BoxDecoration(
            color: const Color(0xff171B26).withOpacity(0.95),
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(
              color: const Color(0xff21C58E).withOpacity(0.75),
              width: 1.w,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 16.r,
                offset: Offset(0, 8.h),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            textDirection: TextDirection.rtl,
            children: [
              Icon(
                Icons.drag_indicator_rounded,
                color: Colors.white,
                size: 16.sp,
              ),
              SizedBox(width: 4.w),
              Text(
                title,
                textDirection: TextDirection.rtl,
                style: AppTextStyles.caption(context).copyWith(
color: Colors.white,
fontWeight: FontWeight.w800
),
              ),
            ],
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.35,
        child: _HandlePill(title: title),
      ),
      child: _HandlePill(title: title),
    );
  }
}

class _HandlePill extends StatelessWidget {
  const _HandlePill({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 26.h,
      padding: EdgeInsets.symmetric(horizontal: 8.w),
      decoration: BoxDecoration(
        color: const Color(0xff21C58E),
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 10.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        textDirection: TextDirection.rtl,
        children: [
          Icon(
            Icons.drag_indicator_rounded,
            color: Colors.white,
            size: 14.sp,
          ),
          SizedBox(width: 2.w),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 82.w),
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textDirection: TextDirection.rtl,
              style: AppTextStyles.caption(context).copyWith(
color: Colors.white,
fontWeight: FontWeight.w800
),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditChipButton extends StatelessWidget {
  const _EditChipButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(18.r),
        onTap: () {
          AppHaptics.tap(context);
          onTap();
        },
        child: Container(
          width: 26.w,
          height: 26.h,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xff171B26),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withOpacity(0.18),
              width: 0.8.w,
            ),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 14.sp,
          ),
        ),
      ),
    );
  }
}

class DashboardEditTopBar extends StatelessWidget {
  const DashboardEditTopBar({
    super.key,
    required this.hiddenCount,
    required this.onDone,
    required this.onReset,
    required this.onShowHidden,
  });

  final int hiddenCount;
  final VoidCallback onDone;
  final VoidCallback onReset;
  final VoidCallback onShowHidden;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 9.h),
        decoration: BoxDecoration(
          color: const Color(0xff171B26).withOpacity(0.94),
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(
            color: const Color(0xff21C58E).withOpacity(0.28),
            width: 0.8.w,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _TopBarButton(
              title: hiddenCount == 0 ? 'المخفية' : 'المخفية $hiddenCount',
              icon: Icons.visibility_rounded,
              onTap: onShowHidden,
            ),
            SizedBox(width: 6.w),
            _TopBarButton(
              title: 'إعادة',
              icon: Icons.restart_alt_rounded,
              onTap: onReset,
            ),
            SizedBox(width: 6.w),
            _TopBarButton(
              title: 'تم',
              icon: Icons.check_rounded,
              onTap: onDone,
              isPrimary: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBarButton extends StatelessWidget {
  const _TopBarButton({
    required this.title,
    required this.icon,
    required this.onTap,
    this.isPrimary = false,
  });

  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14.r),
      onTap: () {
        AppHaptics.tap(context);
        onTap();
      },
      child: Container(
        height: 30.h,
        padding: EdgeInsets.symmetric(horizontal: 7.w),
        decoration: BoxDecoration(
          color: isPrimary ? const Color(0xff21C58E) : Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 13.sp,
            ),
            SizedBox(width: 2.w),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w800,
                color: Colors.white
),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> showHiddenDashboardTilesSheet({
  required BuildContext context,
  required DashboardCustomizeState state,
  required ValueChanged<String> onRestore,
}) async {
  final hiddenIds = state.hiddenTileIds.toList(growable: false);

  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetContext) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          margin: EdgeInsets.all(12.w),
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(24.r),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'الكروت المخفية',
                  textAlign: TextAlign.right,
                  style: AppTextStyles.body(context).copyWith(
fontWeight: FontWeight.w900,
                    color: Colors.white
),
                ),
                SizedBox(height: 10.h),
                if (hiddenIds.isEmpty)
                  Text(
                    'لا يوجد كروت مخفية حاليًا.',
                    textAlign: TextAlign.right,
                    style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.70)
),
                  )
                else
                  ...hiddenIds.map(
                    (id) => Padding(
                      padding: EdgeInsets.only(bottom: 8.h),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16.r),
                        onTap: () {
                          Navigator.pop(sheetContext);
                          onRestore(id);
                        },
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 10.h,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xff171B26),
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                          child: Row(
                            textDirection: TextDirection.rtl,
                            children: [
                              Expanded(
                                child: Text(
                                  DashboardCustomizeService.tileTitle(id),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.right,
                                  style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w800,
                                    color: Colors.white
),
                                ),
                              ),
                              SizedBox(width: 8.w),
                              Icon(
                                Icons.add_circle_outline_rounded,
                                color: const Color(0xff21C58E),
                                size: 18.sp,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

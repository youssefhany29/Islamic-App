import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:islamic_app/shared/widgets/app_main_components/custom_app_bar.dart';
import 'package:islamic_app/core/theme/app_typography.dart';
import 'package:islamic_app/core/services/app_haptics.dart';
import 'package:islamic_app/features/hadith/presentation/widgets/hadith_memory_training_card.dart';
import 'package:islamic_app/features/hadith/data/models/hadith_category_model.dart';
import 'package:islamic_app/features/hadith/data/models/hadith_item_model.dart';
import 'package:islamic_app/features/hadith/data/services/hadith_custom_storage_service.dart';
import 'package:islamic_app/features/hadith/data/services/hadith_progress_service.dart';
import 'package:islamic_app/features/hadith/data/services/hadith_memory_plan_preferences.dart';
import 'add_custom_hadith_page.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';
part 'hadith_item_details_widgets.dart';

class HadithItemDetailsPage extends StatefulWidget {
  const HadithItemDetailsPage({
    super.key,
    required this.category,
    required this.item,
    this.items,
    this.initialIndex = 0,
  });

  final HadithCategoryModel category;
  final HadithItemModel item;
  final List<HadithItemModel>? items;
  final int initialIndex;

  @override
  State<HadithItemDetailsPage> createState() => _HadithItemDetailsPageState();
}

class _HadithItemDetailsPageState extends State<HadithItemDetailsPage> {
  static const String _swipeHintSeenKey = 'hadith_details_swipe_hint_seen_v1';

  final HadithProgressService _progressService = const HadithProgressService();
  final HadithCustomStorageService _customStorageService =
      const HadithCustomStorageService();

  final HadithMemoryPlanPreferences _memoryPlanPreferences =
      const HadithMemoryPlanPreferences();

  late final List<HadithItemModel> _items;
  late final PageController _pageController;
  late int _currentIndex;

  bool _memoryPlanEnabled = false;
  int _counter = 0;
  bool _isCompleted = false;

  HadithItemModel get item => _items[_currentIndex];
  bool get _canSwipeBetweenItems => _items.length > 1;

  @override
  void initState() {
    super.initState();

    _items = (widget.items == null || widget.items!.isEmpty)
        ? <HadithItemModel>[widget.item]
        : List<HadithItemModel>.from(widget.items!);

    final int itemIndex = _items.indexWhere(
      (element) => element.id == widget.item.id,
    );
    final int fallbackIndex = itemIndex == -1 ? widget.initialIndex : itemIndex;
    _currentIndex = fallbackIndex.clamp(0, _items.length - 1);

    _pageController = PageController(initialPage: _currentIndex);

    _loadCompletedState();
    _loadMemoryPlanState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _recordCurrentHadithRead();
      _showSwipeHintOnceIfNeeded();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadMemoryPlanState() async {
    final enabled = await _memoryPlanPreferences.isEnabled();

    if (!mounted) return;

    setState(() {
      _memoryPlanEnabled = enabled;
    });
  }

  Future<void> _loadCompletedState() async {
    final String currentItemId = item.id;

    final completed = await _progressService.isItemCompletedToday(
      categoryId: widget.category.id,
      itemId: currentItemId,
    );

    if (!mounted || item.id != currentItemId) return;

    setState(() {
      _isCompleted = completed;
      _counter = completed ? item.count : 0;
    });
  }

  void _onPageChanged(int index) {
    if (_currentIndex == index) return;

    AppHaptics.tap(context);

    setState(() {
      _currentIndex = index;
      _isCompleted = false;
      _counter = 0;
    });

    _loadCompletedState();
    _recordCurrentHadithRead();
  }

  Future<void> _recordCurrentHadithRead() async {
    await _progressService.recordHadithRead(
      categoryId: widget.category.id,
      itemId: item.id,
    );
  }

  Future<void> _increment() async {
    if (_isCompleted) return;

    AppHaptics.tap(context);

    final int safeCount = item.count <= 0 ? 1 : item.count;
    final int next = _counter + 1;

    setState(() {
      _counter = next > safeCount ? safeCount : next;
    });

    if (_counter >= safeCount) {
      await _markCompleted();
    }
  }

  Future<void> _markCompleted() async {
    await _progressService.markItemCompleted(
      categoryId: widget.category.id,
      itemId: item.id,
    );

    if (!mounted) return;

    setState(() {
      _isCompleted = true;
      _counter = item.count <= 0 ? 1 : item.count;
    });
  }

  Future<void> _unmarkCompleted() async {
    await _progressService.unmarkItemCompleted(
      categoryId: widget.category.id,
      itemId: item.id,
    );

    if (!mounted) return;

    setState(() {
      _isCompleted = false;
      _counter = 0;
    });
  }

  Future<void> _editCustomHadith() async {
    AppHaptics.tap(context);

    final bool? changed = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddCustomHadithPage(itemToEdit: item)),
    );

    if (changed == true && mounted) {
      Navigator.pop(context, true);
    }
  }

  Future<void> _deleteCustomHadith() async {
    AppHaptics.tap(context);

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);

        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: theme.colorScheme.secondary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.r),
            ),
            title: Text(
              'حذف الحديث؟',
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              style: AppTextStyles.body(context).copyWith(
                fontWeight: FontWeight.w900,
                color: theme.colorScheme.surface,
              ),
            ),
            content: Text(
              'سيتم حذف هذا الحديث من أحاديثي الخاصة فقط.',
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              style: AppTextStyles.caption(context).copyWith(
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.surface.withOpacity(0.70),
                height: 1.6,
              ),
            ),
            actionsAlignment: MainAxisAlignment.start,
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: theme.colorScheme.error,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: const Text('حذف'),
              ),
            ],
          ),
        );
      },
    );

    if (shouldDelete != true) return;

    await _customStorageService.deleteCustomHadith(item.id);

    if (!mounted) return;

    Navigator.pop(context, true);
  }

  Future<void> _showSwipeHintOnceIfNeeded() async {
    if (!_canSwipeBetweenItems || !mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final alreadySeen = prefs.getBool(_swipeHintSeenKey) ?? false;

    if (alreadySeen || !mounted) return;

    await prefs.setBool(_swipeHintSeenKey, true);

    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);
        final bool isDark = theme.brightness == Brightness.dark;

        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: theme.colorScheme.secondary,
            insetPadding: EdgeInsets.symmetric(horizontal: 24.w),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22.r),
            ),
            titlePadding: EdgeInsets.fromLTRB(18.w, 18.h, 18.w, 0),
            contentPadding: EdgeInsets.fromLTRB(18.w, 12.h, 18.w, 4.h),
            actionsPadding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 12.h),
            title: Row(
              children: [
                Container(
                  width: 36.w,
                  height: 36.w,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(
                      isDark ? 0.18 : 0.10,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.swipe_rounded,
                    color: theme.colorScheme.primary,
                    size: 19.sp,
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(
                    'تنقّل أسهل بين الأحاديث',
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                    style: AppTextStyles.body(context).copyWith(
                      fontWeight: FontWeight.w900,
                      color: theme.colorScheme.surface,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
            content: Text(
              'تقدر تسحب يمين أو شمال للانتقال بين أحاديث نفس القسم بدون الرجوع للقائمة.',
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              style: AppTextStyles.caption(context).copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.surface.withOpacity(0.72),
                height: 1.65,
              ),
            ),
            actionsAlignment: MainAxisAlignment.start,
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(
                  'فهمت',
                  style: AppTextStyles.caption(context).copyWith(
                    fontWeight: FontWeight.w900,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  bool _isLargeScreen(BuildContext context) {
    final Size size = MediaQuery.sizeOf(context);
    return size.shortestSide >= 600 ||
        (size.width >= 700 && size.height >= 500);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: CustomAppBar(
        category: CustomAppBarCategory(text: widget.category.title),
      ),
      body: SafeArea(
        child: PageView.builder(
          controller: _pageController,
          reverse: true,
          physics: _canSwipeBetweenItems
              ? const BouncingScrollPhysics()
              : const NeverScrollableScrollPhysics(),
          itemCount: _items.length,
          onPageChanged: _onPageChanged,
          itemBuilder: (context, index) {
            return _buildHadithDetailsList(_items[index]);
          },
        ),
      ),
    );
  }

  Widget _buildHadithDetailsList(HadithItemModel pageItem) {
    final bool isActivePage = pageItem.id == item.id;
    final int safeCount = pageItem.count <= 0 ? 1 : pageItem.count;
    final int pageCounter = isActivePage ? _counter : 0;
    final bool pageCompleted = isActivePage ? _isCompleted : false;
    final double progress = safeCount == 0 ? 0 : pageCounter / safeCount;

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isLargeScreen = _isLargeScreen(context);
        final double horizontalPadding = isLargeScreen ? 20 : 14.w;
        final double topPadding = isLargeScreen ? 12 : 8.h;
        final double bottomPadding = isLargeScreen ? 28 : 20.h;
        final double maxContentWidth = constraints.maxWidth >= 980
            ? 920
            : double.infinity;

        return ListView(
          key: PageStorageKey<String>('hadith_details_${pageItem.id}'),
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            topPadding,
            horizontalPadding,
            bottomPadding,
          ),
          physics: const BouncingScrollPhysics(),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxContentWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _HeaderCard(
                      title: widget.category.title,
                      categoryTitle: pageItem.title ?? widget.category.title,
                      isCompleted: pageCompleted,
                    ),
                    if (pageItem.isCustom) ...[
                      SizedBox(height: isLargeScreen ? 14 : 12.h),
                      _CustomActionsCard(
                        onEdit: _editCustomHadith,
                        onDelete: _deleteCustomHadith,
                      ),
                    ],
                    SizedBox(height: isLargeScreen ? 14 : 12.h),
                    _HadithFullTextCard(
                      item: pageItem,
                      reference: pageItem.reference,
                    ),
                    SizedBox(height: isLargeScreen ? 14 : 12.h),
                    if (_memoryPlanEnabled) ...[
                      HadithMemoryTrainingCard(
                        item: pageItem,
                        categoryId: widget.category.id,
                        categoryTitle: widget.category.title,
                      ),
                      SizedBox(height: isLargeScreen ? 14 : 12.h),
                    ],
                    if (pageItem.source != null ||
                        pageItem.benefit != null) ...[
                      SizedBox(height: isLargeScreen ? 14 : 12.h),
                      _InfoCard(
                        source: pageItem.source,
                        benefit: pageItem.benefit,
                      ),
                    ],
                    SizedBox(height: isLargeScreen ? 14 : 12.h),
                    _CounterCard(
                      item: pageItem,
                      counter: pageCounter,
                      total: safeCount,
                      progress: progress.clamp(0.0, 1.0).toDouble(),
                      isCompleted: pageCompleted,
                      onIncrement: _increment,
                      onMarkCompleted: _markCompleted,
                      onUnmarkCompleted: _unmarkCompleted,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

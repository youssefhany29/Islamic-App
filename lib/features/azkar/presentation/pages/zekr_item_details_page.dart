import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:islamic_app/shared/widgets/app_main_components/custom_app_bar.dart';
import 'package:islamic_app/core/theme/app_typography.dart';
import 'package:islamic_app/core/services/app_haptics.dart';
import 'package:islamic_app/features/azkar/presentation/widgets/zekr_memory_training_card.dart';
import 'package:islamic_app/features/azkar/data/models/zekr_category_model.dart';
import 'package:islamic_app/features/azkar/data/models/zekr_item_model.dart';
import 'package:islamic_app/features/azkar/data/services/zekr_custom_storage_service.dart';
import 'package:islamic_app/features/azkar/data/services/zekr_progress_service.dart';
import 'package:islamic_app/features/azkar/data/services/zekr_memory_plan_preferences.dart';
import 'add_custom_zekr_page.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';
part 'zekr_item_details_widgets.dart';

class ZekrItemDetailsPage extends StatefulWidget {
  const ZekrItemDetailsPage({
    super.key,
    required this.category,
    required this.item,
    this.items,
    this.initialIndex = 0,
  });

  final ZekrCategoryModel category;
  final ZekrItemModel item;
  final List<ZekrItemModel>? items;
  final int initialIndex;

  @override
  State<ZekrItemDetailsPage> createState() => _ZekrItemDetailsPageState();
}

class _ZekrItemDetailsPageState extends State<ZekrItemDetailsPage> {
  static const String _swipeHintSeenKey = 'zekr_details_swipe_hint_seen_v1';

  final ZekrProgressService _progressService = const ZekrProgressService();
  final ZekrCustomStorageService _customStorageService =
      const ZekrCustomStorageService();

  final ZekrMemoryPlanPreferences _memoryPlanPreferences =
      const ZekrMemoryPlanPreferences();

  late final List<ZekrItemModel> _items;
  late final PageController _pageController;
  late int _currentIndex;

  bool _memoryPlanEnabled = false;
  int _counter = 0;
  bool _isCompleted = false;

  final Map<String, int> _countersByItemId = <String, int>{};
  final Set<String> _completedItemIds = <String>{};

  ZekrItemModel get item => _items[_currentIndex];
  bool get _canSwipeBetweenItems => _items.length > 1;

  @override
  void initState() {
    super.initState();

    _items = (widget.items == null || widget.items!.isEmpty)
        ? <ZekrItemModel>[widget.item]
        : List<ZekrItemModel>.from(widget.items!);

    final int itemIndex = _items.indexWhere(
      (element) => element.id == widget.item.id,
    );
    final int fallbackIndex = itemIndex == -1 ? widget.initialIndex : itemIndex;
    _currentIndex = fallbackIndex.clamp(0, _items.length - 1);

    _pageController = PageController(initialPage: _currentIndex);

    _loadCompletedState();
    _loadMemoryPlanState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
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

  Future<void> _loadCompletedState({String? itemId}) async {
    final String targetItemId = itemId ?? item.id;

    final completed = await _progressService.isItemCompletedToday(
      categoryId: widget.category.id,
      itemId: targetItemId,
    );

    if (!mounted) return;

    final int targetIndex = _items.indexWhere(
      (element) => element.id == targetItemId,
    );

    if (targetIndex == -1) return;

    final ZekrItemModel targetItem = _items[targetIndex];
    final int safeCount = targetItem.count <= 0 ? 1 : targetItem.count;

    setState(() {
      if (completed) {
        _completedItemIds.add(targetItemId);
        _countersByItemId[targetItemId] = safeCount;
      } else {
        _completedItemIds.remove(targetItemId);
        _countersByItemId.putIfAbsent(targetItemId, () => 0);
      }

      if (item.id == targetItemId) {
        _isCompleted = completed;
        _counter = _countersByItemId[targetItemId] ?? 0;
      }
    });
  }

  void _applyCachedStateForCurrentItem() {
    final String currentItemId = item.id;
    final bool completed = _completedItemIds.contains(currentItemId);
    final int safeCount = item.count <= 0 ? 1 : item.count;
    final int cachedCounter = completed
        ? safeCount
        : (_countersByItemId[currentItemId] ?? 0).clamp(0, safeCount).toInt();

    _isCompleted = completed;
    _counter = cachedCounter;
  }

  void _onPageChanged(int index) {
    if (_currentIndex == index) return;

    AppHaptics.tap(context);

    setState(() {
      _currentIndex = index;
      _applyCachedStateForCurrentItem();
    });

    _loadCompletedState(itemId: item.id);
  }

  Future<void> _increment() async {
    if (_isCompleted) return;

    AppHaptics.tap(context);

    final String currentItemId = item.id;
    final int safeCount = item.count <= 0 ? 1 : item.count;
    final int next = _counter + 1;

    setState(() {
      _counter = next > safeCount ? safeCount : next;
      _countersByItemId[currentItemId] = _counter;
    });

    if (_counter >= safeCount) {
      await _markCompleted();
    }
  }

  Future<void> _markCompleted() async {
    final String currentItemId = item.id;
    final int safeCount = item.count <= 0 ? 1 : item.count;

    setState(() {
      _completedItemIds.add(currentItemId);
      _countersByItemId[currentItemId] = safeCount;
      _isCompleted = true;
      _counter = safeCount;
    });

    await _progressService.markItemCompleted(
      categoryId: widget.category.id,
      itemId: currentItemId,
    );
  }

  Future<void> _unmarkCompleted() async {
    final String currentItemId = item.id;

    setState(() {
      _completedItemIds.remove(currentItemId);
      _countersByItemId[currentItemId] = 0;
      _isCompleted = false;
      _counter = 0;
    });

    await _progressService.unmarkItemCompleted(
      categoryId: widget.category.id,
      itemId: currentItemId,
    );
  }

  Future<void> _editCustomZekr() async {
    AppHaptics.tap(context);

    final bool? changed = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddCustomZekrPage(itemToEdit: item)),
    );

    if (changed == true && mounted) {
      Navigator.pop(context, true);
    }
  }

  Future<void> _deleteCustomZekr() async {
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
              'حذف الذكر؟',
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              style: AppTextStyles.body(context).copyWith(
                fontWeight: FontWeight.w900,
                color: theme.colorScheme.surface,
              ),
            ),
            content: Text(
              'سيتم حذف هذا الذكر من أذكاري الخاصة فقط.',
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

    await _customStorageService.deleteCustomZekr(item.id);

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
                    'تنقّل أسهل بين الأذكار',
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
              'تقدر تسحب يمين أو شمال للانتقال بين أذكار نفس القسم بدون الرجوع للقائمة.',
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
            return _buildZekrDetailsList(_items[index]);
          },
        ),
      ),
    );
  }

  Widget _buildZekrDetailsList(ZekrItemModel pageItem) {
    final int safeCount = pageItem.count <= 0 ? 1 : pageItem.count;
    final bool pageCompleted = _completedItemIds.contains(pageItem.id);
    final int pageCounter = pageCompleted
        ? safeCount
        : (_countersByItemId[pageItem.id] ?? 0).clamp(0, safeCount).toInt();
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
          key: PageStorageKey<String>('zekr_details_${pageItem.id}'),
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
                        onEdit: _editCustomZekr,
                        onDelete: _deleteCustomZekr,
                      ),
                    ],
                    SizedBox(height: isLargeScreen ? 14 : 12.h),
                    _ZekrFullTextCard(
                      item: pageItem,
                      reference: pageItem.reference,
                    ),
                    SizedBox(height: isLargeScreen ? 14 : 12.h),
                    if (_memoryPlanEnabled) ...[
                      ZekrMemoryTrainingCard(
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

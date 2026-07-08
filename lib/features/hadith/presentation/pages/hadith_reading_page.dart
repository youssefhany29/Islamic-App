import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:islamic_app/shared/widgets/app_main_components/custom_app_bar.dart';
import 'package:islamic_app/core/services/app_haptics.dart';

import 'package:islamic_app/features/hadith/data/datasources/hadith_local_data.dart';
import 'package:islamic_app/features/hadith/data/models/hadith_category_model.dart';
import 'package:islamic_app/features/hadith/data/models/hadith_item_model.dart';
import 'package:islamic_app/features/hadith/data/services/hadith_custom_storage_service.dart';
import 'package:islamic_app/features/hadith/data/services/hadith_data_service.dart';
import 'package:islamic_app/features/hadith/data/services/hadith_progress_service.dart';
import 'add_custom_hadith_page.dart';
import 'hadith_item_details_page.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';

class HadithReadingPage extends StatefulWidget {
  const HadithReadingPage({super.key, required this.category});

  final HadithCategoryModel category;

  @override
  State<HadithReadingPage> createState() => _HadithReadingPageState();
}

class _HadithReadingPageState extends State<HadithReadingPage> {
  final HadithDataService _dataService = const HadithDataService();
  final HadithProgressService _progressService = const HadithProgressService();
  final HadithCustomStorageService _customStorageService =
      const HadithCustomStorageService();

  late Future<List<HadithItemModel>> _itemsFuture;
  List<HadithItemModel> _customItems = [];
  bool _isReordering = false;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  void _loadItems() {
    _itemsFuture = _dataService.getItemsByCategory(widget.category.id);
  }

  bool _isLargeScreen(BuildContext context) {
    final Size size = MediaQuery.sizeOf(context);

    final bool tablet = size.shortestSide >= 600;
    final bool unfoldedFold =
        size.width >= 700 && size.height >= 500 && size.shortestSide < 600;

    return tablet || unfoldedFold;
  }

  int _gridColumnsForWidth(double width) {
    if (width >= 1120) return 3;
    if (width >= 700) return 2;
    return 1;
  }

  double _gridCardHeight(double width) {
    if (width >= 1120) return 218;
    if (width >= 700) return 210;
    return 190;
  }

  Future<void> _openDetails(
    HadithItemModel item, {
    required List<HadithItemModel> items,
    required int initialIndex,
  }) async {
    AppHaptics.tap(context);

    final bool? changed = await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          return HadithItemDetailsPage(
            category: widget.category,
            item: item,
            items: items,
            initialIndex: initialIndex,
          );
        },
        transitionDuration: const Duration(milliseconds: 240),
        reverseTransitionDuration: const Duration(milliseconds: 190),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curvedAnimation = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );

          return FadeTransition(
            opacity: curvedAnimation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.045),
                end: Offset.zero,
              ).animate(curvedAnimation),
              child: child,
            ),
          );
        },
      ),
    );

    if (!mounted) return;

    if (changed == true) {
      setState(() {
        _loadItems();
      });
      return;
    }

    setState(() {});
  }

  Future<void> _openAddCustomHadithPage() async {
    AppHaptics.tap(context);

    final bool? added = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddCustomHadithPage()),
    );

    if (added == true && mounted) {
      setState(() {
        _loadItems();
      });
    }
  }

  Future<void> _reorderCustomAzkar(int oldIndex, int newIndex) async {
    if (_isReordering) return;

    AppHaptics.tap(context);

    if (oldIndex < 0 || oldIndex >= _customItems.length) return;

    if (newIndex > oldIndex) {
      newIndex -= 1;
    }

    newIndex = newIndex.clamp(0, _customItems.length - 1);

    final List<HadithItemModel> updatedItems = [..._customItems];
    final HadithItemModel movedItem = updatedItems.removeAt(oldIndex);
    updatedItems.insert(newIndex, movedItem);

    setState(() {
      _customItems = updatedItems;
      _isReordering = true;
    });

    await _customStorageService.reorderCustomAzkar(updatedItems);

    if (!mounted) return;

    setState(() {
      _itemsFuture = Future.value(updatedItems);
      _isReordering = false;
    });
  }

  Widget _buildPreviewCard({
    required HadithItemModel item,
    required List<HadithItemModel> sourceItems,
    required int index,
    required bool isLargeScreen,
    required bool isGridCard,
    required bool showDragHandle,
  }) {
    return FutureBuilder<bool>(
      future: _progressService.isItemCompletedToday(
        categoryId: widget.category.id,
        itemId: item.id,
      ),
      builder: (context, completedSnapshot) {
        final bool isCompleted = completedSnapshot.data ?? false;

        return _HadithPreviewCard(
          item: item,
          isCompleted: isCompleted,
          isLargeScreen: isLargeScreen,
          isGridCard: isGridCard,
          showDragHandle: showDragHandle,
          reorderIndex: index,
          onTap: () =>
              _openDetails(item, items: sourceItems, initialIndex: index),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isCustomPage = widget.category.id == HadithLocalData.customId;
    final bool isLargeScreen = _isLargeScreen(context);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: CustomAppBar(
        category: CustomAppBarCategory(text: widget.category.title),
      ),
      floatingActionButton: isCustomPage
          ? FloatingActionButton.extended(
              onPressed: _openAddCustomHadithPage,
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              elevation: 4,
              icon: const Icon(Icons.add_rounded),
              label: Text(
                'إضافة حديث',
                textDirection: TextDirection.rtl,
                style: AppTextStyles.caption(
                  context,
                ).copyWith(fontWeight: FontWeight.w800, color: Colors.white),
              ),
            )
          : null,
      body: SafeArea(
        child: FutureBuilder<List<HadithItemModel>>(
          future: _itemsFuture,
          builder: (context, snapshot) {
            final List<HadithItemModel> items = snapshot.data ?? [];

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (items.isEmpty) {
              return _EmptyHadithState(
                isCustomPage: isCustomPage,
                onAdd: _openAddCustomHadithPage,
              );
            }

            if (isCustomPage && !_isReordering) {
              _customItems = items;
            }

            if (isCustomPage) {
              return ReorderableListView.builder(
                padding: EdgeInsets.fromLTRB(14.w, 8.h, 14.w, 90.h),
                physics: const BouncingScrollPhysics(),
                buildDefaultDragHandles: false,
                itemCount: _customItems.length,
                onReorder: _reorderCustomAzkar,
                proxyDecorator: (child, index, animation) {
                  return Material(
                    color: Colors.transparent,
                    child: ScaleTransition(
                      scale: Tween<double>(
                        begin: 1,
                        end: 1.02,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                itemBuilder: (context, index) {
                  final HadithItemModel item = _customItems[index];

                  return Padding(
                    key: ValueKey(item.id),
                    padding: EdgeInsets.only(bottom: 12.h),
                    child: _buildPreviewCard(
                      item: item,
                      sourceItems: _customItems,
                      index: index,
                      isLargeScreen: false,
                      isGridCard: false,
                      showDragHandle: true,
                    ),
                  );
                },
              );
            }

            if (!isLargeScreen) {
              return ListView.separated(
                padding: EdgeInsets.fromLTRB(14.w, 8.h, 14.w, 90.h),
                physics: const BouncingScrollPhysics(),
                itemCount: items.length,
                separatorBuilder: (_, __) => SizedBox(height: 12.h),
                itemBuilder: (context, index) {
                  final HadithItemModel item = items[index];

                  return _buildPreviewCard(
                    item: item,
                    sourceItems: items,
                    index: index,
                    isLargeScreen: false,
                    isGridCard: false,
                    showDragHandle: false,
                  );
                },
              );
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                final int columns = _gridColumnsForWidth(constraints.maxWidth);
                final double cardHeight = _gridCardHeight(constraints.maxWidth);

                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 90),
                  physics: const BouncingScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    mainAxisExtent: cardHeight,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final HadithItemModel item = items[index];

                    return _buildPreviewCard(
                      item: item,
                      sourceItems: items,
                      index: index,
                      isLargeScreen: true,
                      isGridCard: true,
                      showDragHandle: false,
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _HadithPreviewCard extends StatelessWidget {
  const _HadithPreviewCard({
    required this.item,
    required this.isCompleted,
    required this.isLargeScreen,
    required this.isGridCard,
    required this.showDragHandle,
    required this.reorderIndex,
    required this.onTap,
  });

  final HadithItemModel item;
  final bool isCompleted;
  final bool isLargeScreen;
  final bool isGridCard;
  final bool showDragHandle;
  final int reorderIndex;
  final VoidCallback onTap;

  String get _title {
    final String? title = item.title;
    if (title == null || title.trim().isEmpty) return 'حديث';
    return title.trim();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    final double radius = isLargeScreen ? 20 : 20.r;
    final double padding = isLargeScreen ? 14 : 14.w;
    final double iconBox = isLargeScreen ? 40 : 45.w;
    final double iconSize = isLargeScreen ? 21 : 22.sp;

    final TextStyle titleStyle = AppTextStyles.caption(context).copyWith(
      fontWeight: FontWeight.w800,
      color: theme.colorScheme.surface.withOpacity(0.84),
      height: 1.28,
    );

    final TextStyle bodyStyle = AppTextStyles.caption(context).copyWith(
      fontWeight: FontWeight.w500,
      color: theme.colorScheme.surface.withOpacity(0.64),
      height: 1.48,
    );

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(radius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radius),
          splashColor: theme.colorScheme.primary.withOpacity(0.10),
          highlightColor: theme.colorScheme.primary.withOpacity(0.06),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final bool hasBoundedHeight =
                  constraints.hasBoundedHeight &&
                  constraints.maxHeight.isFinite;

              final bool compact = constraints.maxWidth < 230;

              return Ink(
                width: double.infinity,
                height: hasBoundedHeight ? double.infinity : null,
                padding: EdgeInsets.all(padding),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary,
                  borderRadius: BorderRadius.circular(radius),
                  border: Border.all(
                    color: isCompleted
                        ? const Color(0xff21C58E)
                        : theme.colorScheme.outline.withOpacity(
                            isDark ? 0.18 : 0.42,
                          ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.10 : 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: hasBoundedHeight
                      ? MainAxisSize.max
                      : MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (compact)
                      _CompactCardHeader(
                        title: _title,
                        body: item.text,
                        titleStyle: titleStyle,
                        bodyStyle: bodyStyle,
                        showDragHandle: showDragHandle,
                        reorderIndex: reorderIndex,
                      )
                    else
                      _NormalCardHeader(
                        title: _title,
                        body: item.text,
                        titleStyle: titleStyle,
                        bodyStyle: bodyStyle,
                        iconBox: iconBox,
                        iconSize: iconSize,
                        isCompleted: isCompleted,
                        isLargeScreen: isLargeScreen,
                        showDragHandle: showDragHandle,
                        reorderIndex: reorderIndex,
                      ),
                    SizedBox(height: isLargeScreen ? 10 : 10.h),
                    if (hasBoundedHeight) const Spacer(),
                    Row(
                      textDirection: TextDirection.rtl,
                      children: [
                        _SmallBadge(
                          text: '${item.count <= 0 ? 1 : item.count} مرة',
                          icon: Icons.repeat_rounded,
                          isLargeScreen: isLargeScreen,
                        ),
                        if (isCompleted)
                          _SmallBadge(
                            text: 'تم اليوم',
                            icon: Icons.check_circle_outline_rounded,
                            isDone: true,
                            isLargeScreen: isLargeScreen,
                          ),
                        const Spacer(),
                        Container(
                          width: isLargeScreen ? 27 : 25.w,
                          height: isLargeScreen ? 27 : 25.w,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(
                              isDark ? 0.18 : 0.08,
                            ),
                            borderRadius: BorderRadius.circular(
                              isLargeScreen ? 9 : 9.r,
                            ),
                          ),
                          child: Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: theme.colorScheme.primary,
                            size: isLargeScreen ? 12 : 12.sp,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _NormalCardHeader extends StatelessWidget {
  const _NormalCardHeader({
    required this.title,
    required this.body,
    required this.titleStyle,
    required this.bodyStyle,
    required this.iconBox,
    required this.iconSize,
    required this.isCompleted,
    required this.isLargeScreen,
    required this.showDragHandle,
    required this.reorderIndex,
  });

  final String title;
  final String body;
  final TextStyle titleStyle;
  final TextStyle bodyStyle;
  final double iconBox;
  final double iconSize;
  final bool isCompleted;
  final bool isLargeScreen;
  final bool showDragHandle;
  final int reorderIndex;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    return Row(
      textDirection: TextDirection.rtl,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: iconBox,
          height: iconBox,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isCompleted
                ? const Color(0xff21C58E).withOpacity(0.14)
                : theme.colorScheme.primary.withOpacity(isDark ? 0.24 : 0.10),
            borderRadius: BorderRadius.circular(isLargeScreen ? 14 : 15.r),
          ),
          child: Icon(
            isCompleted ? Icons.check_rounded : Icons.menu_book_rounded,
            color: isCompleted
                ? const Color(0xff21C58E)
                : theme.colorScheme.primary,
            size: iconSize,
          ),
        ),
        SizedBox(width: isLargeScreen ? 10 : 10.w),
        Expanded(
          child: _CardTextBlock(
            title: title,
            body: body,
            titleStyle: titleStyle,
            bodyStyle: bodyStyle,
            titleMaxLines: isLargeScreen ? 2 : 1,
            bodyMaxLines: isLargeScreen ? 2 : 3,
          ),
        ),
        if (showDragHandle) ...[
          SizedBox(width: isLargeScreen ? 6 : 6.w),
          ReorderableDragStartListener(
            index: reorderIndex,
            child: Icon(
              Icons.drag_indicator_rounded,
              color: theme.colorScheme.surface.withOpacity(0.40),
              size: isLargeScreen ? 20 : 20.sp,
            ),
          ),
        ],
      ],
    );
  }
}

class _CompactCardHeader extends StatelessWidget {
  const _CompactCardHeader({
    required this.title,
    required this.body,
    required this.titleStyle,
    required this.bodyStyle,
    required this.showDragHandle,
    required this.reorderIndex,
  });

  final String title;
  final String body;
  final TextStyle titleStyle;
  final TextStyle bodyStyle;
  final bool showDragHandle;
  final int reorderIndex;

  @override
  Widget build(BuildContext context) {
    if (!showDragHandle) {
      return _CardTextBlock(
        title: title,
        body: body,
        titleStyle: titleStyle,
        bodyStyle: bodyStyle,
        titleMaxLines: 1,
        bodyMaxLines: 1,
      );
    }

    return Row(
      textDirection: TextDirection.rtl,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _CardTextBlock(
            title: title,
            body: body,
            titleStyle: titleStyle,
            bodyStyle: bodyStyle,
            titleMaxLines: 1,
            bodyMaxLines: 1,
          ),
        ),
        SizedBox(width: 6.w),
        ReorderableDragStartListener(
          index: reorderIndex,
          child: Icon(
            Icons.drag_indicator_rounded,
            color: Theme.of(context).colorScheme.surface.withOpacity(0.40),
            size: 20.sp,
          ),
        ),
      ],
    );
  }
}

class _CardTextBlock extends StatelessWidget {
  const _CardTextBlock({
    required this.title,
    required this.body,
    required this.titleStyle,
    required this.bodyStyle,
    required this.titleMaxLines,
    required this.bodyMaxLines,
  });

  final String title;
  final String body;
  final TextStyle titleStyle;
  final TextStyle bodyStyle;
  final int titleMaxLines;
  final int bodyMaxLines;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: double.infinity,
          child: Text(
            title,
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
            locale: const Locale('ar'),
            maxLines: titleMaxLines,
            overflow: TextOverflow.ellipsis,
            style: titleStyle,
          ),
        ),
        SizedBox(height: 6.h),
        SizedBox(
          width: double.infinity,
          child: Text(
            body,
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
            locale: const Locale('ar'),
            maxLines: bodyMaxLines,
            overflow: TextOverflow.ellipsis,
            style: bodyStyle,
          ),
        ),
      ],
    );
  }
}

class _SmallBadge extends StatelessWidget {
  const _SmallBadge({
    required this.text,
    required this.icon,
    required this.isLargeScreen,
    this.isDone = false,
  });

  final String text;
  final IconData icon;
  final bool isLargeScreen;
  final bool isDone;

  @override
  Widget build(BuildContext context) {
    final Color color = isDone
        ? const Color(0xff21C58E)
        : Theme.of(context).colorScheme.primary;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isLargeScreen ? 8 : 8.w,
        vertical: isLargeScreen ? 4 : 4.h,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(isLargeScreen ? 30 : 30.r),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: isLargeScreen ? 12 : 12.sp),
          SizedBox(width: isLargeScreen ? 4 : 4.w),
          Text(
            text,
            textDirection: TextDirection.rtl,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption(
              context,
            ).copyWith(fontWeight: FontWeight.w800, color: color),
          ),
        ],
      ),
    );
  }
}

class _EmptyHadithState extends StatelessWidget {
  const _EmptyHadithState({required this.isCustomPage, required this.onAdd});

  final bool isCustomPage;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isCustomPage
                    ? Icons.edit_note_rounded
                    : Icons.local_florist_outlined,
                size: 54.sp,
                color: Theme.of(context).colorScheme.primary,
              ),
              SizedBox(height: 12.h),
              Text(
                isCustomPage
                    ? 'لسه مفيش أحاديث خاصة'
                    : 'لا توجد أحاديث في هذا القسم حاليًا',
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
                locale: const Locale('ar'),
                style: Theme.of(
                  context,
                ).textTheme.headlineLarge?.copyWith(letterSpacing: 0),
              ),
              SizedBox(height: 6.h),
              Text(
                isCustomPage
                    ? 'أضف حديث أو حديث تحب تكرره، وهيظهر هنا دائمًا.'
                    : 'سيتم إضافة الأحاديث قريبًا.',
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
                locale: const Locale('ar'),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(letterSpacing: 0),
              ),
              if (isCustomPage) ...[
                SizedBox(height: 14.h),
                ElevatedButton.icon(
                  onPressed: () {
                    AppHaptics.tap(context);
                    onAdd();
                  },
                  icon: const Icon(Icons.add_rounded),
                  label: Text(
                    'إضافة حديث',
                    textDirection: TextDirection.rtl,
                    style: AppTextStyles.caption(context).copyWith(
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: 14.w,
                      vertical: 10.h,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15.r),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

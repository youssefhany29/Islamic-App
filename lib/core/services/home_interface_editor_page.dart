import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../services/app_haptics.dart';
import 'home_interface_settings_service.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';
class HomeInterfaceEditorPage extends StatefulWidget {
  const HomeInterfaceEditorPage({
    super.key,
    this.onSettingsChanged,
  });

  final VoidCallback? onSettingsChanged;

  @override
  State<HomeInterfaceEditorPage> createState() =>
      _HomeInterfaceEditorPageState();
}

class _HomeInterfaceEditorPageState extends State<HomeInterfaceEditorPage> {
  final HomeInterfaceSettingsService _service =
      const HomeInterfaceSettingsService();

  HomeInterfaceSettings _settings = HomeInterfaceSettings.defaults();
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await _service.load();

    if (!mounted) return;

    setState(() {
      _settings = settings;
      _isLoading = false;
    });
  }

  Future<void> _saveSettings(HomeInterfaceSettings settings) async {
    setState(() {
      _settings = settings;
      _isSaving = true;
    });

    await _service.save(settings);

    if (!mounted) return;

    setState(() {
      _isSaving = false;
    });

    widget.onSettingsChanged?.call();
  }

  Future<void> _resetSettings() async {
    AppHaptics.medium(context);

    await _service.reset();

    final defaults = HomeInterfaceSettings.defaults();

    await _saveSettings(defaults);
  }

  void _toggleCard(HomeCardId id, bool value) {
    final cards = _settings.cards.map((card) {
      if (card.id != id) return card;

      return card.copyWith(
        visible: card.id.isRequired ? true : value,
      );
    }).toList();

    _saveSettings(
      _settings.copyWith(cards: cards),
    );
  }

  void _changeCardSize(HomeCardId id, HomeCardSize size) {
    final cards = _settings.cards.map((card) {
      if (card.id != id) return card;

      return card.copyWith(size: size);
    }).toList();

    _saveSettings(
      _settings.copyWith(cards: cards),
    );
  }

  void _reorderCards(int oldIndex, int newIndex) {
    final cards = [..._settings.cards];

    if (newIndex > oldIndex) {
      newIndex -= 1;
    }

    final item = cards.removeAt(oldIndex);
    cards.insert(newIndex, item);

    _saveSettings(
      _settings.copyWith(cards: cards),
    );
  }

  void _reorderShortcuts(int oldIndex, int newIndex) {
    final shortcuts = [..._settings.worshipShortcutsOrder];

    if (newIndex > oldIndex) {
      newIndex -= 1;
    }

    final item = shortcuts.removeAt(oldIndex);
    shortcuts.insert(newIndex, item);

    _saveSettings(
      _settings.copyWith(worshipShortcutsOrder: shortcuts),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor = Theme.of(context).colorScheme.background;
    final Color cardColor = Theme.of(context).colorScheme.primary;
    final Color itemColor = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xff171B26)
        : Colors.white;
    final Color textColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : const Color(0xff171B26);
    final Color subTextColor = textColor.withOpacity(0.65);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: cardColor,
          elevation: 0,
          centerTitle: true,
          title: Text(
            'تعديل الواجهة',
            style: AppTextStyles.body(context).copyWith(
fontWeight: FontWeight.w800,
              color: Colors.white
),
          ),
          actions: [
            IconButton(
              tooltip: 'رجوع',
              onPressed: () {
                AppHaptics.tap(context);
                Navigator.pop(context);
              },
              icon: const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white,
              ),
            ),
          ],
        ),
        body: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  color: Theme.of(context).colorScheme.primary,
                ),
              )
            : SafeArea(
                child: ListView(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 14.h,
                  ),
                  children: [
                    _EditorIntroCard(
                      isSaving: _isSaving,
                      onReset: _resetSettings,
                    ),
                    SizedBox(height: 14.h),
                    _EditorSectionTitle(
                      title: 'ترتيب وإظهار كروت الرئيسية',
                      subtitle:
                          'اسحب الكارت لتغيير مكانه، والكروت الأساسية لا يمكن حذفها.',
                      textColor: textColor,
                      subTextColor: subTextColor,
                    ),
                    SizedBox(height: 10.h),
                    ReorderableListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _settings.cards.length,
                      buildDefaultDragHandles: false,
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
                      onReorder: _reorderCards,
                      itemBuilder: (context, index) {
                        final card = _settings.cards[index];

                        return _HomeCardEditorTile(
                          key: ValueKey(card.id.storageKey),
                          card: card,
                          itemColor: itemColor,
                          textColor: textColor,
                          subTextColor: subTextColor,
                          onVisibilityChanged: (value) {
                            AppHaptics.tap(context);
                            _toggleCard(card.id, value);
                          },
                          onSizeChanged: (size) {
                            AppHaptics.tap(context);
                            _changeCardSize(card.id, size);
                          },
                          dragHandle: ReorderableDragStartListener(
                            index: index,
                            child: Icon(
                              Icons.drag_indicator_rounded,
                              color: subTextColor,
                              size: 22.sp,
                            ),
                          ),
                        );
                      },
                    ),
                    SizedBox(height: 18.h),
                    _EditorSectionTitle(
                      title: 'ترتيب عناصر كارت ثبت عبادتك',
                      subtitle:
                          'هذه العناصر أساسية، لذلك يمكنك ترتيبها فقط بدون حذف.',
                      textColor: textColor,
                      subTextColor: subTextColor,
                    ),
                    SizedBox(height: 10.h),
                    ReorderableListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _settings.worshipShortcutsOrder.length,
                      buildDefaultDragHandles: false,
                      onReorder: _reorderShortcuts,
                      itemBuilder: (context, index) {
                        final shortcut = _settings.worshipShortcutsOrder[index];

                        return _ShortcutEditorTile(
                          key: ValueKey(shortcut.storageKey),
                          title: shortcut.title,
                          itemColor: itemColor,
                          textColor: textColor,
                          subTextColor: subTextColor,
                          dragHandle: ReorderableDragStartListener(
                            index: index,
                            child: Icon(
                              Icons.drag_indicator_rounded,
                              color: subTextColor,
                              size: 22.sp,
                            ),
                          ),
                        );
                      },
                    ),
                    SizedBox(height: 24.h),
                  ],
                ),
              ),
      ),
    );
  }
}

class _EditorIntroCard extends StatelessWidget {
  const _EditorIntroCard({
    required this.isSaving,
    required this.onReset,
  });

  final bool isSaving;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(22.r),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Container(
            width: 42.w,
            height: 42.w,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.tune_rounded,
              color: Colors.white,
              size: 22.sp,
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  isSaving ? 'جاري حفظ التعديل...' : 'خصص واجهتك براحتك',
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w800,
                    color: Colors.white
),
                ),
                SizedBox(height: 4.h),
                Text(
                  'أي كارت تخفيه تقدر ترجعه في أي وقت، والترتيب بيتحفظ تلقائيًا.',
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w600,
                    height: 1.45,
                    color: Colors.white.withOpacity(0.72)
),
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          IconButton(
            tooltip: 'استعادة الافتراضي',
            onPressed: onReset,
            icon: const Icon(
              Icons.restart_alt_rounded,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _EditorSectionTitle extends StatelessWidget {
  const _EditorSectionTitle({
    required this.title,
    required this.subtitle,
    required this.textColor,
    required this.subTextColor,
  });

  final String title;
  final String subtitle;
  final Color textColor;
  final Color subTextColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          title,
          textAlign: TextAlign.right,
          textDirection: TextDirection.rtl,
          style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w800,
            color: textColor
),
        ),
        SizedBox(height: 3.h),
        Text(
          subtitle,
          textAlign: TextAlign.right,
          textDirection: TextDirection.rtl,
          style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w600,
            height: 1.45,
            color: subTextColor
),
        ),
      ],
    );
  }
}

class _HomeCardEditorTile extends StatelessWidget {
  const _HomeCardEditorTile({
    super.key,
    required this.card,
    required this.itemColor,
    required this.textColor,
    required this.subTextColor,
    required this.onVisibilityChanged,
    required this.onSizeChanged,
    required this.dragHandle,
  });

  final HomeCardPreference card;
  final Color itemColor;
  final Color textColor;
  final Color subTextColor;
  final ValueChanged<bool> onVisibilityChanged;
  final ValueChanged<HomeCardSize> onSizeChanged;
  final Widget dragHandle;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 9.h),
      padding: EdgeInsets.symmetric(
        horizontal: 12.w,
        vertical: 10.h,
      ),
      decoration: BoxDecoration(
        color: itemColor,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color: textColor.withOpacity(0.06),
        ),
      ),
      child: Column(
        children: [
          Row(
            textDirection: TextDirection.rtl,
            children: [
              dragHandle,
              SizedBox(width: 8.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      card.id.title,
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w800,
                        color: textColor
),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      card.id.subtitle,
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w600,
                        height: 1.35,
                        color: subTextColor
),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              if (card.id.isRequired)
                _RequiredBadge(color: subTextColor)
              else
                Transform.scale(
                  scale: 0.82,
                  child: Switch(
                    value: card.visible,
                    onChanged: onVisibilityChanged,
                    activeColor: Colors.white,
                    activeTrackColor: Colors.green,
                    inactiveThumbColor: Colors.white,
                    inactiveTrackColor: Colors.black,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            textDirection: TextDirection.rtl,
            children: HomeCardSize.values.map((size) {
              final bool selected = card.size == size;

              return Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 2.w),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12.r),
                    onTap: () => onSizeChanged(size),
                    child: Container(
                      height: 30.h,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: selected
                            ? Theme.of(context).colorScheme.primary
                            : textColor.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Text(
                        size.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w800,
                          color: selected ? Colors.white : textColor
),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _ShortcutEditorTile extends StatelessWidget {
  const _ShortcutEditorTile({
    super.key,
    required this.title,
    required this.itemColor,
    required this.textColor,
    required this.subTextColor,
    required this.dragHandle,
  });

  final String title;
  final Color itemColor;
  final Color textColor;
  final Color subTextColor;
  final Widget dragHandle;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50.h,
      margin: EdgeInsets.only(bottom: 9.h),
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      decoration: BoxDecoration(
        color: itemColor,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color: textColor.withOpacity(0.06),
        ),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          dragHandle,
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w800,
                color: textColor
),
            ),
          ),
          Icon(
            Icons.lock_outline_rounded,
            color: subTextColor,
            size: 16.sp,
          ),
        ],
      ),
    );
  }
}

class _RequiredBadge extends StatelessWidget {
  const _RequiredBadge({
    required this.color,
  });

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 8.w,
        vertical: 5.h,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999.r),
      ),
      child: Text(
        'أساسي',
        style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w800,
          color: color
),
      ),
    );
  }
}

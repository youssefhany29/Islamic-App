part of 'app_settings_drawer.dart';

class _PrayerBackgroundStyleCard extends StatelessWidget {
  const _PrayerBackgroundStyleCard();

  Future<void> _selectStyle(
    BuildContext context,
    PrayerBackgroundStyle style,
  ) async {
    final PrayerBackgroundStyleProvider provider = context
        .read<PrayerBackgroundStyleProvider>();

    if (provider.isLoaded && provider.style == style) return;

    AppHaptics.tap(context);
    await provider.setStyle(style);
    await PrayerWidgetSyncService.instance.syncFromCache();
  }

  @override
  Widget build(BuildContext context) {
    final PrayerBackgroundStyleProvider provider = context
        .watch<PrayerBackgroundStyleProvider>();
    final Color cardColor = AppSettingsDrawer._cardColor(context);
    final Color borderColor = AppSettingsDrawer._borderColor(context);
    final Color titleColor = AppSettingsDrawer._titleColor(context);
    final Color mutedColor = AppSettingsDrawer._mutedColor(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(color: borderColor, width: 1.w),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          SizedBox(
            width: double.infinity,
            child: Text(
              'خلفية كارت الصلاة',
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption(context).copyWith(
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
                color: titleColor,
              ),
            ),
          ),
          SizedBox(height: 4.h),
          SizedBox(
            width: double.infinity,
            child: Text(
              'يمكنك اختيار باكدج الخلفية التي تريدها',
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption(context).copyWith(
                fontSize: 10.sp,
                fontWeight: FontWeight.w600,
                height: 1.45,
                color: mutedColor,
              ),
            ),
          ),
          SizedBox(height: 12.h),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: PrayerBackgroundStyle.userSelectableValues.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 8.h,
              crossAxisSpacing: 8.w,
              childAspectRatio: 2.15,
            ),
            itemBuilder: (context, index) {
              final PrayerBackgroundStyle style =
                  PrayerBackgroundStyle.userSelectableValues[index];
              final bool selected = provider.style == style;

              return _PrayerBackgroundStyleGridButton(
                title: style.arabicLabel,
                selected: selected,
                onTap: () => _selectStyle(context, style),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PrayerBackgroundStyleGridButton extends StatelessWidget {
  const _PrayerBackgroundStyleGridButton({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color selectedColor = AppSettingsDrawer._accentColor(context);
    final Color chipColor = AppSettingsDrawer._chipBackground(context);
    final Color borderColor = AppSettingsDrawer._borderColor(context);
    final Color titleColor = AppSettingsDrawer._titleColor(context);

    return InkWell(
      borderRadius: BorderRadius.circular(14.r),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        alignment: Alignment.center,
        padding: EdgeInsets.symmetric(horizontal: 7.w),
        decoration: BoxDecoration(
          color: selected ? selectedColor : chipColor,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: selected ? selectedColor : borderColor,
            width: selected ? 1.1.w : 0.8.w,
          ),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.caption(context).copyWith(
            fontSize: 10.sp,
            color: selected ? Colors.white : titleColor.withOpacity(0.88),
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            height: 1.2,
          ),
        ),
      ),
    );
  }
}

class _EditUserNameDialog extends StatefulWidget {
  const _EditUserNameDialog();

  @override
  State<_EditUserNameDialog> createState() => _EditUserNameDialogState();
}

class _EditUserNameDialogState extends State<_EditUserNameDialog> {
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentName();
  }

  Future<void> _loadCurrentName() async {
    final String currentName = await const UserProfileService().getUserName();

    if (!mounted) return;

    _controller.text = currentName == 'ضيفنا' ? '' : currentName;

    setState(() {
      _isLoading = false;
    });
  }

  void _save() {
    final String name = _controller.text.trim();

    if (name.isEmpty) {
      Navigator.of(context, rootNavigator: true).pop('ضيفنا');
      return;
    }

    Navigator.of(context, rootNavigator: true).pop(name);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18.r),
        ),
        title: Text(
          'تعديل الاسم',
          textAlign: TextAlign.right,
          textDirection: TextDirection.rtl,
          style: AppTextStyles.body(
            context,
          ).copyWith(fontWeight: FontWeight.w800, color: Colors.white),
        ),
        content: _isLoading
            ? SizedBox(
                height: 70.h,
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppSettingsDrawer._successColor,
                  ),
                ),
              )
            : TextField(
                controller: _controller,
                autofocus: true,
                maxLength: 24,
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
                style: AppTextStyles.caption(
                  context,
                ).copyWith(fontWeight: FontWeight.w700, color: Colors.white),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: 'اكتب اسمك',
                  hintTextDirection: TextDirection.rtl,
                  filled: true,
                  fillColor: AppSettingsDrawer._itemBackgroundColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14.r),
                    borderSide: BorderSide.none,
                  ),
                  hintStyle: AppTextStyles.caption(
                    context,
                  ).copyWith(color: Colors.white.withOpacity(0.52)),
                ),
                onSubmitted: (_) => _save(),
              ),
        actionsAlignment: MainAxisAlignment.start,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context, rootNavigator: true).pop();
            },
            child: Text(
              'إلغاء',
              style: AppTextStyles.caption(context).copyWith(
                fontWeight: FontWeight.w700,
                color: Colors.white.withOpacity(0.72),
              ),
            ),
          ),
          TextButton(
            onPressed: _isLoading
                ? null
                : () {
                    AppHaptics.tap(context);
                    _save();
                  },
            child: Text(
              'حفظ',
              style: AppTextStyles.caption(context).copyWith(
                fontWeight: FontWeight.w800,
                color: AppSettingsDrawer._successColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsHeader extends StatelessWidget {
  const _SettingsHeader();

  @override
  Widget build(BuildContext context) {
    final Color titleColor = AppSettingsDrawer._titleColor(context);
    final Color mutedColor = AppSettingsDrawer._mutedColor(context);

    return Row(
      textDirection: TextDirection.rtl,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              SizedBox(
                width: double.infinity,
                child: Text(
                  'الإعدادات',
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                  style: AppTextStyles.display(
                    context,
                  ).copyWith(fontWeight: FontWeight.w800, color: titleColor),
                ),
              ),
              SizedBox(height: 5.h),
              Text(
                'خصص التطبيق كما تحب',
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption(context).copyWith(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                  color: mutedColor,
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: 14.w),
        Image.asset(
          'assets/icons/helal.png',
          width: 78.w,
          height: 78.h,
          fit: BoxFit.contain,
        ),
      ],
    );
  }
}

class _SettingsSectionCard extends StatelessWidget {
  const _SettingsSectionCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final Color cardColor = AppSettingsDrawer._cardColor(context);
    final Color innerCardColor = AppSettingsDrawer._innerCardColor(context);
    final Color borderColor = AppSettingsDrawer._borderColor(context);
    final Color titleColor = AppSettingsDrawer._titleColor(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(12.w, 15.h, 12.w, 10.h),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(color: borderColor, width: 1.w),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          SizedBox(
            width: double.infinity,
            child: Text(
              title,
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              style: AppTextStyles.body(context).copyWith(
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
                color: titleColor,
              ),
            ),
          ),
          SizedBox(height: 10.h),
          Container(
            decoration: BoxDecoration(
              color: innerCardColor,
              borderRadius: BorderRadius.circular(18.r),
              border: Border.all(color: borderColor, width: 0.8.w),
            ),
            child: Column(
              children: [
                for (int index = 0; index < children.length; index++) ...[
                  children[index],
                  if (index != children.length - 1)
                    Padding(
                      padding: EdgeInsetsDirectional.only(
                        start: 14.w,
                        end: 50.w,
                      ),
                      child: Divider(
                        height: 1.h,
                        thickness: 0.8.h,
                        color: borderColor,
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsSwitchTile extends StatelessWidget {
  const _SettingsSwitchTile({
    required this.title,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final IconData icon;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final Color bodyColor = AppSettingsDrawer._bodyColor(context);
    final Color accentColor = AppSettingsDrawer._accentColor(context);
    final Color inactiveTrackColor = AppSettingsDrawer._isDark(context)
        ? Theme.of(context).colorScheme.surface.withOpacity(0.20)
        : Colors.black.withOpacity(0.22);

    return SizedBox(
      height: 50.h,
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          SizedBox(width: 12.w),
          _SettingsCircleIcon(icon: icon),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption(context).copyWith(
                fontSize: 10.sp,
                fontWeight: FontWeight.w700,
                color: bodyColor,
              ),
            ),
          ),
          Transform.scale(
            scale: 0.78,
            child: Switch(
              value: value,
              onChanged: onChanged == null
                  ? null
                  : (newValue) {
                      AppHaptics.tap(context);
                      onChanged!(newValue);
                    },
              activeColor: Colors.white,
              activeTrackColor: accentColor,
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: inactiveTrackColor,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          SizedBox(width: 4.w),
        ],
      ),
    );
  }
}

class _SettingsButton extends StatelessWidget {
  const _SettingsButton({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color bodyColor = AppSettingsDrawer._bodyColor(context);
    final Color titleColor = AppSettingsDrawer._titleColor(context);

    return InkWell(
      onTap: () {
        AppHaptics.tap(context);
        onTap();
      },
      child: SizedBox(
        height: 50.h,
        child: Row(
          textDirection: TextDirection.rtl,
          children: [
            SizedBox(width: 12.w),
            _SettingsCircleIcon(icon: icon),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                title,
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption(context).copyWith(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w700,
                  color: bodyColor,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: titleColor,
              size: 16.sp,
            ),
            SizedBox(width: 14.w),
          ],
        ),
      ),
    );
  }
}

class _SettingsCircleIcon extends StatelessWidget {
  const _SettingsCircleIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final Color iconBackgroundColor = AppSettingsDrawer._iconBackground(
      context,
    );
    final Color iconColor = AppSettingsDrawer._accentColor(context);

    return Container(
      width: 34.w,
      height: 34.w,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: iconBackgroundColor,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: iconColor, size: 18.sp),
    );
  }
}

class _DuaRequestCard extends StatelessWidget {
  const _DuaRequestCard();

  @override
  Widget build(BuildContext context) {
    final bool isDark = AppSettingsDrawer._isDark(context);
    final Color cardColor = AppSettingsDrawer._cardColor(context);
    final Color borderColor = AppSettingsDrawer._borderColor(context);
    final Color titleColor = AppSettingsDrawer._titleColor(context);
    final Color mutedColor = AppSettingsDrawer._mutedColor(context);
    final Color heartColor = isDark
        ? AppSettingsDrawer._accentColor(context)
        : Colors.white;

    return ClipRRect(
      borderRadius: BorderRadius.circular(18.r),
      child: Container(
        width: double.infinity,
        height: 96.h,
        padding: EdgeInsets.fromLTRB(12.w, 13.h, 14.w, 13.h),
        decoration: BoxDecoration(
          color: isDark ? cardColor : null,
          gradient: isDark
              ? null
              : const LinearGradient(
                  begin: Alignment.centerRight,
                  end: Alignment.centerLeft,
                  colors: [Color(0xffF8FBFF), Color(0xffEAF3FF)],
                ),
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(
            color: isDark
                ? borderColor
                : const Color(0xffC9DDF6).withOpacity(0.72),
            width: 0.8.w,
          ),
        ),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: double.infinity,
                child: Row(
                  textDirection: TextDirection.rtl,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Flexible(
                      child: Text(
                        'دعوة طيبة',
                        textAlign: TextAlign.right,
                        textDirection: TextDirection.rtl,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption(context).copyWith(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w700,
                          color: titleColor,
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Icon(
                      Icons.favorite_rounded,
                      color: heartColor,
                      size: 18.sp,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 5.h),
              SizedBox(
                width: double.infinity,
                child: Text(
                  'لا تنسَ أن تدعو لصاحب التطبيق وأهله وأحبابه بظهر الغيب.',
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption(context).copyWith(
                    fontSize: 9.sp,
                    fontWeight: FontWeight.w700,
                    height: 1.45,
                    color: mutedColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppVersionText extends StatelessWidget {
  const _AppVersionText();

  @override
  Widget build(BuildContext context) {
    final Color mutedColor = AppSettingsDrawer._mutedColor(context);

    return Text(
      'V.0.0.1',
      textAlign: TextAlign.center,
      style: AppTextStyles.caption(context).copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 0.4,
        color: mutedColor.withOpacity(0.74),
      ),
    );
  }
}

part of 'islamic_event_details_page.dart';

class _ShareGreetingCard extends StatelessWidget {
  const _ShareGreetingCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool large = _eventDetailsLargeScreen(context);

    return Material(
      color: theme.colorScheme.primary,
      borderRadius: BorderRadius.circular(large ? 20 : 20.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(large ? 20 : 20.r),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(large ? 14 : 14.w),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Row(
              textDirection: TextDirection.rtl,
              children: [
                Icon(
                  Icons.ios_share_rounded,
                  color: Colors.white,
                  size: large ? 20 : 22.sp,
                ),
                SizedBox(width: large ? 10 : 10.w),
                Expanded(
                  child: Text(
                    'مشاركة التهنئة',
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                    locale: const Locale('ar'),
                    style: AppTextStyles.caption(context).copyWith(
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white.withOpacity(0.85),
                  size: large ? 14 : 15.sp,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ShareOptionsSheet extends StatelessWidget {
  const _ShareOptionsSheet({
    required this.shareCardKey,
    required this.shareTitle,
    required this.shareGreeting,
    required this.imageBackgroundPath,
    required this.pickedBackgroundFile,
    required this.colorBackground,
    required this.backgroundMode,
    required this.isEidEvent,
    required this.isSharingImage,
    required this.shareTextIsWhite,
    required this.shareFontSize,
    required this.titleGreetingSpacing,
    required this.onTitleChanged,
    required this.onGreetingChanged,
    required this.onChangeTextColor,
    required this.onChangeFontSize,
    required this.onChangeSpacing,
    required this.onPickCustomBackground,
    required this.onChangeImageBackground,
    required this.onChangeColorBackground,
    required this.onShareText,
    required this.onShareImage,
  });

  final GlobalKey shareCardKey;
  final String shareTitle;
  final String shareGreeting;
  final String imageBackgroundPath;
  final File? pickedBackgroundFile;
  final Color colorBackground;
  final _ShareBackgroundMode backgroundMode;
  final bool isEidEvent;
  final bool isSharingImage;

  final bool shareTextIsWhite;
  final double shareFontSize;
  final double titleGreetingSpacing;

  final ValueChanged<String> onTitleChanged;
  final ValueChanged<String> onGreetingChanged;
  final ValueChanged<bool> onChangeTextColor;
  final ValueChanged<double> onChangeFontSize;
  final ValueChanged<double> onChangeSpacing;

  final VoidCallback onPickCustomBackground;
  final VoidCallback onChangeImageBackground;
  final VoidCallback onChangeColorBackground;
  final VoidCallback onShareText;
  final Future<void> Function() onShareImage;

  bool get _isImageMode => backgroundMode == _ShareBackgroundMode.image;

  String get _backgroundStatusText {
    if (pickedBackgroundFile != null && _isImageMode) {
      return 'الخلفية الحالية: صورة من الجهاز';
    }

    return _isImageMode
        ? 'الخلفية الحالية: صورة جاهزة'
        : 'الخلفية الحالية: لون';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool large = _eventDetailsLargeScreen(context);

    final double horizontalPadding = large ? 22 : 16.w;
    final double topPadding = large ? 16 : 16.h;
    final double bottomPadding = large ? 18 : 18.h;
    final double radius = large ? 30 : 26.r;
    final double previewGap = large ? 14 : 14.h;
    final double safeTop = MediaQuery.viewPaddingOf(context).top;
    final double sheetMaxHeight =
        MediaQuery.sizeOf(context).height - safeTop - (large ? 14 : 10.h);

    return SafeArea(
      top: true,
      bottom: true,
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(maxHeight: sheetMaxHeight),
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          topPadding,
          horizontalPadding,
          bottomPadding,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(radius)),
        ),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    width: large ? 54 : 42.w,
                    height: large ? 4 : 4.h,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                SizedBox(height: large ? 14 : 14.h),
                SizedBox(
                  width: double.infinity,
                  child: Text(
                    isEidEvent ? 'مشاركة تهنئة العيد' : 'مشاركة التذكير',
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                    locale: const Locale('ar'),
                    style: AppTextStyles.headline(context).copyWith(
                      fontWeight: FontWeight.w900,
                      color: theme.colorScheme.surface,
                      letterSpacing: 0,
                      height: 1.25,
                    ),
                  ),
                ),
                SizedBox(height: large ? 4 : 4.h),
                SizedBox(
                  width: double.infinity,
                  child: Text(
                    _backgroundStatusText,
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                    locale: const Locale('ar'),
                    style: AppTextStyles.caption(context).copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.surface.withOpacity(0.55),
                      letterSpacing: 0,
                    ),
                  ),
                ),
                SizedBox(height: large ? 14 : 12.h),
                Align(
                  alignment: Alignment.center,
                  child: RepaintBoundary(
                    key: shareCardKey,
                    child: _ShareImageCard(
                      title: shareTitle,
                      greeting: shareGreeting,
                      imageBackgroundPath: imageBackgroundPath,
                      pickedBackgroundFile: pickedBackgroundFile,
                      colorBackground: colorBackground,
                      backgroundMode: backgroundMode,
                      shareTextIsWhite: shareTextIsWhite,
                      shareFontSize: shareFontSize,
                      titleGreetingSpacing: titleGreetingSpacing,
                    ),
                  ),
                ),
                SizedBox(height: previewGap),
                _ShareEditableTextControls(
                  title: shareTitle,
                  greeting: shareGreeting,
                  onTitleChanged: onTitleChanged,
                  onGreetingChanged: onGreetingChanged,
                ),
                SizedBox(height: large ? 12 : 12.h),
                _ShareTextStyleControls(
                  shareTextIsWhite: shareTextIsWhite,
                  shareFontSize: shareFontSize,
                  titleGreetingSpacing: titleGreetingSpacing,
                  onChangeTextColor: onChangeTextColor,
                  onChangeFontSize: onChangeFontSize,
                  onChangeSpacing: onChangeSpacing,
                ),
                SizedBox(height: large ? 12 : 12.h),
                _ShareActionButton(
                  title: 'من الجهاز',
                  icon: Icons.photo_library_rounded,
                  onTap: onPickCustomBackground,
                ),
                SizedBox(height: large ? 8 : 8.h),
                _ShareActionButton(
                  title: 'تغيير الصورة',
                  icon: Icons.image_rounded,
                  onTap: onChangeImageBackground,
                ),
                SizedBox(height: large ? 8 : 8.h),
                _ShareActionButton(
                  title: 'اختيار لون',
                  icon: Icons.palette_rounded,
                  onTap: onChangeColorBackground,
                ),
                SizedBox(height: large ? 8 : 8.h),
                _ShareActionButton(
                  title: 'مشاركة كنص',
                  icon: Icons.text_fields_rounded,
                  onTap: onShareText,
                ),
                SizedBox(height: large ? 8 : 8.h),
                _ShareActionButton(
                  title: isSharingImage
                      ? 'جاري تجهيز الصورة...'
                      : 'مشاركة كصورة',
                  icon: Icons.ios_share_rounded,
                  isLoading: isSharingImage,
                  onTap: isSharingImage ? null : onShareImage,
                  isPrimary: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ShareActionsWrap extends StatelessWidget {
  const _ShareActionsWrap({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final double buttonWidth = (MediaQuery.of(context).size.width - 48.w) / 2;

    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      alignment: WrapAlignment.center,
      children: children.map((child) {
        return SizedBox(width: buttonWidth, child: child);
      }).toList(),
    );
  }
}

class _ShareEditableTextControls extends StatelessWidget {
  const _ShareEditableTextControls({
    required this.title,
    required this.greeting,
    required this.onTitleChanged,
    required this.onGreetingChanged,
  });

  final String title;
  final String greeting;
  final ValueChanged<String> onTitleChanged;
  final ValueChanged<String> onGreetingChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool large = _eventDetailsLargeScreen(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(large ? 12 : 12.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondary,
        borderRadius: BorderRadius.circular(large ? 18 : 18.r),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            'تعديل نص المشاركة',
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
            style: AppTextStyles.caption(context).copyWith(
              fontWeight: FontWeight.w900,
              color: theme.colorScheme.surface,
              letterSpacing: 0,
            ),
          ),

          SizedBox(height: 10.h),

          _ShareEditTextField(
            initialValue: title,
            label: 'عنوان المناسبة',
            maxLines: 1,
            onChanged: onTitleChanged,
          ),

          SizedBox(height: 10.h),

          _ShareEditTextField(
            initialValue: greeting,
            label: 'نص التهنئة أو التذكير',
            maxLines: 4,
            onChanged: onGreetingChanged,
          ),
        ],
      ),
    );
  }
}

class _ShareEditTextField extends StatefulWidget {
  const _ShareEditTextField({
    required this.initialValue,
    required this.label,
    required this.maxLines,
    required this.onChanged,
  });

  final String initialValue;
  final String label;
  final int maxLines;
  final ValueChanged<String> onChanged;

  @override
  State<_ShareEditTextField> createState() => _ShareEditTextFieldState();
}

class _ShareEditTextFieldState extends State<_ShareEditTextField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void didUpdateWidget(covariant _ShareEditTextField oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.initialValue != widget.initialValue &&
        _controller.text != widget.initialValue) {
      _controller.value = TextEditingValue(
        text: widget.initialValue,
        selection: TextSelection.collapsed(offset: widget.initialValue.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool large = _eventDetailsLargeScreen(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: TextField(
        controller: _controller,
        maxLines: widget.maxLines,
        textAlign: TextAlign.right,
        textDirection: TextDirection.rtl,
        onChanged: widget.onChanged,
        style: AppTextStyles.caption(context).copyWith(
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.surface,
          height: 1.45,
          letterSpacing: 0,
        ),
        decoration: InputDecoration(
          labelText: widget.label,
          alignLabelWithHint: widget.maxLines > 1,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(large ? 14 : 14.r),
          ),
        ),
      ),
    );
  }
}

class _ShareTextStyleControls extends StatelessWidget {
  const _ShareTextStyleControls({
    required this.shareTextIsWhite,
    required this.shareFontSize,
    required this.titleGreetingSpacing,
    required this.onChangeTextColor,
    required this.onChangeFontSize,
    required this.onChangeSpacing,
  });

  final bool shareTextIsWhite;
  final double shareFontSize;
  final double titleGreetingSpacing;

  final ValueChanged<bool> onChangeTextColor;
  final ValueChanged<double> onChangeFontSize;
  final ValueChanged<double> onChangeSpacing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool large = _eventDetailsLargeScreen(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(large ? 12 : 12.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondary,
        borderRadius: BorderRadius.circular(large ? 18 : 18.r),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            'تخصيص النص',
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
            style: AppTextStyles.caption(context).copyWith(
              fontWeight: FontWeight.w900,
              color: theme.colorScheme.surface,
              letterSpacing: 0,
            ),
          ),

          SizedBox(height: 10.h),

          Row(
            textDirection: TextDirection.rtl,
            children: [
              Expanded(
                child: _ColorChoiceButton(
                  title: 'أبيض',
                  selected: shareTextIsWhite,
                  previewColor: Colors.white,
                  onTap: () => onChangeTextColor(true),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _ColorChoiceButton(
                  title: 'أسود',
                  selected: !shareTextIsWhite,
                  previewColor: Colors.black,
                  onTap: () => onChangeTextColor(false),
                ),
              ),
            ],
          ),

          SizedBox(height: 12.h),

          _ShareSliderControl(
            title: 'حجم الخط',
            valueText: shareFontSize.toStringAsFixed(0),
            value: shareFontSize,
            min: 13,
            max: 24,
            divisions: 11,
            onChangeEnd: onChangeFontSize,
          ),

          SizedBox(height: 6.h),

          _ShareSliderControl(
            title: 'التباعد بين العنوان والتهنئة',
            valueText: titleGreetingSpacing.toStringAsFixed(0),
            value: titleGreetingSpacing,
            min: 0,
            max: 34,
            divisions: 17,
            onChangeEnd: onChangeSpacing,
          ),
        ],
      ),
    );
  }
}

class _ColorChoiceButton extends StatelessWidget {
  const _ColorChoiceButton({
    required this.title,
    required this.selected,
    required this.previewColor,
    required this.onTap,
  });

  final String title;
  final bool selected;
  final Color previewColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool large = _eventDetailsLargeScreen(context);

    return Material(
      color: selected
          ? theme.colorScheme.primary
          : theme.colorScheme.primary.withOpacity(0.08),
      borderRadius: BorderRadius.circular(14.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14.r),
        child: Container(
          height: large ? 36 : 42.h,
          padding: EdgeInsets.symmetric(horizontal: large ? 10 : 10.w),
          child: Row(
            textDirection: TextDirection.rtl,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: large ? 14 : 16.w,
                height: large ? 14 : 16.w,
                decoration: BoxDecoration(
                  color: previewColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? Colors.white : theme.colorScheme.outline,
                    width: 1.2,
                  ),
                ),
              ),
              SizedBox(width: 7.w),
              Text(
                title,
                style: AppTextStyles.caption(context).copyWith(
                  fontWeight: FontWeight.w800,
                  color: selected ? Colors.white : theme.colorScheme.primary,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShareSliderControl extends StatefulWidget {
  const _ShareSliderControl({
    required this.title,
    required this.valueText,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChangeEnd,
  });

  final String title;
  final String valueText;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChangeEnd;

  @override
  State<_ShareSliderControl> createState() => _ShareSliderControlState();
}

class _ShareSliderControlState extends State<_ShareSliderControl> {
  late double _draftValue;

  @override
  void initState() {
    super.initState();
    _draftValue = widget.value;
  }

  @override
  void didUpdateWidget(covariant _ShareSliderControl oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.value != widget.value && _draftValue != widget.value) {
      _draftValue = widget.value;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool large = _eventDetailsLargeScreen(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          textDirection: TextDirection.rtl,
          children: [
            Expanded(
              child: Text(
                widget.title,
                textAlign: TextAlign.right,
                style: AppTextStyles.caption(context).copyWith(
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.surface,
                  letterSpacing: 0,
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: large ? 8 : 8.w,
                vertical: large ? 3 : 3.h,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.10),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Text(
                _draftValue.toStringAsFixed(0),
                style: AppTextStyles.caption(context).copyWith(
                  fontWeight: FontWeight.w900,
                  color: theme.colorScheme.primary,
                  letterSpacing: 0,
                ),
              ),
            ),
          ],
        ),

        Slider(
          value: _draftValue,
          min: widget.min,
          max: widget.max,
          divisions: widget.divisions,
          onChanged: (value) {
            setState(() {
              _draftValue = value;
            });
          },
          onChangeEnd: widget.onChangeEnd,
        ),
      ],
    );
  }
}

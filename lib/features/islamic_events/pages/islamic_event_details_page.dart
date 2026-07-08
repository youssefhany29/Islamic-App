import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:islamic_app/shared/widgets/app_main_components/custom_app_bar.dart';
import 'package:islamic_app/shared/widgets/common_components/app_layout_constants.dart';
import 'package:islamic_app/core/services/app_haptics.dart';
import 'package:image_picker/image_picker.dart' as image_picker;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/islamic_event_model.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';
part 'islamic_event_details_widgets.dart';
part 'islamic_event_details_content_widgets.dart';
part 'islamic_event_details_share_sheet.dart';
part 'islamic_event_details_share_image_widgets.dart';

bool _eventDetailsLargeScreen(BuildContext context) {
  final Size size = MediaQuery.sizeOf(context);
  return size.shortestSide >= 600 || (size.width >= 700 && size.height >= 500);
}

enum _ShareBackgroundMode { image, color }

class IslamicEventDetailsPage extends StatefulWidget {
  const IslamicEventDetailsPage({super.key, required this.event});

  final IslamicEventModel event;

  @override
  State<IslamicEventDetailsPage> createState() =>
      _IslamicEventDetailsPageState();
}

class _IslamicEventDetailsPageState extends State<IslamicEventDetailsPage> {
  final GlobalKey _shareCardKey = GlobalKey();

  int _selectedImageIndex = 0;
  int _selectedColorIndex = 0;
  bool _isSharingImage = false;
  bool _shareTextIsWhite = true;
  double _shareFontSize = 18.5;
  double _shareTitleGreetingSpacing = 10;

  String? _customShareTitle;
  String? _customShareGreeting;
  File? _pickedShareBackgroundFile;

  _ShareBackgroundMode _backgroundMode = _ShareBackgroundMode.image;

  IslamicEventModel get event => widget.event;

  bool get _isFastingEvent {
    return event.type == IslamicEventType.fasting ||
        event.title.contains('صيام') ||
        event.title.contains('الأيام البيض') ||
        event.title.contains('عرفة') ||
        event.title.contains('عاشوراء') ||
        event.title.contains('ذي الحجة');
  }

  bool get _isGreetingEvent {
    return event.type == IslamicEventType.greeting ||
        event.title.contains('عيد') ||
        event.title.contains('رمضان مبارك') ||
        event.title.contains('الفطر') ||
        event.title.contains('الأضحى');
  }

  bool get _isEidEvent {
    return event.title.contains('عيد') ||
        event.title.contains('الفطر') ||
        event.title.contains('الأضحى');
  }

  bool get _isRamadanEvent {
    return event.title.contains('رمضان') ||
        event.title.contains('العشر الأواخر');
  }

  bool get _isWhiteDays {
    return event.title.contains('الأيام البيض');
  }

  bool get _isArafah {
    return event.title.contains('عرفة');
  }

  bool get _isAshura {
    return event.title.contains('عاشوراء') || event.title.contains('تاسوعاء');
  }

  bool get _isDhulHijjahFirstDays {
    return event.title.contains('ذي الحجة') ||
        event.title.contains('العشر الأوائل');
  }

  bool get _isMondayThursday {
    return event.title.contains('الاثنين') || event.title.contains('الخميس');
  }

  List<String> get _shareImageBackgrounds {
    final String folder = _isEidEvent ? 'eid' : 'ramadan';

    return List.generate(
      5,
      (index) => 'assets/background/$folder/${index + 1}.webp',
    );
  }

  List<Color> get _shareColorBackgrounds {
    if (_isEidEvent) {
      return const [
        Color(0xff0F4A3C),
        Color(0xff102D5C),
        Color(0xffF1DFB8),
        Color(0xffD99A9A),
        Color(0xff0F6B66),
      ];
    }

    return const [
      Color(0xff8B5E3C),
      Color(0xff9A6A4F),
      Color(0xffA65F46),
      Color(0xff7A6A43),
      Color(0xff8A5A5A),
    ];
  }

  Color get _selectedColorBackground {
    return _shareColorBackgrounds[_selectedColorIndex %
        _shareColorBackgrounds.length];
  }

  String get _selectedImageBackground {
    return _shareImageBackgrounds[_selectedImageIndex %
        _shareImageBackgrounds.length];
  }

  bool get _isUsingImageBackground {
    return _backgroundMode == _ShareBackgroundMode.image;
  }

  int _daysUntil(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);

    return target.difference(today).inDays;
  }

  String _daysText(int days) {
    if (days == 0) return 'اليوم';
    if (days == 1) return 'غدًا';
    if (days == 2) return 'بعد يومين';

    return 'بعد $days أيام';
  }

  String _gregorianDateText(DateTime date) {
    final String day = date.day.toString().padLeft(2, '0');
    final String month = date.month.toString().padLeft(2, '0');
    final String year = date.year.toString();

    return '$day/$month/$year';
  }

  String _typeText(IslamicEventType type) {
    switch (type) {
      case IslamicEventType.fasting:
        return 'صيام';
      case IslamicEventType.greeting:
        return 'تهنئة';
      case IslamicEventType.specialDay:
        return 'مناسبة خاصة';
      case IslamicEventType.reminder:
        return 'تذكير';
    }
  }

  IconData _typeIcon(IslamicEventType type) {
    switch (type) {
      case IslamicEventType.fasting:
        return Icons.nightlight_round;
      case IslamicEventType.greeting:
        return Icons.celebration_rounded;
      case IslamicEventType.specialDay:
        return Icons.star_rounded;
      case IslamicEventType.reminder:
        return Icons.notifications_active_rounded;
    }
  }

  String _mainAdviceText() {
    if (_isArafah) {
      return 'يوم عرفة من أعظم أيام العام، فاستعد له بالصيام إن استطعت، وأكثر من الدعاء والاستغفار والذكر.';
    }

    if (_isAshura) {
      return 'تاسوعاء وعاشوراء فرصة عظيمة للصيام والعمل الصالح، فاستعد بنية صادقة وذكر كثير.';
    }

    if (_isWhiteDays) {
      return 'الأيام البيض فرصة جميلة لتثبيت عادة الصيام كل شهر، جهّز نيتك من الليل وخفّف طعامك للسحور.';
    }

    if (_isDhulHijjahFirstDays) {
      return 'العشر الأوائل من ذي الحجة أيام مباركة، أكثر فيها من التكبير والذكر والصدقة والعمل الصالح.';
    }

    if (_isMondayThursday) {
      return 'صيام الاثنين والخميس عادة عظيمة، حاول تجهيز نيتك من الليل واجعلها بداية لأسبوع مليء بالطاعة.';
    }

    if (event.title.contains('عيد أضحى')) {
      return 'استقبل العيد بالفرح وصلة الرحم، ولا تنس التكبير وإدخال السرور على أهلك ومن حولك.';
    }

    if (event.title.contains('عيد فطر')) {
      return 'اجعل العيد بداية شكر وفرح بعد رمضان، وصل رحمك وشارك من حولك الكلمة الطيبة والتهنئة.';
    }

    if (_isRamadanEvent) {
      return 'استعد لرمضان بالقرآن والدعاء وتنظيم الوقت، واجعل لك وردًا ثابتًا من الآن.';
    }

    if (_isGreetingEvent) {
      return 'اجعل هذه المناسبة فرصة لصلة الرحم، وإدخال السرور على أهلك ومن حولك.';
    }

    if (_isFastingEvent) {
      return 'استعد لهذه المناسبة بنية صادقة، وأكثر من الدعاء والذكر والعمل الصالح.';
    }

    return 'اجعل هذه المناسبة فرصة للتذكّر، والذكر، والعمل الصالح.';
  }

  String _sharingText() {
    if (event.title.contains('عيد أضحى')) {
      return 'عيد أضحى مبارك\nكل عام وأنتم بخير\nتقبل الله منا ومنكم صالح الأعمال';
    }

    if (event.title.contains('عيد فطر')) {
      return 'عيد فطر مبارك\nكل عام وأنتم بخير\nتقبل الله منا ومنكم صالح الأعمال';
    }

    if (event.title.contains('رمضان')) {
      return 'رمضان مبارك\nاللهم بلغنا رمضان وبارك لنا فيه\nوأعنا على الصيام والقيام';
    }

    if (_isArafah) {
      return 'غدًا يوم عرفة\nلا تنس نية الصيام والدعاء\nخير الدعاء دعاء يوم عرفة';
    }

    if (_isAshura) {
      return '${event.title}\nمن الأيام المستحب صيامها\nتقبل الله منا ومنكم';
    }

    if (_isWhiteDays) {
      return 'تذكير بالأيام البيض\nلا تنس نية الصيام\nوتقبل الله منك صالح العمل';
    }

    if (_isMondayThursday) {
      return '${event.title}\nلا تنس نية الصيام من الليل\nتقبل الله منك';
    }

    return '${event.title}\n${event.subtitle}';
  }

  List<String> _sharingLines() {
    return _sharingText()
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
  }

  String _defaultShareTitle() {
    final lines = _sharingLines();
    if (lines.isEmpty) return event.title;
    return lines.first;
  }

  String _defaultShareGreeting() {
    final lines = _sharingLines();
    if (lines.length <= 1) return event.subtitle;
    return lines.skip(1).join('\n');
  }

  String _currentShareTitle() {
    final customTitle = _customShareTitle?.trim();

    if (customTitle != null && customTitle.isNotEmpty) {
      return customTitle;
    }

    return _defaultShareTitle();
  }

  String _currentShareGreeting() {
    final customGreeting = _customShareGreeting?.trim();

    if (customGreeting != null && customGreeting.isNotEmpty) {
      return customGreeting;
    }

    return _defaultShareGreeting();
  }

  String _currentSharingText() {
    final title = _currentShareTitle();
    final greeting = _currentShareGreeting();

    if (greeting.trim().isEmpty) {
      return title;
    }

    return '$title\n$greeting';
  }

  void _changeImageBackground(
    BuildContext context,
    void Function(void Function()) setSheetState,
  ) {
    AppHaptics.tap(context);

    setSheetState(() {
      _pickedShareBackgroundFile = null;
      _backgroundMode = _ShareBackgroundMode.image;
      _selectedImageIndex =
          (_selectedImageIndex + 1) % _shareImageBackgrounds.length;
    });

    setState(() {});
  }

  void _changeColorBackground(
    BuildContext context,
    void Function(void Function()) setSheetState,
  ) {
    AppHaptics.tap(context);

    setSheetState(() {
      _backgroundMode = _ShareBackgroundMode.color;
      _selectedColorIndex =
          (_selectedColorIndex + 1) % _shareColorBackgrounds.length;
    });

    setState(() {});
  }

  void _changeShareTextColor(
    bool isWhite,
    void Function(void Function()) setSheetState,
  ) {
    AppHaptics.tap(context);

    setSheetState(() {
      _shareTextIsWhite = isWhite;
    });

    setState(() {});
  }

  void _changeShareFontSize(
    double value,
    void Function(void Function()) setSheetState,
  ) {
    setSheetState(() {
      _shareFontSize = value;
    });

    setState(() {});
  }

  void _changeShareSpacing(
    double value,
    void Function(void Function()) setSheetState,
  ) {
    setSheetState(() {
      _shareTitleGreetingSpacing = value;
    });

    setState(() {});
  }

  Future<void> _pickCustomShareBackground(
    void Function(void Function()) setSheetState,
  ) async {
    AppHaptics.tap(context);

    final picker = image_picker.ImagePicker();

    final image_picker.XFile? pickedFile = await picker.pickImage(
      source: image_picker.ImageSource.gallery,
      imageQuality: 85,
    );

    if (pickedFile == null) return;

    setSheetState(() {
      _pickedShareBackgroundFile = File(pickedFile.path);
      _backgroundMode = _ShareBackgroundMode.image;
    });

    setState(() {});
  }

  void _updateShareTitle(
    String value,
    void Function(void Function()) setSheetState,
  ) {
    setSheetState(() {
      _customShareTitle = value;
    });

    setState(() {});
  }

  void _updateShareGreeting(
    String value,
    void Function(void Function()) setSheetState,
  ) {
    setSheetState(() {
      _customShareGreeting = value;
    });

    setState(() {});
  }

  void _openShareOptions(BuildContext context) {
    AppHaptics.tap(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return _ShareOptionsSheet(
              shareCardKey: _shareCardKey,
              shareTitle: _currentShareTitle(),
              shareGreeting: _currentShareGreeting(),
              imageBackgroundPath: _selectedImageBackground,
              pickedBackgroundFile: _pickedShareBackgroundFile,
              colorBackground: _selectedColorBackground,
              backgroundMode: _backgroundMode,
              isEidEvent: _isEidEvent,
              isSharingImage: _isSharingImage,
              shareTextIsWhite: _shareTextIsWhite,
              shareFontSize: _shareFontSize,
              titleGreetingSpacing: _shareTitleGreetingSpacing,

              onTitleChanged: (value) {
                _updateShareTitle(value, setSheetState);
              },
              onGreetingChanged: (value) {
                _updateShareGreeting(value, setSheetState);
              },
              onChangeTextColor: (isWhite) {
                _changeShareTextColor(isWhite, setSheetState);
              },
              onChangeFontSize: (value) {
                _changeShareFontSize(value, setSheetState);
              },
              onChangeSpacing: (value) {
                _changeShareSpacing(value, setSheetState);
              },

              onPickCustomBackground: () {
                _pickCustomShareBackground(setSheetState);
              },
              onChangeImageBackground: () {
                _changeImageBackground(context, setSheetState);
              },
              onChangeColorBackground: () {
                _changeColorBackground(context, setSheetState);
              },
              onShareText: () {
                _shareAsText(context);
              },
              onShareImage: () async {
                setSheetState(() {
                  _isSharingImage = true;
                });

                await _shareAsImage(context);

                if (!mounted) return;

                setSheetState(() {
                  _isSharingImage = false;
                });
              },
            );
          },
        );
      },
    );
  }

  Future<void> _shareAsText(BuildContext context) async {
    AppHaptics.tap(context);

    await SharePlus.instance.share(ShareParams(text: _currentSharingText()));
  }

  Future<void> _shareAsImage(BuildContext context) async {
    AppHaptics.tap(context);

    try {
      final boundary =
          _shareCardKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;

      if (boundary == null) {
        _showSnackBar(
          context,
          message: 'حدث خطأ أثناء تجهيز الصورة',
          icon: Icons.error_outline_rounded,
        );
        return;
      }

      final ui.Image image = await boundary.toImage(pixelRatio: 3);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        _showSnackBar(
          context,
          message: 'تعذر حفظ صورة المشاركة',
          icon: Icons.error_outline_rounded,
        );
        return;
      }

      final tempDir = await getTemporaryDirectory();
      final file = File(
        '${tempDir.path}/islamic_event_share_${DateTime.now().millisecondsSinceEpoch}.png',
      );

      await file.writeAsBytes(byteData.buffer.asUint8List());

      await SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));
    } catch (_) {
      if (!context.mounted) return;

      _showSnackBar(
        context,
        message: 'حدث خطأ أثناء مشاركة الصورة',
        icon: Icons.error_outline_rounded,
      );
    }
  }

  void _showSnackBar(
    BuildContext context, {
    required String message,
    required IconData icon,
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xff171B26),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        content: Directionality(
          textDirection: TextDirection.rtl,
          child: Row(
            children: [
              Icon(icon, color: const Color(0xff21C58E), size: 21.sp),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  message,
                  textAlign: TextAlign.right,
                  style: AppTextStyles.caption(context).copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final int days = _daysUntil(event.gregorianDate);
    final bool large = _eventDetailsLargeScreen(context);

    final List<Widget> infoCards = [
      _InfoCard(
        icon: Icons.info_outline_rounded,
        title: 'عن المناسبة',
        body: event.subtitle,
      ),
      _InfoCard(
        icon: Icons.favorite_rounded,
        title: 'نصيحة اليوم',
        body: _mainAdviceText(),
      ),
      if (_isFastingEvent) const _FastingIntentionCard(),
      if (_isGreetingEvent ||
          _isRamadanEvent ||
          _isFastingEvent ||
          event.type == IslamicEventType.specialDay ||
          event.type == IslamicEventType.reminder)
        _ShareGreetingCard(onTap: () => _openShareOptions(context)),
    ];

    if (!large) {
      return Scaffold(
        backgroundColor: theme.colorScheme.background,
        appBar: const CustomAppBar(
          category: CustomAppBarCategory(text: 'تفاصيل المناسبة'),
        ),
        body: SafeArea(
          top: false,
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(
              horizontal: AppLayoutConstants.pageHorizontalPadding,
            ),
            children: [
              SizedBox(height: 16.h),
              _HeroDetailsCard(
                event: event,
                daysText: event.isToday ? 'اليوم' : _daysText(days),
                gregorianDateText: _gregorianDateText(event.gregorianDate),
                typeText: _typeText(event.type),
                typeIcon: _typeIcon(event.type),
              ),
              SizedBox(height: 14.h),
              for (int i = 0; i < infoCards.length; i++) ...[
                infoCards[i],
                if (i != infoCards.length - 1) SizedBox(height: 12.h),
              ],
              SizedBox(height: 18.h),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: const CustomAppBar(
        category: CustomAppBarCategory(text: 'تفاصيل المناسبة'),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(28, 18, 28, 32),
          children: [
            _HeroDetailsCard(
              event: event,
              daysText: event.isToday ? 'اليوم' : _daysText(days),
              gregorianDateText: _gregorianDateText(event.gregorianDate),
              typeText: _typeText(event.type),
              typeIcon: _typeIcon(event.type),
            ),
            const SizedBox(height: 16),
            Column(
              children: [
                for (int i = 0; i < infoCards.length; i++) ...[
                  infoCards[i],
                  if (i != infoCards.length - 1) const SizedBox(height: 14),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:islamic_app/core/services/app_haptics.dart';
import 'package:islamic_app/core/services/user_profile_service.dart';
import 'package:islamic_app/features/prayer/data/services/prayer_widget_sync_service.dart';
import 'package:islamic_app/features/settings/notifications_settings_provider.dart';
import 'package:islamic_app/features/settings/prayer_background_style_provider.dart';
import 'package:islamic_app/features/settings/reminder_settings_page.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:islamic_app/core/theme/theme_provider.dart';
import 'package:islamic_app/shared/widgets/common_components/no_animation_page_route.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';
part 'app_settings_drawer_widgets.dart';

class AppSettingsDrawer extends StatelessWidget {
  const AppSettingsDrawer({
    super.key,
    this.onUserNameChanged,
    this.onEditInterface,
  });

  final VoidCallback? onUserNameChanged;
  final VoidCallback? onEditInterface;

  static const Color _drawerSurfaceColor = Colors.white;
  static const Color _primaryTextColor = Color(0xff143A67);
  static const Color _secondaryTextColor = Color(0xff6F7F99);
  static const Color _lineColor = Color(0xffE7EBF1);
  static const Color _iconBackgroundColor = Color(0xffF1F3F7);
  static const Color _chipBackgroundColor = Color(0xffF6F8FB);
  static const Color _itemBackgroundColor = Color(0xff171B26);
  static const Color _successColor = Color(0xff224368);

  static bool _isDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  static Color _cardColor(BuildContext context) {
    final theme = Theme.of(context);
    return _isDark(context) ? theme.colorScheme.secondary : _drawerSurfaceColor;
  }

  static Color _innerCardColor(BuildContext context) {
    final theme = Theme.of(context);
    return _isDark(context)
        ? theme.colorScheme.surface.withOpacity(0.055)
        : Colors.white;
  }

  static Color _titleColor(BuildContext context) {
    final theme = Theme.of(context);
    return _isDark(context) ? theme.colorScheme.surface : _primaryTextColor;
  }

  static Color _bodyColor(BuildContext context) {
    final theme = Theme.of(context);
    return _isDark(context)
        ? theme.colorScheme.surface.withOpacity(0.88)
        : Colors.black.withOpacity(0.86);
  }

  static Color _mutedColor(BuildContext context) {
    final theme = Theme.of(context);
    return _isDark(context)
        ? theme.colorScheme.surface.withOpacity(0.62)
        : _secondaryTextColor;
  }

  static Color _borderColor(BuildContext context) {
    final theme = Theme.of(context);
    return _isDark(context)
        ? theme.colorScheme.outline.withOpacity(0.12)
        : _lineColor;
  }

  static Color _accentColor(BuildContext context) {
    return Theme.of(context).colorScheme.primary;
  }

  static Color _iconBackground(BuildContext context) {
    return _isDark(context)
        ? _accentColor(context).withOpacity(0.13)
        : _iconBackgroundColor;
  }

  static Color _chipBackground(BuildContext context) {
    final theme = Theme.of(context);
    return _isDark(context)
        ? theme.colorScheme.surface.withOpacity(0.055)
        : _chipBackgroundColor;
  }

  void _showEnableNotificationsSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: _itemBackgroundColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14.r),
        ),
        content: Row(
          textDirection: TextDirection.rtl,
          children: [
            const Icon(
              Icons.notifications_off_rounded,
              color: Color(0xffF6C453),
              size: 22,
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                'يجب تفعيل زر الإشعارات أولًا لفتح إعدادات التذكيرات.',
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
                style: AppTextStyles.caption(
                  context,
                ).copyWith(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openContactEmail(BuildContext context) async {
    const String email = 'youssifhany2222@gmail.com';

    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {
        'subject': 'تواصل من تطبيق ديني في جيبي',
        'body': 'السلام عليكم،\n\n',
      },
    );

    try {
      final bool opened = await launchUrl(
        emailUri,
        mode: LaunchMode.externalApplication,
      );

      if (opened) return;
    } catch (_) {
      // fallback تحت
    }

    await Clipboard.setData(const ClipboardData(text: email));

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: _itemBackgroundColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14.r),
        ),
        content: Text(
          'لم يتم العثور على تطبيق بريد. تم نسخ الإيميل بدلًا من ذلك.',
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.right,
          style: AppTextStyles.caption(
            context,
          ).copyWith(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Future<void> _showEditNameDialog(BuildContext context) async {
    final scaffoldMessenger = ScaffoldMessenger.maybeOf(context);

    final String? newName = await showDialog<String>(
      context: context,
      useRootNavigator: true,
      builder: (_) {
        return const _EditUserNameDialog();
      },
    );

    if (newName == null) return;

    await const UserProfileService().setUserName(newName);

    onUserNameChanged?.call();

    scaffoldMessenger?.showSnackBar(
      SnackBar(
        backgroundColor: _itemBackgroundColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14.r),
        ),
        content: Text(
          'تم تعديل الاسم بنجاح',
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.right,
          style: AppTextStyles.caption(
            context,
          ).copyWith(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  void _showIconSourcesDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18.r),
            ),
            title: Text(
              'المصادر والحقوق',
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              style: AppTextStyles.body(
                context,
              ).copyWith(fontWeight: FontWeight.w800, color: Colors.white),
            ),
            content: SingleChildScrollView(
              child: Text(
                'تم استخدام أيقونات وصور التطبيق من مصدرين مرخّصين: Magnific.com و Flaticon.com.\n\n'
                '• أيقونات من Magnific.com — الإسناد: designed by Aranagraphics - Magnific.com.\n\n'
                '• أيقونات من Flaticon.com — الإسناد: designed by Freepik from Flaticon.\n\n'
                'تنويه YouTube: الفيديوهات المعروضة داخل التطبيق يتم تشغيلها من خلال YouTube أو روابطه الرسمية، ولا يقوم التطبيق بإعادة رفع الفيديوهات أو ادعاء ملكيتها. جميع الحقوق محفوظة لأصحاب القنوات وصنّاع المحتوى الأصليين.\n\nيتم عرض هذا التنويه احترامًا لشروط الترخيص وحقوق المصممين وصنّاع المحتوى.',
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
                style: AppTextStyles.caption(context).copyWith(
                  fontWeight: FontWeight.w600,
                  height: 1.65,
                  color: Colors.white.withOpacity(0.82),
                ),
              ),
            ),
            actionsAlignment: MainAxisAlignment.start,
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext, rootNavigator: true).pop();
                },
                child: Text(
                  'فهمت',
                  style: AppTextStyles.caption(
                    context,
                  ).copyWith(fontWeight: FontWeight.w800, color: _successColor),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final notificationsProvider = Provider.of<NotificationsSettingsProvider>(
      context,
    );

    final bool isDark = themeProvider.themeData.brightness == Brightness.dark;
    final Color drawerSurfaceColor = Theme.of(context).scaffoldBackgroundColor;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Drawer(
        width: MediaQuery.sizeOf(context).width * 0.9,
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: SafeArea(
          child: Align(
            alignment: Alignment.centerRight,
            child: Container(
              width: double.infinity,
              height: double.infinity,
              margin: EdgeInsets.only(
                left: 8.w,
                top: 6.h,
                bottom: 6.h,
                right: 0,
              ),
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 20.h),
              decoration: BoxDecoration(
                color: drawerSurfaceColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(34.r),
                  bottomLeft: Radius.circular(34.r),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const _SettingsHeader(),
                    SizedBox(height: 22.h),
                    _SettingsSectionCard(
                      title: 'إعدادات التطبيق',
                      children: [
                        _SettingsSwitchTile(
                          title: notificationsProvider.isChanging
                              ? 'جاري التفعيل...'
                              : 'الإشعارات',
                          icon: Icons.notifications_none_rounded,
                          value: notificationsProvider.notificationsEnabled,
                          onChanged:
                              notificationsProvider.isLoaded &&
                                  !notificationsProvider.isChanging
                              ? (value) async {
                                  await notificationsProvider
                                      .setNotificationsEnabled(value);
                                }
                              : null,
                        ),
                        _SettingsButton(
                          title: 'التذكيرات',
                          icon: Icons.notifications_active_outlined,
                          onTap: () {
                            if (!notificationsProvider.notificationsEnabled) {
                              _showEnableNotificationsSnackBar(context);
                              return;
                            }
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              NoAnimationPageRoute(
                                page: const ReminderSettingsPage(),
                              ),
                            );
                          },
                        ),
                        _SettingsSwitchTile(
                          title: 'وضع الليل',
                          icon: Icons.dark_mode_outlined,
                          value: isDark,
                          onChanged: (value) {
                            Provider.of<ThemeProvider>(
                              context,
                              listen: false,
                            ).toggleTheme();
                          },
                        ),
                        _SettingsSwitchTile(
                          title: 'الإهتزاز عند النقر',
                          icon: Icons.vibration_rounded,
                          value: notificationsProvider.hapticFeedbackEnabled,
                          onChanged: notificationsProvider.isLoaded
                              ? (value) async {
                                  await notificationsProvider
                                      .setHapticFeedbackEnabled(value);

                                  if (value) {
                                    HapticFeedback.mediumImpact();
                                  }
                                }
                              : null,
                        ),
                        _SettingsButton(
                          title: 'تعديل الاسم',
                          icon: Icons.person_outline_rounded,
                          onTap: () {
                            _showEditNameDialog(context);
                          },
                        ),
                        _SettingsButton(
                          title: 'المصادر والحقوق',
                          icon: Icons.verified_outlined,
                          onTap: () {
                            _showIconSourcesDialog(context);
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: 14.h),
                    const _PrayerBackgroundStyleCard(),
                    SizedBox(height: 14.h),
                    _SettingsSectionCard(
                      title: 'إعدادات أخرى',
                      children: [
                        _SettingsButton(
                          title: 'قيم التطبيق',
                          icon: Icons.star_rounded,
                          onTap: () {},
                        ),
                        _SettingsButton(
                          title: 'شارك التطبيق',
                          icon: Icons.ios_share_outlined,
                          onTap: () async {
                            await SharePlus.instance.share(
                              ShareParams(text: 'جرب تطبيق ديني في جيبي 🌙'),
                            );
                          },
                        ),
                        _SettingsButton(
                          title: 'تواصل معنا',
                          icon: Icons.email_outlined,
                          onTap: () {
                            _openContactEmail(context);
                          },
                        ),
                      ],
                    ),

                    SizedBox(height: 18.h),

                    const _DuaRequestCard(),

                    SizedBox(height: 10.h),

                    const _AppVersionText(),
                    SizedBox(height: 16.h),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

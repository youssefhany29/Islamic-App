import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';
class QiblaDirectionPage extends StatefulWidget {
  const QiblaDirectionPage({super.key});

  @override
  State<QiblaDirectionPage> createState() => _QiblaDirectionPageState();
}

class _QiblaDirectionPageState extends State<QiblaDirectionPage> {
  static const double _kaabaLatitude = 21.4224779;
  static const double _kaabaLongitude = 39.8251832;

  StreamSubscription<CompassEvent>? _compassSubscription;

  bool _isLoading = true;
  String? _errorMessage;

  double? _qiblaBearing;
  double? _heading;
  double? _distanceInKm;
  bool _compassUnavailable = false;

  @override
  void initState() {
    super.initState();
    _loadQiblaDirection();
    _listenToCompass();
  }

  @override
  void dispose() {
    _compassSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadQiblaDirection() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final position = await _determinePosition();

      final bearing = Geolocator.bearingBetween(
        position.latitude,
        position.longitude,
        _kaabaLatitude,
        _kaabaLongitude,
      );

      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        _kaabaLatitude,
        _kaabaLongitude,
      );

      if (!mounted) return;

      setState(() {
        _qiblaBearing = _normalizeDegree(bearing);
        _distanceInKm = distance / 1000;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage = error.toString();
        _isLoading = false;
      });
    }
  }

  void _listenToCompass() {
    try {
      final compassStream = FlutterCompass.events;

      if (compassStream == null) {
        if (!mounted) return;

        setState(() {
          _heading = null;
          _compassUnavailable = true;
        });
        return;
      }

      _compassSubscription = compassStream.listen(
            (event) {
          if (!mounted) return;

          setState(() {
            _heading = event.heading;
            _compassUnavailable = event.heading == null;
          });
        },
        onError: (_) {
          if (!mounted) return;

          setState(() {
            _heading = null;
            _compassUnavailable = true;
          });
        },
        cancelOnError: false,
      );
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _heading = null;
        _compassUnavailable = true;
      });
    }
  }

  Future<Position> _determinePosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      throw 'خدمة الموقع مقفولة. افتح الـ GPS وجرب تاني.';
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied) {
        throw 'لازم تسمح للتطبيق باستخدام الموقع عشان نحدد اتجاه القبلة.';
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw 'صلاحية الموقع مرفوضة نهائيًا. افتح إعدادات التطبيق وفعّل الموقع.';
    }

    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  double _normalizeDegree(double degree) {
    final normalized = degree % 360;
    return normalized < 0 ? normalized + 360 : normalized;
  }

  String _directionText(double bearing) {
    if (bearing >= 337.5 || bearing < 22.5) return 'شمال';
    if (bearing >= 22.5 && bearing < 67.5) return 'شمال شرق';
    if (bearing >= 67.5 && bearing < 112.5) return 'شرق';
    if (bearing >= 112.5 && bearing < 157.5) return 'جنوب شرق';
    if (bearing >= 157.5 && bearing < 202.5) return 'جنوب';
    if (bearing >= 202.5 && bearing < 247.5) return 'جنوب غرب';
    if (bearing >= 247.5 && bearing < 292.5) return 'غرب';
    return 'شمال غرب';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    final qiblaBearing = _qiblaBearing;
    final heading = _heading;

    final double rotationDegree = qiblaBearing == null || heading == null
        ? 0
        : _normalizeDegree(qiblaBearing - heading);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xff0E1118) : const Color(0xffF6F7FB),
        appBar: AppBar(
          centerTitle: true,
          elevation: 0,
          backgroundColor: isDark ? const Color(0xff0E1118) : const Color(0xffF6F7FB),
          foregroundColor: isDark ? Colors.white : const Color(0xff171B26),
          title: Text(
            'اتجاه القبلة',
            style: AppTextStyles.body(context).copyWith(
fontWeight: FontWeight.w800
),
          ),
        ),
        body: SafeArea(
          child: _buildBody(
            context: context,
            isDark: isDark,
            primaryColor: primaryColor,
            qiblaBearing: qiblaBearing,
            rotationDegree: rotationDegree,
          ),
        ),
      ),
    );
  }

  Widget _buildBody({
    required BuildContext context,
    required bool isDark,
    required Color primaryColor,
    required double? qiblaBearing,
    required double rotationDegree,
  }) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: primaryColor,
        ),
      );
    }

    if (_errorMessage != null) {
      return Padding(
        padding: EdgeInsets.all(18.w),
        child: Center(
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(18.w),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xff171B26) : Colors.white,
              borderRadius: BorderRadius.circular(22.r),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.location_off_rounded,
                  color: primaryColor,
                  size: 42.sp,
                ),
                SizedBox(height: 14.h),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xff171B26)
),
                ),
                SizedBox(height: 18.h),
                ElevatedButton(
                  onPressed: _loadQiblaDirection,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                  ),
                  child: Text(
                    'إعادة المحاولة',
                    style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w700
),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final double compassSize = constraints.maxHeight < 700 ? 215.w : 245.w;

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 14.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _InstructionCard(
                isDark: isDark,
              ),

              SizedBox(height: 22.h),

              _CompassCircle(
                isDark: isDark,
                primaryColor: primaryColor,
                rotationDegree: rotationDegree,
                compassSize: compassSize,
              ),

              SizedBox(height: 22.h),

              _QiblaInfoCard(
                isDark: isDark,
                qiblaBearing: qiblaBearing,
                distanceInKm: _distanceInKm,
                heading: _heading,
                compassUnavailable: _compassUnavailable,
                directionText: qiblaBearing == null ? null : _directionText(qiblaBearing),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _InstructionCard extends StatelessWidget {
  final bool isDark;

  const _InstructionCard({
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 15.h),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xff171B26) : Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.12 : 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'وجّه أعلى الهاتف ناحية السهم',
            textAlign: TextAlign.center,
            style: AppTextStyles.body(context).copyWith(
fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xff171B26)
),
          ),
          SizedBox(height: 6.h),
          Text(
            'حرّك الهاتف بهدوء لحد ما السهم يستقر على اتجاه القبلة',
            textAlign: TextAlign.center,
            style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w500,
              color: isDark
                  ? Colors.white.withOpacity(0.65)
                  : const Color(0xff171B26).withOpacity(0.6)
),
          ),
        ],
      ),
    );
  }
}

class _CompassCircle extends StatelessWidget {
  final bool isDark;
  final Color primaryColor;
  final double rotationDegree;
  final double compassSize;

  const _CompassCircle({
    required this.isDark,
    required this.primaryColor,
    required this.rotationDegree,
    required this.compassSize,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: compassSize,
      height: compassSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: compassSize,
            height: compassSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? const Color(0xff171B26) : Colors.white,
              border: Border.all(
                color: primaryColor.withOpacity(0.18),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.22 : 0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
          ),

          Positioned(
            top: 12.h,
            child: Text(
              'N',
              style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w900,
                color: primaryColor
),
            ),
          ),

          AnimatedRotation(
            turns: rotationDegree / 360,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.navigation_rounded,
                  color: primaryColor,
                  size: 78.sp,
                ),
                SizedBox(height: 4.h),
                Image.asset(
                  'assets/icons/kaaba (1).png',
                  width: 40.w,
                  height: 40.w,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.mosque_rounded,
                      color: primaryColor,
                      size: 34.sp,
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QiblaInfoCard extends StatelessWidget {
  final bool isDark;
  final double? qiblaBearing;
  final double? distanceInKm;
  final double? heading;
  final bool compassUnavailable;
  final String? directionText;

  const _QiblaInfoCard({
    required this.isDark,
    required this.qiblaBearing,
    required this.distanceInKm,
    required this.heading,
    required this.compassUnavailable,
    required this.directionText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 15.h),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xff171B26) : Colors.white,
        borderRadius: BorderRadius.circular(22.r),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            qiblaBearing == null
                ? 'جاري تحديد الاتجاه...'
                : 'اتجاه القبلة: ${qiblaBearing!.toStringAsFixed(1)}° - $directionText',
            textAlign: TextAlign.center,
            style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xff171B26)
),
          ),

          if (distanceInKm != null) ...[
            SizedBox(height: 6.h),
            Text(
              'المسافة التقريبية إلى الكعبة: ${distanceInKm!.toStringAsFixed(0)} كم',
              textAlign: TextAlign.center,
              style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w500,
                color: isDark
                    ? Colors.white.withOpacity(0.62)
                    : const Color(0xff171B26).withOpacity(0.55)
),
            ),
          ],

          if (compassUnavailable || heading == null) ...[
            SizedBox(height: 9.h),
            Text(
              'لو السهم مش بيتحرك، اقفل التطبيق وافتحه من جديد أو الجهاز لا يدعم حساس البوصلة.',
              textAlign: TextAlign.center,
              style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w700,
                color: Colors.orangeAccent,
                height: 1.35
),
            ),
          ],
        ],
      ),
    );
  }
}
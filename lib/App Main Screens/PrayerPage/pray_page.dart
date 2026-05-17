import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:islamic_app/App%20Main%20Screens/PrayerPage/Prayer%20Components/following_pray.dart';
import '../../Common Components/SquareLogo.dart';
import '../App Main Screens Components/custom_app_bar.dart';
import 'Prayer Components/pray_table.dart';
import 'Services/location_service.dart';
import 'Services/prayer_time_service.dart';

class PrayPage extends StatefulWidget {
  const PrayPage({super.key});

  @override
  State<PrayPage> createState() => _PrayPageState();
}

class _PrayPageState extends State<PrayPage> {
  final LocationService _locationService = LocationService();
  final PrayerTimeService _prayerTimeService = PrayerTimeService();

  List<Map<String, String>> _prayerWeek = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPrayerTimes();
    _scheduleMidnightUpdate();
  }

  Future<void> _loadPrayerTimes() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final position = await _locationService.getCurrentLocation();
      final week = await _prayerTimeService.getWeekPrayerTimes(position);
      setState(() {
        _prayerWeek = week;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _scheduleMidnightUpdate() {
    final now = DateTime.now();
    // تاريخ منتصف الليل القادم
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    final delay = nextMidnight.difference(now);

    Timer(delay, () {
      _loadPrayerTimes();           // تجديد الجدول
      _scheduleMidnightUpdate();    // جدولة اليوم التالي
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: CustomAppBar(
        category: CustomAppBarCategory(text: 'الصلاة'),
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 16.h),
            SquareLogo(category: SquareLogoCategory(image: 'assets/icons/pray (3).png')),
            SizedBox(height: 16.h),
            if (_loading)
              const Center(child: Center(child: CircularProgressIndicator()))
            else if (_error != null)
              Center(child: Center(child: Text('حدث خطأ: $_error')))
            else
              Center(child: PrayTable(prayerWeek: _prayerWeek)),
            SizedBox(height: 16.h),
            FollowingPray(),
            SizedBox(height: 16.h,)
          ],
        ),
      ),

    );
  }
}

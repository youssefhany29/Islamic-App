import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:just_audio/just_audio.dart';

import 'quran_ayah_audio_service.dart';

class AudioTestPage extends StatefulWidget {
  const AudioTestPage({super.key});

  @override
  State<AudioTestPage> createState() => _AudioTestPageState();
}

class _AudioTestPageState extends State<AudioTestPage> {
  final QuranAyahAudioService _audioService = QuranAyahAudioService.instance;

  final TextEditingController _surahController = TextEditingController(
    text: '1',
  );

  final TextEditingController _ayahController = TextEditingController(
    text: '1',
  );

  QuranAyahAudioInfo? _currentInfo;
  bool _isLoading = false;
  String? _message;

  @override
  void dispose() {
    _surahController.dispose();
    _ayahController.dispose();

    // مش بنعمل dispose للـ service هنا لأنه Singleton
    // وممكن نستخدمه بعدين في صفحة المصحف.
    super.dispose();
  }

  Future<void> _playAyah(int surah, int ayah) async {
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      final QuranAyahAudioInfo? info = await _audioService.playAyah(
        surahNumber: surah,
        ayahNumber: ayah,
      );

      if (!mounted) {
        return;
      }

      if (info == null) {
        setState(() {
          _currentInfo = null;
          _message = 'لم يتم العثور على صوت الآية $surah:$ayah';
        });
        return;
      }

      setState(() {
        _currentInfo = info;
        _message = 'تم تشغيل الآية $surah:$ayah';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _currentInfo = null;
        _message = 'حصل خطأ أثناء تشغيل الصوت: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _playCustomAyah() async {
    final int? surah = int.tryParse(_surahController.text.trim());
    final int? ayah = int.tryParse(_ayahController.text.trim());

    if (surah == null || ayah == null || surah < 1 || surah > 114 || ayah < 1) {
      setState(() {
        _message = 'اكتب رقم سورة وآية صحيحين';
      });
      return;
    }

    await _playAyah(surah, ayah);
  }

  Future<void> _stopAudio() async {
    await _audioService.stop();

    if (!mounted) {
      return;
    }

    setState(() {
      _message = 'تم إيقاف الصوت';
    });
  }

  Future<void> _pauseAudio() async {
    await _audioService.pause();

    if (!mounted) {
      return;
    }

    setState(() {
      _message = 'تم إيقاف مؤقت';
    });
  }

  Future<void> _resumeAudio() async {
    await _audioService.resume();

    if (!mounted) {
      return;
    }

    setState(() {
      _message = 'تم استكمال الصوت';
    });
  }

  String _formatDuration(Duration duration) {
    final int minutes = duration.inMinutes;
    final int seconds = duration.inSeconds.remainder(60);

    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String _formatDoubleDuration(double? seconds) {
    if (seconds == null) {
      return 'غير محددة';
    }

    return '${seconds.toStringAsFixed(2)} ثانية';
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = const Color(0xff005349);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xff101817) : const Color(0xffFFFDF6),
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        title: const Text(
          'تجربة صوت الآيات',
          textDirection: TextDirection.rtl,
          style: TextStyle(
            fontFamily: 'cairo',
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.all(16.w),
            children: <Widget>[
              _InfoCard(
                title: 'تجربة آمنة',
                subtitle:
                'الصفحة دي منفصلة عن المصحف الحالي. هدفنا نجرب قراءة رابط الصوت من قاعدة البيانات وتشغيل الآية فقط.',
                icon: Icons.verified_user_outlined,
                primaryColor: primaryColor,
              ),
              SizedBox(height: 16.h),
              _SectionTitle(
                title: 'تشغيل سريع',
                color: isDark ? Colors.white : Colors.black,
              ),
              SizedBox(height: 10.h),
              Wrap(
                spacing: 10.w,
                runSpacing: 10.h,
                children: <Widget>[
                  _ActionButton(
                    title: 'الفاتحة 1:1',
                    icon: Icons.play_arrow_rounded,
                    color: primaryColor,
                    onTap: _isLoading ? null : () => _playAyah(1, 1),
                  ),
                  _ActionButton(
                    title: 'الفاتحة 1:2',
                    icon: Icons.play_arrow_rounded,
                    color: primaryColor,
                    onTap: _isLoading ? null : () => _playAyah(1, 2),
                  ),
                  _ActionButton(
                    title: 'البقرة 2:255',
                    icon: Icons.play_arrow_rounded,
                    color: primaryColor,
                    onTap: _isLoading ? null : () => _playAyah(2, 255),
                  ),
                ],
              ),
              SizedBox(height: 22.h),
              _SectionTitle(
                title: 'تشغيل آية مخصصة',
                color: isDark ? Colors.white : Colors.black,
              ),
              SizedBox(height: 10.h),
              Row(
                children: <Widget>[
                  Expanded(
                    child: _NumberField(
                      controller: _surahController,
                      label: 'السورة',
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: _NumberField(
                      controller: _ayahController,
                      label: 'الآية',
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _playCustomAyah,
                  icon: _isLoading
                      ? SizedBox(
                    width: 18.w,
                    height: 18.w,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Icon(Icons.play_circle_fill_rounded),
                  label: Text(
                    _isLoading ? 'جاري التشغيل...' : 'تشغيل الآية',
                    style: const TextStyle(
                      fontFamily: 'cairo',
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 13.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 18.h),
              _SectionTitle(
                title: 'التحكم في الصوت',
                color: isDark ? Colors.white : Colors.black,
              ),
              SizedBox(height: 10.h),
              Row(
                children: <Widget>[
                  Expanded(
                    child: _ControlButton(
                      title: 'إيقاف مؤقت',
                      icon: Icons.pause_rounded,
                      onTap: _pauseAudio,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: _ControlButton(
                      title: 'استكمال',
                      icon: Icons.play_arrow_rounded,
                      onTap: _resumeAudio,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: _ControlButton(
                      title: 'إيقاف',
                      icon: Icons.stop_rounded,
                      onTap: _stopAudio,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.h),
              StreamBuilder<PlayerState>(
                stream: _audioService.playerStateStream,
                builder: (context, snapshot) {
                  final PlayerState? state = snapshot.data;
                  final bool playing = state?.playing ?? false;
                  final ProcessingState? processingState = state?.processingState;

                  return _StatusCard(
                    title: playing ? 'الصوت يعمل الآن' : 'الصوت متوقف',
                    subtitle: 'الحالة: ${processingState?.name ?? 'غير معروفة'}',
                    icon: playing
                        ? Icons.graphic_eq_rounded
                        : Icons.volume_off_outlined,
                    primaryColor: primaryColor,
                  );
                },
              ),
              SizedBox(height: 12.h),
              StreamBuilder<Duration>(
                stream: _audioService.positionStream,
                builder: (context, snapshot) {
                  final Duration position = snapshot.data ?? Duration.zero;

                  return _StatusCard(
                    title: 'موضع التشغيل',
                    subtitle: _formatDuration(position),
                    icon: Icons.timer_outlined,
                    primaryColor: primaryColor,
                  );
                },
              ),
              SizedBox(height: 12.h),
              if (_currentInfo != null)
                _CurrentAyahCard(
                  info: _currentInfo!,
                  formattedDuration: _formatDoubleDuration(
                    _currentInfo!.duration,
                  ),
                  primaryColor: primaryColor,
                ),
              if (_message != null) ...<Widget>[
                SizedBox(height: 12.h),
                _MessageBox(
                  message: _message!,
                  isDark: isDark,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.primaryColor,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color primaryColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color: primaryColor.withOpacity(0.18),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            icon,
            color: primaryColor,
            size: 28.sp,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'cairo',
                    fontWeight: FontWeight.w900,
                    fontSize: 15.sp,
                    color: primaryColor,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: 'cairo',
                    fontWeight: FontWeight.w600,
                    fontSize: 12.5.sp,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.color,
  });

  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontFamily: 'cairo',
        fontWeight: FontWeight.w900,
        fontSize: 16.sp,
        color: color,
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150.w,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(
          title,
          style: const TextStyle(
            fontFamily: 'cairo',
            fontWeight: FontWeight.w800,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(
            horizontal: 10.w,
            vertical: 12.h,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.r),
          ),
        ),
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.controller,
    required this.label,
  });

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textAlign: TextAlign.center,
      keyboardType: TextInputType.number,
      style: const TextStyle(
        fontFamily: 'cairo',
        fontWeight: FontWeight.w800,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          fontFamily: 'cairo',
          fontWeight: FontWeight.w700,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15.r),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 12.w,
          vertical: 12.h,
        ),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(
        title,
        style: const TextStyle(
          fontFamily: 'cairo',
          fontWeight: FontWeight.w800,
        ),
      ),
      style: OutlinedButton.styleFrom(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.r),
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.primaryColor,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color primaryColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(13.w),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.07),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            icon,
            color: primaryColor,
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'cairo',
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: 'cairo',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CurrentAyahCard extends StatelessWidget {
  const _CurrentAyahCard({
    required this.info,
    required this.formattedDuration,
    required this.primaryColor,
  });

  final QuranAyahAudioInfo info;
  final String formattedDuration;
  final Color primaryColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color: primaryColor.withOpacity(0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'بيانات الآية الحالية',
            style: TextStyle(
              fontFamily: 'cairo',
              fontWeight: FontWeight.w900,
              fontSize: 15.sp,
              color: primaryColor,
            ),
          ),
          SizedBox(height: 8.h),
          _InfoLine(
            title: 'السورة',
            value: info.surahNumber.toString(),
          ),
          _InfoLine(
            title: 'الآية',
            value: info.ayahNumber.toString(),
          ),
          _InfoLine(
            title: 'المدة',
            value: formattedDuration,
          ),
          _InfoLine(
            title: 'عدد segments',
            value: info.segments.length.toString(),
          ),
          SizedBox(height: 8.h),
          Text(
            info.audioUrl,
            textDirection: TextDirection.ltr,
            style: TextStyle(
              fontFamily: 'cairo',
              fontSize: 11.sp,
              height: 1.5,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({
    required this.title,
    required this.value,
  });

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4.h),
      child: Row(
        children: <Widget>[
          Text(
            '$title: ',
            style: const TextStyle(
              fontFamily: 'cairo',
              fontWeight: FontWeight.w800,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: 'cairo',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBox extends StatelessWidget {
  const _MessageBox({
    required this.message,
    required this.isDark,
  });

  final String message;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(13.w),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontFamily: 'cairo',
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class VideoNetworkImage extends StatelessWidget {
  const VideoNetworkImage({
    super.key,
    required this.imageUrl,
    required this.borderRadius,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.icon = Icons.ondemand_video_rounded,
  });

  final String imageUrl;
  final BorderRadius borderRadius;
  final double? width;
  final double? height;
  final BoxFit fit;
  final IconData icon;

  bool get _hasImage {
    return imageUrl.trim().isNotEmpty && imageUrl.startsWith('http');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: borderRadius,
      child: SizedBox(
        width: width,
        height: height,
        child: _hasImage
            ? Image.network(
          imageUrl,
          fit: fit,
          filterQuality: FilterQuality.low,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) {
              return child;
            }

            return _VideoImagePlaceholder(
              icon: icon,
              showLoader: true,
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return _VideoImagePlaceholder(
              icon: icon,
              showLoader: false,
            );
          },
        )
            : _VideoImagePlaceholder(
          icon: icon,
          showLoader: false,
          isDark: isDark,
        ),
      ),
    );
  }
}

class _VideoImagePlaceholder extends StatelessWidget {
  const _VideoImagePlaceholder({
    required this.icon,
    required this.showLoader,
    this.isDark,
  });

  final IconData icon;
  final bool showLoader;
  final bool? isDark;

  @override
  Widget build(BuildContext context) {
    final dark = isDark ?? Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: dark ? const Color(0xff171B26) : const Color(0xffEEF1F3),
      alignment: Alignment.center,
      child: showLoader
          ? SizedBox(
        width: 18.w,
        height: 18.w,
        child: CircularProgressIndicator(
          strokeWidth: 2.w,
          color: Theme.of(context).colorScheme.primary,
        ),
      )
          : Icon(
        icon,
        size: 30.sp,
        color: Theme.of(context).colorScheme.primary.withOpacity(0.75),
      ),
    );
  }
}
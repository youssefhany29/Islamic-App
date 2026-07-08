import 'dart:ui';

const double _pageHorizontalSafetyInset = 0;

Rect calculateDisplayedPageRect(Size viewportSize, Size imageSize) {
  if (viewportSize.width <= 0 ||
      viewportSize.height <= 0 ||
      !viewportSize.width.isFinite ||
      !viewportSize.height.isFinite ||
      imageSize.width <= 0 ||
      imageSize.height <= 0 ||
      !imageSize.width.isFinite ||
      !imageSize.height.isFinite) {
    return Rect.zero;
  }

  final double imageAspectRatio = imageSize.width / imageSize.height;
  final double maxWidth = (viewportSize.width - _pageHorizontalSafetyInset * 2)
      .clamp(1.0, viewportSize.width)
      .toDouble();
  double height = viewportSize.height;
  double width = height * imageAspectRatio;

  if (width > maxWidth) {
    width = maxWidth;
    height = width / imageAspectRatio;
  }

  final double left = (viewportSize.width - width) / 2;
  final double top = (viewportSize.height - height) / 2;

  return Rect.fromLTWH(left, top, width, height);
}

import 'package:flutter/widgets.dart';

class AdaptiveSafeArea extends StatelessWidget {
  const AdaptiveSafeArea({
    super.key,
    required this.child,
    this.top = true,
    this.bottom = true,
  });

  final Widget child;
  final bool top;
  final bool bottom;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: top,
      bottom: bottom,
      child: child,
    );
  }
}

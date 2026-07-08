import 'package:flutter/widgets.dart';

class AdaptiveTwoPane extends StatelessWidget {
  const AdaptiveTwoPane({
    super.key,
    required this.leading,
    required this.trailing,
    this.gap = 16,
    this.leadingFlex = 1,
    this.trailingFlex = 1,
  });

  final Widget leading;
  final Widget trailing;
  final double gap;
  final int leadingFlex;
  final int trailingFlex;

  @override
  Widget build(BuildContext context) {
    return Row(
      textDirection: TextDirection.rtl,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: leadingFlex,
          child: leading,
        ),
        SizedBox(width: gap),
        Expanded(
          flex: trailingFlex,
          child: trailing,
        ),
      ],
    );
  }
}

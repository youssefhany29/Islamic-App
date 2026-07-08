import 'package:flutter/widgets.dart';

import 'adaptive_breakpoints.dart';
import 'adaptive_device_type.dart';

class AdaptiveLayoutBuilder extends StatelessWidget {
  const AdaptiveLayoutBuilder({
    super.key,
    required this.builder,
  });

  final Widget Function(
    BuildContext context,
    AdaptiveDeviceType deviceType,
    BoxConstraints constraints,
  ) builder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final deviceType = width >= AdaptiveBreakpoints.expanded
            ? AdaptiveDeviceType.expanded
            : width >= AdaptiveBreakpoints.compact
                ? AdaptiveDeviceType.medium
                : AdaptiveDeviceType.compact;

        return builder(context, deviceType, constraints);
      },
    );
  }
}

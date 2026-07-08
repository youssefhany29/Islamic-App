import 'package:flutter/widgets.dart';

import 'adaptive_device_type.dart';
import 'adaptive_layout_builder.dart';

class AdaptivePageShell extends StatelessWidget {
  const AdaptivePageShell({
    super.key,
    required this.phone,
    this.tablet,
    this.foldable,
    this.expanded,
  });

  final Widget phone;
  final Widget? tablet;
  final Widget? foldable;
  final Widget? expanded;

  @override
  Widget build(BuildContext context) {
    return AdaptiveLayoutBuilder(
      builder: (context, deviceType, constraints) {
        switch (deviceType) {
          case AdaptiveDeviceType.compact:
            return phone;
          case AdaptiveDeviceType.medium:
            return tablet ?? foldable ?? phone;
          case AdaptiveDeviceType.expanded:
            return expanded ?? foldable ?? tablet ?? phone;
        }
      },
    );
  }
}

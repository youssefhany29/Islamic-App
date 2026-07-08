import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:islamic_app/core/adaptive/adaptive_constraints.dart';
import 'package:islamic_app/core/adaptive/adaptive_large_screen_shell.dart';
import 'package:islamic_app/core/adaptive/adaptive_page_shell.dart';
import 'package:islamic_app/core/adaptive/adaptive_side_navigation.dart';
import 'package:islamic_app/core/typography/app_text_styles.dart';

void main() {
  testWidgets('adaptive page shell keeps compact phone layout',
      (WidgetTester tester) async {
    await _pumpAtSize(
      tester,
      const Size(390, 844),
      const AdaptivePageShell(
        phone: Text('phone'),
        tablet: Text('tablet'),
        expanded: Text('expanded'),
      ),
    );

    expect(find.text('phone'), findsOneWidget);
    expect(find.text('tablet'), findsNothing);
    expect(find.text('expanded'), findsNothing);
  });

  testWidgets('adaptive page shell switches on tablet widths',
      (WidgetTester tester) async {
    await _pumpAtSize(
      tester,
      const Size(768, 1024),
      const AdaptivePageShell(
        phone: Text('phone'),
        tablet: Text('tablet'),
        expanded: Text('expanded'),
      ),
    );

    expect(find.text('phone'), findsNothing);
    expect(find.text('tablet'), findsOneWidget);
    expect(find.text('expanded'), findsNothing);
  });

  testWidgets('adaptive page shell switches on expanded widths',
      (WidgetTester tester) async {
    await _pumpAtSize(
      tester,
      const Size(1200, 800),
      const AdaptivePageShell(
        phone: Text('phone'),
        tablet: Text('tablet'),
        expanded: Text('expanded'),
      ),
    );

    expect(find.text('phone'), findsNothing);
    expect(find.text('tablet'), findsNothing);
    expect(find.text('expanded'), findsOneWidget);
  });

  test('adaptive constraints preserve compact phone card width', () {
    final width = AdaptiveConstraints.cardWidthForWindow(
      windowWidth: 390,
      scaledPhoneWidth: 360,
    );

    expect(width, 360);
  });

  test('adaptive constraints cap tablet card width', () {
    final width = AdaptiveConstraints.cardWidthForWindow(
      windowWidth: 768,
      scaledPhoneWidth: 720,
    );

    expect(width, AdaptiveConstraints.mediumContentMaxWidth);
  });

  testWidgets('app text styles switch at tablet breakpoint',
      (WidgetTester tester) async {
    late BuildContext phoneContext;
    await _pumpAtSize(
      tester,
      const Size(390, 844),
      Builder(
        builder: (context) {
          phoneContext = context;
          return const SizedBox.shrink();
        },
      ),
    );

    expect(AppTextStyles.display(phoneContext).fontSize, 20);
    expect(AppTextStyles.caption(phoneContext).fontSize, 14);

    late BuildContext tabletContext;
    await _pumpAtSize(
      tester,
      const Size(673, 841),
      Builder(
        builder: (context) {
          tabletContext = context;
          return const SizedBox.shrink();
        },
      ),
    );

    expect(AppTextStyles.display(tabletContext).fontSize, 24);
    expect(AppTextStyles.caption(tabletContext).fontSize, 18);
  });

  testWidgets('adaptive large shell accepts prayer-like scroll body',
      (WidgetTester tester) async {
    await _pumpAtSize(
      tester,
      const Size(673, 841),
      AdaptiveLargeScreenShell(
        navigationItems: [
          AdaptiveNavItem(
            id: 'prayer',
            label: 'Prayer',
            icon: Icons.access_time_rounded,
            onTap: () {},
          ),
        ],
        selectedNavigationId: 'prayer',
        userName: 'User',
        greetingMessage: 'Hello',
        quickItems: const [],
        body: Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Prayer'),
                const SizedBox(height: 12),
                Row(
                  children: const [
                    Expanded(child: SizedBox(height: 120)),
                    SizedBox(width: 12),
                    Expanded(child: SizedBox(height: 120)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpAtSize(
  WidgetTester tester,
  Size size,
  Widget child,
) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(size: size),
        child: child,
      ),
    ),
  );
}

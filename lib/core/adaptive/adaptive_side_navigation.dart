import 'package:flutter/material.dart';
import 'package:islamic_app/core/typography/app_text_styles.dart';

Color adaptiveSidePanelColor(BuildContext context) {
  return Theme.of(context).colorScheme.primary;
}

class AdaptiveNavItem {
  const AdaptiveNavItem({
    required this.id,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String id;
  final String label;
  final IconData icon;
  final VoidCallback onTap;
}

class AdaptiveSideQuickItem {
  const AdaptiveSideQuickItem({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
}

class AdaptiveSideNavigation extends StatelessWidget {
  const AdaptiveSideNavigation({
    super.key,
    required this.items,
    required this.selectedId,
    required this.userName,
    required this.greetingMessage,
    required this.quickItems,
    this.width,
  });

  final List<AdaptiveNavItem> items;
  final String selectedId;
  final String userName;
  final String greetingMessage;
  final List<AdaptiveSideQuickItem> quickItems;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final double navWidth = width ?? 268;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: SizedBox(
        width: navWidth,
        child: ColoredBox(
          color: adaptiveSidePanelColor(context),
          child: SafeArea(
            left: false,
            bottom: true,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 26, 22, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _SideNavigationBrand(),
                  const SizedBox(height: 14),
                  _SideGreetingCard(
                    userName: userName,
                    message: greetingMessage,
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView.separated(
                      padding: EdgeInsets.zero,
                      physics: const BouncingScrollPhysics(),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 7),
                      itemBuilder: (context, index) {
                        final item = items[index];

                        return _AdaptiveNavTile(
                          item: item,
                          selected: item.id == selectedId,
                        );
                      },
                    ),
                  ),
                  if (quickItems.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    _SideQuickActions(items: quickItems),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Color _sideOnPrimaryColor(BuildContext context) {
  final brightness = Theme.of(context).brightness;
  final colors = Theme.of(context).colorScheme;

  return brightness == Brightness.dark ? Colors.white : colors.onPrimary;
}

class _SideNavigationBrand extends StatelessWidget {
  const _SideNavigationBrand();

  @override
  Widget build(BuildContext context) {
    final Color sideTextColor = _sideOnPrimaryColor(context);

    return SizedBox(
      height: 58,
      width: double.infinity,
      child: Stack(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(left: 46),
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'رفيق المسلم',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        textDirection: TextDirection.rtl,
                        style: AppTextStyles.display(context).copyWith(
                          color: sideTextColor,
                          fontWeight: FontWeight.w900,
                          height: 1.05,
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'رفيقك في كل حين',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        textDirection: TextDirection.rtl,
                        style: AppTextStyles.caption(context).copyWith(
                          color: sideTextColor.withOpacity(0.72),
                          fontWeight: FontWeight.w600,
                          height: 1.05,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Icon(
              Icons.nightlight_round,
              color: sideTextColor,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }
}

class _SideGreetingCard extends StatelessWidget {
  const _SideGreetingCard({
    required this.userName,
    required this.message,
  });

  final String userName;
  final String message;

  @override
  Widget build(BuildContext context) {
    final Color sideTextColor = _sideOnPrimaryColor(context);
    final displayName = userName.trim().isEmpty ? 'ضيفنا' : userName.trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: sideTextColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: sideTextColor.withOpacity(0.10),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            child: Text(
              'أهلًا، $displayName 👋',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              style: AppTextStyles.caption(context).copyWith(
                color: sideTextColor,
                fontWeight: FontWeight.w900,
                height: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 5),
          SizedBox(
            width: double.infinity,
            child: Text(
              message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              style: AppTextStyles.caption(context).copyWith(
                color: sideTextColor.withOpacity(0.72),
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdaptiveNavTile extends StatelessWidget {
  const _AdaptiveNavTile({
    required this.item,
    required this.selected,
  });

  final AdaptiveNavItem item;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final Color sideTextColor = _sideOnPrimaryColor(context);

    final Color foreground =
        selected ? sideTextColor : sideTextColor.withOpacity(0.88);

    final Color background =
        selected ? sideTextColor.withOpacity(0.14) : Colors.transparent;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: item.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(14),
            border: selected
                ? Border.all(
                    color: sideTextColor.withOpacity(0.12),
                    width: 1,
                  )
                : null,
          ),
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              Icon(
                item.icon,
                color: foreground,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                  style: AppTextStyles.caption(context).copyWith(
                    color: foreground,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SideQuickActions extends StatelessWidget {
  const _SideQuickActions({
    required this.items,
  });

  final List<AdaptiveSideQuickItem> items;

  @override
  Widget build(BuildContext context) {
    final Color sideTextColor = _sideOnPrimaryColor(context);

    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: const Color(0xff171B26).withOpacity(0.62),
        borderRadius: BorderRadius.circular(21),
        border: Border.all(
          color: sideTextColor.withOpacity(0.08),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          for (int index = 0; index < items.length; index++) ...[
            _SideQuickTile(item: items[index]),
            if (index != items.length - 1) const SizedBox(height: 7),
          ],
        ],
      ),
    );
  }
}

class _SideQuickTile extends StatelessWidget {
  const _SideQuickTile({
    required this.item,
  });

  final AdaptiveSideQuickItem item;

  @override
  Widget build(BuildContext context) {
    final Color sideTextColor = _sideOnPrimaryColor(context);

    return Material(
      color: sideTextColor.withOpacity(0.08),
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: item.onTap,
        child: SizedBox(
          height: 46,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              textDirection: TextDirection.rtl,
              children: [
                Icon(
                  item.icon,
                  color: sideTextColor,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                    style: AppTextStyles.caption(context).copyWith(
                      color: sideTextColor,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

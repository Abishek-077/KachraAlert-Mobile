import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.child,
    this.padding,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.extendBody = false,
  });

  final Widget child;
  final EdgeInsets? padding;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final bool extendBody;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: extendBody,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: appBar,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: padding ?? AppSpacing.screenInsets,
          child: child,
        ),
      ),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isLoading) ...[
            const SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: AppSpacing.labelSpacing),
          ],
          if (icon != null) ...[
            Icon(icon, size: 18),
            const SizedBox(width: AppSpacing.labelSpacing),
          ],
          Text(label),
        ],
      ),
    );
  }
}

class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18),
            const SizedBox(width: AppSpacing.labelSpacing),
          ],
          Text(label),
        ],
      ),
    );
  }
}

class CivicCard extends StatelessWidget {
  const CivicCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.componentPadding),
    this.onTap,
  });

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final card = Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );

    if (onTap == null) return card;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: card,
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.label, this.action});

  final String label;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: Text(
            label.toUpperCase(),
            style: textTheme.labelSmall?.copyWith(
              color: cs.onSurface.withOpacity(0.55),
            ),
          ),
        ),
        if (action != null) action!,
      ],
    );
  }
}

enum StatusTone { success, warning, urgent, neutral }

class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    this.tone = StatusTone.neutral,
  });

  final String label;
  final StatusTone tone;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = switch (tone) {
      StatusTone.success => AppColors.success,
      StatusTone.warning => AppColors.warning,
      StatusTone.urgent => AppColors.error,
      StatusTone.neutral => cs.onSurface.withOpacity(0.65),
    };

    final bgColor = tone == StatusTone.neutral
        ? cs.surfaceVariant
        : color.withOpacity(0.12);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class ListRow extends StatelessWidget {
  const ListRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final content = Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: cs.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: cs.onSurface.withOpacity(0.75)),
        ),
        const SizedBox(width: AppSpacing.itemSpacing),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpacing.labelSpacing),
              Text(
                subtitle,
                style: TextStyle(
                  color: cs.onSurface.withOpacity(0.6),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: AppSpacing.itemSpacing),
          trailing!,
        ],
      ],
    );

    if (onTap == null) {
      return content;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: content,
    );
  }
}

class CivicBottomNavigationBar extends StatelessWidget {
  const CivicBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onIndexChanged,
    required this.onFabTap,
  });

  final int currentIndex;
  final ValueChanged<int> onIndexChanged;
  final VoidCallback onFabTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    const items = <_CivicNavItem>[
      _CivicNavItem(icon: Icons.home_rounded, label: 'Home'),
      _CivicNavItem(icon: Icons.calendar_month_outlined, label: 'Schedule'),
      _CivicNavItem(icon: Icons.notifications_none_rounded, label: 'Alerts'),
      _CivicNavItem(icon: Icons.person_outline_rounded, label: 'Profile'),
    ];

    return SafeArea(
      top: false,
      minimum: AppSpacing.bottomBarInsets,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Container(
            height: 72,
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                _CivicNavItemWidget(
                  item: items[0],
                  selected: currentIndex == 0,
                  onTap: () => onIndexChanged(0),
                ),
                _CivicNavItemWidget(
                  item: items[1],
                  selected: currentIndex == 1,
                  onTap: () => onIndexChanged(1),
                ),
                const SizedBox(width: 72),
                _CivicNavItemWidget(
                  item: items[2],
                  selected: currentIndex == 2,
                  onTap: () => onIndexChanged(2),
                ),
                _CivicNavItemWidget(
                  item: items[3],
                  selected: currentIndex == 3,
                  onTap: () => onIndexChanged(3),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 20,
            child: CivicFloatingActionButton(onTap: onFabTap),
          ),
        ],
      ),
    );
  }
}

class CivicFloatingActionButton extends StatelessWidget {
  const CivicFloatingActionButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return FloatingActionButton(
      onPressed: onTap,
      backgroundColor: cs.primary,
      foregroundColor: cs.onPrimary,
      elevation: 0,
      child: const Icon(Icons.add_rounded, size: 28),
    );
  }
}

class _CivicNavItem {
  const _CivicNavItem({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

class _CivicNavItemWidget extends StatelessWidget {
  const _CivicNavItemWidget({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _CivicNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = selected ? cs.primary : cs.onSurface.withOpacity(0.55);

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: double.infinity,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(item.icon, color: color, size: 22),
                const SizedBox(height: 4),
                Text(
                  item.label,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
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

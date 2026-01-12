import 'package:flutter/material.dart';

/// Bottom navigation dock that matches the reference UI:
/// - Floating rounded container
/// - Center gap for FAB
/// - Soft shadow
class KBottomNavDock extends StatelessWidget {
  const KBottomNavDock({
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

    // Icons must align with our current navigation: Home, Schedule, Alerts, Profile
    const items = <_DockItem>[
      _DockItem(icon: Icons.home_rounded, label: 'Home'),
      _DockItem(icon: Icons.calendar_month_outlined, label: 'Schedule'),
      _DockItem(icon: Icons.notifications_none_rounded, label: 'Alerts'),
      _DockItem(icon: Icons.person_outline_rounded, label: 'Profile'),
    ];

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Dock
          Container(
            height: 74,
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  blurRadius: 28,
                  offset: const Offset(0, 14),
                  color: Colors.black.withOpacity(0.10),
                ),
              ],
            ),
            child: Row(
              children: [
                _NavItem(
                  item: items[0],
                  selected: currentIndex == 0,
                  onTap: () => onIndexChanged(0),
                ),
                _NavItem(
                  item: items[1],
                  selected: currentIndex == 1,
                  onTap: () => onIndexChanged(1),
                ),

                // Center FAB gap
                const SizedBox(width: 74),

                _NavItem(
                  item: items[2],
                  selected: currentIndex == 2,
                  onTap: () => onIndexChanged(2),
                ),
                _NavItem(
                  item: items[3],
                  selected: currentIndex == 3,
                  onTap: () => onIndexChanged(3),
                ),
              ],
            ),
          ),

          // FAB
          Positioned(
            bottom: 18,
            child: FloatingActionButton(
              onPressed: onFabTap,
              backgroundColor: cs.primary,
              foregroundColor: cs.onPrimary,
              elevation: 0,
              child: const Icon(Icons.add_rounded, size: 30),
            ),
          ),
        ],
      ),
    );
  }
}

class _DockItem {
  final IconData icon;
  final String label;
  const _DockItem({required this.icon, required this.label});
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _DockItem item;
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
                Icon(item.icon, color: color, size: 24),
                const SizedBox(height: 4),
                Text(
                  item.label,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 4),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  height: 3,
                  width: selected ? 16 : 0,
                  decoration: BoxDecoration(
                    color: cs.primary,
                    borderRadius: BorderRadius.circular(999),
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

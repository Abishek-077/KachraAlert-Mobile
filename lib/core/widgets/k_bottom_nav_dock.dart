import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';

/// Bottom navigation dock with glassmorphism and premium effects
class KBottomNavDock extends StatefulWidget {
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
  State<KBottomNavDock> createState() => _KBottomNavDockState();
}

class _KBottomNavDockState extends State<KBottomNavDock>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    const items = <_DockItem>[
      _DockItem(icon: Icons.home_rounded, label: 'Home', branchIndex: 0),
      _DockItem(
        icon: Icons.calendar_month_outlined,
        label: 'Schedule',
        branchIndex: 1,
      ),
      _DockItem(
        icon: Icons.chat_bubble_outline_rounded,
        label: 'Messages',
        branchIndex: 2,
      ),
      _DockItem(
        icon: Icons.person_outline_rounded,
        label: 'Profile',
        branchIndex: 4,
      ),
    ];

    Widget navItem(_DockItem item) {
      return _NavItem(
        item: item,
        selected: widget.currentIndex == item.branchIndex,
        onTap: () {
          HapticFeedback.selectionClick();
          widget.onIndexChanged(item.branchIndex);
        },
      );
    }

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Glassmorphic Dock
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                height: 74,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: isDark
                        ? [
                            cs.surface.withOpacity(0.8),
                            cs.surface.withOpacity(0.7),
                          ]
                        : [
                            cs.surface.withOpacity(0.95),
                            cs.surface.withOpacity(0.85),
                          ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: cs.onSurface.withOpacity(isDark ? 0.1 : 0.08),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 40,
                      offset: const Offset(0, 20),
                      color: Colors.black.withOpacity(isDark ? 0.4 : 0.12),
                    ),
                    if (!isDark)
                      BoxShadow(
                        blurRadius: 20,
                        offset: const Offset(0, -4),
                        color: Colors.white.withOpacity(0.5),
                      ),
                  ],
                ),
                child: Row(
                  children: [
                    navItem(items[0]),
                    navItem(items[1]),
                    // Center FAB gap
                    const SizedBox(width: 86),
                    navItem(items[2]),
                    navItem(items[3]),
                  ],
                ),
              ),
            ),
          ),
          // Premium Gradient FAB with pulse
          Positioned(
            bottom: 18,
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color:
                            cs.primary.withOpacity(0.4 * _pulseAnimation.value),
                        blurRadius: 24 * _pulseAnimation.value,
                        spreadRadius: 4 * (_pulseAnimation.value - 1),
                      ),
                    ],
                  ),
                  child: FloatingActionButton(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      widget.onFabTap();
                    },
                    elevation: 0,
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            cs.primary,
                            cs.primary.withOpacity(0.8),
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.add_rounded,
                        size: 32,
                        color: cs.onPrimary,
                      ),
                    ),
                  ),
                );
              },
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
  final int branchIndex;

  const _DockItem({
    required this.icon,
    required this.label,
    required this.branchIndex,
  });
}

class _NavItem extends StatefulWidget {
  const _NavItem({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _DockItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    // Use easeOut instead of elasticOut to avoid overshooting [0,1] range
    _bounceAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeOut),
    );
  }

  @override
  void didUpdateWidget(_NavItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected && !oldWidget.selected) {
      _bounceController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = widget.selected ? cs.primary : cs.onSurface.withOpacity(0.55);

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          child: SizedBox(
            height: double.infinity,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedBuilder(
                  animation: _bounceAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: widget.selected ? _bounceAnimation.value : 1.0,
                      child: Icon(widget.item.icon, color: color, size: 26),
                    );
                  },
                ),
                const SizedBox(height: 4),
                Text(
                  widget.item.label,
                  style: TextStyle(
                    color: color,
                    fontWeight:
                        widget.selected ? FontWeight.w800 : FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 4),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                  height: 3,
                  width: widget.selected ? 20 : 0,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [cs.primary, cs.primary.withOpacity(0.6)],
                    ),
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: widget.selected
                        ? [
                            BoxShadow(
                              color: cs.primary.withOpacity(0.4),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ]
                        : [],
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

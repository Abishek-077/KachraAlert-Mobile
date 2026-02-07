import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Minimal premium dock with centered home action.
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
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: SizedBox(
        height: 86,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: const Color(0xFFDCE4EA)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1D0F201A),
                      blurRadius: 24,
                      offset: Offset(0, 10),
                    ),
                    BoxShadow(
                      color: Color(0xE6FFFFFF),
                      blurRadius: 10,
                      offset: Offset(-3, -3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _DockIcon(
                        icon: Icons.calendar_month_outlined,
                        selected: currentIndex == 1,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          onIndexChanged(1);
                        },
                      ),
                    ),
                    Expanded(
                      child: _DockIcon(
                        icon: Icons.chat_bubble_outline_rounded,
                        selected: currentIndex == 2,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          onIndexChanged(2);
                        },
                      ),
                    ),
                    const SizedBox(width: 84),
                    Expanded(
                      child: _DockIcon(
                        icon: Icons.notifications_none_rounded,
                        selected: currentIndex == 3,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          onIndexChanged(3);
                        },
                      ),
                    ),
                    Expanded(
                      child: _DockIcon(
                        icon: Icons.person_outline_rounded,
                        selected: currentIndex == 4,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          onIndexChanged(4);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _CenterHomeButton(
              selected: currentIndex == 0,
              onTap: () {
                HapticFeedback.selectionClick();
                onIndexChanged(0);
              },
              onLongPress: () {
                HapticFeedback.mediumImpact();
                onFabTap();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DockIcon extends StatelessWidget {
  const _DockIcon({
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: selected
                  ? const Color(0xFF22A575).withValues(alpha: 0.12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 27,
              color:
                  selected ? const Color(0xFF22A575) : const Color(0xFF7A8089),
            ),
          ),
        ),
      ),
    );
  }
}

class _CenterHomeButton extends StatelessWidget {
  const _CenterHomeButton({
    required this.selected,
    required this.onTap,
    required this.onLongPress,
  });

  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        onLongPress: onLongPress,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF3B52DE), Color(0xFF4A3FC8)],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.92),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF3B52DE).withValues(
                  alpha: selected ? 0.36 : 0.22,
                ),
                blurRadius: selected ? 18 : 10,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(Icons.home_rounded, color: Colors.white, size: 30),
        ),
      ),
    );
  }
}

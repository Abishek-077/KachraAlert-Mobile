import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Password strength meter with real-time validation and visual feedback
class PasswordStrengthMeter extends StatefulWidget {
  const PasswordStrengthMeter({
    super.key,
    required this.password,
    this.showRequirements = true,
  });

  final String password;
  final bool showRequirements;

  @override
  State<PasswordStrengthMeter> createState() => _PasswordStrengthMeterState();
}

class _PasswordStrengthMeterState extends State<PasswordStrengthMeter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int _previousStrength = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
  }

  @override
  void didUpdateWidget(PasswordStrengthMeter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.password != widget.password) {
      final newStrength = _calculateStrength(widget.password);
      if (newStrength != _previousStrength) {
        _controller.forward(from: 0);
        _previousStrength = newStrength;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int _calculateStrength(String password) {
    if (password.isEmpty) return 0;
    
    int strength = 0;
    if (password.length >= 8) strength++;
    if (password.length >= 12) strength++;
    if (RegExp(r'[a-z]').hasMatch(password)) strength++;
    if (RegExp(r'[A-Z]').hasMatch(password)) strength++;
    if (RegExp(r'[0-9]').hasMatch(password)) strength++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(password)) strength++;

    return math.min(strength, 5);
  }

  Color _getStrengthColor(int strength, ColorScheme cs) {
    switch (strength) {
      case 0:
      case 1:
        return const Color(0xFFEF4444); // Red
      case 2:
        return const Color(0xFFF97316); // Orange
      case 3:
        return const Color(0xFFFBBF24); // Yellow
      case 4:
        return cs.primary; // Green
      case 5:
        return const Color(0xFF3B82F6); // Blue
      default:
        return cs.outlineVariant;
    }
  }

  String _getStrengthLabel(int strength) {
    switch (strength) {
      case 0:
        return '';
      case 1:
        return 'Very Weak';
      case 2:
        return 'Weak';
      case 3:
        return 'Fair';
      case 4:
        return 'Strong';
      case 5:
        return 'Very Strong';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final strength = _calculateStrength(widget.password);
    final strengthColor = _getStrengthColor(strength, cs);
    final strengthLabel = _getStrengthLabel(strength);

    final hasLength = widget.password.length >= 8;
    final hasLower = RegExp(r'[a-z]').hasMatch(widget.password);
    final hasUpper = RegExp(r'[A-Z]').hasMatch(widget.password);
    final hasNumber = RegExp(r'[0-9]').hasMatch(widget.password);
    final hasSpecial = RegExp(r'[^A-Za-z0-9]').hasMatch(widget.password);

    if (widget.password.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        // Strength bar
        Row(
          children: [
            Expanded(
              child: Container(
                height: 6,
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  children: List.generate(5, (index) {
                    return Expanded(
                      child: AnimatedBuilder(
                        animation: _animation,
                        builder: (context, child) {
                          final isActive = index < strength;
                          return Container(
                            margin: EdgeInsets.only(
                              left: index == 0 ? 0 : 2,
                            ),
                            decoration: BoxDecoration(
                              gradient: isActive
                                  ? LinearGradient(
                                      colors: [
                                        strengthColor,
                                        strengthColor.withOpacity(0.8),
                                      ],
                                    )
                                  : null,
                              borderRadius: BorderRadius.horizontal(
                                left: index == 0
                                    ? const Radius.circular(999)
                                    : Radius.zero,
                                right: index == 4
                                    ? const Radius.circular(999)
                                    : Radius.zero,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(width: 12),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: strengthColor,
              ),
              child: Text(strengthLabel),
            ),
          ],
        ),
        // Requirements checklist
        if (widget.showRequirements) ...[
          const SizedBox(height: 12),
          _RequirementItem(
            label: '8+ characters',
            isMet: hasLength,
          ),
          const SizedBox(height: 6),
          _RequirementItem(
            label: 'Uppercase letter',
            isMet: hasUpper,
          ),
          const SizedBox(height: 6),
          _RequirementItem(
            label: 'Lowercase letter',
            isMet: hasLower,
          ),
          const SizedBox(height: 6),
          _RequirementItem(
            label: 'Number',
            isMet: hasNumber,
          ),
          const SizedBox(height: 6),
          _RequirementItem(
            label: 'Special character',
            isMet: hasSpecial,
          ),
        ],
      ],
    );
  }
}

class _RequirementItem extends StatelessWidget {
  const _RequirementItem({
    required this.label,
    required this.isMet,
  });

  final String label;
  final bool isMet;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: isMet ? cs.primary : cs.surfaceContainerHighest,
              shape: BoxShape.circle,
              border: Border.all(
                color: isMet ? cs.primary : cs.outlineVariant,
                width: isMet ? 0 : 1.5,
              ),
            ),
            child: isMet
                ? const Icon(
                    Icons.check,
                    size: 12,
                    color: Colors.white,
                  )
                : null,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isMet
                  ? cs.onSurface
                  : cs.onSurfaceVariant.withOpacity(0.6),
              fontWeight: isMet ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

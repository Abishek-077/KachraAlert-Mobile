import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../motion/app_motion.dart';
import '../motion/motion_profile.dart';
import '../services/feedback/feedback_service.dart';

/// Premium animated text field with floating labels and validation states.
class AnimatedTextField extends ConsumerStatefulWidget {
  const AnimatedTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.enabled = true,
    this.validator,
    this.onChanged,
    this.suffixIcon,
    this.isValid,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscureText;
  final TextInputType keyboardType;
  final bool enabled;
  final String? Function(String)? validator;
  final void Function(String)? onChanged;
  final Widget? suffixIcon;
  final bool? isValid;

  @override
  ConsumerState<AnimatedTextField> createState() => _AnimatedTextFieldState();
}

class _AnimatedTextFieldState extends ConsumerState<AnimatedTextField>
    with SingleTickerProviderStateMixin {
  final FocusNode _focusNode = FocusNode();
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _labelAnimation;

  bool _isFocused = false;
  String? _errorText;
  MotionProfile? _lastProfile;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AppMotion.short,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _labelAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _focusNode.addListener(_onFocusChanged);

    widget.controller.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final profile = context.motionProfile;
    if (_lastProfile == profile) return;
    _lastProfile = profile;

    _controller.duration = AppMotion.scaled(profile, AppMotion.short);
    if (profile.reduceMotion && _controller.value != 0) {
      _controller.value = 0;
    }
  }

  void _onFocusChanged() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
      if (_isFocused) {
        if (!context.motionProfile.reduceMotion) {
          _controller.forward();
        }
        ref.read(feedbackServiceProvider).selection();
      } else {
        _controller.reverse();
        _validate();
      }
    });
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _validate() {
    if (widget.validator != null && widget.controller.text.isNotEmpty) {
      setState(() {
        _errorText = widget.validator!(widget.controller.text);
      });
      if (_errorText != null) {
        ref.read(feedbackServiceProvider).lightImpact();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final profile = context.motionProfile;
    final hasText = widget.controller.text.isNotEmpty;
    final isValid = widget.isValid ?? (_errorText == null && hasText);
    final hasError = _errorText != null;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final labelProgress = hasText ? 1.0 : _labelAnimation.value;
        final scaleValue = profile.reduceMotion ? 1.0 : _scaleAnimation.value;

        return Transform.scale(
          scale: scaleValue,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Opacity(
                opacity: labelProgress,
                child: Transform.translate(
                  offset: Offset(0, (1 - labelProgress) * 8),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 8),
                    child: Row(
                      children: [
                        Text(
                          widget.label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color:
                                _isFocused ? cs.primary : cs.onSurfaceVariant,
                          ),
                        ),
                        if (isValid && !hasError) ...[
                          const SizedBox(width: 6),
                          Icon(
                            Icons.check_circle,
                            size: 14,
                            color: cs.primary,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: _isFocused
                      ? [
                          BoxShadow(
                            color: cs.primary.withValues(alpha: 0.15),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : const [],
                ),
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focusNode,
                  obscureText: widget.obscureText,
                  keyboardType: widget.keyboardType,
                  enabled: widget.enabled,
                  onChanged: widget.onChanged,
                  style: TextStyle(
                    fontSize: 15,
                    color: cs.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: widget.label,
                    hintStyle: TextStyle(
                      color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                    ),
                    prefixIcon: AnimatedContainer(
                      duration: AppMotion.scaled(profile, AppMotion.short),
                      child: Icon(
                        widget.icon,
                        size: 20,
                        color: _isFocused
                            ? cs.primary
                            : cs.onSurfaceVariant.withValues(alpha: 0.7),
                      ),
                    ),
                    suffixIcon: widget.suffixIcon ??
                        (isValid && !hasError
                            ? Icon(
                                Icons.check_circle,
                                size: 20,
                                color: cs.primary,
                              )
                            : null),
                    filled: true,
                    fillColor: cs.surfaceContainerHighest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: hasError ? cs.error : cs.primary,
                        width: 2,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: cs.error,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                ),
              ),
              if (hasError)
                Padding(
                  padding: const EdgeInsets.only(left: 16, top: 6),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 14,
                        color: cs.error,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _errorText!,
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.error,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

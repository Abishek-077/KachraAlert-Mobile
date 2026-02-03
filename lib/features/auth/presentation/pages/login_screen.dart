import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui';

import 'package:smart_waste_app/app/theme/app_colors.dart';
import 'package:smart_waste_app/core/ui/snackbar.dart';
import 'package:smart_waste_app/core/widgets/floating_particles.dart';
import 'package:smart_waste_app/core/widgets/animated_text_field.dart';
import 'package:smart_waste_app/core/widgets/premium_button.dart';
import '../providers/auth_providers.dart';
import 'package:smart_waste_app/core/extensions/async_value_extensions.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _hide = true;
  String _role = 'resident';
  bool _loginSuccess = false;

  late final AnimationController _animationController;
  late final AnimationController _logoController;
 late final Animation<double> _logoScaleAnimation;
  late final Animation<double> _logoRotationAnimation;
  
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..forward();

    _logoController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _logoScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );

    _logoRotationAnimation = Tween<double>(begin: -0.2, end: 0.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOut),
    );

    _logoController.forward();
    
    _initialized = true;
  }

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    _animationController.dispose();
    _logoController.dispose();
    super.dispose();
  }

  String? _validateInputs() {
    final email = _email.text.trim();
    final pass = _pass.text;

    if (email.isEmpty) return 'Email is required';
    if (pass.isEmpty) return 'Password is required';
    if (pass.length < 8) return 'Password must be at least 8 characters';
    return null;
  }

  Future<void> _login(bool loading) async {
    if (loading) return;

    final validationError = _validateInputs();
    if (validationError != null) {
      AppSnack.show(context, validationError);
      return;
    }

    await ref
        .read(authStateProvider.notifier)
        .login(email: _email.text.trim(), password: _pass.text, role: _role);

    if (!mounted) return;
    final auth = ref.read(authStateProvider).valueOrNull;
    if (auth?.isLoggedIn == true) {
      setState(() => _loginSuccess = true);
      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted) context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    ref.listen<AsyncValue<AuthState>>(authStateProvider, (prev, next) {
      final msg = next.valueOrNull?.errorMessage;
      if (msg != null && msg.isNotEmpty) {
        AppSnack.show(context, msg);
        ref.read(authStateProvider.notifier).clearError();
      }
    });

    final authAsync = ref.watch(authStateProvider);
    final loading = authAsync.isLoading;

    final fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    final slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Animated mesh gradient background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        const Color(0xFF0F2027),
                        const Color(0xFF203A43),
                        const Color(0xFF2C5364),
                      ]
                    : [
                        const Color(0xFFE7F7EF),
                        const Color(0xFFD1F2EB),
                        Colors.white,
                      ],
              ),
            ),
          ),
          // Floating particles
          const Positioned.fill(
            child: FloatingParticles(particleCount: 30),
          ),
          // Glow orbs
          Positioned(
            right: -100,
            top: -50,
            child: _GlowCircle(
              size: 250,
              color: scheme.primary.withOpacity(isDark ? 0.15 : 0.1),
            ),
          ),
          Positioned(
            left: -80,
            bottom: 60,
            child: _GlowCircle(
              size: 200,
              color: scheme.secondary.withOpacity(isDark ? 0.12 : 0.08),
            ),
          ),
          // Main content
          SafeArea(
            child: AbsorbPointer(
              absorbing: loading,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 40),
                      // Logo with animation
                      FadeTransition(
                        opacity: fadeAnimation,
                        child: AnimatedBuilder(
                          animation: _logoController,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _logoScaleAnimation.value,
                              child: Transform.rotate(
                                angle: _logoRotationAnimation.value,
                                child: Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    gradient: AppColors.tealEmeraldGradient,
                                    borderRadius: BorderRadius.circular(22),
                                    boxShadow: [
                                      BoxShadow(
                                        color: scheme.primary.withOpacity(0.4),
                                        blurRadius: 24,
                                        offset: const Offset(0, 10),
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.recycling_rounded,
                                    color: Colors.white,
                                    size: 40,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Title with gradient
                      FadeTransition(
                        opacity: fadeAnimation,
                        child: ShaderMask(
                          shaderCallback: (bounds) => AppColors.tealEmeraldGradient
                              .createShader(bounds),
                          child: const Text(
                            'Welcome Back',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -0.5,
                              height: 1.2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      FadeTransition(
                        opacity: fadeAnimation,
                        child: Text(
                          'Sign in to manage alerts, reports, and schedules',
                          style: TextStyle(
                            fontSize: 15,
                            color: scheme.onSurfaceVariant,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Glassmorphic form card
                      SlideTransition(
                        position: slideAnimation,
                        child: FadeTransition(
                          opacity: fadeAnimation,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(28),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: isDark
                                        ? [
                                            scheme.surface.withOpacity(0.8),
                                            scheme.surface.withOpacity(0.6),
                                          ]
                                        : [
                                            Colors.white.withOpacity(0.9),
                                            Colors.white.withOpacity(0.7),
                                          ],
                                  ),
                                  borderRadius: BorderRadius.circular(28),
                                  border: Border.all(
                                    color: scheme.onSurface.withOpacity(0.1),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                                      blurRadius: 30,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(28),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildRoleSelector(loading, scheme),
                                      const SizedBox(height: 24),
                                      AnimatedTextField(
                                        controller: _email,
                                        label: 'Email Address',
                                        icon: Icons.email_outlined,
                                        enabled: !loading,
                                        keyboardType: TextInputType.emailAddress,
                                        validator: (value) {
                                          if (value.isEmpty) return 'Email is required';
                                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                              .hasMatch(value)) {
                                            return 'Enter a valid email';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 20),
                                      AnimatedTextField(
                                        controller: _pass,
                                        label: 'Password',
                                        icon: Icons.lock_outline,
                                        obscureText: _hide,
                                        enabled: !loading,
                                        suffixIcon: IconButton(
                                          onPressed: () => setState(() => _hide = !_hide),
                                          icon: Icon(
                                            _hide
                                                ? Icons.visibility_off_outlined
                                                : Icons.visibility_outlined,
                                            size: 20,
                                            color: scheme.onSurfaceVariant.withOpacity(0.6),
                                          ),
                                        ),
                                        validator: (value) {
                                          if (value.isEmpty) return 'Password is required';
                                          if (value.length < 8) {
                                            return 'Password must be at least 8 characters';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 28),
                                      PremiumButton(
                                        onPressed: () => _login(loading),
                                        label: 'Login',
                                        loading: loading,
                                        success: _loginSuccess,
                                        enabled: !loading,
                                        icon: Icons.arrow_forward_rounded,
                                      ),
                                      const SizedBox(height: 20),
                                      Center(
                                        child: RichText(
                                          text: TextSpan(
                                            text: "Don't have an account? ",
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: scheme.onSurfaceVariant,
                                            ),
                                            children: [
                                              TextSpan(
                                                text: 'Sign Up',
                                                style: TextStyle(
                                                  color: scheme.primary,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                                recognizer: TapGestureRecognizer()
                                                  ..onTap = loading
                                                      ? null
                                                      : () => context.go('/auth/signup'),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleSelector(bool loading, ColorScheme scheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Account Type',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _buildRoleCard(
                title: 'Resident',
                subtitle: 'Receive alerts',
                icon: Icons.home_work_outlined,
                value: 'resident',
                loading: loading,
                scheme: scheme,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildRoleCard(
                title: 'Admin',
                subtitle: 'Manage system',
                icon: Icons.local_shipping_outlined,
                value: 'admin_driver',
                loading: loading,
                scheme: scheme,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRoleCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required String value,
    required bool loading,
    required ColorScheme scheme,
  }) {
    final isSelected = _role == value;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: loading ? null : () => setState(() => _role = value),
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        scheme.primary.withOpacity(0.15),
                        scheme.primary.withOpacity(0.08),
                      ],
                    )
                  : null,
              color: isSelected ? null : scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isSelected ? scheme.primary : scheme.outlineVariant,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: scheme.primary.withOpacity(0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [],
            ),
            child: Column(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? AppColors.tealEmeraldGradient
                        : null,
                    color: isSelected ? null : scheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: scheme.primary.withOpacity(0.3),
                              blurRadius: 8,
                            ),
                          ]
                        : [],
                  ),
                  child: Icon(
                    icon,
                    color: isSelected ? Colors.white : scheme.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: scheme.onSurfaceVariant.withOpacity(0.8),
                    fontWeight: FontWeight.w500,
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

class _GlowCircle extends StatelessWidget {
  const _GlowCircle({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, Colors.transparent],
        ),
      ),
    );
  }
}

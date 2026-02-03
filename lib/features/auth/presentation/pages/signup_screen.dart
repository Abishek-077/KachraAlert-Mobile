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
import 'package:smart_waste_app/core/widgets/password_strength_meter.dart';
import 'package:smart_waste_app/core/widgets/confetti_celebration.dart';
import 'package:smart_waste_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:smart_waste_app/core/extensions/async_value_extensions.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen>
    with TickerProviderStateMixin {
  final _fullName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _pass = TextEditingController();
  final _society = TextEditingController();
  final _building = TextEditingController();
  final _apartment = TextEditingController();

  bool _hide = true;
  bool _agreeTerms = false;
  String _role = 'resident';
  int _step = 0;
  bool _signupSuccess = false;

  late final AnimationController _controller;
  late final AnimationController _logoController;
  late final Animation<double> _logoScaleAnimation;
  late final Animation<double> _logoRotationAnimation;
  
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
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
    _fullName.dispose();
    _email.dispose();
    _phone.dispose();
    _pass.dispose();
    _society.dispose();
    _building.dispose();
    _apartment.dispose();
    _controller.dispose();
    _logoController.dispose();
    super.dispose();
  }

  String? _validateStepOne() {
    if (_fullName.text.trim().isEmpty) return 'Full name is required';
    final email = _email.text.trim();
    if (email.isEmpty) return 'Email is required';
    if (_phone.text.trim().isEmpty) return 'Phone number is required';
    if (_pass.text.isEmpty) return 'Password is required';
    final passwordError = _passwordStrengthError(_pass.text);
    if (passwordError != null) return passwordError;
    return null;
  }

  String? _validateStepTwo() {
    if (_society.text.trim().isEmpty) return 'Society is required';
    if (_building.text.trim().isEmpty) return 'Building is required';
    if (_apartment.text.trim().isEmpty) return 'Apartment is required';
    if (!_agreeTerms) return 'Please accept the Terms & Conditions';
    return null;
  }

  void _goNext(bool loading) {
    if (loading) return;
    final validationError = _validateStepOne();
    if (validationError != null) {
      AppSnack.show(context, validationError);
      return;
    }
    setState(() => _step = 1);
  }

  Future<void> _signup(bool loading) async {
    if (loading) return;

    final stepOneError = _validateStepOne();
    if (stepOneError != null) {
      AppSnack.show(context, stepOneError);
      setState(() => _step = 0);
      return;
    }

    final validationError = _validateStepTwo();
    if (validationError != null) {
      AppSnack.show(context, validationError);
      return;
    }

    await ref.read(authStateProvider.notifier).signup(
          email: _email.text.trim(),
          password: _pass.text,
          role: _role,
          fullName: _fullName.text.trim(),
          phone: _phone.text.trim(),
          society: _society.text.trim(),
          building: _building.text.trim(),
          apartment: _apartment.text.trim(),
          termsAccepted: _agreeTerms,
        );

    if (!mounted) return;
    final auth = ref.read(authStateProvider).valueOrNull;
    if (auth?.isLoggedIn == true) {
      setState(() => _signupSuccess = true);
      showConfetti(context);
      await Future.delayed(const Duration(milliseconds: 2500));
      if (mounted) context.go('/home');
    }
  }

  String? _passwordStrengthError(String password) {
    if (password.length < 8) {
      return 'Password must be at least 8 characters.';
    }
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      return 'Password must include a lowercase letter.';
    }
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return 'Password must include an uppercase letter.';
    }
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      return 'Password must include a number.';
    }
    if (!RegExp(r'[^A-Za-z0-9]').hasMatch(password)) {
      return 'Password must include a special character.';
    }
    return null;
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
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    final slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeOut),
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
                      const SizedBox(height: 20),
                      // Back button
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          onPressed: loading
                              ? null
                              : () => context.go('/auth/login'),
                          icon: Icon(
                            Icons.arrow_back_rounded,
                            color: scheme.onSurface,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
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
                                  width: 72,
                                  height: 72,
                                  decoration: BoxDecoration(
                                    gradient: AppColors.purplePinkGradient,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFA855F7)
                                            .withOpacity(0.4),
                                        blurRadius: 24,
                                        offset: const Offset(0, 10),
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.person_add_rounded,
                                    color: Colors.white,
                                    size: 36,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Title with gradient
                      FadeTransition(
                        opacity: fadeAnimation,
                        child: ShaderMask(
                          shaderCallback: (bounds) =>
                              AppColors.purplePinkGradient.createShader(bounds),
                          child: const Text(
                            'Create Account',
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
                          'Join the community and make a difference',
                          style: TextStyle(
                            fontSize: 15,
                            color: scheme.onSurfaceVariant,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 24),
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
                                      color: Colors.black
                                          .withOpacity(isDark ? 0.3 : 0.08),
                                      blurRadius: 30,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(28),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildStepIndicator(scheme),
                                      const SizedBox(height: 24),
                                      AnimatedSwitcher(
                                        duration:
                                            const Duration(milliseconds: 300),
                                        switchInCurve: Curves.easeOut,
                                        switchOutCurve: Curves.easeIn,
                                        child: _step == 0
                                            ? _buildAccountStep(
                                                scheme, loading)
                                            : _buildAddressStep(
                                                scheme, loading),
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
                      // Footer
                      Center(
                        child: RichText(
                          text: TextSpan(
                            text: 'Already have an account? ',
                            style: TextStyle(
                              fontSize: 14,
                              color: scheme.onSurfaceVariant,
                            ),
                            children: [
                              TextSpan(
                                text: 'Login',
                                style: TextStyle(
                                  color: scheme.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = loading
                                      ? null
                                      : () => context.go('/auth/login'),
                              ),
                            ],
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

  Widget _buildStepIndicator(ColorScheme scheme) {
    return Row(
      children: [
        _buildStepBubble(label: '1', isActive: _step == 0, scheme: scheme),
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 14),
            height: 5,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOut,
                height: 5,
                width: _step == 0 ? 0 : double.infinity,
                decoration: BoxDecoration(
                  gradient: AppColors.purplePinkGradient,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: _step == 1
                      ? [
                          BoxShadow(
                            color: const Color(0xFFA855F7).withOpacity(0.4),
                            blurRadius: 8,
                          ),
                        ]
                      : [],
                ),
              ),
            ),
          ),
        ),
        _buildStepBubble(label: '2', isActive: _step == 1, scheme: scheme),
      ],
    );
  }

  Widget _buildStepBubble({
    required String label,
    required bool isActive,
    required ColorScheme scheme,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        gradient: isActive ? AppColors.purplePinkGradient : null,
        color: isActive ? null : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isActive
              ? Colors.transparent
              : scheme.outlineVariant,
          width: 1.5,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: const Color(0xFFA855F7).withOpacity(0.4),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ]
            : [],
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 16,
            color: isActive ? Colors.white : scheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildAccountStep(ColorScheme scheme, bool loading) {
    return Column(
      key: const ValueKey('account_step'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildRoleSelector(loading, scheme),
        const SizedBox(height: 24),
        AnimatedTextField(
          controller: _fullName,
          label: 'Full Name',
          icon: Icons.person_outline,
          enabled: !loading,
          validator: (value) {
            if (value.isEmpty) return 'Full name is required';
            return null;
          },
        ),
        const SizedBox(height: 18),
        AnimatedTextField(
          controller: _email,
          label: 'Email Address',
          icon: Icons.email_outlined,
          enabled: !loading,
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value.isEmpty) return 'Email is required';
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
              return 'Enter a valid email';
            }
            return null;
          },
        ),
        const SizedBox(height: 18),
        AnimatedTextField(
          controller: _phone,
          label: 'Phone Number',
          icon: Icons.phone_outlined,
          enabled: !loading,
          keyboardType: TextInputType.phone,
          validator: (value) {
            if (value.isEmpty) return 'Phone is required';
            return null;
          },
        ),
        const SizedBox(height: 18),
        AnimatedTextField(
          controller: _pass,
          label: 'Password',
          icon: Icons.lock_outline,
          obscureText: _hide,
          enabled: !loading,
          onChanged: (_) => setState(() {}),
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
        ),
        // Password strength meter
        PasswordStrengthMeter(
          password: _pass.text,
          showRequirements: true,
        ),
        const SizedBox(height: 28),
        PremiumButton(
          onPressed: () => _goNext(loading),
          label: 'Next Step',
          loading: loading,
          enabled: !loading,
          icon: Icons.arrow_forward_rounded,
        ),
      ],
    );
  }

  Widget _buildAddressStep(ColorScheme scheme, bool loading) {
    return Column(
      key: const ValueKey('address_step'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedTextField(
          controller: _society,
          label: 'Society',
          icon: Icons.location_city_outlined,
          enabled: !loading,
          validator: (value) {
            if (value.isEmpty) return 'Society is required';
            return null;
          },
        ),
        const SizedBox(height: 18),
        AnimatedTextField(
          controller: _building,
          label: 'Building',
          icon: Icons.apartment_outlined,
          enabled: !loading,
          validator: (value) {
            if (value.isEmpty) return 'Building is required';
            return null;
          },
        ),
        const SizedBox(height: 18),
        AnimatedTextField(
          controller: _apartment,
          label: 'Apartment',
          icon: Icons.door_front_door_outlined,
          enabled: !loading,
          validator: (value) {
            if (value.isEmpty) return 'Apartment is required';
            return null;
          },
        ),
        const SizedBox(height: 16),
        // Terms checkbox
        Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: _agreeTerms,
                onChanged: loading
                    ? null
                    : (value) => setState(() => _agreeTerms = value ?? false),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'I agree to the Terms & Conditions',
                style: TextStyle(
                  fontSize: 13,
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: loading ? null : () => setState(() => _step = 0),
                style: OutlinedButton.styleFrom(
                  foregroundColor: scheme.onSurface,
                  side: BorderSide(color: scheme.outlineVariant, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Back',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: PremiumButton(
                onPressed: () => _signup(loading),
                label: 'Create Account',
                loading: loading,
                success: _signupSuccess,
                enabled: !loading,
                gradient: AppColors.purplePinkGradient,
                icon: Icons.rocket_launch_rounded,
              ),
            ),
          ],
        ),
      ],
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
                        const Color(0xFFA855F7).withOpacity(0.15),
                        const Color(0xFFEC4899).withOpacity(0.08),
                      ],
                    )
                  : null,
              color: isSelected ? null : scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFFA855F7)
                    : scheme.outlineVariant,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: const Color(0xFFA855F7).withOpacity(0.2),
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
                    gradient:
                        isSelected ? AppColors.purplePinkGradient : null,
                    color: isSelected ? null : scheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: const Color(0xFFA855F7).withOpacity(0.3),
                              blurRadius: 8,
                            ),
                          ]
                        : [],
                  ),
                  child: Icon(
                    icon,
                    color: isSelected ? Colors.white : const Color(0xFFA855F7),
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

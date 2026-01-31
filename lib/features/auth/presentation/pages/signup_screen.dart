import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:smart_waste_app/core/ui/snackbar.dart';
import 'package:smart_waste_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:smart_waste_app/core/extensions/async_value_extensions.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen>
    with SingleTickerProviderStateMixin {
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

  late final AnimationController _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..forward();
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
      context.go('/home');
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    scheme.surface,
                    scheme.surfaceContainerHighest,
                    theme.scaffoldBackgroundColor,
                  ]
                : [
                    const Color(0xFFF1FFF7),
                    const Color(0xFFE6F4FF),
                    Colors.white,
                  ],
            stops: const [0, 0.45, 1],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -80,
              top: -20,
              child: _GlowCircle(
                size: 220,
                color: scheme.primary.withOpacity(isDark ? 0.2 : 0.12),
              ),
            ),
            Positioned(
              right: -40,
              bottom: 120,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      scheme.primary.withOpacity(isDark ? 0.16 : 0.18),
                      Colors.transparent,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            Positioned(
              left: -70,
              bottom: 80,
              child: _GlowCircle(
                size: 180,
                color: scheme.secondary.withOpacity(isDark ? 0.18 : 0.1),
              ),
            ),
            Positioned(
              left: -40,
              top: 140,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(40),
                  border: Border.all(
                    color: scheme.primary.withOpacity(isDark ? 0.25 : 0.2),
                    width: 1,
                  ),
                  gradient: LinearGradient(
                    colors: [
                      scheme.surface.withOpacity(isDark ? 0.2 : 0.5),
                      Colors.transparent,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            SafeArea(
              child: AbsorbPointer(
                absorbing: loading,
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            onPressed:
                                loading ? null : () => context.go('/auth/login'),
                            icon: Icon(
                              Icons.arrow_back_rounded,
                              color: scheme.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        FadeTransition(
                          opacity: fadeAnimation,
                          child: Column(
                            children: [
                              Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      scheme.primary,
                                      scheme.primaryContainer,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: scheme.primary.withOpacity(0.25),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.eco_rounded,
                                  color: Colors.white,
                                  size: 34,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Create your account',
                                style: TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w900,
                                  color: scheme.onSurface,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Join the smart waste network and personalize pickup alerts in minutes.',
                                style: TextStyle(
                                  fontSize: 15.5,
                                  color: scheme.onSurfaceVariant,
                                  height: 1.4,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                alignment: WrapAlignment.center,
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _HeaderPill(
                                    icon: Icons.auto_awesome_outlined,
                                    label: 'Two-step setup',
                                    scheme: scheme,
                                  ),
                                  _HeaderPill(
                                    icon: Icons.lock_outline,
                                    label: 'Private & secure',
                                    scheme: scheme,
                                  ),
                                  _HeaderPill(
                                    icon: Icons.timeline_outlined,
                                    label: 'Real-time updates',
                                    scheme: scheme,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),
                        SlideTransition(
                          position: slideAnimation,
                          child: FadeTransition(
                            opacity: fadeAnimation,
                            child: Container(
                              decoration: BoxDecoration(
                                color: scheme.surface,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: scheme.outlineVariant,
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(
                                      theme.brightness == Brightness.dark
                                          ? 0.18
                                          : 0.06,
                                    ),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildStepIndicator(scheme),
                                    const SizedBox(height: 20),
                                    AnimatedSwitcher(
                                      duration: const Duration(milliseconds: 250),
                                      switchInCurve: Curves.easeOut,
                                      switchOutCurve: Curves.easeIn,
                                      child: _step == 0
                                          ? _buildAccountStep(scheme, loading)
                                          : _buildAddressStep(scheme, loading),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
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
      ),
    );
  }

  Widget _buildStepIndicator(ColorScheme scheme) {
    return Row(
      children: [
        _buildStepBubble(label: '1', isActive: _step == 0, scheme: scheme),
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            height: 4,
            decoration: BoxDecoration(
              color: scheme.outlineVariant,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                height: 4,
                width: _step == 0 ? 52 : 120,
                decoration: BoxDecoration(
                  color: scheme.primary,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
        ),
        _buildStepBubble(label: '2', isActive: _step == 1, scheme: scheme),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            _step == 0 ? 'Account details' : 'Location details',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepBubble({
    required String label,
    required bool isActive,
    required ColorScheme scheme,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: isActive ? scheme.primary : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isActive ? scheme.primary : scheme.outlineVariant,
        ),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: isActive ? scheme.onPrimary : scheme.onSurfaceVariant,
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
        _SectionTitle(
          title: 'Account details',
          subtitle: 'Pick a role and create your credentials.',
          scheme: scheme,
        ),
        const SizedBox(height: 16),
        _buildRoleSelector(loading, scheme),
        const SizedBox(height: 20),
        _buildTextField(
          scheme: scheme,
          controller: _fullName,
          label: 'Full Name',
          icon: Icons.person_outline,
          enabled: !loading,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          scheme: scheme,
          controller: _email,
          label: 'Email Address',
          icon: Icons.email_outlined,
          enabled: !loading,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          scheme: scheme,
          controller: _phone,
          label: 'Phone Number',
          icon: Icons.phone_outlined,
          enabled: !loading,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 16),
        _buildPasswordField(
          scheme: scheme,
          controller: _pass,
          label: 'Password',
          enabled: !loading,
        ),
        const SizedBox(height: 24),
        _buildAuthButton(
          scheme: scheme,
          label: 'Next Step',
          loading: loading,
          onPressed: () => _goNext(loading),
        ),
      ],
    );
  }

  Widget _buildAddressStep(ColorScheme scheme, bool loading) {
    return Column(
      key: const ValueKey('address_step'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          title: 'Address & access',
          subtitle: 'Tell us where your pickups will happen.',
          scheme: scheme,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          scheme: scheme,
          controller: _society,
          label: 'Society',
          icon: Icons.location_city_outlined,
          enabled: !loading,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          scheme: scheme,
          controller: _building,
          label: 'Building',
          icon: Icons.apartment_outlined,
          enabled: !loading,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          scheme: scheme,
          controller: _apartment,
          label: 'Apartment',
          icon: Icons.door_front_door_outlined,
          enabled: !loading,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Checkbox(
              value: _agreeTerms,
              onChanged: loading
                  ? null
                  : (value) => setState(() => _agreeTerms = value ?? false),
            ),
            Expanded(
              child: Text(
                'I agree to the Terms & Conditions.',
                style: TextStyle(
                  fontSize: 13,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: loading ? null : () => setState(() => _step = 0),
                style: OutlinedButton.styleFrom(
                  foregroundColor: scheme.onSurface,
                  side: BorderSide(color: scheme.outlineVariant),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text('Back'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildAuthButton(
                scheme: scheme,
                label: 'Create Account',
                loading: loading,
                onPressed: () => _signup(loading),
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
            fontWeight: FontWeight.w600,
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildRoleCard(
                title: 'Resident',
                subtitle: 'Receive pickup alerts',
                icon: Icons.home_work_outlined,
                value: 'resident',
                loading: loading,
                scheme: scheme,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildRoleCard(
                title: 'Admin/Driver',
                subtitle: 'Manage schedules',
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
    return InkWell(
      onTap: loading ? null : () => setState(() => _role = value),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isSelected
                ? [
                    scheme.primary.withOpacity(0.18),
                    scheme.primaryContainer.withOpacity(0.25),
                  ]
                : [
                    scheme.surfaceContainerHighest,
                    scheme.surface,
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? scheme.primary : scheme.outlineVariant,
            width: isSelected ? 1.6 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isSelected ? 0.12 : 0.04),
              blurRadius: isSelected ? 16 : 8,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected ? scheme.primary : scheme.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected ? scheme.onPrimary : scheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required ColorScheme scheme,
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool enabled,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          enabled: enabled,
          keyboardType: keyboardType,
          style: TextStyle(fontSize: 15, color: scheme.onSurface),
          decoration: InputDecoration(
            hintText: label,
            hintStyle: TextStyle(
              color: scheme.onSurfaceVariant.withOpacity(0.5),
              fontSize: 15,
            ),
            prefixIcon: Icon(icon, size: 20, color: scheme.primary),
            filled: true,
            fillColor: scheme.surfaceContainerHighest,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: scheme.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required ColorScheme scheme,
    required TextEditingController controller,
    required String label,
    required bool enabled,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          enabled: enabled,
          obscureText: _hide,
          style: TextStyle(fontSize: 15, color: scheme.onSurface),
          decoration: InputDecoration(
            hintText: label,
            hintStyle: TextStyle(
              color: scheme.onSurfaceVariant.withOpacity(0.5),
              fontSize: 15,
            ),
            prefixIcon: Icon(
              Icons.lock_outline,
              size: 20,
              color: scheme.primary,
            ),
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
            filled: true,
            fillColor: scheme.surfaceContainerHighest,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: scheme.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAuthButton({
    required ColorScheme scheme,
    required String label,
    required bool loading,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton(
        onPressed: loading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          disabledBackgroundColor: scheme.primary.withOpacity(0.6),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: loading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }
}

class _HeaderPill extends StatelessWidget {
  const _HeaderPill({
    required this.icon,
    required this.label,
    required this.scheme,
  });

  final IconData icon;
  final String label;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withOpacity(0.9),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: scheme.outlineVariant.withOpacity(0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: scheme.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.subtitle,
    required this.scheme,
  });

  final String title;
  final String subtitle;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: scheme.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 13,
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
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

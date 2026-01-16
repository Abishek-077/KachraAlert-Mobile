import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:smart_waste_app/core/ui/snackbar.dart';
import 'package:smart_waste_app/features/auth/presentation/providers/auth_providers.dart';

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
  String _role = 'citizen';
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
    if (_pass.text.length < 6) return 'Password must be at least 6 characters';
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
        );

    if (!mounted) return;
    final auth = ref.read(authStateProvider).valueOrNull;
    if (auth?.isLoggedIn == true) {
      context.go('/home');
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
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [scheme.surface, theme.scaffoldBackgroundColor]
                : [const Color(0xFFE7F7EF), Colors.white],
          ),
        ),
        child: SafeArea(
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
                        onPressed: loading ? null : () => context.go('/auth/login'),
                        icon: Icon(Icons.arrow_back_rounded, color: scheme.onSurface),
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
                              color: scheme.primary,
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
                            'Create Account',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: scheme.onSurface,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Join KachraAlert today',
                            style: TextStyle(
                              fontSize: 15,
                              color: scheme.onSurfaceVariant,
                              height: 1.4,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
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
                                  theme.brightness == Brightness.dark ? 0.18 : 0.06,
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
                value: 'citizen',
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
                value: 'admin',
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
          color: isSelected
              ? scheme.primary.withOpacity(0.12)
              : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? scheme.primary : scheme.outlineVariant,
            width: isSelected ? 1.6 : 1,
          ),
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

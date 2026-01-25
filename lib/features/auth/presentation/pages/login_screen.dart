import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:smart_waste_app/core/ui/snackbar.dart';
import '../providers/auth_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _hide = true;
  String _role = 'resident';

  late final AnimationController _animationController;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..forward();
    _initialized = true;
  }

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    _animationController.dispose();
    super.dispose();
  }

  String? _validateInputs() {
    final email = _email.text.trim();
    final pass = _pass.text;

    if (email.isEmpty) return 'Email is required';
    if (pass.isEmpty) return 'Password is required';
    if (pass.length < 6) return 'Password must be at least 6 characters';
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
    final auth = ref.read(authStateProvider).asData?.value;
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
      final msg = next.asData?.value.errorMessage;
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
              left: -70,
              bottom: 80,
              child: _GlowCircle(
                size: 180,
                color: scheme.secondary.withOpacity(isDark ? 0.18 : 0.1),
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
                        const SizedBox(height: 36),
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
                                'Welcome Back',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  color: scheme.onSurface,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Sign in to manage alerts, reports, and schedules.',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: scheme.onSurfaceVariant,
                                  height: 1.4,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: scheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.verified_outlined,
                                      size: 16,
                                      color: scheme.primary,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Secure city-grade access',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: scheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
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
                                    _buildRoleSelector(loading, scheme),
                                    const SizedBox(height: 20),
                                    _buildTextField(
                                      scheme: scheme,
                                      controller: _email,
                                      label: 'Email Address',
                                      icon: Icons.email_outlined,
                                      enabled: !loading,
                                      keyboardType: TextInputType.emailAddress,
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
                                      label: 'Login',
                                      loading: loading,
                                      onPressed: () => _login(loading),
                                    ),
                                    const SizedBox(height: 16),
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
                                                    : () =>
                                                        context.go('/auth/signup'),
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
                        const SizedBox(height: 32),
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

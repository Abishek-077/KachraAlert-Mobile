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
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _adminCode = TextEditingController();

  bool _hide = true;
  String _role = 'citizen';

  late final AnimationController _controller;
  bool _initialized = false;

  static const _requiredAdminCode = 'ADMIN2026';

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
    _email.dispose();
    _pass.dispose();
    _adminCode.dispose();
    _controller.dispose();
    super.dispose();
  }

  String? _validateInputs() {
    final email = _email.text.trim();
    final pass = _pass.text;

    if (email.isEmpty) return 'Email is required';
    if (pass.isEmpty) return 'Password is required';
    if (pass.length < 6) return 'Password must be at least 6 characters';

    if (_role == 'admin') {
      final code = _adminCode.text.trim();
      if (code.isEmpty) return 'Admin code is required';
      if (code != _requiredAdminCode)
        return 'Invalid admin code. Use ADMIN2026 for demo.';
    }

    return null;
  }

  Future<void> _signup(bool loading) async {
    if (loading) return;

    final validationError = _validateInputs();
    if (validationError != null) {
      AppSnack.show(context, validationError);
      return;
    }

    await ref
        .read(authStateProvider.notifier)
        .signup(email: _email.text.trim(), password: _pass.text, role: _role);

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

    // ✅ Listen for auth error and show snackbar
    ref.listen<AsyncValue<AuthState>>(authStateProvider, (prev, next) {
      final msg = next.valueOrNull?.errorMessage;
      if (msg != null && msg.isNotEmpty) {
        AppSnack.show(context, msg);
        ref.read(authStateProvider.notifier).clearError();
      }
    });

    final authAsync = ref.watch(authStateProvider);
    final loading = authAsync.isLoading;

    final fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    final slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: loading ? null : () => context.go('/auth/login'),
          icon: Icon(Icons.arrow_back_rounded, color: scheme.onSurface),
        ),
      ),
      body: SafeArea(
        child: AbsorbPointer(
          absorbing: loading,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 24),

                  FadeTransition(
                    opacity: fadeAnimation,
                    child: Column(
                      children: [
                        Text(
                          'Create Account',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: scheme.onSurface,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Join the smart waste community',
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

                  const SizedBox(height: 40),

                  SlideTransition(
                    position: slideAnimation,
                    child: FadeTransition(
                      opacity: fadeAnimation,
                      child: Container(
                        decoration: BoxDecoration(
                          color: scheme.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: scheme.outlineVariant,
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(
                                theme.brightness == Brightness.dark
                                    ? 0.18
                                    : 0.04,
                              ),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildRoleSelector(loading, scheme),
                              const SizedBox(height: 24),

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

                              if (_role == 'admin') ...[
                                const SizedBox(height: 16),
                                _buildTextField(
                                  scheme: scheme,
                                  controller: _adminCode,
                                  label: 'Admin Code',
                                  icon: Icons.admin_panel_settings_outlined,
                                  enabled: !loading,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Tip: For demo use ADMIN2026',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: scheme.onSurfaceVariant.withOpacity(
                                      0.7,
                                    ),
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],

                              const SizedBox(height: 24),

                              _buildAuthButton(
                                scheme: scheme,
                                label: 'Create Account',
                                loading: loading,
                                onPressed: () => _signup(loading),
                              ),
                              const SizedBox(height: 16),

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
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleSelector(bool loading, ColorScheme scheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Role',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: scheme.outlineVariant, width: 1),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildRoleSegment('Citizen', 'citizen', loading, scheme),
              ),
              Expanded(
                child: _buildRoleSegment('Admin', 'admin', loading, scheme),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRoleSegment(
    String label,
    String value,
    bool loading,
    ColorScheme scheme,
  ) {
    final isSelected = _role == value;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: loading ? null : () => setState(() => _role = value),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? scheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? scheme.onPrimary : scheme.onSurface,
              ),
            ),
          ),
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

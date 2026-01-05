// lib/features/auth/presentation/providers/auth_state_notifier.dart
import 'package:flutter_riverpod/legacy.dart';
import 'package:kachra_alert/features/auth/domain/entities/auth_entity.dart';
import 'package:kachra_alert/features/auth/presentation/providers/auth_providers.dart';
import 'package:kachra_alert/features/auth/domain/usecases/login_usecase.dart';
import 'package:kachra_alert/features/auth/domain/usecases/register_usecase.dart';
import 'package:kachra_alert/features/auth/domain/usecases/logout_usecase.dart';

// Auth State
class AuthState {
  final AuthEntity? user;
  final bool isLoading;
  final String? error;
  final bool isAuthenticated;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.isAuthenticated = false,
  });

  AuthState copyWith({
    AuthEntity? user,
    bool? isLoading,
    String? error,
    bool? isAuthenticated,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }

  @override
  String toString() =>
      'AuthState(user: $user, isLoading: $isLoading, error: $error, isAuthenticated: $isAuthenticated)';
}

// Auth State Notifier
class AuthStateNotifier extends StateNotifier<AuthState> {
  final LoginUseCase loginUseCase;
  final RegisterUseCase registerUseCase;
  final LogoutUseCase logoutUseCase;

  AuthStateNotifier({
    required this.loginUseCase,
    required this.registerUseCase,
    required this.logoutUseCase,
  }) : super(const AuthState());

  // Login
  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await loginUseCase.call(email, password);
      if (user != null) {
        state = state.copyWith(
          user: user,
          isLoading: false,
          isAuthenticated: true,
          error: null,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Login failed',
          isAuthenticated: false,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        isAuthenticated: false,
      );
    }
  }

  // Register
  Future<void> register({
    required String fullName,
    required String email,
    required String password,
    required String phone,
    required String address,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await registerUseCase.call(
        fullName: fullName,
        email: email,
        password: password,
        phone: phone,
        address: address,
      );
      state = state.copyWith(
        user: user,
        isLoading: false,
        isAuthenticated: true,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        isAuthenticated: false,
      );
    }
  }

  // Logout
  Future<void> logout() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await logoutUseCase.call();
      state = const AuthState();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Provider
final authStateProvider = StateNotifierProvider<AuthStateNotifier, AuthState>((
  ref,
) {
  final loginUseCase = ref.watch(loginUseCaseProvider);
  final registerUseCase = ref.watch(registerUseCaseProvider);
  final logoutUseCase = ref.watch(logoutUseCaseProvider);

  return AuthStateNotifier(
    loginUseCase: loginUseCase,
    registerUseCase: registerUseCase,
    logoutUseCase: logoutUseCase,
  );
});

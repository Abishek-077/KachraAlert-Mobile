import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:logger/logger.dart';
import 'package:smart_waste_app/core/api/api_client.dart';

import '../../../../core/constants/hive_table_constant.dart';
import '../../../../core/services/hive/hive_service.dart';
import '../../../admin/domain/services/admin_broadcast_sound_gate.dart';
import '../../data/models/user_session_hive_model.dart';
import '../../data/services/auth_api_service.dart';

final _logger = Logger();

/// ✅ Base auth exception
sealed class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => message;
}

class UnknownAuthException extends AuthException {
  const UnknownAuthException([
    super.message = 'Something went wrong. Please try again.',
  ]);
}

class UserNotFoundException extends AuthException {
  const UserNotFoundException() : super('No account found for this email.');
}

class InvalidCredentialsException extends AuthException {
  const InvalidCredentialsException() : super('Invalid email or password.');
}

class EmailAlreadyRegisteredException extends AuthException {
  const EmailAlreadyRegisteredException()
    : super('This email is already registered.');
}

class InvalidInputException extends AuthException {
  const InvalidInputException(String field) : super('$field is required.');
}

class PasswordTooShortException extends AuthException {
  const PasswordTooShortException()
    : super('Password must be at least 6 characters.');
}

class RoleMismatchException extends AuthException {
  const RoleMismatchException()
    : super('Selected role does not match this account.');
}

/// ✅ Auth state with errorMessage (SnackBar uses this)
class AuthState {
  final bool isLoggedIn;
  final UserSessionHiveModel? session;
  final String? errorMessage;

  const AuthState({required this.isLoggedIn, this.session, this.errorMessage});

  bool get isAdmin => (session?.role == 'admin_driver');

  AuthState copyWith({
    bool? isLoggedIn,
    UserSessionHiveModel? session,
    String? errorMessage,
  }) {
    return AuthState(
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      session: session ?? this.session,
      errorMessage: errorMessage,
    );
  }

  static const loggedOut = AuthState(isLoggedIn: false);
}

/// ✅ Auth provider
final authStateProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<AuthState>>((ref) {
      return AuthNotifier(authApi: ref.watch(authApiServiceProvider));
    });

class AuthNotifier extends StateNotifier<AsyncValue<AuthState>> {
  AuthNotifier({required AuthApiService authApi})
    : _authApi = authApi,
      super(const AsyncValue.loading()) {
    _load();
  }

  final AuthApiService _authApi;
  late final Box<UserSessionHiveModel> _sessionBox;
  bool _isInitialized = false;

  Future<void> _initBoxes() async {
    if (_isInitialized) return;

    _sessionBox = HiveService.box<UserSessionHiveModel>(
      HiveTableConstant.sessionBox,
    );

    _isInitialized = true;
  }

  Future<void> _load() async {
    try {
      await _initBoxes();
      final session = _sessionBox.get('session');
      if (session == null) {
        state = const AsyncValue.data(AuthState.loggedOut);
      } else {
        state = AsyncValue.data(AuthState(isLoggedIn: true, session: session));
      }
    } catch (e, st) {
      _logger.e('Auth load failed', error: e, stackTrace: st);
      state = const AsyncValue.data(AuthState.loggedOut);
    }
  }

  /// ✅ SIGNUP (NO THROW, sets errorMessage)
  Future<void> signup({
    required String email,
    required String password,
    required String role,
    required String fullName,
    required String phone,
    required String society,
    required String building,
    required String apartment,
    required bool termsAccepted,
  }) async {
    state = const AsyncValue.loading();

    try {
      await _initBoxes();

      final cleanEmail = email.trim().toLowerCase();

      if (cleanEmail.isEmpty) throw const InvalidInputException('Email');
      if (password.isEmpty) throw const InvalidInputException('Password');
      if (password.length < 6) throw const PasswordTooShortException();
      if (fullName.trim().isEmpty) {
        throw const InvalidInputException('Full name');
      }
      if (phone.trim().isEmpty) throw const InvalidInputException('Phone');
      if (society.trim().isEmpty) {
        throw const InvalidInputException('Society');
      }
      if (building.trim().isEmpty) {
        throw const InvalidInputException('Building');
      }
      if (apartment.trim().isEmpty) {
        throw const InvalidInputException('Apartment');
      }

      final user = await _authApi.signup(
        email: cleanEmail,
        password: password,
        accountType: role,
        name: fullName,
        phone: phone,
        society: society,
        building: building,
        apartment: apartment,
        termsAccepted: termsAccepted,
      );

      var session = UserSessionHiveModel(
        userId: user.userId,
        email: user.email,
        role: user.role,
        lastHeardBroadcastAt: 0,
      );

      try {
        session = await AdminBroadcastSoundGate.playIfNeeded(session: session);
      } catch (e) {
        _logger.w('Broadcast gate failed during signup', error: e);
      }

      await _sessionBox.put('session', session);

      state = AsyncValue.data(
        AuthState(isLoggedIn: true, session: session, errorMessage: null),
      );
    } on ApiException catch (e) {
      _logger.w('Signup API error: $e');
      state = AsyncValue.data(
        AuthState(isLoggedIn: false, session: null, errorMessage: e.message),
      );
    } on AuthException catch (e) {
      _logger.w('Signup validation error: $e');
      state = AsyncValue.data(
        AuthState(isLoggedIn: false, session: null, errorMessage: e.message),
      );
    } catch (e, st) {
      _logger.e('Signup failed', error: e, stackTrace: st);
      state = const AsyncValue.data(
        AuthState(
          isLoggedIn: false,
          session: null,
          errorMessage: 'Something went wrong. Please try again.',
        ),
      );
    }
  }

  /// ✅ LOGIN (NO THROW, sets errorMessage)
  Future<void> login({
    required String email,
    required String password,
    String role = 'resident',
  }) async {
    state = const AsyncValue.loading();

    try {
      await _initBoxes();

      final cleanEmail = email.trim().toLowerCase();

      if (cleanEmail.isEmpty) throw const InvalidInputException('Email');
      if (password.isEmpty) throw const InvalidInputException('Password');
      if (password.length < 6) throw const PasswordTooShortException();

      final previous = _sessionBox.get('session');
      final user = await _authApi.login(
        email: cleanEmail,
        password: password,
        role: role,
      );

      if (user.role != role) {
        throw const RoleMismatchException();
      }

      var session = UserSessionHiveModel(
        userId: user.userId,
        email: user.email,
        role: user.role,
        lastHeardBroadcastAt: previous?.lastHeardBroadcastAt ?? 0,
      );

      try {
        session = await AdminBroadcastSoundGate.playIfNeeded(session: session);
      } catch (e) {
        _logger.w('Broadcast gate failed during login', error: e);
      }

      await _sessionBox.put('session', session);

      state = AsyncValue.data(
        AuthState(isLoggedIn: true, session: session, errorMessage: null),
      );
    } on ApiException catch (e) {
      _logger.w('Login API error: $e');
      state = AsyncValue.data(
        AuthState(isLoggedIn: false, session: null, errorMessage: e.message),
      );
    } on AuthException catch (e) {
      _logger.w('Login validation error: $e');
      state = AsyncValue.data(
        AuthState(isLoggedIn: false, session: null, errorMessage: e.message),
      );
    } catch (e, st) {
      _logger.e('Login failed', error: e, stackTrace: st);
      state = const AsyncValue.data(
        AuthState(
          isLoggedIn: false,
          session: null,
          errorMessage: 'Something went wrong. Please try again.',
        ),
      );
    }
  }

  /// ✅ Clears error message after UI shows SnackBar
  void clearError() {
    final current = state.valueOrNull;
    if (current == null) return;
    if (current.errorMessage == null) return;
    state = AsyncValue.data(current.copyWith(errorMessage: null));
  }

  Future<void> logout() async {
    try {
      await _initBoxes();
      await _sessionBox.delete('session');
      state = const AsyncValue.data(AuthState.loggedOut);
    } catch (e, st) {
      _logger.e('Logout failed', error: e, stackTrace: st);
      state = const AsyncValue.data(AuthState.loggedOut);
    }
  }
}

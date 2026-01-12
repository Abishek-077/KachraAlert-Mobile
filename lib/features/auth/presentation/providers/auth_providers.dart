import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/hive_table_constant.dart';
import '../../../../core/services/hive/hive_service.dart';
import '../../../admin/domain/services/admin_broadcast_sound_gate.dart';
import '../../data/models/user_account_hive_model.dart';
import '../../data/models/user_session_hive_model.dart';

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

  bool get isAdmin => (session?.role == 'admin');

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
      return AuthNotifier();
    });

class AuthNotifier extends StateNotifier<AsyncValue<AuthState>> {
  AuthNotifier() : super(const AsyncValue.loading()) {
    _load();
  }

  late final Box<UserSessionHiveModel> _sessionBox;
  late final Box<UserAccountHiveModel> _accountsBox;
  bool _isInitialized = false;

  Future<void> _initBoxes() async {
    if (_isInitialized) return;

    _sessionBox = HiveService.box<UserSessionHiveModel>(
      HiveTableConstant.sessionBox,
    );
    _accountsBox = HiveService.box<UserAccountHiveModel>(
      HiveTableConstant.accountsBox,
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
  }) async {
    state = const AsyncValue.loading();

    try {
      await _initBoxes();

      final cleanEmail = email.trim().toLowerCase();

      if (cleanEmail.isEmpty) throw const InvalidInputException('Email');
      if (password.isEmpty) throw const InvalidInputException('Password');
      if (password.length < 6) throw const PasswordTooShortException();

      final exists = _accountsBox.values.any((u) => u.email == cleanEmail);
      if (exists) throw const EmailAlreadyRegisteredException();

      final account = UserAccountHiveModel(
        userId: const Uuid().v4(),
        email: cleanEmail,
        password: password,
        role: role,
      );
      await _accountsBox.put(account.userId, account);

      var session = UserSessionHiveModel(
        userId: account.userId,
        email: account.email,
        role: account.role,
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
    } on AuthException catch (e) {
      _logger.w('Signup error: $e');
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
    String role = 'citizen',
  }) async {
    state = const AsyncValue.loading();

    try {
      await _initBoxes();

      final cleanEmail = email.trim().toLowerCase();

      if (cleanEmail.isEmpty) throw const InvalidInputException('Email');
      if (password.isEmpty) throw const InvalidInputException('Password');
      if (password.length < 6) throw const PasswordTooShortException();

      final match = _accountsBox.values
          .where((u) => u.email == cleanEmail)
          .toList();
      if (match.isEmpty) throw const UserNotFoundException();

      final user = match.first;

      if (user.password != password) throw const InvalidCredentialsException();
      if (user.role != role) throw const RoleMismatchException();

      final previous = _sessionBox.get('session');
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
    } on AuthException catch (e) {
      _logger.w('Login error: $e');
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

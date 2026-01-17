// core/services/user_session_service.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// SharedPreferences provider – must be overridden in main.dart
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be overridden in main.dart');
});

// UserSessionService provider
final userSessionServiceProvider = Provider<UserSessionService>((ref) {
  final prefs = ref.read(sharedPreferencesProvider);
  return UserSessionService(prefs: prefs);
});

class UserSessionService {
  final SharedPreferences _prefs;

  // Keys prefixed with app name to avoid conflicts
  static const String _keyIsLoggedIn = 'kachraalert_is_logged_in';
  static const String _keyOnboardingCompleted =
      'kachraalert_onboarding_completed';

  static const String _keyUserId = 'kachraalert_user_id';
  static const String _keyUserFullName = 'kachraalert_user_full_name';
  static const String _keyUserEmail = 'kachraalert_user_email';
  static const String _keyUserPhone = 'kachraalert_user_phone';
  static const String _keyUserAddress =
      'kachraalert_user_address'; // Locality/area for targeted alerts
  static const String _keyUserRole =
      'kachraalert_user_role'; // 'resident', 'admin_driver'
  static const String _keyUserProfilePic =
      'kachraalert_user_profile_pic'; // Local file path or URL

  UserSessionService({required SharedPreferences prefs}) : _prefs = prefs;

  // Save session after successful login/registration
  Future<void> saveUserSession({
    required String userId,
    required String fullName,
    required String email,
    String? phone,
    String? address,
    String? role = 'resident',
    String? profilePic,
  }) async {
    await _prefs.setBool(_keyIsLoggedIn, true);
    await _prefs.setString(_keyUserId, userId);
    await _prefs.setString(_keyUserFullName, fullName);
    await _prefs.setString(_keyUserEmail, email);

    if (phone != null && phone.isNotEmpty) {
      await _prefs.setString(_keyUserPhone, phone);
    } else {
      await _prefs.remove(_keyUserPhone);
    }

    if (address != null && address.isNotEmpty) {
      await _prefs.setString(_keyUserAddress, address);
    } else {
      await _prefs.remove(_keyUserAddress);
    }

    await _prefs.setString(_keyUserRole, role ?? 'resident');

    if (profilePic != null && profilePic.isNotEmpty) {
      await _prefs.setString(_keyUserProfilePic, profilePic);
    } else {
      await _prefs.remove(_keyUserProfilePic);
    }
  }

  // Mark onboarding as completed (called once)
  Future<void> completeOnboarding() async {
    await _prefs.setBool(_keyOnboardingCompleted, true);
  }

  // Check onboarding status
  bool isOnboardingCompleted() {
    return _prefs.getBool(_keyOnboardingCompleted) ?? false;
  }

  // Check login status
  bool isLoggedIn() {
    return _prefs.getBool(_keyIsLoggedIn) ?? false;
  }

  // Getters
  String? getUserId() => _prefs.getString(_keyUserId);

  String? getUserFullName() => _prefs.getString(_keyUserFullName);

  String? getUserEmail() => _prefs.getString(_keyUserEmail);

  String? getUserPhone() => _prefs.getString(_keyUserPhone);

  String? getUserAddress() => _prefs.getString(_keyUserAddress);

  String getUserRole() => _prefs.getString(_keyUserRole) ?? 'resident';

  String? getUserProfilePic() => _prefs.getString(_keyUserProfilePic);

  // Role helpers
  bool isAdmin() => getUserRole() == 'admin_driver';

  bool isCollector() => getUserRole() == 'collector';

  bool isCitizen() => getUserRole() == 'resident';

  // Logout – clears login data but preserves onboarding
  Future<void> logout() async {
    await _prefs.remove(_keyIsLoggedIn);
    await _prefs.remove(_keyUserId);
    await _prefs.remove(_keyUserFullName);
    await _prefs.remove(_keyUserEmail);
    await _prefs.remove(_keyUserPhone);
    await _prefs.remove(_keyUserAddress);
    await _prefs.remove(_keyUserRole);
    await _prefs.remove(_keyUserProfilePic);
    // Onboarding flag stays – no repeat onboarding
  }

  // Full reset – for testing or account deletion
  Future<void> clearAllSessionData() async {
    await logout();
    await _prefs.remove(_keyOnboardingCompleted);
  }
}

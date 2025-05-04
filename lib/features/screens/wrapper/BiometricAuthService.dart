import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BiometricAuthService {
  static final LocalAuthentication _localAuth = LocalAuthentication();
  static const String _authKey = 'auth_timestamp';
  static const String _isLoggedInKey = 'is_logged_in';

  // Check if device supports biometrics
  static Future<bool> isBiometricAvailable() async {
    bool canCheckBiometrics = false;
    try {
      canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      return canCheckBiometrics && availableBiometrics.isNotEmpty;
    } on PlatformException catch (e) {
      debugPrint("Error checking biometrics: $e");
      return false;
    }
  }

  // Authenticate with biometrics
  static Future<bool> authenticateWithBiometrics() async {
    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Please authenticate to access RedPulse',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // Allow PIN/pattern as fallback
        ),
      );

      if (authenticated) {
        await _updateAuthTimestamp();
      }
      return authenticated;
    } on PlatformException catch (e) {
      debugPrint("Error using biometrics: $e");
      return false;
    }
  }

  // Update authentication timestamp
  static Future<void> _updateAuthTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_authKey, DateTime.now().toIso8601String());
  }

  // Check if authentication is needed (app reopened)
  static Future<bool> shouldAuthenticate() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool(_isLoggedInKey) ?? false;

    // If user is logged in, require biometric authentication on app reopen
    return isLoggedIn;
  }

  // Mark user as logged in
  static Future<void> setLoggedIn(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, value);
    if (value) {
      await _updateAuthTimestamp();
    }
  }

  // Clear auth state on logout
  static Future<void> clearAuthState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_authKey);
    await prefs.setBool(_isLoggedInKey, false);
  }
}
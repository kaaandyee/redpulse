import 'package:flutter/material.dart';
import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:redpulse/features/screens/on_boarding_screen.dart';
import 'package:redpulse/features/screens/wrapper/BiometricAuthService.dart';
import 'package:redpulse/features/screens/wrapper/wrapper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'BiometricAuthScreen.dart';
import 'wrapper/wrapper.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  Future<Widget> _checkOnboardingStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final seenOnboarding = prefs.getBool('seenOnboarding') ?? false;

    if (seenOnboarding) {
      return const Wrapper(); // Go directly to login or main app
    } else {
      return OnBoardingScreen(); // First-time users
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSplashScreen(
      duration: 2500,
      splash: 'assets/images/splash_logo.gif',
      splashIconSize: 2000.0,
      centered: true,
      nextScreen: const AuthCheckScreen(), // Use intermediate screen
      splashTransition: SplashTransition.fadeTransition,
      backgroundColor: Colors.white,
    );
  }
}

// Intermediate screen to check auth state after splash animation
class AuthCheckScreen extends StatefulWidget {
  const AuthCheckScreen({super.key});

  @override
  State<AuthCheckScreen> createState() => _AuthCheckScreenState();
}

class _AuthCheckScreenState extends State<AuthCheckScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthenticationState();
  }

  Future<void> _checkAuthenticationState() async {
    // Check if biometric auth is needed
    final needsAuth = await BiometricAuthService.shouldAuthenticate();

    if (!mounted) return;

    if (needsAuth && await BiometricAuthService.isBiometricAvailable()) {
      // Navigate to biometric auth screen
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const BiometricAuthScreen()));
    } else {
      // Navigate to normal flow
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const Wrapper()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

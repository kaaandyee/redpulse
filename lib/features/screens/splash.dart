import 'package:flutter/material.dart';
import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:redpulse/features/screens/on_boarding_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
    return FutureBuilder<Widget>(
      future: _checkOnboardingStatus(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else {
          return AnimatedSplashScreen(
            duration: 2500,
            splash: 'assets/images/splash_logo.gif',
            splashIconSize: 2000.0,
            centered: true,
            nextScreen: snapshot.data!,
            splashTransition: SplashTransition.fadeTransition,
            backgroundColor: Colors.white,
          );
        }
      },
    );
  }
}

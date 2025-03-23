import 'package:flutter/material.dart';
import 'package:animated_splash_screen/animated_splash_screen.dart';
//import 'login.dart'; // Import LoginScreen
import 'wrapper/wrapper.dart'; // Import Wrapper

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedSplashScreen(
      duration: 2500, // 2.5 seconds
      splash: 'assets/images/splash_logo.gif',
      splashIconSize: 2000.0,
      centered: true,
      nextScreen: const Wrapper(),
      splashTransition: SplashTransition.fadeTransition,
      backgroundColor: Colors.white, // Adjust based on design
    );
  }
}

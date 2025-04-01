//USING THIS, SPLASH SCREEN, WONT WORK

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:redpulse/features/screens/login.dart'; // Import the login screen
import 'package:redpulse/features/screens/splash.dart'; // Import the splash screen
import 'package:redpulse/features/screens/user/start.dart'; // Import the user start screen

class AppRouter {
  // Define your routes
  static final GoRouter router = GoRouter(
    initialLocation: '/', // Initial route
    routes: [
      // Splash screen route
      GoRoute(
        path: '/',
        builder: (BuildContext context, GoRouterState state) {
          return const SplashScreen(); // Show SplashScreen first
        },
        redirect: (BuildContext context, GoRouterState state) {
          // After splash, decide where to route
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            // If user is logged in, route to the home screen or user start screen
            return '/start';
          }
          // If user is not logged in, route to login screen
          return '/login';
        },
      ),
      // Login screen route
      GoRoute(
        path: '/login',
        builder: (BuildContext context, GoRouterState state) {
          return const LoginScreen(); // Show LoginScreen if user is not logged in
        },
      ),
      // User Start screen route
      GoRoute(
        path: '/start',
        builder: (BuildContext context, GoRouterState state) {
          return const UserStart(); // Show UserStart if user is logged in
        },
      ),
    ],
  );
}

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:redpulse/features/screens/login.dart';
import 'package:redpulse/features/screens/signup.dart';
import 'package:redpulse/features/screens/splash.dart';
import 'package:redpulse/AppRouter.dart';
import 'package:redpulse/utilities/constants/styles.dart';
import 'package:flutter/foundation.dart' as foundation; // For platform checking
import 'features/screens/wrapper/wrapper.dart';
import 'firebase_options.dart';

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
GlobalKey<ScaffoldMessengerState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  if (Firebase.apps.isEmpty) {
    if (foundation.kIsWeb) {
      // Firebase initialization for web (no name required)
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } else {
      // Firebase initialization for non-web (e.g., Android, iOS) with name
      await Firebase.initializeApp(
        name: "RedPulse",
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  }

  runApp(
    MultiProvider(
      providers: [
        StreamProvider<User?>.value(
          value: FirebaseAuth.instance.authStateChanges(),
          initialData: null,
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RedPulse',
      scaffoldMessengerKey: scaffoldMessengerKey, // Register the key here
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.red,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
<<<<<<< HEAD
<<<<<<< Updated upstream
      home: const SplashScreen(),
=======
      home:
          const SplashScreen(), // Make SplashScreen the first screen to appear
      routes: {
        '/wrapper': (context) => Wrapper(), // Add the SignUpScreen route here
      },
>>>>>>> Stashed changes
=======
      home: const SplashScreen(), // Make SplashScreen the first screen to appear
>>>>>>> 2f1a807451ac93c8b55032ec34ba52310931c6c3
    );
  }
}
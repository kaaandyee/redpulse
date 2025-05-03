import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:redpulse/features/screens/google_signup_completion.dart';
import 'package:redpulse/features/screens/user/start.dart';

class FirebaseServices {
  final auth = FirebaseAuth.instance;
  final googleSignIn = GoogleSignIn();
  final firestore = FirebaseFirestore.instance;

  Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      // Begin Google sign-in process
      final GoogleSignInAccount? gUser = await googleSignIn.signIn();
      if (gUser == null) {
        throw Exception("Google Sign In was canceled");
      }

      // Obtain auth details
      final GoogleSignInAuthentication gAuth = await gUser.authentication;

      // Create credential
      final credential = GoogleAuthProvider.credential(
        accessToken: gAuth.accessToken,
        idToken: gAuth.idToken,
      );

      // Sign in with Firebase
      final UserCredential userCredential = await auth.signInWithCredential(credential);
      final User user = userCredential.user!;

      // Check if user exists in our database
      final userDoc = await firestore.collection('users').doc(user.uid).get();
      final bool isNewUser = !userDoc.exists;

      return {
        'user': user,
        'isNewUser': isNewUser,
        'userCredential': userCredential
      };
    } catch (e) {
      print("Error in Google Sign In: $e");
      rethrow;
    }
  }

  // Handle Google sign-in logic and navigation
  Future<void> handleGoogleSignIn(BuildContext context) async {
    try {
      final result = await signInWithGoogle();

      if (result['isNewUser'] == true) {
        // New user - redirect to blood type collection screen
        final User user = result['user'];

        if (context.mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => GoogleSignupCompletionScreen(
                uid: user.uid,
                email: user.email ?? '',
                displayName: user.displayName ?? 'User',
                photoURL: user.photoURL,
              ),
            ),
          );
        }
      } else {
        // Existing user - go directly to home
        if (context.mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const UserStart(),
            ),
          );
        }
      }
    } catch (e) {
      throw e;
    }
  }

  // Save user data after Google sign-in
  Future<void> saveGoogleUserData({
    required String uid,
    required String email,
    required String displayName,
    required String? photoURL,
    required String bloodType,
  }) async {
    try {
      // Split display name into first and last name
      List<String> nameParts = displayName.split(' ');
      String firstName = nameParts[0];
      String lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

      // Save to Firestore
      await firestore.collection('users').doc(uid).set({
        'id': uid,
        'email': email,
        'firstName': firstName,
        'lastName': lastName,
        'fullName': displayName,
        'profileImageUrl': photoURL ?? '',
        'bloodType': bloodType,
        'role': 'user',
        'dateCreated': DateTime.now(),
        'phoneNumber': '',
        'address': '',
      });
    } catch (e) {
      print("Error saving Google user data: $e");
      throw e;
    }
  }
}
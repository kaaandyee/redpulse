import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../widgets/abottombar.dart';
import '../../../widgets/ubottombar.dart';
import '../../models/users.dart';
import '../login.dart';
import 'BiometricAuthService.dart';


class Wrapper extends StatelessWidget {
  const Wrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Get the current firebase user from a higher-level Provider.
    final firebaseUser = Provider.of<User?>(context);

    _checkBiometricAuth(context);

    if (firebaseUser == null) {
      return const LoginScreen();
    } else {
      // Instead of doing a StreamBuilder here,
      // wrap your UI in a StreamProvider so that anywhere
      // in the subtree you can access the latest user data.
      return StreamProvider<UserAdminModel?>.value(
        value: FirebaseFirestore.instance
            .collection('users')
            .doc(firebaseUser.uid)
            .snapshots()
            .map((snapshot) {
          if (snapshot.exists) {
            return UserAdminModel.fromJson(
              snapshot.data() as Map<String, dynamic>,
              snapshot.id,
            );
          }
          return null;
        }),
        initialData: null,
        child: Consumer<UserAdminModel?>(builder: (context, userAdmin, _) {
          if (userAdmin == null) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          // Decide which UI to show based on the role.
          if (userAdmin.role == 'Admin') {
            return ABottomBar(
              isAdminLinkedToBloodBank: userAdmin.bloodBankId?.isNotEmpty ?? false,
            );
          } else {
            return const UBottomBar();
          }
        }),
      );
    }
  }

  Future<void> _checkBiometricAuth(BuildContext context) async {
    // Check if biometric auth is needed (user previously logged in)
    bool shouldAuth = await BiometricAuthService.shouldAuthenticate();

    if (shouldAuth) {
      // Check if device supports biometrics
      bool canUseBiometrics = await BiometricAuthService.isBiometricAvailable();

      if (canUseBiometrics) {
        // Show the authentication dialog
        bool authenticated = await BiometricAuthService.authenticateWithBiometrics();

        // If authentication fails, log the user out
        if (!authenticated) {
          // Show a brief message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Authentication required to continue')),
          );

          // Clear auth state and sign out
          await BiometricAuthService.clearAuthState();
          await FirebaseAuth.instance.signOut();
        }
      }
    }
  }
}
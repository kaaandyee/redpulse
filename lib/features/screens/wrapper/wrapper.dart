import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../widgets/abottombar.dart';
import '../../../widgets/ubottombar.dart';
import '../../models/users.dart';
import '../admin/home.dart';
import '../admin/start.dart';
import '../login.dart';
import '../user/home.dart';
import '../user/start.dart';


class Wrapper extends StatelessWidget {
  const Wrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Get the current firebase user from a higher-level Provider.
    final firebaseUser = Provider.of<User?>(context);

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
}
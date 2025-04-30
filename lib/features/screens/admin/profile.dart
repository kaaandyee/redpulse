import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:redpulse/features/screens/admin/sub/bloodbankprofile.dart';
import 'package:redpulse/features/screens/login.dart';
import 'package:redpulse/utilities/constants/styles.dart';

import '../../../widgets/confirmLogout.dart';

class ProfileScreen extends StatelessWidget {
  final String? adminId;

  const ProfileScreen({super.key, this.adminId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(120),
        child: AppBar(
          backgroundColor: Styles.primaryColor,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
          ),
          elevation: 0,
          flexibleSpace: Padding(
            padding: const EdgeInsets.all(20),
            child: Align(
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  Text(
                    "Blood Bank Profile",
                    style: Styles.headerStyle2.copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Styles.tertiaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 50),

            // Blood Bank Profile Navigation Tile
            ListTile(
              title: Text(
                "Blood Bank Account",
                style: Styles.headerStyle3.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Styles.accentColor,
                ),
              ),
              trailing: const Icon(Icons.arrow_forward_ios_outlined, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BloodBankProfileScreen(),
                  ),
                );
              },
            ),
            const Divider(), // Simple Line Separator

            // Log Out Navigation Tile with confirmation
            ListTile(
              title: Text(
                "Log Out",
                style: Styles.headerStyle3.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Styles.primaryColor,
                ),
              ),
              trailing: const Icon(Icons.arrow_forward_ios_outlined, size: 16),
              onTap: () async {
                // Show the confirmation dialog
                final shouldLogout = await showDialog<bool>(
                  context: context,
                  builder: (context) => const Confirmlogout(),
                );

                // If confirmed, perform complete logout
                if (shouldLogout == true) {
                  try {
                    // Show loading indicator
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => const Center(
                        child: CircularProgressIndicator(),
                      ),
                    );

                    // Clear all authentication data
                    final auth = FirebaseAuth.instance;
                    await auth.signOut();

                    // Remove all routes and navigate to login
                    if (context.mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                            (route) => false, // This removes all previous routes
                      );
                    }
                  } catch (e) {
                    // Handle any errors during logout
                    if (context.mounted) {
                      Navigator.pop(context); // Remove loading dialog
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error signing out: $e')),
                      );
                    }
                  }
                }
              },
            ),
            const Divider(),
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:redpulse/features/screens/admin/sub/adminprofile.dart';
import 'package:redpulse/features/screens/admin/sub/bloodbankprofile.dart';
import 'package:redpulse/features/screens/login.dart';
import 'package:redpulse/utilities/constants/styles.dart';

import '../../../widgets/confirmLogout.dart';

class ProfileScreen extends StatelessWidget {
  final String? adminId; // Made adminId optional

  const ProfileScreen({Key? key, this.adminId}) : super(key: key);

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
                    "Profile",
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
            // Admin Profile Navigation Tile
            ListTile(
              title: Text(
                "My Account",
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
                    builder: (context) => const AdminProfileScreen(),
                  ),
                );
              },
            ),
            const Divider(), // Simple Line Separator

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
                // Show the logout confirmation dialog
                final shouldLogout = await showDialog<bool>(
                  context: context,
                  builder: (context) => const Confirmlogout(),
                );

                // If the user confirmed logout, perform sign-out logic and navigate to LoginScreen
                if (shouldLogout == true) {
                  // Optionally: Add your sign-out logic here, e.g.,
                  // await FirebaseAuth.instance.signOut();

                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                        (Route<dynamic> route) => false,
                  );
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

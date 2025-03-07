import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:redpulse/features/models/users.dart'; // your user model
import 'package:provider/provider.dart';
import 'package:redpulse/features/screens/user/sub/userCardsHome.dart';
import 'package:redpulse/utilities/constants/styles.dart';

class UserHome extends StatelessWidget {
  const UserHome({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Read the latest user data from the Provider.
    final user = Provider.of<UserAdminModel?>(context);

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(120),
        child: AppBar(
          backgroundColor: Styles.primaryColor,
          elevation: 0,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
          ),
          flexibleSpace: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 50),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  Text("RED PULSE", style: Styles.headerStyle1),
                  Text(
                    "Saving lives, One drop at a time.",
                    style: Styles.headerStyle3.copyWith(fontSize: 15),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        children: [
          // Row containing the profile image and welcome text.
          Padding(
            padding:
            const EdgeInsets.symmetric(horizontal: 50, vertical: 30),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Profile Image
                CircleAvatar(
                  radius: 30,
                  backgroundImage: (user.profileImageUrl != null &&
                      user.profileImageUrl!.isNotEmpty)
                      ? NetworkImage(user.profileImageUrl!)
                      : const AssetImage(
                      'assets/images/default_profile.jpg')
                  as ImageProvider,
                ),
                const SizedBox(width: 15),
                // Welcome Text
                Expanded(
                  child: Text(
                    "Welcome, ${user.fullName}!",
                    style: GoogleFonts.robotoMono(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Styles.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Other content on the home screen.
          const userCardsHome(),
        ],
      ),
    );
  }
}
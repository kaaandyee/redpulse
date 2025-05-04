import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:redpulse/features/models/users.dart';
import 'package:redpulse/features/screens/login.dart';
import 'package:redpulse/features/screens/user/sub/updateprofile.dart';
import 'package:redpulse/services/auth.dart';
import 'package:redpulse/utilities/constants/styles.dart';

import '../../../widgets/confirmLogout.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  Future<String?> get userId async {
    try {
      // Fetch the current authenticated user.
      final User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("User is not logged in.");
      }

      // Use the user's UID to fetch the corresponding document from Firestore.
      DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userSnapshot.exists) {
        throw Exception("User document not found.");
      }

      // Retrieve the userId (or other relevant field) from the document.
      String? userId = userSnapshot['id'];

      if (userId!.isEmpty) {
        throw Exception("UserId not found or is empty.");
      }

      return userId; // Return the userId if found.
    } catch (error) {
      print("Error fetching userId: $error");
      return null; // Return null on failure.
    }
  }

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<UserAdminModel?> _userFuture;
  String? _userId; // Store the userId locally.

  @override
  void initState() {
    super.initState();
    _initializeUserId();
  }

  Future<void> _initializeUserId() async {
    final userId = await widget.userId;
    if (userId != null) {
      setState(() {
        _userId = userId;
        _userFuture =
            _fetchUserProfile(); // Fetch profile once userId is available.
      });
    }
  }

  // Fetch user profile from Firestore.
  Future<UserAdminModel?> _fetchUserProfile() async {
    try {
      if (_userId == null) throw Exception('User ID is null.');

      // Get user data from Firestore.
      final docSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId) // Pass the userId to the query.
          .get();

      if (docSnapshot.exists) {
        // If user exists, create UserAdminModel from the snapshot.
        return UserAdminModel.fromJson(docSnapshot.data()!, docSnapshot.id);
      } else {
        print('User not found');
        return null;
      }
    } catch (e) {
      print('Error fetching user profile: $e');
      return null;
    }
  }

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
<<<<<<< Updated upstream
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
=======
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: screenSize.width * 0.06,
                    vertical: screenSize.height * 0.015),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      "Profile",
                      style: GoogleFonts.montserrat(
                        fontSize: screenSize.width * 0.055,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
>>>>>>> Stashed changes
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: _userId == null
<<<<<<< Updated upstream
          ? const Center(child: CircularProgressIndicator()) // Show loading until userId is fetched.
          : FutureBuilder<UserAdminModel?>(
        future: _userFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('No user data available'));
          }

          final user = snapshot.data!;

          // Wrap the content in SingleChildScrollView to make it scrollable.
          return SingleChildScrollView(
            child: Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 50, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: CircleAvatar(
                      radius: 50,
                      backgroundImage: user.profileImageUrl != null
                          ? NetworkImage(user.profileImageUrl!)
                          : const AssetImage(
                          'assets/images/default_profile.jpg')
                      as ImageProvider,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('Full Name:',
                      style: Styles.headerStyle5.copyWith(
                          fontSize: 18, color: Styles.accentColor)),
                  Text('${user.fullName}',
                      style: Styles.headerStyle5.copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Styles.accentColor)),
                  const SizedBox(height: 15),
                  Text('Email:',
                      style: Styles.headerStyle5.copyWith(
                          fontSize: 18, color: Styles.accentColor)),
                  Text('${user.email}',
                      style: Styles.headerStyle5.copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Styles.accentColor)),
                  const SizedBox(height: 15),
                  Text('Phone Number:',
                      style: Styles.headerStyle5.copyWith(
                          fontSize: 18, color: Styles.accentColor)),
                  Text('${user.phoneNumber}',
                      style: Styles.headerStyle5.copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Styles.accentColor)),
                  const SizedBox(height: 15),
                  Text('Address:',
                      style: Styles.headerStyle5.copyWith(
                          fontSize: 18, color: Styles.accentColor)),
                  Text('${user.address}',
                      style: Styles.headerStyle5.copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Styles.accentColor)),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text('Blood Type:',
                          style: Styles.headerStyle5.copyWith(
                              fontSize: 18, color: Styles.accentColor)),
                      const SizedBox(width: 62),
                      Text('Role:',
                          style: Styles.headerStyle5.copyWith(
                              fontSize: 18, color: Styles.accentColor)),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text('${user.bloodType}',
                          style: Styles.headerStyle5.copyWith(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Styles.accentColor)),
                      const SizedBox(width: 135),
                      Text('${user.role}',
                          style: Styles.headerStyle5.copyWith(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Styles.accentColor)),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Text('Account Created:',
                      style: Styles.headerStyle5.copyWith(
                          fontSize: 18, color: Styles.accentColor)),
                  Text(
                    DateFormat('MM/dd/yyyy').format(user.dateCreated),
                    style: Styles.headerStyle5.copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Styles.accentColor),
                  ),
                  const SizedBox(height: 30),
                  // Logout Button
                  ElevatedButton(
                    onPressed: () async {
                      // Show the confirmation dialog and await the result.
                      final shouldLogout = await showDialog<bool>(
                        context: context,
                        builder: (context) => const Confirmlogout(),
                      );

                      // If the user confirms the logout, sign out and navigate to LoginScreen.
                      if (shouldLogout == true) {
                        await FirebaseAuth.instance.signOut();
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                              (Route<dynamic> route) => false,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: Styles.primaryColor,
                      foregroundColor: Styles.tertiaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Log Out',
                      style: Styles.headerStyle6.copyWith(
                          color: Styles.tertiaryColor),
                    ),
                  ),
                  const SizedBox(height: 30),
                  // Edit Profile Button
                  ElevatedButton(
                    onPressed: () async {
                      final user = await _userFuture;
                      if (user != null) {
                        bool? updated = await showDialog<bool>(
                          context: context,
                          builder: (context) =>
                              UpdateProfileDialog(user: user),
                        );
                        if (updated == true) {
                          setState(() {
                            _userFuture = _fetchUserProfile(); // Refresh profile data
                          });
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: Styles.primaryColor,
                      foregroundColor: Styles.tertiaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Update Profile',
                      style: Styles.headerStyle6.copyWith(
                          color: Styles.tertiaryColor),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
=======
          ? Center(child: CircularProgressIndicator(color: Styles.primaryColor))
          : MovingBackground(
              animationType: AnimationType.translation,
              backgroundColor: const Color.fromARGB(255, 248, 248, 248),
              circles: const [
                MovingCircle(
                    color: Color.fromARGB(65, 230, 132, 125), radius: 120),
                MovingCircle(
                    color: Color.fromARGB(55, 230, 132, 125), radius: 150),
                MovingCircle(
                    color: Color.fromARGB(45, 230, 132, 125), radius: 180),
                MovingCircle(
                    color: Color.fromARGB(35, 230, 132, 125), radius: 200),
              ],
              child: FutureBuilder<UserAdminModel?>(
                future: _userFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                        child: CircularProgressIndicator(
                            color: Styles.primaryColor));
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: FadeInUp(
                        duration: const Duration(milliseconds: 800),
                        child: Text(
                          'Error: ${snapshot.error}',
                          style: GoogleFonts.roboto(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    );
                  }
                  if (!snapshot.hasData) {
                    return Center(
                      child: FadeInUp(
                        duration: const Duration(milliseconds: 800),
                        child: Text(
                          'No user data available',
                          style: GoogleFonts.roboto(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    );
                  }

                  final user = snapshot.data!;

                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.only(
                      top: screenSize.height * 0.15,
                      left: screenSize.width * 0.06,
                      right: screenSize.width * 0.06,
                      bottom: screenSize.height * 0.05,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: FadeInDown(
                            duration: const Duration(milliseconds: 800),
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        Styles.primaryColor.withOpacity(0.25),
                                    spreadRadius: 2,
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: screenSize.width * 0.15,
                                backgroundImage: user.profileImageUrl != null
                                    ? NetworkImage(user.profileImageUrl!)
                                    : const AssetImage(
                                            'assets/images/default_profile.jpg')
                                        as ImageProvider,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: screenSize.height * 0.03),

                        // Profile Card
                        FadeInUp(
                          duration: const Duration(milliseconds: 900),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.2),
                                  spreadRadius: 2,
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            padding: EdgeInsets.all(screenSize.width * 0.05),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildProfileItem('Full Name',
                                    user.fullName ?? 'Not provided', context),
                                _buildDivider(),
                                _buildProfileItem('Email',
                                    user.email ?? 'Not provided', context),
                                _buildDivider(),
                                _buildProfileItem(
                                    'Phone Number',
                                    user.phoneNumber ?? 'Not provided',
                                    context),
                                _buildDivider(),
                                _buildProfileItem('Address',
                                    user.address ?? 'Not provided', context),
                                _buildDivider(),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildProfileItem('Blood Type',
                                          user.bloodType ?? 'Not set', context),
                                    ),
                                    Expanded(
                                      child: _buildProfileItem(
                                          'Role', user.role ?? 'User', context),
                                    ),
                                  ],
                                ),
                                _buildDivider(),
                                _buildProfileItem(
                                    'Account Created',
                                    DateFormat('MM/dd/yyyy')
                                        .format(user.dateCreated),
                                    context),
                              ],
                            ),
                          ),
                        ),

                        SizedBox(height: screenSize.height * 0.03),

                        // Note about blood type changes
                        FadeInUp(
                          duration: const Duration(milliseconds: 950),
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(
                              horizontal: screenSize.width * 0.04,
                              vertical: screenSize.height * 0.01,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Text(
                              'To change your blood type, contact redpulse@gmail.com',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.roboto(
                                fontSize: screenSize.width * 0.035,
                                fontStyle: FontStyle.italic,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: screenSize.height * 0.02),

                        // Buttons
                        FadeInUp(
                          duration: const Duration(milliseconds: 1000),
                          child: ElevatedButton(
                            onPressed: () async {
                              final user = await _userFuture;
                              if (user != null) {
                                bool? updated = await showDialog<bool>(
                                  context: context,
                                  builder: (context) =>
                                      UpdateProfileDialog(user: user),
                                );
                                if (updated == true) {
                                  setState(() {
                                    _userFuture =
                                        _fetchUserProfile(); // Refresh profile data
                                  });
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              minimumSize: Size(
                                  double.infinity, screenSize.height * 0.06),
                              backgroundColor: Styles.primaryColor,
                              foregroundColor: Colors.white,
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            child: Text(
                              'Update Profile',
                              style: GoogleFonts.montserrat(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: screenSize.height * 0.02),

                        FadeInUp(
                          duration: const Duration(milliseconds: 1100),
                          child: ElevatedButton(
                            onPressed: () async {
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
                                  if (mounted) {
                                    Navigator.of(context).pushAndRemoveUntil(
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const LoginScreen(),
                                      ),
                                      (route) =>
                                          false, // This removes all previous routes
                                    );
                                  }
                                } catch (e) {
                                  // Handle any errors during logout
                                  if (mounted) {
                                    Navigator.pop(
                                        context); // Remove loading dialog
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content:
                                              Text('Error signing out: $e')),
                                    );
                                  }
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              minimumSize: Size(
                                  double.infinity, screenSize.height * 0.06),
                              backgroundColor: Colors.red.shade700,
                              foregroundColor: Colors.white,
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            child: Text(
                              'Log Out',
                              style: GoogleFonts.montserrat(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }

  Widget _buildProfileItem(String label, String value, BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: screenSize.height * 0.01),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.roboto(
              fontSize: screenSize.width * 0.035,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: screenSize.height * 0.005),
          Text(
            value,
            style: GoogleFonts.montserrat(
              fontSize: screenSize.width * 0.045,
              fontWeight: FontWeight.w600,
              color: Styles.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      color: Colors.grey.withOpacity(0.3),
      thickness: 1,
    );
  }
>>>>>>> Stashed changes
}

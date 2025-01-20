import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:redpulse/features/models/users.dart';
import 'package:redpulse/features/screens/login.dart';
import 'package:redpulse/services/auth.dart';
import 'package:redpulse/utilities/constants/styles.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  Future<String?> get userId async {
    try {
      // Fetch the current authenticated user
      final User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("User is not logged in.");
      }

      // Use the user's UID to fetch the corresponding document from Firestore
      DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userSnapshot.exists) {
        throw Exception("User document not found.");
      }

      // Retrieve the userId (or other relevant field) from the document
      String? userId = userSnapshot['id'];

      if (userId == null || userId.isEmpty) {
        throw Exception("UserId not found or is empty.");
      }

      return userId; // Return the userId if found
    } catch (error) {
      print("Error fetching userId: $error");
      return null; // Return null on failure
    }
  }

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<UserAdminModel?> _userFuture;
  String? _userId; // Store the userId locally

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
        _userFuture = _fetchUserProfile(); // Fetch profile once userId is available
      });
    }
  }

  // Fetch user profile from Firestore
  Future<UserAdminModel?> _fetchUserProfile() async {
    try {
      if (_userId == null) throw Exception('User ID is null.');

      // Get user data from Firestore
      final docSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId) // Pass the userId to the query
          .get();

      if (docSnapshot.exists) {
        // If user exists, create UserAdminModel from the snapshot
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
      backgroundColor: Styles.tertiaryColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(120),
        child: AppBar(
          backgroundColor: Styles.primaryColor,
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
                        color: Styles.tertiaryColor),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: _userId == null
          ? const Center(child: CircularProgressIndicator()) // Show loading until userId is fetched
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

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Full Name:', style: Styles.headerStyle5.copyWith(fontSize: 18, color: Styles.accentColor)),  // Display blood bank name
                      Text('${user.fullName}', style: Styles.headerStyle5.copyWith(fontSize: 20, fontWeight: FontWeight.bold, color: Styles.accentColor)),
                      SizedBox(height: 15),

                      Text('Email:', style: Styles.headerStyle5.copyWith(fontSize: 18, color: Styles.accentColor)),  // Display blood bank name
                      Text('${user.email}', style: Styles.headerStyle5.copyWith(fontSize: 20, fontWeight: FontWeight.bold, color: Styles.accentColor)),
                      SizedBox(height: 15),

                      Text('Phone Number:', style: Styles.headerStyle5.copyWith(fontSize: 18, color: Styles.accentColor)),  // Display blood bank name
                      Text('${user.phoneNumber}', style: Styles.headerStyle5.copyWith(fontSize: 20, fontWeight: FontWeight.bold, color: Styles.accentColor)),
                      SizedBox(height: 15),

                      Text('Address:', style: Styles.headerStyle5.copyWith(fontSize: 18, color: Styles.accentColor)),  // Display blood bank name
                      Text('${user.address}', style: Styles.headerStyle5.copyWith(fontSize: 20, fontWeight: FontWeight.bold, color: Styles.accentColor)),
                      SizedBox(height: 15),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text('Blood Type:', style: Styles.headerStyle5.copyWith(fontSize: 18, color: Styles.accentColor)), 
                          SizedBox(width: 62),
                          Text('Role:', style: Styles.headerStyle5.copyWith(fontSize: 18, color: Styles.accentColor)), 
                        
                      ],),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text('${user.bloodType}', style: Styles.headerStyle5.copyWith(fontSize: 20, fontWeight: FontWeight.bold, color: Styles.accentColor)),
                          SizedBox(width: 135),
                          Text('${user.role}', style: Styles.headerStyle5.copyWith(fontSize: 20, fontWeight: FontWeight.bold, color: Styles.accentColor)),
                        
                      ],),
                      SizedBox(height: 15),

                      Text('Account Created:', style: Styles.headerStyle5.copyWith(fontSize: 18, color: Styles.accentColor)),  // Display blood bank name
                      Text(DateFormat('MM/dd/yyyy').format(user.dateCreated), style: Styles.headerStyle5.copyWith(fontSize: 20, fontWeight: FontWeight.bold, color: Styles.accentColor)),
                      SizedBox(height: 30),

                      /*Text('Email: ${user.email}', style: const TextStyle(fontSize: 18)),
                      const SizedBox(height: 10),
                      Text('Phone Number: ${user.phoneNumber}', style: const TextStyle(fontSize: 18)),
                      const SizedBox(height: 10),
                      Text('Address: ${user.address}', style: const TextStyle(fontSize: 18)),
                      const SizedBox(height: 10),
                      Text('Blood Type: ${user.bloodType}', style: const TextStyle(fontSize: 18)),
                      Text('Blood Type:', style: Styles.headerStyle5.copyWith(fontSize: 18, color: Styles.accentColor)),  // Display blood bank name
                      Text('${user.bloodType}', style: Styles.headerStyle5.copyWith(fontSize: 20, fontWeight: FontWeight.bold, color: Styles.accentColor)),
                      SizedBox(height: 15),
                      const SizedBox(height: 10),
                      Text('Role: ${user.role}', style: const TextStyle(fontSize: 18)),
                      const SizedBox(height: 10),
                      
                      Text(
                        'Account Created: ${DateFormat.yMMMd().format(user.dateCreated)}',
                        style: const TextStyle(fontSize: 18),
                      ),
                      const Divider(),*/

                      Positioned(
                        bottom: 20,
                        left: 20,
                        right: 60,
                        child: ElevatedButton(
                          onPressed: () async {
                          await FirebaseAuth.instance.signOut();
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoginScreen(),
                            ),
                          );
                        },
                          style: ElevatedButton.styleFrom(
                            minimumSize: Size(double.infinity, 50), // Make the button full width
                            backgroundColor: Styles.primaryColor,
                            foregroundColor: Styles.tertiaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            'Log Out',
                            style: Styles.headerStyle6.copyWith(color: Styles.tertiaryColor),
                          ),
                        ),
                      ),
                      /*ListTile(
                        title: Text(
                          "Log Out",
                          style: Styles.headerStyle3.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Styles.primaryColor),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios_outlined, size: 16),
                        onTap: () async {
                          await FirebaseAuth.instance.signOut();
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoginScreen(),
                            ),
                          );
                        },
                      ),
                      const Divider(),*/
                    ],
                  ),
                );
              },
            ),
    );
  }
}
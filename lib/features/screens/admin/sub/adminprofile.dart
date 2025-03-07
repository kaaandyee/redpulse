import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:redpulse/features/models/users.dart';
import 'package:redpulse/features/screens/login.dart';
import 'package:redpulse/services/auth.dart';
import 'package:redpulse/utilities/constants/styles.dart';

class AdminProfileScreen extends StatefulWidget {
  const AdminProfileScreen({Key? key}) : super(key: key);

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
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
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
        _userFuture = _fetchAdminProfile(); // Fetch profile once userId is available
      });
    }
  }

  // Fetch admin profile from Firestore
  Future<UserAdminModel?> _fetchAdminProfile() async {
    try {
      if (_userId == null) throw Exception('User ID is null.');

      // Get user data from Firestore
      final docSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId) // Pass the userId to the query
          .get();

      if (docSnapshot.exists) {
        var userData = docSnapshot.data();
        if (userData?['role'] == 'Admin') {
          // If user exists and role is 'Admin', create UserAdminModel from the snapshot
          return UserAdminModel.fromJson(userData!, docSnapshot.id);
        } else {
          print('User is not an admin');
          return null; // Return null if the role is not Admin
        }
      } else {
        print('User not found');
        return null;
      }
    } catch (e) {
      print('Error fetching admin profile: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Styles.tertiaryColor,
      appBar: AppBar(
            backgroundColor: Styles.primaryColor,
            leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_outlined, size: 20, color: Colors.white), onPressed: () {Navigator.pop(context);},),
            title: Text("My Account", style: Styles.headerStyle2.copyWith(fontSize: 18, fontWeight: FontWeight.bold, color: Styles.tertiaryColor,)),
            centerTitle: true,
          ),
      body: _userId == null
          ? const Center(child: CircularProgressIndicator()) // Show loading until userId is fetched
          : FutureBuilder<UserAdminModel?>(  // Use FutureBuilder to display user data
              future: _userFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: Text('No admin data available'));
                }

                final user = snapshot.data!;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Full Name:', style: Styles.headerStyle5.copyWith(fontSize: 18, color: Styles.accentColor)),
                      Text('${user.fullName}', style: Styles.headerStyle5.copyWith(fontSize: 20, fontWeight: FontWeight.bold, color: Styles.accentColor)),
                      SizedBox(height: 15),

                      Text('Email:', style: Styles.headerStyle5.copyWith(fontSize: 18, color: Styles.accentColor)),
                      Text('${user.email}', style: Styles.headerStyle5.copyWith(fontSize: 20, fontWeight: FontWeight.bold, color: Styles.accentColor)),
                      SizedBox(height: 15),

                      Text('Phone Number:', style: Styles.headerStyle5.copyWith(fontSize: 18, color: Styles.accentColor)),
                      Text('${user.phoneNumber}', style: Styles.headerStyle5.copyWith(fontSize: 20, fontWeight: FontWeight.bold, color: Styles.accentColor)),
                      SizedBox(height: 15),

                      Text('Address:', style: Styles.headerStyle5.copyWith(fontSize: 18, color: Styles.accentColor)),
                      Text('${user.address}', style: Styles.headerStyle5.copyWith(fontSize: 20, fontWeight: FontWeight.bold, color: Styles.accentColor)),
                      SizedBox(height: 15),

                      Text('Role:', style: Styles.headerStyle5.copyWith(fontSize: 18, color: Styles.accentColor)),
                      Text('${user.role}', style: Styles.headerStyle5.copyWith(fontSize: 20, fontWeight: FontWeight.bold, color: Styles.accentColor)),
                      SizedBox(height: 15),

                      Text('Account Created:', style: Styles.headerStyle5.copyWith(fontSize: 18, color: Styles.accentColor)),
                      Text(DateFormat('MM/dd/yyyy').format(user.dateCreated), style: Styles.headerStyle5.copyWith(fontSize: 20, fontWeight: FontWeight.bold, color: Styles.accentColor)),
                      SizedBox(height: 30),

                    ],
                  ),
                );
              },
            ),
    );
  }
}

import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:redpulse/features/models/bloodbank.dart';
import 'package:redpulse/features/models/users.dart';
import 'package:redpulse/features/screens/login.dart';
import 'package:redpulse/services/auth.dart';
import 'package:redpulse/utilities/constants/styles.dart';

class BloodBankProfileScreen extends StatefulWidget {
  const BloodBankProfileScreen({Key? key}) : super(key: key);

  Future<String?> get adminId async {
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

      // Retrieve the adminId (or other relevant field) from the document
      String? adminId = userSnapshot['id'];

      if (adminId == null || adminId.isEmpty) {
        throw Exception("AdminId not found or is empty.");
      }

      return adminId; // Return the adminId if found
    } catch (error) {
      print("Error fetching adminId: $error");
      return null; // Return null on failure
    }
  }

  @override
  State<BloodBankProfileScreen> createState() => _BloodBankProfileScreenState();
}

class _BloodBankProfileScreenState extends State<BloodBankProfileScreen> {
  late Future<BloodBankModel?> _bloodBankFuture;
  String? _adminId; // Store the adminId locally

  @override
  void initState() {
    super.initState();
    _initializeAdminId();
  }

  Future<void> _initializeAdminId() async {
    final adminId = await widget.adminId;
    if (adminId != null) {
      setState(() {
        _adminId = adminId;
        _bloodBankFuture = _fetchBloodBankProfile(); // Fetch profile once adminId is available
      });
    }
  }

  // Fetch the blood bank profile using adminId to find the linked blood bankId
  Future<BloodBankModel?> _fetchBloodBankProfile() async {
    try {
      if (_adminId == null) throw Exception('Admin ID is null.');

      // Get admin data from Firestore to get linked blood bankId
      final adminSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(_adminId) // Fetch admin using adminId
          .get();

      if (!adminSnapshot.exists) {
        throw Exception("Admin not found.");
      }

      String? bloodBankId = adminSnapshot['bloodBankId'];
      if (bloodBankId == null || bloodBankId.isEmpty) {
        throw Exception("BloodBankId not found for admin.");
      }

      // Now, fetch the corresponding Blood Bank data
      final bloodBankSnapshot = await FirebaseFirestore.instance
          .collection('bloodbanks') // Blood bank collection
          .doc(bloodBankId) // Using bloodBankId to get the data
          .get();

      if (bloodBankSnapshot.exists) {
        // If blood bank exists, return the blood bank data
        return BloodBankModel.fromJson(bloodBankSnapshot.data()!);
      } else {
        print('Blood Bank not found');
        return null;
      }
    } catch (e) {
      print('Error fetching blood bank profile: $e');
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
            title: Text("Blood Bank Account", style: Styles.headerStyle2.copyWith(fontSize: 18, fontWeight: FontWeight.bold, color: Styles.tertiaryColor,)),
            centerTitle: true,
          ),
      body: _adminId == null
          ? const Center(child: CircularProgressIndicator()) // Show loading until adminId is fetched
          : FutureBuilder<BloodBankModel?>(
              future: _bloodBankFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: Text('No blood bank data available'));
                }

                final bloodBank = snapshot.data!;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Blood Bank Name:', style: Styles.headerStyle5.copyWith(fontSize: 18, color: Styles.accentColor)),
                      Text('${bloodBank.bloodBankName}', style: Styles.headerStyle5.copyWith(fontSize: 20, fontWeight: FontWeight.bold, color: Styles.accentColor)),
                      SizedBox(height: 15),

                      Text('Email:', style: Styles.headerStyle5.copyWith(fontSize: 18, color: Styles.accentColor)),
                      Text('${bloodBank.email}', style: Styles.headerStyle5.copyWith(fontSize: 20, fontWeight: FontWeight.bold, color: Styles.accentColor)),
                      SizedBox(height: 15),

                      Text('Address:', style: Styles.headerStyle5.copyWith(fontSize: 18, color: Styles.accentColor)),
                      Text('${bloodBank.address}', style: Styles.headerStyle5.copyWith(fontSize: 20, fontWeight: FontWeight.bold, color: Styles.accentColor)),
                      SizedBox(height: 15),

                      Text('Contact Number:', style: Styles.headerStyle5.copyWith(fontSize: 18, color: Styles.accentColor)),
                      Text('${bloodBank.contactNumber}', style: Styles.headerStyle5.copyWith(fontSize: 20, fontWeight: FontWeight.bold, color: Styles.accentColor)),
                      SizedBox(height: 15),

                      Text('Location (Latitude, Longitude):', style: Styles.headerStyle5.copyWith(fontSize: 18, color: Styles.accentColor)),
                      Text('(${bloodBank.latitude}, ${bloodBank.longitude})', style: Styles.headerStyle5.copyWith(fontSize: 20, fontWeight: FontWeight.bold, color: Styles.accentColor)),
                      SizedBox(height: 15),

                      /*Text('Inventory ID:', style: Styles.headerStyle5.copyWith(fontSize: 18, color: Styles.accentColor)),
                      Text('${bloodBank.inventoryId ?? 'Not available'}', style: Styles.headerStyle5.copyWith(fontSize: 20, fontWeight: FontWeight.bold, color: Styles.accentColor)),
                      SizedBox(height: 15),*/
                      Text('Account Created:', style: Styles.headerStyle5.copyWith(fontSize: 18, color: Styles.accentColor)),
                      Text(DateFormat('MM/dd/yyyy').format(bloodBank.dateCreated), style: Styles.headerStyle5.copyWith(fontSize: 20, fontWeight: FontWeight.bold, color: Styles.accentColor)),
                      SizedBox(height: 30),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

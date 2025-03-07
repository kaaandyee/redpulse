import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:redpulse/features/screens/admin/inventory.dart';
import 'package:redpulse/features/screens/admin/register.dart';
import 'package:redpulse/features/screens/admin/sub/updateinventory.dart';
import 'package:redpulse/features/screens/login.dart';
import 'package:redpulse/services/auth.dart';
import 'package:redpulse/services/googleauth.dart';
import 'package:redpulse/utilities/constants/adminmap.dart';
//import 'package:redpulse/services/googleauth.dart';
import 'package:redpulse/utilities/constants/styles.dart';
import 'package:redpulse/widgets/button.dart';

class AdminHome extends StatefulWidget {
  final bool isAdminLinkedToBloodBank;
  final String bloodBankId;  // Add bloodBankId parameter

  const AdminHome({
    super.key, 
    required this.isAdminLinkedToBloodBank, 
    required this.bloodBankId,  // Add this line
  });

  @override
  AdminHomeState createState() => AdminHomeState();
}

class AdminHomeState extends State<AdminHome> {
  late String _bloodBankId;
  late Future<String> _adminFullNameFuture; // Future to store the user's full name

  @override
  void initState() {
    super.initState();
    _adminFullNameFuture = AuthMethod().getAdminName(); 
    _fetchBloodBankId();
     // Fetch the full name
  }

  // Function to fetch blood bank ID based on admin's user ID
  Future<void> _fetchBloodBankId() async {
    try {
      // Get the admin ID from the AuthMethod class
      String adminId = await AuthMethod().getAdminId();

      // Fetch the corresponding admin document from Firestore to get the bloodBankId
      DocumentSnapshot adminSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(adminId)
          .get();

      if (adminSnapshot.exists) {
        var data = adminSnapshot.data() as Map<String, dynamic>;
        String bloodBankId = data['bloodBankId'] ?? ''; // Ensure bloodBankId is fetched

        setState(() {
          _bloodBankId = bloodBankId;
        });
        print('Fetched bloodBankId: $_bloodBankId'); // Debug message
      } else {
        throw Exception("Admin document not found.");
      }
    } catch (e) {
      print("Error fetching blood bank ID: $e");
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
              ),
              elevation: 0,
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
                      Text("Saving lives, One drop at a time.", style: Styles.headerStyle3.copyWith(fontSize: 15)),
                    ],
                  ),
                ),
              ),
            ),
          ),

      body: FutureBuilder<String>(
        future: _adminFullNameFuture, // Fetch the full name here
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator()); // Show loading indicator
          } else if (snapshot.hasError || !snapshot.hasData) {
            return const Center(child: Text('Error fetching user name.'));
          } else {
            final fullName = snapshot.data!;

            return ListView(
              children: [
                    // Welcome Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 30),
                      child: Row(
                        children: [
                          Text("Welcome, $fullName!", style: Styles.headerStyle2), // Display full name
                        ],
                      ),
                    ),

                    // Link to Register Blood Bank or display message
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30),
                      child: widget.isAdminLinkedToBloodBank
                          ? Column(
                              children: [
                                ListTile(
                                  contentPadding: const EdgeInsets.only(top: 8, bottom: 8, left: 20, right: 20),
                                  tileColor: Styles.primaryColor, // Background color
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(5), // Rounded corners
                                  ),
                                  title: Text(
                                    "Update Inventory",
                                    style: Styles.headerStyle5.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                  trailing: Icon(Icons.arrow_forward_ios_outlined, size: 16, color: Styles.tertiaryColor),
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => UpdateInventory(bloodBankId: _bloodBankId,),
                                      ),
                                    );
                                    // No navigation needed since it's just a message
                                  },
                                ),
                                //const Divider(), // Add a divider after the first ListTile
                              ],
                            )
                          : Column(
                              children: [
                                ListTile(
                                  contentPadding: const EdgeInsets.only(top: 8, bottom: 8, left: 20, right: 20),
                                  tileColor: Styles.primaryColor, // Background color
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(5), // Rounded corners
                                  ),
                                  title: Text(
                                    "Register Blood Bank",
                                    style: Styles.headerStyle5.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                  trailing: Icon(Icons.arrow_forward_ios_outlined, size: 16, color: Styles.tertiaryColor),
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => const RegisterForm(),
                                      ),
                                    );
                                  },
                                ),
                                //const Divider(), // Add a divider after the second ListTile
                              ],
                            ),
                    ),


                    const SizedBox(width: 20, height: 20),

                    // Link to View Blood Bank Location
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30),
                      child: Column(
                        children: [
                          ListTile(
                            contentPadding: const EdgeInsets.only(top: 8, bottom: 8, left: 20, right: 20),
                            tileColor: Styles.primaryColor, // Background color
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5),), // Rounded corners
                            title: Text(
                              "Blood Bank Location",
                              style: Styles.headerStyle5.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                            trailing: Icon(Icons.arrow_forward_ios_outlined, size: 16, color: Styles.tertiaryColor),
                            onTap: () {
                              // Check if blood bank ID is valid before navigating
                              print('Navigating to MapScreen with bloodBankId: $_bloodBankId');
                              if (_bloodBankId.isNotEmpty) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AdminMapScreen(bloodBankId: _bloodBankId),
                                  ),
                                );
                              } else {
                                print('Error: Invalid bloodBankId.');
                              }
                            },
                          ),
                          //const Divider(), // Add a divider after the ListTile
                        ],
                      ),
                    ),


                  ],
              );
          }
        },
      ),
    );
  }
}
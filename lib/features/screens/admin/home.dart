// home.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:redpulse/features/screens/admin/register.dart';
import 'package:redpulse/features/screens/admin/sub/updateinventory.dart';
import 'package:redpulse/services/auth.dart';
import 'package:redpulse/utilities/constants/adminmap.dart';
import 'package:redpulse/utilities/constants/styles.dart';

class AdminHome extends StatefulWidget {
  final bool isAdminLinkedToBloodBank;
  final String bloodBankId;

  const AdminHome({
    super.key,
    required this.isAdminLinkedToBloodBank,
    required this.bloodBankId,
  });

  @override
  AdminHomeState createState() => AdminHomeState();
}

class AdminHomeState extends State<AdminHome> {
  late String _bloodBankId;
  late Future<String> _adminFullNameFuture;
  late Future<Map<String, dynamic>> _adminDetailsFuture;
  late Future<Map<String, dynamic>> _bloodBankDetailsFuture;

  @override
  void initState() {
    super.initState();
    _adminFullNameFuture = AuthMethod().getAdminName();
    _fetchBloodBankId();
    _adminDetailsFuture = _fetchAdminDetails();
    _bloodBankDetailsFuture = _fetchBloodBankDetails();
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
        String bloodBankId = data['bloodBankId'] ?? '';

        setState(() {
          _bloodBankId = bloodBankId;
        });
      } else {
        throw Exception("Admin document not found.");
      }
    } catch (e) {
      print("Error fetching blood bank ID: $e");
    }
  }

  // Function to fetch admin details
  Future<Map<String, dynamic>> _fetchAdminDetails() async {
    try {
      String adminId = await AuthMethod().getAdminId();
      DocumentSnapshot adminSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(adminId)
          .get();

      if (adminSnapshot.exists) {
        return adminSnapshot.data() as Map<String, dynamic>;
      } else {
        return {};
      }
    } catch (e) {
      print("Error fetching admin details: $e");
      return {};
    }
  }

  // Function to fetch blood bank details
  Future<Map<String, dynamic>> _fetchBloodBankDetails() async {
    try {
      await _fetchBloodBankId();
      if (_bloodBankId.isEmpty) {
        return {};
      }

      DocumentSnapshot bloodBankSnapshot = await FirebaseFirestore.instance
          .collection('bloodbanks')
          .doc(_bloodBankId)
          .get();

      if (bloodBankSnapshot.exists) {
        return bloodBankSnapshot.data() as Map<String, dynamic>;
      } else {
        return {};
      }
    } catch (e) {
      print("Error fetching blood bank details: $e");
      return {};
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
                  Text("Saving lives, One drop at a time.",
                      style: Styles.headerStyle3.copyWith(fontSize: 15)),
                ],
              ),
            ),
          ),
        ),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: Future.wait([
          _adminFullNameFuture,
          _adminDetailsFuture,
          _bloodBankDetailsFuture
        ]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return const Center(child: Text('No data available'));
          } else {
            final fullName = snapshot.data![0] as String;
            final adminDetails = snapshot.data![1] as Map<String, dynamic>;
            final bloodBankDetails = snapshot.data![2] as Map<String, dynamic>;

            return ListView(
              children: [
                // Welcome Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                  child: Text("Welcome, $fullName!",
                      style: Styles.headerStyle2),
                ),

                // Admin Details Card
                if (adminDetails.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                    child: Card(
                      elevation: 3,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(color: Styles.primaryColor.withOpacity(0.5), width: 1),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("Admin Details",
                                    style: Styles.headerStyle4.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Styles.primaryColor,
                                    )),
                                Icon(Icons.admin_panel_settings, color: Styles.primaryColor),
                              ],
                            ),
                            const Divider(),
                            _buildDetailRow("Name", "${adminDetails['firstName'] ?? ''} ${adminDetails['lastName'] ?? ''}"),
                            _buildDetailRow("Email", adminDetails['email'] ?? ''),
                            _buildDetailRow("Phone", adminDetails['phoneNumber'] ?? ''),
                            _buildDetailRow("Address", adminDetails['address'] ?? ''),
                          ],
                        ),
                      ),
                    ),
                  ),

                // Blood Bank Details Card - only show if admin is linked to a blood bank
                if (widget.isAdminLinkedToBloodBank && bloodBankDetails.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                    child: Card(
                      elevation: 3,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(color: Styles.primaryColor.withOpacity(0.5), width: 1),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("Blood Bank Details",
                                    style: Styles.headerStyle4.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Styles.primaryColor,
                                    )),
                                Icon(Icons.local_hospital, color: Styles.primaryColor),
                              ],
                            ),
                            const Divider(),
                            _buildDetailRow("Name", bloodBankDetails['bloodBankName'] ?? ''),
                            _buildDetailRow("Email", bloodBankDetails['email'] ?? ''),
                            _buildDetailRow("Contact", bloodBankDetails['contactNumber'] ?? ''),
                            _buildDetailRow("Address", bloodBankDetails['address'] ?? ''),
                          ],
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 20),

                // Action Buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: widget.isAdminLinkedToBloodBank
                      ? Column(
                    children: [
                      ListTile(
                        contentPadding: const EdgeInsets.only(
                            top: 8, bottom: 8, left: 20, right: 20),
                        tileColor: Styles.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        title: Text(
                          "Update Inventory",
                          style: Styles.headerStyle5.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
                        ),
                        trailing: Icon(Icons.arrow_forward_ios_outlined,
                            size: 16, color: Styles.tertiaryColor),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => UpdateInventory(
                                bloodBankId: _bloodBankId,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                    ],
                  )
                      : Column(
                    children: [
                      ListTile(
                        contentPadding: const EdgeInsets.only(
                            top: 8, bottom: 8, left: 20, right: 20),
                        tileColor: Styles.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        title: Text(
                          "Register Blood Bank",
                          style: Styles.headerStyle5.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
                        ),
                        trailing: Icon(Icons.arrow_forward_ios_outlined,
                            size: 16, color: Styles.tertiaryColor),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const RegisterForm(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),

                // Blood Bank Location Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: const EdgeInsets.only(
                            top: 8, bottom: 8, left: 20, right: 20),
                        tileColor: Styles.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        title: Text(
                          "Blood Bank Location",
                          style: Styles.headerStyle5.copyWith(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        trailing: Icon(Icons.arrow_forward_ios_outlined,
                            size: 16, color: Styles.tertiaryColor),
                        onTap: () {
                          if (_bloodBankId.isNotEmpty) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    AdminMapScreen(bloodBankId: _bloodBankId),
                              ),
                            );
                          } else {
                            // Show error message if no blood bank is linked
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("No blood bank linked to this admin account."),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                      ),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              "$label: ",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Styles.accentColor,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
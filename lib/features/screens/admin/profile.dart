import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:redpulse/features/models/bloodbank.dart';
import 'package:redpulse/features/screens/login.dart';
import 'package:redpulse/utilities/constants/styles.dart';
import 'package:redpulse/widgets/confirmLogout.dart';

class ProfileScreen extends StatefulWidget {
  final String? adminId;

  const ProfileScreen({super.key, this.adminId});

  // Renamed the getter to avoid conflict with the parameter
  Future<String?> get fetchAdminId async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("User is not logged in.");
      }

      DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userSnapshot.exists) {
        throw Exception("User document not found.");
      }

      String? adminId = userSnapshot['id'];
      if (adminId == null || adminId.isEmpty) {
        throw Exception("AdminId not found or is empty.");
      }

      return adminId;
    } catch (error) {
      print("Error fetching adminId: $error");
      return null;
    }
  }

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<BloodBankModel?> _bloodBankFuture;
  String? _adminId;
  String? _bloodBankId;

  @override
  void initState() {
    super.initState();
    _initializeAdminId();
  }

  Future<void> _initializeAdminId() async {
    final adminId = widget.adminId ?? await widget.fetchAdminId;
    if (adminId != null) {
      setState(() {
        _adminId = adminId;
        _bloodBankFuture = _fetchBloodBankProfile();
      });
    }
  }

  Future<BloodBankModel?> _fetchBloodBankProfile() async {
    try {
      if (_adminId == null) throw Exception('Admin ID is null.');

      final adminSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(_adminId)
          .get();

      if (!adminSnapshot.exists) {
        throw Exception("Admin not found.");
      }

      String? bloodBankId = adminSnapshot['bloodBankId'];
      _bloodBankId = bloodBankId; // Store for later use in updates

      if (bloodBankId == null || bloodBankId.isEmpty) {
        throw Exception("BloodBankId not found for admin.");
      }

      final bloodBankSnapshot = await FirebaseFirestore.instance
          .collection('bloodbanks')
          .doc(bloodBankId)
          .get();

      if (bloodBankSnapshot.exists) {
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

  Future<void> _updateBloodBankDetails(Map<String, dynamic> updatedData) async {
    try {
      if (_bloodBankId == null || _bloodBankId!.isEmpty) {
        throw Exception("Blood Bank ID is not available");
      }

      await FirebaseFirestore.instance
          .collection('bloodbanks')
          .doc(_bloodBankId)
          .update(updatedData);

      // Refresh blood bank data
      setState(() {
        _bloodBankFuture = _fetchBloodBankProfile();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Blood Bank details updated successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating details: $e')),
      );
    }
  }

  void _showEditDialog(BloodBankModel bloodBank) {
    final TextEditingController nameController = TextEditingController(text: bloodBank.bloodBankName);
    final TextEditingController emailController = TextEditingController(text: bloodBank.email);
    final TextEditingController addressController = TextEditingController(text: bloodBank.address);
    final TextEditingController contactController = TextEditingController(text: bloodBank.contactNumber);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
            "Edit Blood Bank Details",
            style: TextStyle(color: Styles.primaryColor, fontWeight: FontWeight.bold)
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Blood Bank Name',
                  labelStyle: TextStyle(color: Styles.accentColor),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Styles.primaryColor),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  labelStyle: TextStyle(color: Styles.accentColor),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Styles.primaryColor),
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: addressController,
                decoration: InputDecoration(
                  labelText: 'Address',
                  labelStyle: TextStyle(color: Styles.accentColor),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Styles.primaryColor),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: contactController,
                decoration: InputDecoration(
                  labelText: 'Contact Number',
                  labelStyle: TextStyle(color: Styles.accentColor),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Styles.primaryColor),
                  ),
                ),
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Styles.primaryColor,
            ),
            onPressed: () {
              Navigator.pop(context);
              _updateBloodBankDetails({
                'bloodBankName': nameController.text.trim(),
                'email': emailController.text.trim(),
                'address': addressController.text.trim(),
                'contactNumber': contactController.text.trim(),
              });
            },
            child: const Text('Save Changes', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
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
      body: _adminId == null
          ? const Center(child: CircularProgressIndicator())
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

          // Parse location coordinates
          final double latitude = bloodBank.latitude;
          final double longitude = bloodBank.longitude;
          final LatLng bloodBankLocation = LatLng(latitude, longitude);

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),

                  // Blood Bank Details Section
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(color: Styles.primaryColor.withOpacity(0.3)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Blood Bank Details",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Styles.primaryColor,
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.edit, color: Styles.primaryColor),
                                onPressed: () => _showEditDialog(bloodBank),
                              )
                            ],
                          ),
                          const Divider(),
                          _buildDetailItem('Blood Bank Name', bloodBank.bloodBankName),
                          _buildDetailItem('Email', bloodBank.email),
                          _buildDetailItem('Address', bloodBank.address),
                          _buildDetailItem('Contact Number', bloodBank.contactNumber),

                          // Location as Google Map
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Location',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Styles.accentColor,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Container(
                                  height: 200,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.grey.shade300),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: GoogleMap(
                                      initialCameraPosition: CameraPosition(
                                        target: bloodBankLocation,
                                        zoom: 15,
                                      ),
                                      markers: {
                                        Marker(
                                          markerId: const MarkerId('bloodBankLocation'),
                                          position: bloodBankLocation,
                                          infoWindow: InfoWindow(title: bloodBank.bloodBankName),
                                        ),
                                      },
                                      zoomControlsEnabled: false,
                                      myLocationButtonEnabled: false,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 5),
                              ],
                            ),
                          ),

                          _buildDetailItem('Account Created', DateFormat('MM/dd/yyyy').format(bloodBank.dateCreated)),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Log Out Section
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
                      final shouldLogout = await showDialog<bool>(
                        context: context,
                        builder: (context) => const Confirmlogout(),
                      );

                      if (shouldLogout == true) {
                        try {
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) => const Center(
                              child: CircularProgressIndicator(),
                            ),
                          );

                          final auth = FirebaseAuth.instance;
                          await auth.signOut();

                          if (context.mounted) {
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                builder: (context) => const LoginScreen(),
                              ),
                                  (route) => false,
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            Navigator.pop(context);
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
        },
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Styles.accentColor,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 5),
        ],
      ),
    );
  }
}
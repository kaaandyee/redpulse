import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:redpulse/features/models/bloodbank.dart';
import 'package:redpulse/features/screens/login.dart';
import 'package:redpulse/utilities/constants/styles.dart';
import 'package:redpulse/widgets/confirmLogout.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter_moving_background/flutter_moving_background.dart';
import 'package:flutter_moving_background/enums/animation_types.dart';
import 'package:redpulse/features/screens/wrapper/BiometricAuthService.dart';

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
        const SnackBar(
            content: Text('Blood Bank details updated successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating details: $e')),
      );
    }
  }

  void _showEditDialog(BloodBankModel bloodBank) {
    final TextEditingController nameController =
        TextEditingController(text: bloodBank.bloodBankName);
    final TextEditingController emailController =
        TextEditingController(text: bloodBank.email);
    final TextEditingController addressController =
        TextEditingController(text: bloodBank.address);
    final TextEditingController contactController =
        TextEditingController(text: bloodBank.contactNumber);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "Edit Blood Bank Details",
          style: GoogleFonts.montserrat(
            color: Styles.primaryColor,
            fontWeight: FontWeight.bold,
          ),
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
            child: Text(
              'Cancel',
              style: GoogleFonts.roboto(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Styles.primaryColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
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
            child: Text(
              'Save Changes',
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(screenSize.height * 0.07),
        child: FadeInDown(
          duration: const Duration(milliseconds: 800),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Styles.primaryColor,
                  Styles.primaryColor.withOpacity(0.95),
                ],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(25),
                bottomRight: Radius.circular(25),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.2),
                  blurRadius: 15,
                  spreadRadius: 2,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: screenSize.width * 0.06,
                  vertical: screenSize.height * 0.015,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      "Blood Bank Profile",
                      style: GoogleFonts.montserrat(
                        fontSize: screenSize.width * 0.055,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      body: _adminId == null
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
              child: FutureBuilder<BloodBankModel?>(
                future: _bloodBankFuture,
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
                          'No blood bank data available',
                          style: GoogleFonts.roboto(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    );
                  }

                  final bloodBank = snapshot.data!;

                  // Parse location coordinates
                  final double latitude = bloodBank.latitude;
                  final double longitude = bloodBank.longitude;
                  final LatLng bloodBankLocation = LatLng(latitude, longitude);

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
                        // Blood Bank Icon/Logo
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
                                backgroundColor:
                                    Styles.primaryColor.withOpacity(0.9),
                                child: Icon(
                                  Icons.local_hospital_rounded,
                                  color: Colors.white,
                                  size: screenSize.width * 0.15,
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: screenSize.height * 0.03),

                        // Blood Bank Details Card
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
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "Blood Bank Details",
                                      style: GoogleFonts.montserrat(
                                        fontSize: screenSize.width * 0.05,
                                        fontWeight: FontWeight.w700,
                                        color: Styles.primaryColor,
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.edit,
                                        color: Styles.primaryColor,
                                        size: screenSize.width * 0.06,
                                      ),
                                      onPressed: () =>
                                          _showEditDialog(bloodBank),
                                    )
                                  ],
                                ),
                                _buildDivider(),
                                _buildDetailItem('Blood Bank Name',
                                    bloodBank.bloodBankName, context),
                                _buildDivider(),
                                _buildDetailItem(
                                    'Email', bloodBank.email, context),
                                _buildDivider(),
                                _buildDetailItem(
                                    'Address', bloodBank.address, context),
                                _buildDivider(),
                                _buildDetailItem('Contact Number',
                                    bloodBank.contactNumber, context),
                                _buildDivider(),

                                // Location Map
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                      vertical: screenSize.height * 0.01),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Location',
                                        style: GoogleFonts.roboto(
                                          fontSize: screenSize.width * 0.035,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      SizedBox(
                                          height: screenSize.height * 0.01),
                                      Container(
                                        height: 200,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(15),
                                          border: Border.all(
                                              color: Colors.grey.shade300),
                                          boxShadow: [
                                            BoxShadow(
                                              color:
                                                  Colors.grey.withOpacity(0.1),
                                              spreadRadius: 1,
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(15),
                                          child: GoogleMap(
                                            initialCameraPosition:
                                                CameraPosition(
                                              target: bloodBankLocation,
                                              zoom: 15,
                                            ),
                                            markers: {
                                              Marker(
                                                markerId: const MarkerId(
                                                    'bloodBankLocation'),
                                                position: bloodBankLocation,
                                                infoWindow: InfoWindow(
                                                    title: bloodBank
                                                        .bloodBankName),
                                              ),
                                            },
                                            zoomControlsEnabled: false,
                                            myLocationButtonEnabled: false,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                _buildDivider(),
                                _buildDetailItem(
                                    'Account Created',
                                    DateFormat('MM/dd/yyyy')
                                        .format(bloodBank.dateCreated),
                                    context),
                              ],
                            ),
                          ),
                        ),

                        SizedBox(height: screenSize.height * 0.03),

                        // Log Out Button
                        FadeInUp(
                          duration: const Duration(milliseconds: 1100),
                          child: ElevatedButton(
                            onPressed: () async {
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

                                  await BiometricAuthService.clearAuthState();

                                  final auth = FirebaseAuth.instance;
                                  await auth.signOut();

                                  if (mounted) {
                                    Navigator.of(context).pushAndRemoveUntil(
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const LoginScreen(),
                                      ),
                                      (route) => false,
                                    );
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    Navigator.pop(context);
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

  Widget _buildDetailItem(String label, String value, BuildContext context) {
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
}

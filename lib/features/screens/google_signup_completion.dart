import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_moving_background/flutter_moving_background.dart';
import 'package:flutter_moving_background/enums/animation_types.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:redpulse/features/screens/user/start.dart';
import 'package:redpulse/utilities/constants/enums.dart';
import 'package:redpulse/utilities/constants/styles.dart';
import 'package:redpulse/widgets/dropdown.dart';

class GoogleSignupCompletionScreen extends StatefulWidget {
  final String uid;
  final String email;
  final String displayName;
  final String? photoURL;

  const GoogleSignupCompletionScreen({
    Key? key,
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoURL,
  }) : super(key: key);

  @override
  State<GoogleSignupCompletionScreen> createState() => _GoogleSignupCompletionScreenState();
}

class _GoogleSignupCompletionScreenState extends State<GoogleSignupCompletionScreen> {
  BloodType selectedBType = BloodType.oNegative;
  bool isLoading = false;

  Future<void> completeSignup() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Extract first and last name from display name
      List<String> nameParts = widget.displayName.split(' ');
      String firstName = nameParts.isNotEmpty ? nameParts[0] : '';
      String lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

      // Create user document in Firestore
      await FirebaseFirestore.instance.collection('users').doc(widget.uid).set({
        'email': widget.email,
        'firstName': firstName,
        'lastName': lastName,
        'fullName': widget.displayName,
        'profileImageUrl': widget.photoURL ?? '',
        'bloodType': selectedBType.name,
        'role': 'user',
        'dateCreated': DateTime.now(),
        'id': widget.uid,
        'phoneNumber': '',
        'address': '',
      });

      // Navigate to home screen
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const UserStart()),
              (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error completing signup: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      body: SafeArea(
        child: MovingBackground(
          animationType: AnimationType.translation,
          backgroundColor: const Color.fromARGB(255, 248, 248, 248),
          circles: const [
            MovingCircle(color: Color.fromARGB(65, 230, 132, 125), radius: 120),
            MovingCircle(color: Color.fromARGB(55, 230, 132, 125), radius: 150),
            MovingCircle(color: Color.fromARGB(45, 230, 132, 125), radius: 180),
            MovingCircle(color: Color.fromARGB(35, 230, 132, 125), radius: 200),
          ],
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 30),

                  // Logo
                  Image.asset('assets/images/logoo.png', height: 120, width: 120),

                  const SizedBox(height: 20),

                  // Title
                  FadeInDown(
                    duration: const Duration(milliseconds: 800),
                    child: Text(
                      "Just One More Step!",
                      style: GoogleFonts.montserrat(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: const Color.fromARGB(250, 212, 61, 61),
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  FadeInDown(
                    duration: const Duration(milliseconds: 900),
                    child: Text(
                      "Please select your blood type to complete signup",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.roboto(
                        fontSize: 16,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Profile info from Google
                  FadeInUp(
                    duration: const Duration(milliseconds: 1000),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            spreadRadius: 2,
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundImage: widget.photoURL != null
                                ? NetworkImage(widget.photoURL!)
                                : const AssetImage('assets/images/default_profile.jpg') as ImageProvider,
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.displayName,
                                  style: GoogleFonts.montserrat(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  widget.email,
                                  style: GoogleFonts.roboto(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Blood Type selection
                  FadeInUp(
                    duration: const Duration(milliseconds: 1100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 5),
                          child: Text(
                            "Select Your Blood Type",
                            style: GoogleFonts.montserrat(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Dropdown<BloodType>(
                          label: "Blood Type",
                          enumValues: BloodType.values,
                          selectedValue: selectedBType,
                          hintText: 'Select Blood Type',
                          onChanged: (BloodType type) {
                            setState(() {
                              selectedBType = type;
                            });
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 50),

                  // Complete Signup Button
                  FadeInUp(
                    duration: const Duration(milliseconds: 1200),
                    child: SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : completeSignup,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Styles.primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text(
                          "Complete Signup",
                          style: GoogleFonts.montserrat(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
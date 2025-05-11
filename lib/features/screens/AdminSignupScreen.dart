import 'package:flutter/material.dart';
import 'package:flutter_moving_background/enums/animation_types.dart';
import 'package:flutter_moving_background/flutter_moving_background.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:redpulse/features/screens/admin/register.dart';
import 'package:redpulse/services/auth.dart';
import 'package:redpulse/services/validation.dart';
import 'package:redpulse/utilities/constants/enums.dart';
import 'package:redpulse/utilities/constants/styles.dart';
import 'package:redpulse/widgets/button.dart';
import 'package:redpulse/widgets/textfield.dart';
import 'login.dart';

class AdminSignupScreen extends StatefulWidget {
  const AdminSignupScreen({super.key});

  @override
  State<AdminSignupScreen> createState() => _AdminSignupScreenState();
}

class _AdminSignupScreenState extends State<AdminSignupScreen> {
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneNumberController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;

  @override
  void dispose() {
    super.dispose();
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    phoneNumberController.dispose();
    passwordController.dispose();
    addressController.dispose();
  }

  void signupAdmin() async {
    setState(() {
      isLoading = true;
    });

    // Get values from the controllers
    String email = emailController.text.trim();
    String phoneNumber = phoneNumberController.text.trim();
    String password = passwordController.text.trim();
    String address = addressController.text.trim();
    String firstName = firstNameController.text.trim();
    String lastName = lastNameController.text.trim();

    // Show popup dialog
    void showPopup(String message) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Notice"),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("OK"),
              ),
            ],
          );
        },
      );
    }

    // Validation checks
    if (firstName.isEmpty || lastName.isEmpty || phoneNumber.isEmpty || address.isEmpty || password.isEmpty || email.isEmpty) {
      showPopup("Please fill in all fields.");
      return;
    }

    if (!isValidEmail(email)) {
      showPopup("Please enter a valid email address.");
      return;
    }

    if (!isValidPhoneNumber(phoneNumber)) {
      showPopup("Please enter a valid phone number.");
      return;
    }

    // Password validation
    if (password.length < 6) {
      showPopup("Password must be at least 6 characters long.");
      return;
    }

    try {
      // Signup admin using AuthMethod
      String res = await AuthMethod().signupUser(
        email: email,
        phoneNumber: phoneNumber,
        password: password,
        address: address,
        firstName: firstName,
        lastName: lastName,
        userRole: AppRole.admin,
        bloodType: BloodType.oNegative, // Default value, not relevant for admin
        bloodBankId: null, // Will be set after blood bank registration
      );

      if (!mounted) return;

      if (res == "success") {
        setState(() {
          isLoading = false;
        });

        // Proceed to blood bank registration with pre-filled data
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => RegisterForm(
              initialEmail: emailController.text.trim(),
              initialAddress: addressController.text.trim(),
              initialContactNumber: phoneNumberController.text.trim(),
            ),
          ),
        );
      } else {
        showPopup(res);
      }
    } catch (e) {
      // Catch any unexpected errors
      showPopup("An error occurred: ${e.toString()}");
    }
  }

  @override
  Widget build(BuildContext context) {
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        children: [
                          const SizedBox(height: 40),

                          // App Logo with Animation
                          FadeIn(
                            duration: const Duration(milliseconds: 1000),
                            child: Pulse(
                              duration: const Duration(milliseconds: 2000),
                              infinite: true,
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.red.withOpacity(0.2),
                                      spreadRadius: 5,
                                      blurRadius: 15,
                                    ),
                                  ],
                                ),
                                child: Image.asset(
                                  'assets/images/logoo.png',
                                  height: 120,
                                  width: 120,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 35),

                          // App Title
                          FadeInDown(
                            duration: const Duration(milliseconds: 800),
                            child: Column(
                              children: [
                                Text(
                                  "Blood Bank",
                                  style: GoogleFonts.montserrat(
                                    fontSize: 30,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.2,
                                    color: Styles.primaryColor,
                                    shadows: [
                                      Shadow(
                                        blurRadius: 2.0,
                                        color: Colors.black.withOpacity(0.1),
                                        offset: const Offset(1, 1),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  "Administrator",
                                  style: GoogleFonts.montserrat(
                                    fontSize: 30,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.2,
                                    color: Styles.primaryColor,
                                    shadows: [
                                      Shadow(
                                        blurRadius: 2.0,
                                        color: Colors.black.withOpacity(0.1),
                                        offset: const Offset(1, 1),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            
                          ),
                          FadeInDown(
                            duration: const Duration(milliseconds: 800),
                            child: Text(
                              "Create your administrator account",
                              style: GoogleFonts.roboto(
                                fontSize: 16,
                                color: Styles.primaryColor,
                              ),
                            ),
                          ),

                          const SizedBox(height: 35),

                          // Section heading
                         // Section title
                          FadeInDown(
                            delay: const Duration(milliseconds: 300),
                            child: Padding(
                              padding: const EdgeInsets.only(left: 35),
                              child: Align(
                                alignment: Alignment.centerLeft,
                               child: Text(
                                  "Basic Information",
                                  style: GoogleFonts.roboto(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 10),
                          // Form fields with animations
                          FadeInRight(
                            delay: const Duration(milliseconds: 500),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 15),
                              child: TextFieldInput(
                                icon: Icons.person,
                                textEditingController: firstNameController,
                                hintText: 'First Name',
                                textInputType: TextInputType.text,
                              ),
                            ),
                          ),const SizedBox(height: 10),

                          FadeInLeft(
                            delay: const Duration(milliseconds: 600),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 15),
                              child: TextFieldInput(
                                icon: Icons.person,
                                textEditingController: lastNameController,
                                hintText: 'Last Name',
                                textInputType: TextInputType.text,
                              ),
                            ),
                          ),const SizedBox(height: 10),

                          FadeInRight(
                            delay: const Duration(milliseconds: 700),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 15),
                              child: TextFieldInput(
                                icon: Icons.phone,
                                textEditingController: phoneNumberController,
                                hintText: 'Phone Number',
                                textInputType: TextInputType.phone,
                              ),
                            ),
                          ),const SizedBox(height: 10),

                          FadeInLeft(
                            delay: const Duration(milliseconds: 800),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 15),
                              child: TextFieldInput(
                                icon: Icons.home,
                                textEditingController: addressController,
                                hintText: 'Home Address',
                                textInputType: TextInputType.text,
                              ),
                            ),
                          ),const SizedBox(height: 10),

                          FadeInRight(
                            delay: const Duration(milliseconds: 900),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 15),
                              child: TextFieldInput(
                                icon: Icons.email,
                                textEditingController: emailController,
                                hintText: 'Email',
                                textInputType: TextInputType.emailAddress,
                                externalPadding: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 10),
                              ),
                            ),
                          ),const SizedBox(height: 10),

                          FadeInLeft(
                            delay: const Duration(milliseconds: 1000),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 15),
                              child: TextFieldInput(
                                icon: Icons.lock,
                                textEditingController: passwordController,
                                hintText: 'Password',
                                textInputType: TextInputType.text,
                                isPass: true,
                              ),
                            ),
                          ),


                          // Continue button
                          FadeInUp(
                            delay: const Duration(milliseconds: 1000),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                              child: isLoading
                                  ? const CircularProgressIndicator(color: Color.fromARGB(250, 212, 61, 61))
                                  : MyButtons(onTap: signupAdmin, text: "Blood Bank Registration"),
                            ),
                          ),

                          // Login link
                          //const SizedBox(height: 10),
                          FadeIn(
                            delay: const Duration(milliseconds: 1200),
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 30),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Already have an account?",
                                    style: Styles.headerStyle5.copyWith(color: Colors.grey)
                                  ),
                                  SizedBox(width: 5),
                                  GestureDetector(
                                    onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => const LoginScreen(),
                                      ),
                                    );
                                  },
                                    child: Text(
                                      "Log In",
                                      style: Styles.headerStyle5.copyWith(color: Styles.primaryColor, 
                                      fontWeight: FontWeight.w700,
                                      )
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
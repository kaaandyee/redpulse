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

        // Proceed to blood bank registration
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const RegisterForm(),
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
                          const SizedBox(height: 20),

                          // Logo - keeping as is
                          Image.asset(
                            'assets/images/logoo.png',
                            height: 120,
                            width: 120,
                          ),

                          const SizedBox(height: 15),

                          // Title with enhanced styling
                          FadeInDown(
                            duration: const Duration(milliseconds: 800),
                            child: Text(
                              "BLOOD BANK ADMINISTRATOR",
                              style: GoogleFonts.montserrat(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1,
                                color: const Color.fromARGB(250, 212, 61, 61),
                                shadows: [
                                  Shadow(
                                    blurRadius: 2.0,
                                    color: Colors.black.withOpacity(0.1),
                                    offset: const Offset(1, 1),
                                  ),
                                ],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),

                          const SizedBox(height: 10),

                          // Subtitle
                          FadeInDown(
                            delay: const Duration(milliseconds: 400),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 25),
                              child: Text(
                                "Step 1: Create your administrator account",
                                style: GoogleFonts.roboto(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[700],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),

                          const SizedBox(height: 30),

                          // Section heading
                          FadeInDown(
                            delay: const Duration(milliseconds: 500),
                            child: Padding(
                              padding: const EdgeInsets.only(left: 25),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Administrator Information',
                                  style: GoogleFonts.roboto(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[800],
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 15),

                          // Form fields with animations
                          FadeInLeft(
                            delay: const Duration(milliseconds: 600),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextFieldInput(
                                    icon: Icons.person,
                                    textEditingController: firstNameController,
                                    hintText: 'First Name',
                                    textInputType: TextInputType.text,
                                    externalPadding: const EdgeInsets.only(left: 20, right: 5, top: 0, bottom: 10),
                                  ),
                                ),
                                Expanded(
                                  child: TextFieldInput(
                                    icon: Icons.person,
                                    textEditingController: lastNameController,
                                    hintText: 'Last Name',
                                    textInputType: TextInputType.text,
                                    externalPadding: const EdgeInsets.only(left: 5, right: 20, top: 0, bottom: 10),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          FadeInRight(
                            delay: const Duration(milliseconds: 700),
                            child: TextFieldInput(
                              icon: Icons.phone,
                              textEditingController: phoneNumberController,
                              hintText: 'Phone Number',
                              textInputType: TextInputType.phone,
                            ),
                          ),

                          FadeInLeft(
                            delay: const Duration(milliseconds: 800),
                            child: TextFieldInput(
                              icon: Icons.home,
                              textEditingController: addressController,
                              hintText: 'Home Address',
                              textInputType: TextInputType.text,
                            ),
                          ),

                          FadeInRight(
                            delay: const Duration(milliseconds: 900),
                            child: TextFieldInput(
                              icon: Icons.email,
                              textEditingController: emailController,
                              hintText: 'Email',
                              textInputType: TextInputType.emailAddress,
                              externalPadding: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 10),
                            ),
                          ),

                          FadeInLeft(
                            delay: const Duration(milliseconds: 1000),
                            child: TextFieldInput(
                              icon: Icons.lock,
                              textEditingController: passwordController,
                              hintText: 'Password',
                              textInputType: TextInputType.text,
                              isPass: true,
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Divider with text
                          FadeIn(
                            delay: const Duration(milliseconds: 1100),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Row(
                                children: [
                                  Expanded(child: Divider(color: Colors.grey[400], thickness: 0.5)),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                    child: Text(
                                      "After signup, you'll register your blood bank",
                                      style: GoogleFonts.roboto(
                                        color: Colors.grey[600],
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  Expanded(child: Divider(color: Colors.grey[400], thickness: 0.5)),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 25),

                          // Continue button
                          FadeInUp(
                            delay: const Duration(milliseconds: 1200),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
                              child: isLoading
                                  ? const CircularProgressIndicator(color: Color.fromARGB(250, 212, 61, 61))
                                  : Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: MyButtons(
                                  onTap: signupAdmin,
                                  text: "Continue to Blood Bank Registration",
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 25),

                          // Login link
                          FadeIn(
                            delay: const Duration(milliseconds: 1300),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Already have an account? ",
                                  style: GoogleFonts.roboto(
                                    fontSize: 15,
                                    color: Colors.grey[700],
                                  ),
                                ),
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
                                    style: GoogleFonts.roboto(
                                      color: const Color.fromARGB(250, 212, 61, 61),
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
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
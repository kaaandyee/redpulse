import 'package:flutter/material.dart';
import 'package:flutter_moving_background/enums/animation_types.dart';
import 'package:flutter_moving_background/flutter_moving_background.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:redpulse/features/screens/admin/register.dart';
import 'package:redpulse/features/screens/admin/start.dart';
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
          backgroundColor: const Color.fromARGB(255, 219, 216, 216),
          circles: const [
            MovingCircle(color: Color.fromARGB(95, 230, 132, 125)),
            MovingCircle(color: Color.fromARGB(95, 230, 132, 125)),
            MovingCircle(color: Color.fromARGB(95, 230, 132, 125)),
            MovingCircle(color: Color.fromARGB(95, 230, 132, 125)),
          ],
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                Image.asset(
                  'assets/images/logoo.png',
                  height: 120,
                  width: 120,
                ),
                const SizedBox(height: 15),
                Text("BLOOD BANK ADMINISTRATOR",
                    style: GoogleFonts.roboto(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: const Color.fromARGB(250, 212, 61, 61)
                    )
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  child: Text(
                    "Step 1: Create your administrator account",
                    style: Styles.headerStyle5.copyWith(color: Colors.black87),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 15),

                Padding(
                  padding: const EdgeInsets.only(left: 25),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Administrator Information',
                      style: Styles.headerStyle6.copyWith(color: Styles.accentColor),
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                Row(
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
                TextFieldInput(
                    icon: Icons.phone,
                    textEditingController: phoneNumberController,
                    hintText: 'Phone Number',
                    textInputType: TextInputType.phone),
                TextFieldInput(
                    icon: Icons.home,
                    textEditingController: addressController,
                    hintText: 'Home Address',
                    textInputType: TextInputType.text),
                TextFieldInput(
                    icon: Icons.email,
                    textEditingController: emailController,
                    hintText: 'Email',
                    textInputType: TextInputType.emailAddress,
                    externalPadding: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 10)),
                TextFieldInput(
                  icon: Icons.lock,
                  textEditingController: passwordController,
                  hintText: 'Password',
                  textInputType: TextInputType.text,
                  isPass: true,
                ),

                const SizedBox(height: 10),

                // Divider with text
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(child: Divider(color: Styles.accentColor.withOpacity(0.5))),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text("After signup, you'll register your blood bank",
                            style: TextStyle(color: Styles.accentColor, fontSize: 12)
                        ),
                      ),
                      Expanded(child: Divider(color: Styles.accentColor.withOpacity(0.5))),
                    ],
                  ),
                ),

                const SizedBox(height: 15),
                MyButtons(
                    onTap: signupAdmin,
                    text: isLoading ? "Creating Account..." : "Continue to Blood Bank Registration"
                ),
                const SizedBox(height: 15),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Already have an account?", style: Styles.headerStyle5.copyWith(color: Styles.accentColor)),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                        );
                      },
                      child: Text(
                        " Log In",
                        style: Styles.headerStyle5.copyWith(color: Colors.blue),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
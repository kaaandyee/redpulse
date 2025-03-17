import 'package:flutter/material.dart';
import 'package:flutter_moving_background/enums/animation_types.dart';
import 'package:flutter_moving_background/flutter_moving_background.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:redpulse/features/screens/admin/start.dart';
import 'package:redpulse/features/screens/user/start.dart';
import 'package:redpulse/services/auth.dart';
import 'package:redpulse/services/validation.dart';
import 'package:redpulse/utilities/constants/enums.dart';
import 'package:redpulse/utilities/constants/styles.dart';
import 'package:redpulse/widgets/button.dart';
import 'package:redpulse/widgets/dropdown.dart';
import 'package:redpulse/widgets/snackbar';
import 'package:redpulse/widgets/textfield.dart';
import 'login.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneNumberController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  AppRole selectedRole = AppRole.user;  // Default role set to user
  BloodType selectedBType = BloodType.oNegative;  // Default blood type
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

  void signupUser() async {
    setState(() {
      isLoading = true;
    });

    // Get values from the controllers
    String email = emailController.text;
    String phoneNumber = phoneNumberController.text;
    String password = passwordController.text;
    String address = addressController.text;
    String firstName = firstNameController.text;
    String lastName = lastNameController.text;

    // Validation checks
    if (firstName.isEmpty || lastName.isEmpty || phoneNumber.isEmpty || address.isEmpty || password.isEmpty || email.isEmpty) {
      setState(() {
        isLoading = false;
      });
      showSnackBar(context, "Please fill in all fields.");
      return;
    }

    if (!isValidEmail(email)) {
      setState(() {
        isLoading = false;
      });
      showSnackBar(context, "Please enter a valid email address.");
      return;
    }

    if (!isValidPhoneNumber(phoneNumber)) {
      setState(() {
        isLoading = false;
      });
      showSnackBar(context, "Please enter a valid phone number.");
      return;
    }

    // Signup user using AuthMethod with user data
    String res = await AuthMethod().signupUser(
      email: email,
      phoneNumber: phoneNumber,
      password: password,
      address: address,
      firstName: firstName,
      lastName: lastName,
      userRole: selectedRole,
      bloodType: selectedBType,
      bloodBankId: selectedRole == AppRole.admin ? 'your_blood_bank_id_here' : null,  // Set bloodBankId only for admins
    );

    if (res == "success") {
      setState(() {
        isLoading = false;
      });
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => selectedRole == AppRole.admin
              ? const AdminStart(isAdminLinkedToBloodBank: false) // Modify this as needed
              : const UserStart(), // For regular users
        ),
      );
    } else {
      setState(() {
        isLoading = false;
      });
      showSnackBar(context, res);  // Show error message
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
                'assets/images/logoo.png',  // Path to your logo image
                height: 120,  // Adjust the height of the logo as needed
                width: 120,
                // Adjust the width of the logo as needed
              ),
              const SizedBox(height: 15),
              Text("SIGN UP", style: GoogleFonts.roboto(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: const Color.fromARGB(250, 212, 61, 61))),
              const SizedBox(height: 15),

            Padding(
              padding: const EdgeInsets.only(left: 25),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Basic Information',
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
                textInputType: TextInputType.text),
            TextFieldInput(
                icon: Icons.home,
                textEditingController: addressController,
                hintText: 'Home Address',
                textInputType: TextInputType.text),
            TextFieldInput(
                icon: Icons.email,
                textEditingController: emailController,
                hintText: 'Email',
                textInputType: TextInputType.text,
                externalPadding: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 10)),
            TextFieldInput(
              icon: Icons.lock,
              textEditingController: passwordController,
              hintText: 'Password',
              textInputType: TextInputType.text,
              isPass: true,
            ),

            // Role and Blood Type selection
            Row(
              children: [
                Expanded(
                  child: Dropdown<AppRole>(
                    label: "Role",
                    externalPadding: const EdgeInsets.only(top: 10, bottom: 10, left: 20, right: 5),
                    enumValues: AppRole.values,
                    selectedValue: selectedRole,
                    hintText: 'Select Role',
                    onChanged: (AppRole role) {
                      setState(() {
                        selectedRole = role;
                      });
                    },
                  ),
                ),
                Expanded(
                  child: Dropdown<BloodType>(
                    label: "Blood Type",
                    externalPadding: const EdgeInsets.only(top: 10, bottom: 10, left: 5, right: 20),
                    enumValues: BloodType.values,
                    selectedValue: selectedBType,
                    hintText: 'Select Blood Type',
                    onChanged: (BloodType type) {
                      setState(() {
                        selectedBType = type;
                      });
                    },
                  ),
                ),
              ],
            ),
            MyButtons(onTap: signupUser, text: "Sign Up"),
            const SizedBox(height: 5),
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
                )
              ],
            )
          ],
        ),
      ),
    ),
    );
  }
}
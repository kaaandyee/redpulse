import 'package:flutter/material.dart';
import 'package:redpulse/features/models/user.dart';
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
  AppRole selectedRole = AppRole.user;
  BloodType selectedBType = BloodType.oNegative;
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
    // set is loading to true.
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
    //String role = 'user'; // Assume 'user' by default, change to 'admin' if needed
    
    // If you want to set a specific role or allow the user to choose, you can add UI elements (e.g., dropdown)
    // For now, we'll assume it's a user signup, and an admin signup logic would follow a similar pattern.

    // Validate email format
  if (!isValidEmail(email)) {
    setState(() {
      isLoading = false;
    });
    showSnackBar(context, "Please enter a valid email address.");
    return;
  }

  // Validate phone number format
  if (!isValidPhoneNumber(phoneNumber)) {
    setState(() {
      isLoading = false;
    });
    showSnackBar(context, "Please enter a valid phone number.");
    return;
  }

  // Validate other fields if needed
  if (firstName.isEmpty || lastName.isEmpty || phoneNumber.isEmpty || address.isEmpty || password.isEmpty || email.isEmpty) {
    setState(() {
      isLoading = false;
    });
    showSnackBar(context, "Please fill in all fields.");
    return;
  }


    // signup user using AuthMethod with user data
    String res = await AuthMethod().signupUser(
      email: email,
      phoneNumber: phoneNumber,
      password: password,
      address: address,
      firstName: firstName,
      lastName: lastName,
      userRole: selectedRole,
      bloodType: selectedBType,
      bloodBankId: selectedRole == AppRole.admin ? 'your_blood_bank_id_here' : null, // Set bloodBankId only for admins
    );

    if (res == "success") {
      setState(() {
        isLoading = false;
      });
      if (selectedRole == AppRole.admin) {
        // Navigate to Admin homepage
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const AdminStart(), // Replace with your Admin's homepage
          ),
        );
      } else {
        // Navigate to User homepage
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const UserStart(), // Replace with your User's homepage
          ),
        );
      }
    } else {
      setState(() {
        isLoading = false;
      });
      // show error
      showSnackBar(context, res);
    }
  }

  @override
  Widget build(BuildContext context) {
    //double height = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            //SizedBox(
              //height: height / 2.8,
              //child: Image.asset('images/signup.jpeg'),
            //),
            Text("SIGN UP", style: Styles.headerStyle8),
            const SizedBox(height:30,),

            // "Basic Information" label aligned to the left
          Padding(
            padding: const EdgeInsets.only(left: 35), // Adjust padding if needed
            child: Align(
              alignment: Alignment.centerLeft, // Align the label to the left
              child: Text(
                'Basic Information', // Label text
                style: Styles.headerStyle6.copyWith(color: Styles.accentColor),
              ),
            ),
          ),
          const SizedBox(height: 5),
            // Row widget to place First and Last name in one row
          Row(
            //mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // First Name TextField
              Expanded(
                child: TextFieldInput(
                  icon: Icons.person,
                  textEditingController: firstNameController,
                  hintText: 'First Name',
                  textInputType: TextInputType.text,
                  externalPadding: const EdgeInsets.only(left: 20, right: 5, top: 0, bottom: 10),
                ),
              ),
              // Last Name TextField
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
                externalPadding: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 10),),
            TextFieldInput(
              icon: Icons.lock,
              textEditingController: passwordController,
              hintText: 'Password',
              textInputType: TextInputType.text,
              isPass: true,
            ),

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
    );
  }
}

/*
import 'package:flutter/material.dart';
import 'package:redpulse/features/screens/start.dart';
import 'package:redpulse/services/auth.dart';
import 'package:redpulse/utilities/constants/styles.dart';
import 'package:redpulse/widgets/button.dart';
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
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;

  @override
  void dispose() {
    super.dispose();
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
  }

  void signupUser() async {
    // set is loading to true.
    setState(() {
      isLoading = true;
    });
    // signup user using our authmethod
    String res = await AuthMethod().signupUser(
        email: emailController.text,
        password: passwordController.text,
        name: nameController.text);
    // if string return is success, user has been creaded and navigate to next screen other witse show error.
    if (res == "success") {
      setState(() {
        isLoading = false;
      });
      //navigate to the next screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const Start(),
        ),
      );
    } else {
      setState(() {
        isLoading = false;
      });
      // show error
      showSnackBar(context, res);
    }
  }

  @override
  Widget build(BuildContext context) {
    //double height = MediaQuery.of(context).size.height;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: SizedBox(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            //SizedBox(
              //height: height / 2.8,
              //child: Image.asset('images/signup.jpeg'),
            //),
            Text("Sign Up", style: Styles.headerStyle2),
            const SizedBox(height:30,),
            TextFieldInput(
                icon: Icons.person,
                textEditingController: nameController,
                hintText: 'Name',
                textInputType: TextInputType.text),
            TextFieldInput(
                icon: Icons.email,
                textEditingController: emailController,
                hintText: 'Email',
                textInputType: TextInputType.text),
            TextFieldInput(
              icon: Icons.lock,
              textEditingController: passwordController,
              hintText: 'Password',
              textInputType: TextInputType.text,
              isPass: true,
            ),
            MyButtons(onTap: signupUser, text: "Sign Up"),
            const SizedBox(height: 50),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Already have an account?"),
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    " Login",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                )
              ],
            )
          ],
        ),
      )),
    );
  }
}*/
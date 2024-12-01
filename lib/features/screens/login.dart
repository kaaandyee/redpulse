import 'package:flutter/material.dart';
import 'package:redpulse/features/screens/admin/start.dart';
import 'package:redpulse/features/screens/user/home.dart';
import 'package:redpulse/features/screens/user/start.dart';
import 'package:redpulse/services/auth.dart';
import 'package:redpulse/services/googleauth.dart';
import 'package:redpulse/services/password.dart';
import 'package:redpulse/services/phoneauth.dart';
import 'package:redpulse/utilities/constants/enums.dart';
import 'package:redpulse/utilities/constants/styles.dart';
import 'package:redpulse/widgets/button.dart';
import 'package:redpulse/widgets/snackbar';
import 'package:redpulse/widgets/textfield.dart';
import 'signup.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;

  @override
  void dispose() {
    super.dispose();
    emailController.dispose();
    passwordController.dispose();
  }

// email and passowrd auth part
  void loginUser() async {
  setState(() {
    isLoading = true;
  });

  // Get the email and password from the controllers
  String email = emailController.text;
  String password = passwordController.text;

  // Login user using the AuthMethod
  String res = await AuthMethod().loginUser(email: email, password: password);

  if (res == "success") {
    try {
      // Get the user role after successful login
      AppRole userRole = await AuthMethod().getUserRole(email);

      setState(() {
        isLoading = false;
      });

      // Navigate based on the user role
      if (userRole == AppRole.admin) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const AdminStart(), // Admin's homepage
          ),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const UserStart(), // User's homepage
          ),
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      // Show error if fetching user role fails
      showSnackBar(context, "Error: $e");
    }
  } else {
    setState(() {
      isLoading = false;
    });

    // Show error message if login fails
    showSnackBar(context, res);
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SizedBox(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("LOG IN", style: Styles.headerStyle8),
              const SizedBox(height:30,),
              TextFieldInput(
                icon: Icons.person,
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
            //  we call our forgot password below the login in button
            
            const ForgotPassword(),
            MyButtons(onTap: loginUser, text: "Log In"),

            /*Row(
              children: [
                Expanded(
                  child: Container(height: 1, color: Colors.black26),
                ),
                const Text("  or  "),
                Expanded(
                  child: Container(height: 1, color: Colors.black26),
                )
              ],
            ),*/

            // for google login
            /*Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
              child: ElevatedButton(
                style:
                    ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey, alignment: Alignment.center),
                onPressed: () async {
                  await FirebaseServices().signInWithGoogle();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const UserHome(),
                    ),
                  );
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Image.network(
                        "https://ouch-cdn2.icons8.com/VGHyfDgzIiyEwg3RIll1nYupfj653vnEPRLr0AeoJ8g/rs:fit:456:456/czM6Ly9pY29uczgu/b3VjaC1wcm9kLmFz/c2V0cy9wbmcvODg2/LzRjNzU2YThjLTQx/MjgtNGZlZS04MDNl/LTAwMTM0YzEwOTMy/Ny5wbmc.png",
                        height: 20,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "Continue with Google",
                      style: Styles.headerStyle6.copyWith(color: Styles.tertiaryColor),
                    )
                  ],
                ),
              ),
            ),*/
           // for phone authentication 
           //const PhoneAuthentication(),
            // Don't have an account? got to signup screen
            Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Don't have an account? ", style: Styles.headerStyle5.copyWith(color: Styles.accentColor)),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const SignupScreen(),
                        ),
                      );
                    },
                    child: Text(
                      "Sign Up",
                      style: Styles.headerStyle5.copyWith(color: Colors.blue),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      )),
    );
  }

  Container socialIcon(image) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 32,
        vertical: 15,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFedf0f8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.black45,
          width: 2,
        ),
      ),
      child: Image.network(
        image,
        height: 40,
      ),
    );
  }
}
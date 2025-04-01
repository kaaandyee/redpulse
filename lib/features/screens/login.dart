import 'package:flutter/material.dart';
import 'package:redpulse/features/screens/user/start.dart';
import 'package:redpulse/services/auth.dart';
import 'package:redpulse/services/googleauth.dart';
import 'package:redpulse/services/password.dart';
import 'package:redpulse/utilities/constants/styles.dart';
import 'package:redpulse/widgets/button.dart';
import 'package:redpulse/widgets/snackbar';
import 'package:redpulse/widgets/textfield.dart';
import 'signup.dart';

import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_moving_background/flutter_moving_background.dart';
import 'package:flutter_moving_background/enums/animation_types.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;

  @override
  void dispose() {
    super.dispose();
    emailController.dispose();
    passwordController.dispose();
  }

  void loginUser() async {
    setState(() {
      isLoading = true;
    });

    String email = emailController.text;
    String password = passwordController.text;

    String res = await AuthMethod().loginUser(
      email: email,
      password: password,
      context: context,
    );

    if (res == "success") {
      setState(() {
        isLoading = false;
      });
      // Perform post-login actions like navigating to the respective home page.
    } else {
      setState(() {
        isLoading = false;
      });
      showSnackBar(context, res); // Show error if login fails
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                reverse: true, // Push content up when keyboard appears
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
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/images/splash_logo.png',
                            height: 100,
                            width: 100,
                          ),
                          const SizedBox(height: 18),
                          Text(
                            "LOG IN",
                            style: GoogleFonts.roboto(
                              fontSize: 35,
                              fontWeight: FontWeight.w700,
                              color: const Color.fromARGB(250, 212, 61, 61),
                            ),
                          ),
                          const SizedBox(height: 35),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              children: [
                                TextFieldInput(
                                  icon: Icons.person,
                                  textEditingController: emailController,
                                  hintText: 'Email',
                                  textInputType: TextInputType.emailAddress,
                                ),
                                const SizedBox(height: 15),
                                TextFieldInput(
                                  icon: Icons.lock,
                                  textEditingController: passwordController,
                                  hintText: 'Password',
                                  textInputType: TextInputType.text,
                                  isPass: true,
                                ),
                              ],
                            ),
                          ),
                          const ForgotPassword(),
                          Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: MyButtons(onTap: loginUser, text: "Log In"),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "or",
                            style: Styles.headerStyle5
                                .copyWith(color: Styles.accentColor),
                          ),
                          const SizedBox(height: 10),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 25),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red[700],
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: () async {
                                try {
                                  await FirebaseServices().signInWithGoogle();
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const UserStart(),
                                    ),
                                  );
                                } catch (e) {
                                  // Handle sign-in errors here
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(
                                            "Google sign-in failed. Please try again.")),
                                  );
                                }
                              },
                              child: FittedBox(
                                // Prevents content from overflowing
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 8),
                                      child: Image.network(
                                        "https://ouch-cdn2.icons8.com/VGHyfDgzIiyEwg3RIll1nYupfj653vnEPRLr0AeoJ8g/rs:fit:456:456/czM6Ly9pY29uczgu/b3VjaC1wcm9kLmFz/c2V0cy9wbmcvODg2/LzRjNzU2YThjLTQx/MjgtNGZlZS04MDNl/LTAwMTM0YzEwOTMy/Ny5wbmc.png",
                                        height: 20,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                        const Icon(
                                          Icons
                                              .error, // Fallback icon if image fails
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      "Continue with Google",
                                      style: Styles.headerStyle6.copyWith(
                                          color: Styles.tertiaryColor),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Padding(
                            padding: const EdgeInsets.only(top: 5),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Don't have an account? ",
                                  style: Styles.headerStyle5
                                      .copyWith(color: Styles.accentColor),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) =>
                                        const SignupScreen(),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    "Sign Up",
                                    style: Styles.headerStyle5.copyWith(
                                        color: Colors.blue,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(
                              height:
                              20), // Extra padding to prevent bottom overflow
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

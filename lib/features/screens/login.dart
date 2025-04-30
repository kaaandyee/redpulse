import 'package:flutter/material.dart';
import 'package:redpulse/features/screens/user/start.dart';
import 'package:redpulse/services/auth.dart';
import 'package:redpulse/services/googleauth.dart';
import 'package:redpulse/services/password.dart';
import 'package:redpulse/utilities/constants/styles.dart';
import 'package:redpulse/widgets/button.dart';
import 'package:redpulse/widgets/snackbar';
import 'package:redpulse/widgets/textfield.dart';
import '../../utilities/flowTransition.dart';
import 'signup.dart';

import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_moving_background/flutter_moving_background.dart';
import 'package:flutter_moving_background/enums/animation_types.dart';
import 'package:lottie/lottie.dart';
import 'package:animate_do/animate_do.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
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
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const UserStart(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOut;
            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            return SlideTransition(position: animation.drive(tween), child: child);
          },
        ),
      );
    } else {
      setState(() {
        isLoading = false;
      });
      showSnackBar(context, res);
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
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 30),

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
                                  'assets/images/splash_logo.png',
                                  height: 120,
                                  width: 120,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 15),

                          // App Title
                          FadeInDown(
                            duration: const Duration(milliseconds: 800),
                            child: Text(
                              "RedPulse",
                              style: GoogleFonts.montserrat(
                                fontSize: 32,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                                color: const Color.fromARGB(250, 212, 61, 61),
                                shadows: [
                                  Shadow(
                                    blurRadius: 2.0,
                                    color: Colors.black.withOpacity(0.1),
                                    offset: const Offset(1, 1),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 50),

                          // Login Title
                          FadeInDown(
                            delay: const Duration(milliseconds: 400),
                            child: Text(
                              "Welcome Back",
                              style: GoogleFonts.roboto(
                                fontSize: 26,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[800],
                              ),
                            ),
                          ),

                          const SizedBox(height: 10),

                          FadeInDown(
                            delay: const Duration(milliseconds: 500),
                            child: Text(
                              "Sign in to continue",
                              style: GoogleFonts.roboto(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),

                          const SizedBox(height: 40),

                          // Login Fields
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 25),
                            child: Column(
                              children: [
                                FadeInLeft(
                                  delay: const Duration(milliseconds: 600),
                                  child: TextFieldInput(
                                    icon: Icons.email,
                                    textEditingController: emailController,
                                    hintText: 'Email',
                                    textInputType: TextInputType.emailAddress,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                FadeInRight(
                                  delay: const Duration(milliseconds: 700),
                                  child: TextFieldInput(
                                    icon: Icons.lock,
                                    textEditingController: passwordController,
                                    hintText: 'Password',
                                    textInputType: TextInputType.text,
                                    isPass: true,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          FadeInUp(
                            delay: const Duration(milliseconds: 800),
                            child: const ForgotPassword(),
                          ),

                          const SizedBox(height: 10),

                          // Login Button
                          FadeInUp(
                            delay: const Duration(milliseconds: 900),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
                              child: isLoading
                                  ? const CircularProgressIndicator(color: Color.fromARGB(250, 212, 61, 61))
                                  : Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(15),
                                  // boxShadow removed to eliminate the red glow
                                ),
                                child: MyButtons(onTap: loginUser, text: "Log In"),
                              ),
                            ),
                          ),

                          const SizedBox(height: 25),

                          FadeIn(
                            delay: const Duration(milliseconds: 1000),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Divider(
                                    color: Colors.grey[400],
                                    thickness: 0.5,
                                    indent: 50,
                                    endIndent: 15,
                                  ),
                                ),
                                Text(
                                  "OR",
                                  style: GoogleFonts.roboto(
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Expanded(
                                  child: Divider(
                                    color: Colors.grey[400],
                                    thickness: 0.5,
                                    indent: 15,
                                    endIndent: 50,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 25),

                          // Google Login Button
                          FadeInUp(
                            delay: const Duration(milliseconds: 1100),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 25),
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.black87,
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 15),
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
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text("Google sign-in failed. Please try again."),
                                      ),
                                    );
                                  }
                                },
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Image.asset(
                                      'assets/images/google_logo.png',
                                      height: 24,
                                      errorBuilder: (context, error, stackTrace) => const Icon(
                                        Icons.g_mobiledata,
                                        color: Colors.red,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      "Continue with Google",
                                      style: GoogleFonts.roboto(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 30),

                          // Sign Up Link
                          FadeIn(
                            delay: const Duration(milliseconds: 1200),
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 30),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Don't have an account? ",
                                    style: GoogleFonts.roboto(
                                      fontSize: 15,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.of(context).push(
                                        Flow3DPageRoute(page: const SignupScreen()),
                                      );
                                    },
                                    child: Text(
                                      "Sign Up",
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
                          ),
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
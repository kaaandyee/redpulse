import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:redpulse/features/screens/wrapper/BiometricAuthService.dart';
import 'package:redpulse/features/screens/wrapper/wrapper.dart';
import 'package:redpulse/utilities/constants/styles.dart';

class BiometricAuthScreen extends StatefulWidget {
  const BiometricAuthScreen({super.key});

  @override
  State<BiometricAuthScreen> createState() => _BiometricAuthScreenState();
}

class _BiometricAuthScreenState extends State<BiometricAuthScreen> {
  bool _isAuthenticating = false;
  bool _biometricsAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    final biometricsAvailable =
        await BiometricAuthService.isBiometricAvailable();

    if (mounted) {
      setState(() {
        _biometricsAvailable = biometricsAvailable;
      });

      if (_biometricsAvailable) {
        _authenticate();
      } else {
        // If biometrics not available, proceed anyway
        _navigateToWrapper();
      }
    }
  }

  Future<void> _authenticate() async {
    if (_isAuthenticating) return;

    setState(() {
      _isAuthenticating = true;
    });

    final authenticated =
        await BiometricAuthService.authenticateWithBiometrics();

    if (mounted) {
      setState(() {
        _isAuthenticating = false;
      });

      if (authenticated) {
        _navigateToWrapper();
      }
    }
  }

  void _navigateToWrapper() {
    Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const Wrapper()));
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 1),

              // Logo or app icon
              Icon(
                Icons.fingerprint,
                size: 100,
                color: Styles.primaryColor,
              ),

              const SizedBox(height: 24),

              Text(
                "Welcome Back to RedPulse",
                style: GoogleFonts.montserrat(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Styles.primaryColor,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              Text(
                "Please authenticate to continue",
                style: GoogleFonts.roboto(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),

              const Spacer(flex: 1),

              ElevatedButton.icon(
                onPressed: _isAuthenticating ? null : _authenticate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Styles.primaryColor,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.fingerprint),
                label: _isAuthenticating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ))
                    : const Text("Authenticate",
                        style: TextStyle(fontSize: 16)),
              ),

              const SizedBox(height: 16),

              TextButton(
                onPressed: () {
                  BiometricAuthService.clearAuthState();
                  _navigateToWrapper();
                },
                child: const Text("Skip for now (logout)"),
              ),

              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }
}

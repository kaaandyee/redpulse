//import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:redpulse/features/screens/admin/register.dart';
import 'package:redpulse/features/screens/login.dart';
import 'package:redpulse/services/googleauth.dart';
//import 'package:redpulse/services/googleauth.dart';
import 'package:redpulse/utilities/constants/styles.dart';
import 'package:redpulse/widgets/button.dart';
//import 'package:redpulse/widgets/button.dart';
//import 'login.dart';

class AdminHome extends StatefulWidget {
  final bool isAdminLinkedToBloodBank;

  const AdminHome({super.key, required this.isAdminLinkedToBloodBank});

  @override
  AdminHomeState createState() => AdminHomeState();
}

class AdminHomeState extends State<AdminHome> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Styles.tertiaryColor,
      body: ListView(
        children: [
          Column(
            children: [
              // Header
              Container(
                height: 150,
                color: Styles.primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 50),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("RED PULSE", style: Styles.headerStyle1),
                        Text("Saving lives, One drop at a time.", style: Styles.headerStyle3),
                      ],
                    ),
                  ],
                ),
              ),

              // Welcome Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 30),
                child: Row(
                  children: [
                    Text("Welcome, Admin!", style: Styles.headerStyle2),
                  ],
                ),
              ),

              // Conditional UI
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: widget.isAdminLinkedToBloodBank
                    ? const Text(
                        "You are already linked to a blood bank.",
                        style: TextStyle(color: Colors.red, fontSize: 16),
                      )
                    : MyButtons(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const RegisterForm(),
                            ),
                          );
                        },
                        text: "Register Blood Bank",
                      ),
              ),
              MyButtons(
                onTap: () async {
                  await FirebaseServices().googleSignOut();
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                  );
                },
                text: "Log Out",
              ),
            ],
          ),
        ],
      ),
    );
  }
}
//import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:redpulse/features/screens/login.dart';
import 'package:redpulse/features/screens/user/reservation.dart';
import 'package:redpulse/services/auth.dart';
import 'package:redpulse/services/googleauth.dart';
//import 'package:redpulse/services/googleauth.dart';
import 'package:redpulse/utilities/constants/styles.dart';
import 'package:redpulse/widgets/button.dart';
//import 'package:redpulse/widgets/button.dart';
//import 'login.dart';

class UserHome extends StatefulWidget {
  const UserHome({super.key});

  @override
  UserHomeState createState() => UserHomeState();
}

class UserHomeState extends State<UserHome> {
  late Future<String> _userFullNameFuture; 

  @override
  void initState() {
    super.initState();
    _userFullNameFuture = AuthMethod().getUserName(); // Load the first name when the widget is initialized
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Styles.tertiaryColor,
      appBar: PreferredSize(
            preferredSize: const Size.fromHeight(120),
            child: AppBar(
              backgroundColor: Styles.primaryColor,
              elevation: 0,
              flexibleSpace: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 50),
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      Text("RED PULSE", style: Styles.headerStyle1),
                      Text("Saving lives, One drop at a time.", style: Styles.headerStyle3.copyWith(fontSize: 15)),
                    ],
                  ),
                ),
              ),
            ),
          ),
      body: FutureBuilder<String>(
        future: _userFullNameFuture, // Fetch the full name here
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator()); // Show loading indicator
          } else if (snapshot.hasError || !snapshot.hasData) {
            return const Center(child: Text('Error fetching user name.'));
          } else {
            final fullName = snapshot.data!; // User's full name
            return ListView(
            children: [
                Column(
                  children: [
                    // Welcome Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 30),
                      child: Row(
                        children: [
                          Text("Welcome, $fullName!", style: Styles.headerStyle2), // Display full name
                        ],
                      ),
                    ),
                ],
              ),
            ],
          );
          }
        }
      )
    );
  }
}
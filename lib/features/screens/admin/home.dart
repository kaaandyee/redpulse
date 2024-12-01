//import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:redpulse/features/screens/login.dart';
import 'package:redpulse/services/googleauth.dart';
//import 'package:redpulse/services/googleauth.dart';
import 'package:redpulse/utilities/constants/styles.dart';
import 'package:redpulse/widgets/button.dart';
//import 'package:redpulse/widgets/button.dart';
//import 'login.dart';

class AdminHome extends StatelessWidget {
  const AdminHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Styles.tertiaryColor,
      body: ListView(
        children: [
          Container(
            child: Column(
              children: [
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal:50, vertical: 30),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [Text("Welcome, Admin!", style: Styles.headerStyle2),],
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
                text: "Log Out"),
              ]
            ),
          )
        ],
      ),
    );
  }
      /*body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Congratulation\nYou have successfully Login",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
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
                text: "Log Out"),
            // for google sign in ouser detail
            // Image.network("${FirebaseAuth.instance.currentUser!.photoURL}"),
            // Text("${FirebaseAuth.instance.currentUser!.email}"),
            // Text("${FirebaseAuth.instance.currentUser!.displayName}")
          ],
        ),
      ),
    );
  }
}*/

}
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:redpulse/features/screens/admin/home.dart';
import 'package:redpulse/features/screens/admin/inventory.dart';
import 'package:redpulse/features/screens/admin/profile.dart';
import 'package:redpulse/features/screens/admin/reservation.dart';
import 'package:redpulse/features/screens/user/home.dart';
import 'package:redpulse/features/screens/user/search.dart';
import 'package:redpulse/services/auth.dart';
import 'package:redpulse/utilities/constants/styles.dart';

/*class ABottomBar extends StatefulWidget {
  const ABottomBar({super.key});
  @override
  State<ABottomBar> createState() => _ABottomBarState();
}

class _ABottomBarState extends State<ABottomBar> {
  int _selectedIndex = 0;
  static final List<Widget>_widgetOptions =<Widget>[
    const AdminHome(),
    const Text("Reservation"),
    const Text("Inventory"),
    const Text("Profile")
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Center(
          child: _widgetOptions[_selectedIndex],
        ),
        bottomNavigationBar: BottomNavigationBar(
          backgroundColor: Styles.tertiaryColor,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          elevation: 10,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          selectedItemColor: const Color(0xFFB8001F),
          type: BottomNavigationBarType.fixed,
          unselectedItemColor: Colors.black,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined, size: 30), label:"Home"),
            BottomNavigationBarItem(icon: Icon(Icons.ballot_outlined, size: 30), label:"Reservation"),
            BottomNavigationBarItem(icon: Icon(Icons.bloodtype_outlined, size: 30), label:"Inventory"),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded, size: 30), label:"Profile")
          ],
        )
    );
  }
}*/

class ABottomBar extends StatefulWidget {
  final bool isAdminLinkedToBloodBank;

  const ABottomBar({super.key, required this.isAdminLinkedToBloodBank});
  
  Future<String?> get bloodBankId async {
    try {
      // Fetch the current authenticated user
      final User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("Admin is not logged in.");
      }

      // Use the user's UID to fetch the corresponding document from Firestore
      DocumentSnapshot adminSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!adminSnapshot.exists) {
        throw Exception("Admin document not found.");
      }

      // Check if the bloodBankId field exists in the document
      String? bloodBankId = adminSnapshot['bloodBankId'];

      if (bloodBankId == null || bloodBankId.isEmpty) {
        throw Exception("Admin is not linked to a blood bank.");
      }

      return bloodBankId; // Return the bloodBankId if found
    } catch (error) {
      print("Error fetching bloodBankId: $error");
      return null; // Return null on failure
    }
  }

  @override
  State<ABottomBar> createState() => _ABottomBarState();
}

class _ABottomBarState extends State<ABottomBar> {
  int _selectedIndex = 0;

  // This method dynamically creates the widget options based on isAdminLinkedToBloodBank
  // Create a list of widgets for each navigation tab
  List<Widget> _getWidgetOptions(String? bloodBankId) {
    return [
      AdminHome(isAdminLinkedToBloodBank: widget.isAdminLinkedToBloodBank, bloodBankId: '',), // Home screen
      //const ReservationScreen(),
      //const Text("Reservation"), // Reservation screen
      AdminReservationScreen(bloodBankId: bloodBankId ?? "null"),
      Inventory(bloodBankId: bloodBankId ?? "null"), // Inventory screen
      const ProfileScreen(), // Profile screen
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: widget.bloodBankId, // Fetch the bloodBankId asynchronously
      builder: (context, snapshot) {
        String? bloodBankId;

        if (snapshot.hasData) {
          bloodBankId = snapshot.data; // Use the fetched data
        } else {
          // Set default bloodBankId if data is not available
          bloodBankId = "null";
        }

        // List of options based on selectedIndex
        List<Widget> _widgetOptions = _getWidgetOptions(bloodBankId);

        return Scaffold(
          backgroundColor: Colors.white,
          body: Center(
            child: _widgetOptions[_selectedIndex], // Display selected option
          ),
          bottomNavigationBar: BottomNavigationBar(
            backgroundColor: Styles.tertiaryColor,
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            elevation: 10,
            showSelectedLabels: false,
            showUnselectedLabels: false,
            selectedItemColor: const Color(0xFFB8001F),
            type: BottomNavigationBarType.fixed,
            unselectedItemColor: Colors.black,
            items: const [
              BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined, size: 30), label: "Home"),
              BottomNavigationBarItem(
                  icon: Icon(Icons.ballot_outlined, size: 30), label: "Reservation"),
              BottomNavigationBarItem(
                  icon: Icon(Icons.bloodtype_outlined, size: 30), label: "Inventory"),
              BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline_rounded, size: 30), label: "Profile"),
            ],
          ),
        );
      },
    );
  }
}



import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:redpulse/features/screens/admin/home.dart';
import 'package:redpulse/features/screens/admin/inventory.dart';
import 'package:redpulse/features/screens/admin/profile.dart';
import 'package:redpulse/features/screens/admin/reservation.dart';
import 'package:redpulse/utilities/constants/styles.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';

class ABottomBar extends StatefulWidget {
  final bool isAdminLinkedToBloodBank;

  const ABottomBar({super.key, required this.isAdminLinkedToBloodBank});

  Future<String?> get bloodBankId async {
    try {
      // Fetch the current authenticated user.
      final User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("Admin is not logged in.");
      }

      // Retrieve the admin document from Firestore.
      DocumentSnapshot adminSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!adminSnapshot.exists) {
        throw Exception("Admin document not found.");
      }

      // Check and retrieve the bloodBankId.
      String? bloodBankId = adminSnapshot['bloodBankId'];
      if (bloodBankId == null || bloodBankId.isEmpty) {
        throw Exception("Admin is not linked to a blood bank.");
      }
      return bloodBankId;
    } catch (error) {
      print("Error fetching bloodBankId: $error");
      return null;
    }
  }

  @override
  State<ABottomBar> createState() => _ABottomBarState();
}

class _ABottomBarState extends State<ABottomBar> {
  int _selectedIndex = 0;
  final GlobalKey<CurvedNavigationBarState> _bottomNavigationKey = GlobalKey();
  final List<int> _navigationHistory = [0];

  /// Dynamically creates the widget options based on the provided bloodBankId.
  List<Widget> _getWidgetOptions(String? bloodBankId) {
    return [
      AdminHome(
        isAdminLinkedToBloodBank: widget.isAdminLinkedToBloodBank,
        bloodBankId: '', // Pass an empty string or default value if needed.
      ),
      AdminReservationScreen(bloodBankId: bloodBankId ?? "null"),
      Inventory(bloodBankId: bloodBankId ?? "null"),
      const ProfileScreen(),
    ];
  }

  /// Updates the selected tab and records the change in the navigation history.
  void _onItemTapped(int index) {
    if (index != _selectedIndex) {
      setState(() {
        _selectedIndex = index;
        _navigationHistory.add(index);
      });
    }
  }

  /// Intercepts the back button press.
  Future<bool> _onWillPop() async {
    if (_navigationHistory.length > 1) {
      setState(() {
        _navigationHistory.removeLast();
        _selectedIndex = _navigationHistory.last;
      });
      return false; // Handled internally.
    }
    return true; // No more history; allow default back button behavior.
  }

  /// Helper widget to wrap icons so they remain upright after rotation.
  Widget _rotatedIcon(IconData iconData) {
    return RotatedBox(
      quarterTurns: 3, // Rotate back counter-clockwise by 270°.
      child: Icon(
        iconData,
        size: 30,
        color: Colors.white,
      ),
    );
  }

  /// Builds the left (vertical) floating navigation bar for wide screens.
  Widget _buildLeftNavBar() {
    return Container(
      width: 80, // Fixed width for the vertical nav bar.
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 25,
            offset: Offset(0, 4),
          )
        ],
      ),
      child: RotatedBox(
        quarterTurns: 1, // Rotate the nav bar 90° clockwise.
        child: CurvedNavigationBar(
          index: _selectedIndex,
          height: 65.0, // Interpreted as the nav bar's width when rotated.
          items: <Widget>[
            _rotatedIcon(Icons.home_outlined),
            _rotatedIcon(Icons.ballot_outlined),
            _rotatedIcon(Icons.bloodtype_outlined),
            _rotatedIcon(Icons.person_outline_rounded),
          ],
          color: Styles.primaryColor,
          buttonBackgroundColor: const Color(0xFFB8001F),
          backgroundColor: Colors.transparent,
          animationCurve: Curves.easeInOut,
          animationDuration: const Duration(milliseconds: 600),
          onTap: _onItemTapped,
          letIndexChange: (index) => true,
        ),
      ),
    );
  }

  /// Builds the bottom navigation bar for narrow screens.
  Widget _buildBottomNavBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 25,
            offset: Offset(0, 4),
          )
        ],
      ),
      child: CurvedNavigationBar(
        key: _bottomNavigationKey,
        index: _selectedIndex,
        height: 65.0,
        items: const <Widget>[
          Icon(Icons.home_outlined, size: 30, color: Colors.white),
          Icon(Icons.ballot_outlined, size: 30, color: Colors.white),
          Icon(Icons.bloodtype_outlined, size: 30, color: Colors.white),
          Icon(Icons.person_outline_rounded, size: 30, color: Colors.white),
        ],
        color: Styles.primaryColor,
        buttonBackgroundColor: const Color(0xFFB8001F),
        backgroundColor: Colors.transparent,
        animationCurve: Curves.easeInOut,
        animationDuration: const Duration(milliseconds: 600),
        onTap: _onItemTapped,
        letIndexChange: (index) => true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: widget.bloodBankId, // Asynchronously fetch the bloodBankId.
      builder: (context, snapshot) {
        // Use the fetched bloodBankId or a default value.
        String? bloodBankId = snapshot.hasData ? snapshot.data : "null";
        // Create the list of widget options based on the bloodBankId.
        List<Widget> _widgetOptions = _getWidgetOptions(bloodBankId);

        return WillPopScope(
          onWillPop: _onWillPop,
          child: LayoutBuilder(
            builder: (context, constraints) {
              bool isWide = constraints.maxWidth >= 800;

              return Scaffold(
                body: Stack(
                  children: [
                    // Main content area with left padding for wide screens.
                    Padding(
                      padding: EdgeInsets.only(left: isWide ? 96 : 0),
                      child: IndexedStack(
                        index: _selectedIndex,
                        children: _widgetOptions,
                      ),
                    ),
                    // Left navigation bar for wide screens.
                    if (isWide)
                      Positioned(
                        left: 5,
                        top: 16,
                        bottom: 16,
                        child: _buildLeftNavBar(),
                      ),
                  ],
                ),
                // Bottom navigation bar for narrow screens.
                bottomNavigationBar: isWide ? null : _buildBottomNavBar(),
              );
            },
          ),
        );
      },
    );
  }
}

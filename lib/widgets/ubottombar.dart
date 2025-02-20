import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:redpulse/features/screens/user/home.dart';
import 'package:redpulse/features/screens/user/profile.dart';
import 'package:redpulse/features/screens/user/reservation.dart';
import 'package:redpulse/features/screens/user/search.dart';
import 'package:redpulse/utilities/constants/styles.dart';

class UBottomBar extends StatefulWidget {
  const UBottomBar({Key? key}) : super(key: key);

  @override
  State<UBottomBar> createState() => _UBottomBarState();
}

class _UBottomBarState extends State<UBottomBar> {
  int _selectedIndex = 0;
  final List<int> _navigationHistory = [0];

  // Each page is provided with a unique PageStorageKey.
  final List<Widget> _widgetOptions = [
    const UserHome(key: PageStorageKey('UserHome')),
    const SearchScreen(key: PageStorageKey('SearchScreen')),
    const ReservationScreen(key: PageStorageKey('ReservationScreen')),
    const ProfileScreen(key: PageStorageKey('ProfileScreen')),
  ];

  void _onItemTapped(int index) {
    if (index != _selectedIndex) {
      setState(() {
        _selectedIndex = index;
        _navigationHistory.add(index);
      });
    }
  }

  Future<bool> _onWillPop() async {
    if (_navigationHistory.length > 1) {
      setState(() {
        _navigationHistory.removeLast();
        _selectedIndex = _navigationHistory.last;
      });
      return false;
    }
    return true;
  }

  // Helper widget to wrap icons so that they remain upright after rotation.
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

  /// Build the left (vertical) floating navigation bar.
  Widget _buildLeftNavBar() {
    return Container(
      // Set a fixed width for the left nav bar.
      // Remove external margins to avoid shifting it right.
      // Instead, we let Positioned handle its location.
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
          height: 65.0, // This becomes the nav bar’s width when rotated.
          items: <Widget>[
            _rotatedIcon(Icons.home_outlined),
            _rotatedIcon(Icons.search_rounded),
            _rotatedIcon(Icons.monitor_heart_outlined),
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

  /// Build the bottom navigation bar for narrow screens.
  Widget _buildBottomNavBar() {
    return Container(
      margin: const EdgeInsets.all(10),
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
        index: _selectedIndex,
        height: 65.0,
        items: const <Widget>[
          Icon(Icons.home_outlined, size: 30, color: Colors.white),
          Icon(Icons.search_rounded, size: 30, color: Colors.white),
          Icon(Icons.monitor_heart_outlined, size: 30, color: Colors.white),
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
    return WillPopScope(
      onWillPop: _onWillPop,
      child: LayoutBuilder(
        builder: (context, constraints) {
          bool isWide = constraints.maxWidth >= 800;

          return Scaffold(
            body: Stack(
              children: [
                // Main content area.
                // Increase left padding to account for the nav bar (80 + extra spacing).
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
                    // Position it flush to the left with some vertical spacing.
                    left: 5,
                    top: 16,
                    bottom: 16,
                    child: _buildLeftNavBar(),
                  ),
              ],
            ),
            // For narrow screens, use the bottom navigation bar.
            bottomNavigationBar: isWide ? null : _buildBottomNavBar(),
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:redpulse/features/screens/admin/home.dart';
import 'package:redpulse/features/screens/user/home.dart';
import 'package:redpulse/features/screens/user/search.dart';
import 'package:redpulse/utilities/constants/styles.dart';

class ABottomBar extends StatefulWidget {
  const ABottomBar({super.key});
  @override
  State<ABottomBar> createState() => _ABottomBarState();
}

class _ABottomBarState extends State<ABottomBar> {
  int _selectedIndex = 0;
  static final List<Widget>_widgetOptions =<Widget>[
    const AdminHome(),
    const SearchScreen(),
    const Text("Activity"),
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
            BottomNavigationBarItem(icon: Icon(Icons.search_rounded, size: 30), label:"Search"),
            BottomNavigationBarItem(icon: Icon(Icons.monitor_heart_outlined, size: 30), label:"Activity"),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded, size: 30), label:"Profile")
          ],
        )
    );
  }
}
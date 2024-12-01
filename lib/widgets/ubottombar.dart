import 'package:flutter/material.dart';
import 'package:redpulse/features/screens/user/home.dart';
import 'package:redpulse/features/screens/user/search.dart';
import 'package:redpulse/utilities/constants/styles.dart';

class UBottomBar extends StatefulWidget {
  const UBottomBar({super.key});
  @override
  State<UBottomBar> createState() => _UBottomBarState();
}

class _UBottomBarState extends State<UBottomBar> {
  int _selectedIndex = 0;
  static final List<Widget>_widgetOptions =<Widget>[
    const UserHome(),
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
      backgroundColor: Colors.white,
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
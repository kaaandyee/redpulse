import 'package:flutter/material.dart';
import 'package:redpulse/utilities/constants/styles.dart';
import 'package:redpulse/widgets/ubottombar.dart';

class UserStart extends StatelessWidget {
  const UserStart({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'RED PULSE',
        theme: ThemeData(
          primaryColor: Styles.primaryColor,
        ),
        home: const UBottomBar(),
    );
  }
}

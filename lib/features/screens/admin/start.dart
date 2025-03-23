import 'package:flutter/material.dart';
import 'package:redpulse/utilities/constants/styles.dart';
import 'package:redpulse/widgets/abottombar.dart';

class AdminStart extends StatelessWidget {
  final bool isAdminLinkedToBloodBank;

  const AdminStart({super.key, required this.isAdminLinkedToBloodBank});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'RED PULSE',
      theme: ThemeData(primaryColor: Styles.primaryColor),
      home: ABottomBar(isAdminLinkedToBloodBank: isAdminLinkedToBloodBank),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:redpulse/utilities/constants/styles.dart';
import 'package:redpulse/widgets/abottombar.dart';
import 'package:redpulse/widgets/ubottombar.dart';


class AdminStart extends StatelessWidget {
  final bool isAdminLinkedToBloodBank;

  const AdminStart({Key? key, required this.isAdminLinkedToBloodBank}) : super(key: key);

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



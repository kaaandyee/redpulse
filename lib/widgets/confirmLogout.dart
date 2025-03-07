import 'package:flutter/material.dart';

class Confirmlogout extends StatefulWidget {
  const Confirmlogout({Key? key}) : super(key: key);

  @override
  State<Confirmlogout> createState() => _ConfirmlogoutState();
}

class _ConfirmlogoutState extends State<Confirmlogout> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Confirm Logout"),
      content: const Text("Are you sure you want to logout?"),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false), // Return false when canceled
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true), // Return true when confirmed
          child: const Text("Logout"),
        ),
      ],
    );
  }
}

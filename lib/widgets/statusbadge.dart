import 'package:flutter/material.dart';
import 'package:redpulse/utilities/constants/styles.dart';

class StatusBadge extends StatelessWidget {
  final String status;

  StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color badgeColor;
    String statusText;

    switch (status) {
      case 'Low Stock':
        badgeColor = const Color.fromARGB(255, 174, 119, 37);
        statusText = '  Low Stock ';
        break;
      case 'Out of Stock':
        badgeColor = Styles.primaryColor;
        statusText = 'Out of Stock';
        break;
      default:
        badgeColor = const Color.fromARGB(255, 45, 122, 48);
        statusText = '   Available  ';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        statusText,
        style: Styles.headerStyle5.copyWith(fontSize: 12, color: Styles.tertiaryColor),
      ),
    );
  }
}

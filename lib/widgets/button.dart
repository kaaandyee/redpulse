import 'package:flutter/material.dart';
import 'package:redpulse/utilities/constants/styles.dart';

class MyButtons extends StatelessWidget {
  final VoidCallback onTap;
  final String text;
  const MyButtons({
    super.key,
    required this.onTap,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(right: 20, left: 20, top: 20, bottom: 10),
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: ShapeDecoration(
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(
                  Radius.circular(10),
                ),
              ),
              color: Styles.primaryColor),
          child: Text(
            text,
            style: Styles.headerStyle6.copyWith(color: Styles.tertiaryColor),
          ),
        ),
      ),
    );
  }
}
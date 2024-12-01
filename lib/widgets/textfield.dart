import 'package:flutter/material.dart';
import 'package:redpulse/utilities/constants/styles.dart';

class TextFieldInput extends StatelessWidget {
  final TextEditingController textEditingController;
  final bool isPass;
  final String hintText;
  final IconData? icon;
  final TextInputType textInputType;
  final EdgeInsets? externalPadding;
  //final EdgeInsetsGeometry contentPadding;

  const TextFieldInput({
    super.key,
    required this.textEditingController,
    this.isPass = false,
    required this.hintText,
    this.icon,
    required this.textInputType,
    this.externalPadding,
  });

  @override
  Widget build(BuildContext context) {
    // Default padding
    const defaultPadding = EdgeInsets.only(top: 10, bottom: 10, left: 20, right: 20);
    
    // Merge default padding with external padding
    final mergedPadding = EdgeInsets.only(
      top: externalPadding?.top ?? defaultPadding.top,
      bottom: externalPadding?.bottom ?? defaultPadding.bottom,
      left: externalPadding?.left ?? defaultPadding.left,
      right: externalPadding?.right ?? defaultPadding.right,
    );

    return Padding(
      padding: mergedPadding,
      child: TextField(
        style: Styles.headerStyle5.copyWith(color: Styles.accentColor),
        controller: textEditingController,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.black54),
          hintText: hintText,
          hintStyle: Styles.headerStyle5,
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: BorderRadius.circular(10),
          ),
          border: InputBorder.none,
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.grey),
            borderRadius: BorderRadius.circular(10),
          ),
          filled: true,
          fillColor: const Color.fromARGB(255, 238, 238, 238),
        ),
        keyboardType: textInputType,
        obscureText: isPass,
      ),
    );
  }
}
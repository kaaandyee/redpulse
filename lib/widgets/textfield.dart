import 'package:flutter/material.dart';
import 'package:redpulse/utilities/constants/styles.dart';

class TextFieldInput extends StatelessWidget {
  final TextEditingController textEditingController;
  final bool isPass;
  final String hintText;
  final IconData? icon;
  final TextInputType textInputType;
  final EdgeInsets? externalPadding;
  final bool isFilled; // ✅ New parameter to control fill behavior

  const TextFieldInput({
    super.key,
    required this.textEditingController,
    this.isPass = false,
    required this.hintText,
    this.icon,
    required this.textInputType,
    this.externalPadding,
    this.isFilled = true, // ✅ Default to true (changeable when used)
  });

  @override
  Widget build(BuildContext context) {
    // Default padding
    const defaultPadding = EdgeInsets.symmetric(
        horizontal: 20, vertical: 3); // Reduced vertical padding

    // Merge default padding with external padding
    final mergedPadding = externalPadding ?? defaultPadding;

    return Padding(
      padding: mergedPadding,
      child: SizedBox(
        height: 45, // ✅ Controls the height of the input field
        child: TextField(
          style: Styles.headerStyle5.copyWith(
              color: Styles.accentColor, fontSize: 14), // Smaller font
          controller: textEditingController,
          cursorColor: Colors.black,
          decoration: InputDecoration(
            prefixIcon: icon != null
                ? Icon(icon, color: Colors.black54, size: 20) // ✅ Smaller icon
                : null,
            hintText: hintText,
            hintStyle: Styles.headerStyle5
                .copyWith(fontSize: 16), // ✅ Smaller font size
            filled: isFilled, // ✅ Controlled by the new parameter
            fillColor: isFilled
                ? Colors.grey[200]
                : Colors.transparent, // ✅ Background color toggled
            enabledBorder: OutlineInputBorder(
              borderSide: isFilled
                  ? BorderSide.none
                  : const BorderSide(
                      color: Colors.grey), // ✅ Adjust border when not filled
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(
                vertical: 5, horizontal: 10), // ✅ Reduced inner spacing
          ),
          keyboardType: textInputType,
          obscureText: isPass,
        ),
      ),
    );
  }
}

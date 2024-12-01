import 'package:flutter/material.dart';
import 'package:redpulse/utilities/constants/styles.dart';
import 'package:redpulse/utilities/helpers.dart';

class Dropdown<T> extends StatefulWidget {
  final List<T> enumValues;
  final T selectedValue;
  final Function(T) onChanged;
  final String hintText;
  final String label; // Label for the dropdown
  final EdgeInsets externalPadding; // Padding for the outer container
  final double height; // Height of the dropdown
  final double width; // Width of the dropdown

  const Dropdown({
    super.key,
    required this.enumValues,
    required this.selectedValue,
    required this.onChanged,
    required this.hintText,
    required this.label,
    this.externalPadding = const EdgeInsets.only(top: 10, bottom: 10, left: 20, right: 20), // Default padding
    this.height = 50, // Default height
    this.width = double.infinity, // Default width takes the full space
  });

  @override
  State<Dropdown<T>> createState() => DropdownState<T>();
}

class DropdownState<T> extends State<Dropdown<T>> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: widget.externalPadding, // Using the externalPadding property
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // Align the label to the left
        
        children: [
          // Label for the dropdown
          Padding(padding: const EdgeInsets.only(left: 15),
          // Move the label a bit to the right
            child: Text(
              widget.label,
              style: Styles.headerStyle6.copyWith(color: Styles.accentColor) // Style the label
            ),
          ),
          
          const SizedBox(height: 5), // Space between label and dropdown
          
          // Container to control the size of the dropdown
          Container(
            width: widget.width, // Set width based on the widget property
            height: widget.height, // Set height for dropdown container
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 238, 238, 238), // Background color
              borderRadius: BorderRadius.circular(10), // Rounded corners
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15), // Content padding
              child: DropdownButton<T>(
                value: widget.selectedValue,
                items: widget.enumValues.map((T value) {
                  final label = (value as dynamic).label;
                  return DropdownMenuItem<T>(
                    value: value,
                    child: Text(
                      label,
                      style: Styles.headerStyle5.copyWith(color: Styles.accentColor), // Enum to string
                    ),
                  );
                }).toList(),
                onChanged: (T? newValue) {
                  if (newValue != null) {
                    widget.onChanged(newValue);
                  }
                },
                hint: Text(widget.hintText, style: Styles.headerStyle5.copyWith(color: Styles.accentColor)),
                isExpanded: true, // Makes dropdown full width
                icon: const Icon(Icons.arrow_drop_down),
                iconSize: 30,
                dropdownColor: Colors.white,
                elevation: 3,
                style: Styles.headerStyle5.copyWith(color: Styles.accentColor), // Apply same style for selected value
              ),
            ),
          ),
        ],
      ),
    );
  }
}






/*import 'package:flutter/material.dart';
import 'package:redpulse/utilities/constants/styles.dart';
import 'package:redpulse/utilities/helpers.dart';

class Dropdown<T> extends StatefulWidget {
  final List<T> enumValues;
  final T selectedValue;
  final Function(T) onChanged;
  final String hintText;

  const Dropdown({
    super.key,
    required this.enumValues,
    required this.selectedValue,
    required this.onChanged,
    required this.hintText,
  });

  @override
  State<Dropdown<T>> createState() => DropdownState<T>();
}

class DropdownState<T> extends State<Dropdown<T>> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 238, 238, 238), // Background color similar to TextField
          borderRadius: BorderRadius.circular(10), // Rounded corners
          //border: Border.all(color: Colors.grey), // Border color
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15), // Content padding

          child: DropdownButton<T>(
          value: widget.selectedValue,
          items: widget.enumValues.map((T value) {
            final label = (value as dynamic).label;
            return DropdownMenuItem<T>(
              value: value,
              child: Text(label, style: Styles.headerStyle5.copyWith(color: Styles.accentColor)), // Convert enum to string
            );
          }).toList(),
          onChanged: (T? newValue) {
          if (newValue != null) {
            widget.onChanged(newValue);
          }
          },
          hint: Text(widget.hintText, style: Styles.headerStyle5.copyWith(color: Styles.accentColor)),
        
          isExpanded: true, // Makes dropdown full width
          icon: const Icon(Icons.arrow_drop_down),
          iconSize: 30,
          dropdownColor: Colors.white,
          elevation: 3,
          style: Styles.headerStyle5.copyWith(color: Styles.accentColor), // Apply the same style for selected value
          ),
        )
      
    ),
    );
  }
}*/
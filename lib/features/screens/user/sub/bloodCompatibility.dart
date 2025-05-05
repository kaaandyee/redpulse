import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:redpulse/utilities/constants/styles.dart';

class BloodCompatibilityCard extends StatefulWidget {
  const BloodCompatibilityCard({super.key});

  @override
  State<BloodCompatibilityCard> createState() => _BloodCompatibilityCardState();
}

class _BloodCompatibilityCardState extends State<BloodCompatibilityCard> {
  String? selectedBloodType;
  bool showCompatibility = false;

  final Map<String, Map<String, List<String>>> compatibilityData = {
    'A+': {
      'canDonateTo': ['A+', 'AB+'],
      'canReceiveFrom': ['A+', 'A-', 'O+', 'O-'],
      'description': ['A+ is one of the most common blood types'],
    },
    'A-': {
      'canDonateTo': ['A+', 'A-', 'AB+', 'AB-'],
      'canReceiveFrom': ['A-', 'O-'],
      'description': ['A- can donate to both A and AB blood types'],
    },
    'B+': {
      'canDonateTo': ['B+', 'AB+'],
      'canReceiveFrom': ['B+', 'B-', 'O+', 'O-'],
      'description': ['B+ is less common than A+ or O+'],
    },
    'B-': {
      'canDonateTo': ['B+', 'B-', 'AB+', 'AB-'],
      'canReceiveFrom': ['B-', 'O-'],
      'description': ['B- is one of the rarer blood types'],
    },
    'AB+': {
      'canDonateTo': ['AB+'],
      'canReceiveFrom': ['All Types'],
      'description': ['AB+ is the universal recipient'],
    },
    'AB-': {
      'canDonateTo': ['AB+', 'AB-'],
      'canReceiveFrom': ['AB-', 'A-', 'B-', 'O-'],
      'description': ['AB- is the rarest blood type'],
    },
    'O+': {
      'canDonateTo': ['O+', 'A+', 'B+', 'AB+'],
      'canReceiveFrom': ['O+', 'O-'],
      'description': ['O+ is the most common blood type'],
    },
    'O-': {
      'canDonateTo': ['All Types'],
      'canReceiveFrom': ['O-'],
      'description': ['O- is the universal donor'],
    },
  };

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(  // Wrap the content in SingleChildScrollView
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.bloodtype, color: Styles.primaryColor),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      'Blood Compatibility Checker',
                      style: GoogleFonts.robotoMono(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Styles.primaryColor,
                      ),
                      softWrap: true, // Allows wrapping if there’s not enough space
                    ),
                  ),
                ],
              ),


              const SizedBox(height: 20),

              // Blood Type Selection
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Select Your Blood Type',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  prefixIcon: const Icon(Icons.arrow_drop_down_circle),
                ),
                value: selectedBloodType,
                items: const [
                  DropdownMenuItem(value: 'A+', child: Text('A+')),
                  DropdownMenuItem(value: 'A-', child: Text('A-')),
                  DropdownMenuItem(value: 'B+', child: Text('B+')),
                  DropdownMenuItem(value: 'B-', child: Text('B-')),
                  DropdownMenuItem(value: 'AB+', child: Text('AB+')),
                  DropdownMenuItem(value: 'AB-', child: Text('AB-')),
                  DropdownMenuItem(value: 'O+', child: Text('O+')),
                  DropdownMenuItem(value: 'O-', child: Text('O-')),
                ],
                onChanged: (value) {
                  setState(() {
                    selectedBloodType = value;
                    showCompatibility = true;
                  });
                },
              ),
              const SizedBox(height: 20),

              // Compatibility Results
              if (showCompatibility && selectedBloodType != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Blood Type Description
                    Text(
                      compatibilityData[selectedBloodType]!['description']!.join(', '),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Can Donate To Section
                    _buildCompatibilitySection(
                      title: 'You Can Donate To',
                      types: compatibilityData[selectedBloodType]!['canDonateTo']!,
                      icon: Icons.arrow_circle_up,
                      color: Colors.red.shade700,
                    ),
                    const SizedBox(height: 20),

                    // Can Receive From Section
                    _buildCompatibilitySection(
                      title: 'You Can Receive From',
                      types: compatibilityData[selectedBloodType]!['canReceiveFrom']!,
                      icon: Icons.arrow_circle_down,
                      color: Colors.green.shade700,
                    ),

                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 10),
                    const Text(
                      'Note: Compatibility may vary in rare cases. Always consult with medical professionals.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                )
              else
                Center(
                  child: Text(
                    'Select your blood type to see compatibility',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompatibilitySection({
    required String title,
    required List<String> types,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: types.map((type) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Text(
                type,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:redpulse/features/models/blood_group_model.dart';
import 'package:redpulse/utilities/constants/styles.dart';

class BloodGroupDetailsScreen extends StatelessWidget {
  final BloodGroup bloodGroup;

  const BloodGroupDetailsScreen({super.key, required this.bloodGroup});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Styles.primaryColor,
        title: Text(
          '${bloodGroup.group} Blood Type',
          style: GoogleFonts.robotoMono(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Hero(
              tag: 'blood-image-${bloodGroup.group}',
              child: Image.network(
                bloodGroup.imageUrl,
                width: double.infinity,
                height: 300,
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Compatibility Information',
                    style: GoogleFonts.robotoMono(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    bloodGroup.description,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 30),
                  _buildDonationTips(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDonationTips() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Donation Tips',
          style: GoogleFonts.robotoMono(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          '• Drink plenty of water before donating\n'
              '• Eat iron-rich foods\n'
              '• Get a good night\'s sleep\n'
              '• Bring your ID when donating',
          style: TextStyle(fontSize: 16, height: 1.5),
        ),
      ],
    );
  }
}
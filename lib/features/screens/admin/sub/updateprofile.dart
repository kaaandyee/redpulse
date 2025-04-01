import 'package:flutter/material.dart';
import 'package:redpulse/features/models/bloodbank.dart';
import 'package:redpulse/services/firestore.dart';

class UpdateProfileScreen extends StatefulWidget {
  final String bloodBankId;
  final BloodBankModel bloodBank;

  const UpdateProfileScreen({
    super.key,
    required this.bloodBankId,
    required this.bloodBank,
  });

  @override
  _UpdateProfileScreenState createState() => _UpdateProfileScreenState();
}

class _UpdateProfileScreenState extends State<UpdateProfileScreen> {
  late TextEditingController _bloodBankNameController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _contactNumberController;
  late TextEditingController _latitudeController;
  late TextEditingController _longitudeController;

  @override
  void initState() {
    super.initState();
    _bloodBankNameController =
        TextEditingController(text: widget.bloodBank.bloodBankName);
    _emailController = TextEditingController(text: widget.bloodBank.email);
    _addressController = TextEditingController(text: widget.bloodBank.address);
    _contactNumberController =
        TextEditingController(text: widget.bloodBank.contactNumber);
    _latitudeController =
        TextEditingController(text: widget.bloodBank.latitude.toString());
    _longitudeController =
        TextEditingController(text: widget.bloodBank.longitude.toString());
  }

  @override
  void dispose() {
    _bloodBankNameController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _contactNumberController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    // Validate latitude and longitude fields
    if (_latitudeController.text.isEmpty || _longitudeController.text.isEmpty) {
      _showErrorDialog('Latitude and Longitude cannot be empty');
      return;
    }

    double? latitude = double.tryParse(_latitudeController.text);
    double? longitude = double.tryParse(_longitudeController.text);

    if (latitude == null || longitude == null) {
      _showErrorDialog('Please enter valid latitude and longitude');
      return;
    }

    try {
      // Create a new BloodBankModel with updated data
      final updatedBloodBank = widget.bloodBank.copyWith(
        bloodBankName: _bloodBankNameController.text,
        email: _emailController.text,
        address: _addressController.text,
        contactNumber: _contactNumberController.text,
        latitude: latitude,
        longitude: longitude,
      );

      // Assuming FirestoreService.updateBloodBankInfo updates the Firestore data
      await FirestoreService.updateBloodBankInfo(
          widget.bloodBankId, updatedBloodBank);

      // Return updated BloodBankModel
      Navigator.pop(context, updatedBloodBank);
    } catch (e) {
      // Handle any errors during update
      _showErrorDialog('Error updating profile: $e');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Update Blood Bank Profile"),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _bloodBankNameController,
              decoration: const InputDecoration(labelText: 'Blood Bank Name'),
            ),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(labelText: 'Address'),
            ),
            TextField(
              controller: _contactNumberController,
              decoration: const InputDecoration(labelText: 'Contact Number'),
            ),
            TextField(
              controller: _latitudeController,
              decoration: const InputDecoration(labelText: 'Latitude'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _longitudeController,
              decoration: const InputDecoration(labelText: 'Longitude'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _updateProfile,
              child: const Text('Update Profile'),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:redpulse/features/models/bloodbank.dart';
import 'package:redpulse/services/firestore.dart';

class UpdateProfileScreen extends StatefulWidget {
  final String bloodBankId;
  final BloodBankModel bloodBank;

  const UpdateProfileScreen({Key? key, required this.bloodBankId, required this.bloodBank}) : super(key: key);

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
    _bloodBankNameController = TextEditingController(text: widget.bloodBank.bloodBankName);
    _emailController = TextEditingController(text: widget.bloodBank.email);
    _addressController = TextEditingController(text: widget.bloodBank.address);
    _contactNumberController = TextEditingController(text: widget.bloodBank.contactNumber);
    _latitudeController = TextEditingController(text: widget.bloodBank.latitude.toString());
    _longitudeController = TextEditingController(text: widget.bloodBank.longitude.toString());
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
    // Create a new BloodBankModel with updated data
    final updatedBloodBank = widget.bloodBank.copyWith(
      bloodBankName: _bloodBankNameController.text,
      email: _emailController.text,
      address: _addressController.text,
      contactNumber: _contactNumberController.text,
      latitude: double.parse(_latitudeController.text),
      longitude: double.parse(_longitudeController.text),
    );

    // Assuming FirestoreService.updateBloodBankInfo updates the Firestore data
    await FirestoreService.updateBloodBankInfo(widget.bloodBankId, updatedBloodBank);

    // Return updated BloodBankModel
    Navigator.pop(context, updatedBloodBank);
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

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:redpulse/features/models/users.dart';

class UpdateProfileScreen extends StatefulWidget {
  final UserAdminModel user;

  const UpdateProfileScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<UpdateProfileScreen> createState() => _UpdateProfileScreenState();
}

class _UpdateProfileScreenState extends State<UpdateProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _firstName, _lastName, _phoneNumber, _address;

  @override
  void initState() {
    super.initState();
    _firstName = widget.user.firstName;
    _lastName = widget.user.lastName;
    _phoneNumber = widget.user.phoneNumber;
    _address = widget.user.address;
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.id)
          .update({
        'firstName': _firstName,
        'lastName': _lastName,
        'phoneNumber': _phoneNumber,
        'address': _address,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
      Navigator.pop(context, true); // Return true to indicate profile was updated.
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Update Profile'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                initialValue: _firstName,
                decoration: const InputDecoration(labelText: 'First Name'),
                onSaved: (value) => _firstName = value!,
                validator: (value) => value == null || value.isEmpty ? 'Enter first name' : null,
              ),
              TextFormField(
                initialValue: _lastName,
                decoration: const InputDecoration(labelText: 'Last Name'),
                onSaved: (value) => _lastName = value!,
                validator: (value) => value == null || value.isEmpty ? 'Enter last name' : null,
              ),
              TextFormField(
                initialValue: _phoneNumber,
                decoration: const InputDecoration(labelText: 'Phone Number'),
                onSaved: (value) => _phoneNumber = value!,
                validator: (value) => value == null || value.isEmpty ? 'Enter phone number' : null,
              ),
              TextFormField(
                initialValue: _address,
                decoration: const InputDecoration(labelText: 'Address'),
                onSaved: (value) => _address = value!,
                validator: (value) => value == null || value.isEmpty ? 'Enter address' : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _updateProfile,
                child: const Text('Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}



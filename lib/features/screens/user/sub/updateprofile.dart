import 'dart:io';
// Import this to work with Uint8List.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as path;
import '../../../../main.dart'; // Ensure this file exports scaffoldMessengerKey.
import 'package:redpulse/features/models/users.dart';
import 'package:flutter/foundation.dart';

class UpdateProfileDialog extends StatefulWidget {
  final UserAdminModel user;

  const UpdateProfileDialog({super.key, required this.user});

  @override
  _UpdateProfileDialogState createState() => _UpdateProfileDialogState();
}

class _UpdateProfileDialogState extends State<UpdateProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  late String _firstName, _lastName, _phoneNumber, _address;
  bool _isUpdated = false;
  bool _isLoading = false;
  String? _profileImageUrl;

  @override
  @override
  void initState() {
    super.initState();
    // Use existing firstName and lastName if available
    if (widget.user.firstName != null && widget.user.lastName != null) {
      _firstName = widget.user.firstName!;
      _lastName = widget.user.lastName!;
    } else {
      // Fallback to splitting fullName
      final names = widget.user.fullName.split(' ');
      _firstName = names.isNotEmpty ? names.first : '';
      _lastName = names.length > 1 ? names.sublist(1).join(' ') : '';
    }
    _phoneNumber = widget.user.phoneNumber;
    _address = widget.user.address;
    _profileImageUrl = widget.user.profileImageUrl;
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 800, // Add reasonable constraints
        maxHeight: 800,
        imageQuality: 80, // Built-in quality reduction
      );

      if (pickedFile == null) return;

      setState(() {
        _isLoading = true;
      });

      // Get image data based on platform
      Uint8List imageData;
      if (kIsWeb) {
        imageData = await pickedFile.readAsBytes();
        print("Web image size: ${imageData.length} bytes");
      } else {
        final File file = File(pickedFile.path);
        imageData = await file.readAsBytes();

        // Simple compression for large files
        if (imageData.length > 500 * 1024) {
          imageData = await FlutterImageCompress.compressWithList(
            imageData,
            quality: 70,
            format: CompressFormat.jpeg,
          );
          print("Compressed image size: ${imageData.length} bytes");
        }
      }

      // Generate a unique filename
      final String fileName = '${widget.user.id}_${DateTime.now().millisecondsSinceEpoch}';
      final Reference storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_images/$fileName.jpg');

      print("Uploading to: ${storageRef.fullPath}");

      // Upload the image
      final UploadTask uploadTask = storageRef.putData(
        imageData,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      // Monitor upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        print('Upload progress: ${snapshot.bytesTransferred}/${snapshot.totalBytes}');
      });

      // Wait for upload to complete
      final TaskSnapshot snapshot = await uploadTask;
      final String newUrl = await snapshot.ref.getDownloadURL();

      print("Upload successful. URL: $newUrl");

      // Update Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.id)
          .update({'profileImageUrl': newUrl});

      print("Firestore updated successfully");

      setState(() {
        _profileImageUrl = newUrl;
        _isUpdated = true;
        _isLoading = false;
      });

      // Show success message
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile picture updated successfully')),
      );
    } catch (e) {
      print("Error in _pickImage: $e");
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile picture: $e')),
      );
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    try {
      final fullName = '$_firstName $_lastName'.trim();
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.id)
          .update({
        'firstName': _firstName,
        'lastName': _lastName,
        'fullName': fullName,
        'phoneNumber': _phoneNumber,
        'address': _address,
      });

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(content: Text('Error updating profile: $e')),
        );
      });
      Navigator.of(context).pop(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Update Profile'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Profile Image and other form fields.
              GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: _profileImageUrl != null &&
                          _profileImageUrl!.isNotEmpty
                          ? NetworkImage(_profileImageUrl!)
                          : null,
                      child: (_profileImageUrl == null ||
                          _profileImageUrl!.isEmpty)
                          ? const Icon(Icons.person, size: 40)
                          : null,
                    ),
                    if (_isLoading)
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(
                            valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              TextButton(
                onPressed: _pickImage,
                child: const Text('Change Profile Picture'),
              ),
              // First Name Field.
              TextFormField(
                initialValue: _firstName,
                decoration: const InputDecoration(labelText: 'First Name'),
                onSaved: (value) => _firstName = value!,
                validator: (value) =>
                value == null || value.isEmpty ? 'Enter first name' : null,
              ),
              // Last Name Field.
              TextFormField(
                initialValue: _lastName,
                decoration: const InputDecoration(labelText: 'Last Name'),
                onSaved: (value) => _lastName = value!,
                validator: (value) =>
                value == null || value.isEmpty ? 'Enter last name' : null,
              ),
              // Phone Number Field.
              TextFormField(
                initialValue: _phoneNumber,
                decoration: const InputDecoration(labelText: 'Phone Number'),
                onSaved: (value) => _phoneNumber = value!,
                validator: (value) => value == null || value.isEmpty
                    ? 'Enter phone number'
                    : null,
              ),
              // Address Field.
              TextFormField(
                initialValue: _address,
                decoration: const InputDecoration(labelText: 'Address'),
                onSaved: (value) => _address = value!,
                validator: (value) =>
                value == null || value.isEmpty ? 'Enter address' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(_isUpdated),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              _formKey.currentState!.save();
              await _updateProfile();
              // _updateProfile already calls Navigator.pop.
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

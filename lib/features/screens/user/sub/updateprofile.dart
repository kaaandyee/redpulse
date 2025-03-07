import 'dart:io';
import 'dart:typed_data'; // Import this to work with Uint8List.
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

  const UpdateProfileDialog({Key? key, required this.user}) : super(key: key);

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
  void initState() {
    super.initState();
    final names = widget.user.fullName.split(' ');
    _firstName = names.isNotEmpty ? names.first : '';
    _lastName = names.length > 1 ? names.sublist(1).join(' ') : '';
    _phoneNumber = widget.user.phoneNumber;
    _address = widget.user.address;
    _profileImageUrl = widget.user.profileImageUrl;
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      if (!mounted) return;
      setState(() {
        _isLoading = true;
      });

      try {
        Uint8List uploadData;

        // On web, avoid using File and compression.
        if (kIsWeb) {
          // Read image bytes directly from the picked file.
          uploadData = await pickedFile.readAsBytes();
        } else {
          // For mobile, use dart:io and compress/convert as needed.
          final file = File(pickedFile.path);
          final int fileSize = await file.length();
          final String ext = path.extension(pickedFile.path).toLowerCase();
          final bool isJpg = ext == '.jpg' || ext == '.jpeg';
          final CompressFormat format =
          isJpg ? CompressFormat.jpeg : CompressFormat.png;
          final String extToUse = isJpg ? 'jpg' : 'png';
          bool needCompress = fileSize > 500 * 1024 || !isJpg;
          List<int>? imageBytes;

          if (needCompress) {
            int quality = 100;
            do {
              imageBytes = await FlutterImageCompress.compressWithFile(
                pickedFile.path,
                quality: quality,
                format: format,
              );
              quality -= 10;
            } while (imageBytes != null &&
                imageBytes.length > 500 * 1024 &&
                quality > 10);
            if (imageBytes == null) {
              throw Exception("Image compression failed.");
            }
          } else {
            imageBytes = await file.readAsBytes();
          }
          uploadData = Uint8List.fromList(imageBytes);
        }

        // Upload image to Firebase Storage.
        final String extToUse = kIsWeb
            ? path.extension(pickedFile.name).replaceFirst('.', '')
            : (path.extension(pickedFile.path).toLowerCase() == '.jpg' ||
            path.extension(pickedFile.path).toLowerCase() == '.jpeg'
            ? 'jpg'
            : 'png');
        final Reference storageRef = FirebaseStorage.instance
            .ref()
            .child('profile_images/${widget.user.id}.$extToUse');
        final UploadTask uploadTask = storageRef.putData(uploadData);
        final TaskSnapshot snapshot = await uploadTask;
        final String newUrl = await snapshot.ref.getDownloadURL();

        // Update Firestore with the new image URL.
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.user.id)
            .update({'profileImageUrl': newUrl});

        if (!mounted) return;
        setState(() {
          _isUpdated = true;
          _profileImageUrl = newUrl;
        });
      } catch (e) {
        // Only schedule a SnackBar if the widget is still mounted.
        if (!mounted) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          scaffoldMessengerKey.currentState?.showSnackBar(
            SnackBar(content: Text('Error uploading image: $e')),
          );
        });
      } finally {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });
      }
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
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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
                validator: (value) =>
                value == null || value.isEmpty ? 'Enter phone number' : null,
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

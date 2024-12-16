import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:redpulse/features/models/inventory.dart';
import 'package:redpulse/features/screens/admin/home.dart';
import 'package:redpulse/features/screens/admin/start.dart';
import 'package:redpulse/services/auth.dart';
import 'package:redpulse/services/validation.dart';
import 'package:redpulse/utilities/constants/styles.dart';
import 'package:redpulse/widgets/button.dart';
import 'package:redpulse/widgets/snackbar';
import 'package:redpulse/widgets/textfield.dart';



class RegisterForm extends StatefulWidget {
  const RegisterForm({super.key});

  @override
  State<RegisterForm> createState() => RegisterFormState();
}

class RegisterFormState extends State<RegisterForm> {
  final TextEditingController bloodBankNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController contactNumberController = TextEditingController();
  final TextEditingController latitudeController = TextEditingController();
  final TextEditingController longitudeController = TextEditingController();
  bool isLoading = false;

  @override
  void dispose() {
    bloodBankNameController.dispose();
    emailController.dispose();
    addressController.dispose();
    contactNumberController.dispose();
    latitudeController.dispose();
    longitudeController.dispose();
    super.dispose();
  }

  Future<void> registerBloodBank() async {
  setState(() {
    isLoading = true;
  });

  String bloodBankName = bloodBankNameController.text;
  String email = emailController.text;
  String address = addressController.text;
  String contactNumber = contactNumberController.text;
  String latitude = latitudeController.text;
  String longitude = longitudeController.text;

  // Validate input fields
  if (bloodBankName.isEmpty ||
      email.isEmpty ||
      address.isEmpty ||
      contactNumber.isEmpty ||
      latitude.isEmpty ||
      longitude.isEmpty) {
    setState(() {
      isLoading = false;
    });
    showSnackBar(context, "Please fill in all fields.");
    return;
  }

  if (!isValidEmail(email)) {
    setState(() {
      isLoading = false;
    });
    showSnackBar(context, "Please enter a valid email address.");
    return;
  }

  if (!isValidPhoneNumber(contactNumber)) {
    setState(() {
      isLoading = false;
    });
    showSnackBar(context, "Please enter a valid contact number.");
    return;
  }

  if (!isValidLatitude(latitude) || !isValidLongitude(longitude)) {
    setState(() {
      isLoading = false;
    });
    showSnackBar(context, "Invalid coordinates. Please check latitude and longitude.");
    return;
  }

  try {
    // Call the updated registerBloodBank method
    String res = await AuthMethod().registerBloodBank(
      bloodBankName: bloodBankName,
      email: email,
      address: address,
      contactNumber: contactNumber,
      latitude: double.parse(latitude),
      longitude: double.parse(longitude),
    );

    if (res == "Blood bank successfully registered.") {
      setState(() {
        isLoading = false;
      });

      // Navigate to Admin Home or Dashboard
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => AdminStart(isAdminLinkedToBloodBank: true),
        ),
      );
    } else {
      setState(() {
        isLoading = false;
      });
      showSnackBar(context, res);
    }
  } catch (error) {
    setState(() {
      isLoading = false;
    });
    showSnackBar(context, "Failed to register blood bank. Please try again.");
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("REGISTER BLOOD BANK", style: Styles.headerStyle8),
            const SizedBox(height: 30),
            TextFieldInput(
              icon: Icons.business,
              textEditingController: bloodBankNameController,
              hintText: 'Blood Bank Name',
              textInputType: TextInputType.text,
            ),
            TextFieldInput(
              icon: Icons.email,
              textEditingController: emailController,
              hintText: 'Email',
              textInputType: TextInputType.emailAddress,
            ),
            TextFieldInput(
              icon: Icons.home,
              textEditingController: addressController,
              hintText: 'Address',
              textInputType: TextInputType.text,
            ),
            TextFieldInput(
              icon: Icons.phone,
              textEditingController: contactNumberController,
              hintText: 'Contact Number',
              textInputType: TextInputType.phone,
            ),
            TextFieldInput(
              icon: Icons.location_on,
              textEditingController: latitudeController,
              hintText: 'Latitude',
              textInputType: TextInputType.number,
            ),
            TextFieldInput(
              icon: Icons.location_on,
              textEditingController: longitudeController,
              hintText: 'Longitude',
              textInputType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            MyButtons(onTap: registerBloodBank, text: "Register"),
          ],
        ),
      ),
    );
  }
}



/*class RegisterForm extends StatefulWidget {
  const RegisterForm({super.key});

  @override
  State<RegisterForm> createState() => RegisterFormState();
}

class RegisterFormState extends State<RegisterForm> {
  final TextEditingController bloodBankNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController contactNumberController = TextEditingController();
  final TextEditingController latitudeController = TextEditingController();
  final TextEditingController longitudeController = TextEditingController();
  bool isLoading = false;

  @override
  void dispose() {
    super.dispose();
    bloodBankNameController.dispose();
    emailController.dispose();
    addressController.dispose();
    contactNumberController.dispose();
    latitudeController.dispose();
    longitudeController.dispose();
  }

  void registerBloodBank() async {
    setState(() {
      isLoading = true;
    });

    String bloodBankName = bloodBankNameController.text;
    String email = emailController.text;
    String address = addressController.text;
    String contactNumber = contactNumberController.text;
    String latitude = latitudeController.text;
    String longitude = longitudeController.text;
    //String dateCreated = DateTime.now().toIso8601String(); // Automatically generated

    if (bloodBankName.isEmpty ||
        email.isEmpty ||
        address.isEmpty ||
        contactNumber.isEmpty ||
        latitude.isEmpty ||
        longitude.isEmpty) {
      setState(() {
        isLoading = false;
      });
      showSnackBar(context, "Please fill in all fields.");
      return;
    }

    if (!isValidEmail(email)) {
      setState(() {
        isLoading = false;
      });
      showSnackBar(context, "Please enter a valid email address.");
      return;
    }

    if (!isValidPhoneNumber(contactNumber)) {
      setState(() {
        isLoading = false;
      });
      showSnackBar(context, "Please enter a valid contact number.");
      return;
    }

    // Validate latitude and longitude format
    if (!isValidLatitude(latitude) || !isValidLongitude(longitude)) {
      setState(() {
        isLoading = false;
      });
      showSnackBar(context, "Invalid coordinates. Please check latitude and longitude.");
      return;
    }

    // Simulated API call or database save operation
    String res = await AuthMethod().registerBloodBank(
      bloodBankName: bloodBankName,
      email: email,
      address: address,
      contactNumber: contactNumber,
      latitude: double.parse(latitude),
      longitude: double.parse(longitude),
      //dateCreated: dateCreated,
      //adminId: "auto_generated_admin_id", // Example for Admin ID
      //bloodBankId: "auto_generated_blood_bank_id", // Example for Blood Bank ID
    );

    if (res == "Blood bank successfully registered.") {
      // Call the method to initialize inventory for this blood bank
      registerBloodBank(String bloodBankId);
      String bloodBankId = "auto_generated_blood_bank_id"; // You will get this ID from the response after registration
      await Inventory.initializeBloodTypeInventory(bloodBankId);

      setState(() {
        isLoading = false;
      });
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const AdminStart(isAdminLinkedToBloodBank: true), // Navigate to dashboard
        ),
      );
    } else {
      setState(() {
        isLoading = false;
      });
      showSnackBar(context, res);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("REGISTER BLOOD BANK", style: Styles.headerStyle8),
            const SizedBox(height: 30),
            TextFieldInput(
              icon: Icons.business,
              textEditingController: bloodBankNameController,
              hintText: 'Blood Bank Name',
              textInputType: TextInputType.text,
            ),
            TextFieldInput(
              icon: Icons.email,
              textEditingController: emailController,
              hintText: 'Email',
              textInputType: TextInputType.emailAddress,
            ),
            TextFieldInput(
              icon: Icons.home,
              textEditingController: addressController,
              hintText: 'Address',
              textInputType: TextInputType.text,
            ),
            TextFieldInput(
              icon: Icons.phone,
              textEditingController: contactNumberController,
              hintText: 'Contact Number',
              textInputType: TextInputType.phone,
            ),
            TextFieldInput(
              icon: Icons.location_on,
              textEditingController: latitudeController,
              hintText: 'Latitude',
              textInputType: TextInputType.number,
            ),
            TextFieldInput(
              icon: Icons.location_on,
              textEditingController: longitudeController,
              hintText: 'Longitude',
              textInputType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            MyButtons(onTap: registerBloodBank, text: "Register"),
          ],
        ),
      ),
    );
  }
}*/



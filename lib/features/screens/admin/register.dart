import 'package:flutter/material.dart';
import 'package:redpulse/features/screens/admin/start.dart';
import 'package:redpulse/services/auth.dart';
import 'package:redpulse/services/validation.dart';
import 'package:redpulse/utilities/constants/styles.dart';
import 'package:redpulse/widgets/button.dart';
import 'package:redpulse/widgets/textfield.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class RegisterForm extends StatefulWidget {

  final String? initialEmail;
  final String? initialAddress;
  final String? initialContactNumber;

  const RegisterForm({
    super.key,
    this.initialEmail,
    this.initialAddress,
    this.initialContactNumber
  });

  @override
  State<RegisterForm> createState() => RegisterFormState();
}

class RegisterFormState extends State<RegisterForm> {
  final TextEditingController bloodBankNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController contactNumberController = TextEditingController();
  bool isLoading = false;

  // Replace lat/long controllers with a LatLng variable
  LatLng? selectedLocation;
  GoogleMapController? mapController;
  Set<Marker> markers = {};

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();


    // Pre-fill fields with data from AdminSignupScreen if available
    if (widget.initialEmail != null) {
      emailController.text = widget.initialEmail!;
    }
    if (widget.initialAddress != null) {
      addressController.text = widget.initialAddress!;
    }
    if (widget.initialContactNumber != null) {
      contactNumberController.text = widget.initialContactNumber!;
    }
  }

  @override
  void dispose() {
    bloodBankNameController.dispose();
    emailController.dispose();
    addressController.dispose();
    contactNumberController.dispose();
    mapController?.dispose();
    super.dispose();
  }

  // Request location permission
  Future<void> _requestLocationPermission() async {
    final status = await Permission.location.request();
    if (status.isGranted) {
      _getCurrentLocation();
    }
  }

  // Get current location
  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high
      );

      setState(() {
        selectedLocation = LatLng(position.latitude, position.longitude);
        _updateMarker();
      });

      mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(selectedLocation!, 15)
      );
    } catch (e) {
      // Default to a location in the Philippines if unable to get current location
      setState(() {
        selectedLocation = const LatLng(14.6091, 121.0223); // Manila coordinates
        _updateMarker();
      });
    }
  }

  // Update marker on the map
  void _updateMarker() {
    if (selectedLocation == null) return;

    setState(() {
      markers = {
        Marker(
          markerId: const MarkerId('bloodBankLocation'),
          position: selectedLocation!,
          draggable: true,
          onDragEnd: (newPosition) {
            setState(() {
              selectedLocation = newPosition;
            });
          },
        ),
      };
    });
  }

  Future<void> registerBloodBank() async {
    setState(() {
      isLoading = true;
    });

    String bloodBankName = bloodBankNameController.text;
    String email = emailController.text;
    String address = addressController.text;
    String contactNumber = contactNumberController.text;

    // Show popup dialog instead of snackbar
    void showPopup(String message) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Notice"),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("OK"),
              ),
            ],
          );
        },
      );
    }

    // Validation checks
    if (bloodBankName.isEmpty ||
        email.isEmpty ||
        address.isEmpty ||
        contactNumber.isEmpty ||
        selectedLocation == null) {
      setState(() {
        isLoading = false;
      });
      showPopup("Please fill in all fields and select a location on the map.");
      return;
    }

    if (!isValidEmail(email)) {
      setState(() {
        isLoading = false;
      });
      showPopup("Please enter a valid email address.");
      return;
    }

    if (!isValidPhoneNumber(contactNumber)) {
      setState(() {
        isLoading = false;
      });
      showPopup("Please enter a valid contact number.");
      return;
    }

    try {
      // Call the registerBloodBank method with coordinates from the map
      String res = await AuthMethod().registerBloodBank(
        bloodBankName: bloodBankName,
        email: email,
        address: address,
        contactNumber: contactNumber,
        latitude: selectedLocation!.latitude,
        longitude: selectedLocation!.longitude,
      );

      if (!mounted) return;

      if (res == "Blood bank successfully registered.") {
        setState(() {
          isLoading = false;
        });

        // Navigate to Admin Home
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const AdminStart(isAdminLinkedToBloodBank: true),
          ),
        );
      } else {
        setState(() {
          isLoading = false;
        });
        showPopup(res);
      }
    } catch (error) {
      setState(() {
        isLoading = false;
      });
      showPopup("Failed to register blood bank. Please try again.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Blood Bank Registration", style: TextStyle(color: Styles.accentColor)),
        backgroundColor: Styles.primaryColor,
        elevation: 0,
        iconTheme: IconThemeData(color: Styles.accentColor),
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                Text("REGISTER BLOOD BANK", style: Styles.headerStyle8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Text(
                    "Step 2: Complete your admin account by registering your blood bank details",
                    style: Styles.headerStyle5,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 20),

                // Information card about blood bank details
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.blue.withOpacity(0.5))
                  ),
                  child: Column(
                    children: [
                      Text(
                        "Blood Bank Information",
                        style: Styles.headerStyle5.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade800
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        "These details will be shown to users searching for blood banks and will appear in your admin dashboard.",
                        style: TextStyle(fontSize: 12, color: Colors.black87),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),
                TextFieldInput(
                  icon: Icons.business,
                  textEditingController: bloodBankNameController,
                  hintText: 'Blood Bank Name',
                  textInputType: TextInputType.text,
                ),
                // Add this after the blood bank name field
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "Your email, address, and phone number have been carried over from the previous step.",
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                    textAlign: TextAlign.center,
                  ),
                ),

                // Location section with Google Maps
                Padding(
                  padding: const EdgeInsets.only(left: 25, top: 15, bottom: 5),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Blood Bank Location',
                      style: Styles.headerStyle6.copyWith(color: Styles.accentColor),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 5),
                  child: Text(
                    "Tap on the map to set your blood bank location or drag the marker to adjust",
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                ),

                // Google Maps widget
                Container(
                  height: 300,
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: selectedLocation == null
                        ? const Center(child: CircularProgressIndicator())
                        : GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: selectedLocation!,
                        zoom: 15,
                      ),
                      onMapCreated: (controller) {
                        mapController = controller;
                      },
                      markers: markers,
                      onTap: (position) {
                        setState(() {
                          selectedLocation = position;
                          _updateMarker();
                        });
                      },
                      myLocationEnabled: true,
                      myLocationButtonEnabled: true,
                      zoomControlsEnabled: true,
                      compassEnabled: true,
                    ),
                  ),
                ),

                // Show selected coordinates
                if (selectedLocation != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 5),
                    child: Text(
                      "Selected: ${selectedLocation!.latitude.toStringAsFixed(6)}, ${selectedLocation!.longitude.toStringAsFixed(6)}",
                      style: TextStyle(fontSize: 12, color: Styles.accentColor),
                    ),
                  ),

                const SizedBox(height: 20),
                isLoading
                    ? const CircularProgressIndicator()
                    : MyButtons(onTap: registerBloodBank, text: "Complete Registration"),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
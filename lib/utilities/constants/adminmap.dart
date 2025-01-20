import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:redpulse/utilities/constants/styles.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminMapScreen extends StatefulWidget {
  final String bloodBankId;

  const AdminMapScreen({super.key, required this.bloodBankId});

  @override
  AdminMapScreenState createState() => AdminMapScreenState();
}

class AdminMapScreenState extends State<AdminMapScreen> {
  static const _initialCameraPosition = CameraPosition(
    target: LatLng(10.31672, 123.89071), // Default coordinates if no data
    zoom: 11.5,
  );

  late GoogleMapController _googleMapController;
  late LatLng _bloodBankLocation;
  late Marker _bloodBankMarker;

  @override
  void initState() {
    super.initState();
    _bloodBankLocation = LatLng(10.31672, 123.89071); // Default location
    _bloodBankMarker = Marker(
      markerId: MarkerId('bloodBankMarker'),
      position: _bloodBankLocation,
      infoWindow: InfoWindow(title: 'Blood Bank Location'),
    );
    _fetchBloodBankLocation(); // Fetch the location and name of the blood bank
  }

  // Fetch latitude, longitude, and name from Firestore
  Future<void> _fetchBloodBankLocation() async {
    try {
      // Fetch blood bank data from Firestore using the bloodBankId
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('bloodbanks')
          .doc(widget.bloodBankId)
          .get();

      if (snapshot.exists) {
        var data = snapshot.data() as Map<String, dynamic>;
        double latitude = data['latitude'];
        double longitude = data['longitude'];
        String bloodBankName = data['bloodBankName'] ?? 'Blood Bank'; // Default name if not available

        // Update the blood bank's location and name
        setState(() {
          _bloodBankLocation = LatLng(latitude, longitude);
          _bloodBankMarker = Marker(
            markerId: MarkerId('bloodBankMarker'),
            position: _bloodBankLocation,
            infoWindow: InfoWindow(title: bloodBankName), // Set the name here
          );
        });

        // Update the camera position to focus on the blood bank's location
        _googleMapController.animateCamera(
          CameraUpdate.newLatLngZoom(_bloodBankLocation, 14),
        );
      }
    } catch (e) {
      print("Error fetching blood bank location: $e");
    }
  }

  @override
  void dispose() {
    _googleMapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Styles.tertiaryColor,
      appBar: AppBar(
                backgroundColor: Styles.primaryColor,
                leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_outlined, size: 20, color: Colors.white), onPressed: () {Navigator.pop(context);},),
                title: Text('Blood Bank Location', style: Styles.headerStyle2.copyWith(fontSize: 18, fontWeight: FontWeight.bold, color: Styles.tertiaryColor,)),
                centerTitle: true,
              ),
      body: GoogleMap(
        myLocationButtonEnabled: false,
        zoomControlsEnabled: true,
        initialCameraPosition: _initialCameraPosition,
        onMapCreated: (controller) => _googleMapController = controller,
        markers: {_bloodBankMarker}, // Add the blood bank marker to the map
      ),
      /*floatingActionButton: FloatingActionButton(
        backgroundColor: Styles.primaryColor,
        foregroundColor: Styles.tertiaryColor,
        onPressed: () => _googleMapController.animateCamera(
          CameraUpdate.newCameraPosition(CameraPosition(target: _bloodBankLocation, zoom: 14)),
        ),
        child: const Icon(Icons.center_focus_strong),
      ),*/
    );
  }
}


/*class MapScreen extends StatefulWidget {
  final String bloodBankId;

  const MapScreen({super.key, required this.bloodBankId});

  @override
  MapScreenState createState() => MapScreenState();
}

class MapScreenState extends State<MapScreen> {
  static const _initialCameraPosition = CameraPosition(
    target: LatLng(10.31672, 123.89071), // Default coordinates if no data
    zoom: 11.5,
  );

  late GoogleMapController _googleMapController;
  late LatLng _bloodBankLocation;
  late Marker _bloodBankMarker;

  @override
  void initState() {
    super.initState();
    _bloodBankLocation = LatLng(10.31672, 123.89071); // Default location
    _bloodBankMarker = Marker(
      markerId: MarkerId('bloodBankMarker'),
      position: _bloodBankLocation,
      infoWindow: InfoWindow(title: 'Blood Bank Location'),
    );
    _fetchBloodBankLocation(); // Fetch the location of the blood bank
  }

  // Fetch latitude and longitude from Firestore
  Future<void> _fetchBloodBankLocation() async {
    try {
      // Fetch blood bank data from Firestore using the bloodBankId
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('bloodbanks')
          .doc(widget.bloodBankId)
          .get();

      if (snapshot.exists) {
        var data = snapshot.data() as Map<String, dynamic>;
        double latitude = data['latitude'];
        double longitude = data['longitude'];

        // Update the blood bank's location
        setState(() {
          _bloodBankLocation = LatLng(latitude, longitude);
          _bloodBankMarker = Marker(
            markerId: MarkerId('bloodBankMarker'),
            position: _bloodBankLocation,
            infoWindow: InfoWindow(title: 'Blood Bank Location'),
          );
        });

        // Update the camera position to focus on the blood bank's location
        _googleMapController.animateCamera(
          CameraUpdate.newLatLngZoom(_bloodBankLocation, 14),
        );
      }
    } catch (e) {
      print("Error fetching blood bank location: $e");
    }
  }

  @override
  void dispose() {
    _googleMapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Styles.primaryColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_circle_left, size: 25, color: Colors.white), // White back icon
          onPressed: () {
            Navigator.pop(context); // Navigate back to the previous screen (AdminHome)
          },
        ),
        title: Text("Blood Bank Location", style: Styles.headerStyle2.copyWith(fontSize: 20, fontWeight: FontWeight.bold, color: Styles.tertiaryColor,),
),
      ),
      body: GoogleMap(
        myLocationButtonEnabled: false,
        zoomControlsEnabled: false,
        initialCameraPosition: _initialCameraPosition,
        onMapCreated: (controller) => _googleMapController = controller,
        markers: {_bloodBankMarker}, // Add the blood bank marker to the map
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Styles.primaryColor,
        foregroundColor: Styles.tertiaryColor,
        onPressed: () => _googleMapController.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(target: _bloodBankLocation, zoom: 14))),
        child: const Icon(Icons.center_focus_strong),
      ),
    );
  }
}*/



/*class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  MapScreenState createState() => MapScreenState();
}

class MapScreenState extends State<MapScreen> {
  static const _initialCameraPosition = CameraPosition(
    target: LatLng(10.31672, 123.89071),
    zoom: 11.5,
  );

  late GoogleMapController _googleMapController;
  @override
  void dispose() {
    _googleMapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GoogleMap(
        myLocationButtonEnabled: false,
        zoomControlsEnabled: false,
        initialCameraPosition: _initialCameraPosition,
        onMapCreated: (controller) => _googleMapController = controller,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Styles.primaryColor,
        foregroundColor: Styles.tertiaryColor,
        onPressed: () => _googleMapController.animateCamera(CameraUpdate.newCameraPosition(_initialCameraPosition)),
        child: const Icon(Icons.center_focus_strong),
      ),
    );
  }
}*/
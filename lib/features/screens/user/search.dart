import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:redpulse/features/screens/user/sub/bloodbankdetails.dart';
import 'package:redpulse/utilities/constants/styles.dart';
import 'package:redpulse/widgets/textfield.dart';
import 'package:geolocator/geolocator.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  SearchScreenState createState() => SearchScreenState();
}

class SearchScreenState extends State<SearchScreen> {
  static const _initialCameraPosition = CameraPosition(
    target: LatLng(10.317870822438445, 123.88928644803421), // Default camera position 10.317870822438445, 123.88928644803421
    zoom: 11.5,
  );

  late GoogleMapController _googleMapController;
  final Set<Marker> _markers = {}; // Stores all the blood bank markers
  List<Map<String, dynamic>> _bloodBanks = []; // Stores fetched blood banks
  List<Map<String, dynamic>> _filteredBloodBanks = []; // Stores filtered blood banks based on search input
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();// Automatically fetch location on screen load
    _placeUserLocationMarker(); 
    _fetchBloodBanks(); // Fetch all blood bank locations
    _searchController.addListener(_filterBloodBanks); // Listen for search field changes
  }

  // Fetch blood banks from Firestore and create markers
  // Fetch blood banks from Firestore and create markers
  Future<void> _fetchBloodBanks() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('bloodbanks') // Adjust collection name if needed
          .get();

      // Create a list of blood bank data
      List<Map<String, dynamic>> fetchedBloodBanks = [];
      for (var doc in snapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        double latitude = data['latitude'];
        double longitude = data['longitude'];
        String bloodBankName = data['bloodBankName'] ?? 'Blood Bank';

        // Fetch the blood type from the 'inventories' subcollection
        QuerySnapshot inventorySnapshot = await FirebaseFirestore.instance
            .collection('bloodbanks')
            .doc(doc.id)
            .collection('inventories')
            .get();

        // Assuming each blood type has its own document in the subcollection
        List<String> bloodTypes = [];
        for (var inventoryDoc in inventorySnapshot.docs) {
          bloodTypes.add(inventoryDoc.id); // Using document ID as the blood type
        }

        // Add the blood bank data to the list
        fetchedBloodBanks.add({
          'bloodBankId': doc.id,
          'bloodBankName': bloodBankName,
          'bloodTypes': bloodTypes, // Store list of blood types
          'latitude': latitude,
          'longitude': longitude,
        });
      }

      setState(() {
        _bloodBanks = fetchedBloodBanks; // Store the fetched blood banks
        _filteredBloodBanks = fetchedBloodBanks; // Initially show all blood banks
        _createMarkers(); // Create markers for all fetched blood banks
      });
    } catch (e) {
      print("Error fetching blood banks: $e");
    }
  }

  // Filter the blood banks based on search input
  void _filterBloodBanks() {
    String query = _searchController.text.toLowerCase();

    setState(() {
      _filteredBloodBanks = _bloodBanks.where((bloodBank) {
        return bloodBank['bloodBankName'].toLowerCase().contains(query) ||
            bloodBank['bloodTypes'].any((bloodType) => bloodType.toLowerCase().contains(query));
      }).toList();

      _createMarkers(); // Update markers after filtering

      // Zoom to the first blood bank that matches the query
      if (_filteredBloodBanks.isNotEmpty) {
        var firstMatch = _filteredBloodBanks.first;
        _googleMapController.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(firstMatch['latitude'], firstMatch['longitude']),
            14.0, // Zoom level, you can adjust it as needed
          ),
        );
      }
    });
  }

  // Create markers for the filtered blood banks
  /*void _createMarkers() {
    _markers.clear(); // Clear existing markers

    for (var bloodBank in _filteredBloodBanks) {
      Marker marker = Marker(
        markerId: MarkerId(bloodBank['bloodBankId']),
        position: LatLng(bloodBank['latitude'], bloodBank['longitude']),
        infoWindow: InfoWindow(
          title: bloodBank['bloodBankName'], // Display blood bank name in the info window
          snippet: "Blood Types: ${bloodBank['bloodTypes'].join(', ')}",
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BloodBankDetailsScreen(bloodBankId: bloodBank['bloodBankId']),
              ),
            );
          },
        ),
      );
      _markers.add(marker);
    }
  }*/

  void _createMarkers() async {
  setState(() {
      _markers.clear(); // Clear existing markers
    });

    for (var bloodBank in _filteredBloodBanks) {
      // Get the reference to the 'inventories' sub-collection
      var inventoryCollection = FirebaseFirestore.instance
          .collection('bloodbanks')
          .doc(bloodBank['bloodBankId'])
          .collection('inventories');

      // Fetch all the documents in the 'inventories' sub-collection
      var inventorySnapshot = await inventoryCollection.get();

      // Filter blood types with Available or Low Stock status
      var availableBloodTypes = inventorySnapshot.docs.where((doc) {
        var status = doc['status'];
        return status == 'Available' || status == 'Low Stock';
      }).toList();

      // Prepare the snippet for the info window
      String snippet;

      // If there are blood types with Available or Low Stock status
      if (availableBloodTypes.isNotEmpty) {
        // List the blood types with Available or Low Stock status
        snippet = "Blood Types: ${availableBloodTypes.map((doc) => doc.id).join(', ')}";
        
        /*"Blood Types: ${availableBloodTypes.map((doc) => "${doc.id} (${doc['status']})").join(', ')}";*/

        
      } else {
        snippet = "Out of Stock"; // Default message if no blood types are available
      }

      // Debugging: Print the blood bank and its available blood types
      print('Creating marker for ${bloodBank['bloodBankName']} with snippet: $snippet');

      // Create the marker with the snippet
      Marker marker = Marker(
        markerId: MarkerId(bloodBank['bloodBankId']),
        position: LatLng(bloodBank['latitude'], bloodBank['longitude']),
        infoWindow: InfoWindow(
          title: bloodBank['bloodBankName'], // Display blood bank name in the info window
          snippet: snippet,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BloodBankDetailsScreen(bloodBankId: bloodBank['bloodBankId']),
              ),
            );
          },
        ),
      );
      
      // Add marker to the map
      setState(() {
        _markers.add(marker);
      });
    }
  }

  // Function to calculate distance and find nearest blood bank
  Future<void> _locateNearestBloodBank() async {
    // Check if location permissions are granted
    Position position = await _getCurrentLocation();
    LatLng _userLocation = LatLng(position.latitude, position.longitude);

    double closestDistance = double.infinity;
    Map<String, dynamic>? nearestBloodBank;

    // Loop through blood banks to find the closest one
    for (var bloodBank in _bloodBanks) {
      double distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        bloodBank['latitude'],
        bloodBank['longitude'],
      );

      if (distance < closestDistance) {
        closestDistance = distance;
        nearestBloodBank = bloodBank;
      }
    }

    // If a nearest blood bank is found, update the map
    if (nearestBloodBank != null) {
      _googleMapController.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(nearestBloodBank['latitude'], nearestBloodBank['longitude']),
          14.0,
        ),
      );

      setState(() {
        // Ensure nearestBloodBank has valid latitude and longitude values
        if (nearestBloodBank != null &&
            nearestBloodBank['latitude'] != null &&
            nearestBloodBank['longitude'] != null) {

          // Clear any existing markers and add the nearest blood bank marker
          _markers.clear();
          _markers.add(Marker(
            markerId: MarkerId(nearestBloodBank['id']),
            position: LatLng(
              nearestBloodBank['latitude'].toDouble(), // Ensure it's a double
              nearestBloodBank['longitude'].toDouble(), // Ensure it's a double
            ),
            infoWindow: InfoWindow(title: nearestBloodBank['name']),
          ));
        } else {
          print("Invalid nearestBloodBank data: Latitude and/or Longitude missing.");
        }
      });

    }
  }

  // Get the user's current location and place a marker
  Future<Position> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    // Check and request permissions
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permission denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permission permanently denied.');
    }

    // Fetch current position
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }

  // Function to place a marker on the user's location
  Future<void> _placeUserLocationMarker() async {
    try {
      // Get the current location
      Position position = await _getCurrentLocation();

      // Create a LatLng object with the user's current position
      LatLng userLocation = LatLng(position.latitude, position.longitude);

      // Add a marker for the user's location
      /*setState(() {
        _markers.add(
          Marker(
            markerId: const MarkerId('user_location'),
            position: userLocation,
            infoWindow: const InfoWindow(title: 'Your Location'),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure), // Change the color
          ),
        );
      });*/


      _googleMapController.animateCamera(
        CameraUpdate.newLatLngZoom(userLocation, 15.0),
      );
    } catch (e) {
      print('Error getting user location: $e');
    }
  }

  @override
  void dispose() {
    _googleMapController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(120),
        child: AppBar(
          backgroundColor: Styles.primaryColor,
          elevation: 0,
          flexibleSpace: Padding(
            padding: const EdgeInsets.all(20),
            child: Align(
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  Text(
                    "Search",
                    style: Styles.headerStyle2.copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Styles.tertiaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Google Map in the background
          GoogleMap(
            myLocationEnabled: true, // Enable user location only after permissions
            myLocationButtonEnabled: false,
            zoomControlsEnabled: true,
            initialCameraPosition:  _initialCameraPosition,
            onMapCreated: (controller) => _googleMapController = controller,
            markers: _markers,
          ),


          // Search Bar and FloatingActionButton beside it
        Positioned(
          top: 20,
          left: 10,
          right: 20,
          child: Row(
            children: [
              // Search Text Field
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    // Optional Box Shadow if needed
                  ),
                  child: TextFieldInput(
                    icon: Icons.search,
                    textEditingController: _searchController,
                    hintText: 'Search blood bank name...',
                    textInputType: TextInputType.text,
                    externalPadding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                ),
              ),

              ElevatedButton(
              style: ElevatedButton.styleFrom(foregroundColor: Styles.tertiaryColor, backgroundColor: Styles.primaryColor, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10),),), padding: const EdgeInsets.all(15),),
              onPressed: () async {
                Position position = await _getCurrentLocation();

                // Create a CameraPosition using the current location
                CameraPosition cameraPosition = CameraPosition(
                  target: LatLng(position.latitude, position.longitude),
                  zoom: 15.0, // You can adjust the zoom level
                );

                // Animate the camera to the new position
                _googleMapController.animateCamera(
                  CameraUpdate.newCameraPosition(cameraPosition),
                );
              },
              child: const Icon(Icons.center_focus_strong), // Icon inside the button
            ),
            ],
          ),
        ),

        // 'Find Nearest Blood Bank' Button at the bottom
        Positioned(
          bottom: 20,
          left: 20,
          right: 60,
          child: ElevatedButton(
            onPressed: _locateNearestBloodBank,
            style: ElevatedButton.styleFrom(
              minimumSize: Size(double.infinity, 50), // Make the button full width
              backgroundColor: Styles.primaryColor,
              foregroundColor: Styles.tertiaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Find Nearest Blood Bank',
              style: Styles.headerStyle6.copyWith(color: Styles.tertiaryColor),
            ),
          ),

        ),
      ],
    ),
  );
}
}
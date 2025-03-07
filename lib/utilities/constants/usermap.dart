import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:redpulse/features/screens/user/sub/bloodbankdetails.dart';
import 'package:redpulse/utilities/constants/styles.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  SearchScreenState createState() => SearchScreenState();
}

class SearchScreenState extends State<SearchScreen> {
  static const _initialCameraPosition = CameraPosition(
    target: LatLng(10.31672, 123.89071), // Default camera position
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
    _fetchBloodBanks(); // Fetch all blood bank locations
    _searchController.addListener(_filterBloodBanks); // Listen for changes in the search field
  }

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
  void _createMarkers() {
    _markers.clear(); // Clear existing markers

    for (var bloodBank in _filteredBloodBanks) {
      Marker marker = Marker(
        markerId: MarkerId(bloodBank['bloodBankId']),
        position: LatLng(bloodBank['latitude'], bloodBank['longitude']),
        infoWindow: InfoWindow(
          title: bloodBank['bloodBankName'],
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
  }

  @override
  void dispose() {
    _googleMapController.dispose();
    _searchController.dispose(); // Dispose the search controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Styles.primaryColor,
        title: const Text(
          'Search Blood Banks',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by blood bank name or blood type...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
          ),
          // Google Map
          Expanded(
            child: GoogleMap(
              myLocationButtonEnabled: true,
              zoomControlsEnabled: true,
              initialCameraPosition: _initialCameraPosition,
              onMapCreated: (controller) => _googleMapController = controller,
              markers: _markers, // Display all the markers on the map
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Styles.primaryColor,
        foregroundColor: Styles.tertiaryColor,
        onPressed: () => _googleMapController.animateCamera(
          CameraUpdate.newCameraPosition(_initialCameraPosition),
        ),
        child: const Icon(Icons.center_focus_strong),
      ),
    );
  }
}


/*class UserMapScreen extends StatefulWidget {
  const UserMapScreen({super.key});

  @override
  UserMapScreenState createState() => UserMapScreenState();
}

class UserMapScreenState extends State<UserMapScreen> {
  static const _initialCameraPosition = CameraPosition(
    target: LatLng(10.31672, 123.89071), // Default camera position
    zoom: 11.5,
  );

  late GoogleMapController _googleMapController;
  final Set<Marker> _markers = {}; // Stores all the blood bank markers

  @override
  void initState() {
    super.initState();
    _fetchBloodBanks(); // Fetch all blood bank locations
  }

  // Fetch blood banks from Firestore and create markers
  Future<void> _fetchBloodBanks() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('bloodbanks') // Adjust collection name if needed
          .get();

      for (var doc in snapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        double latitude = data['latitude'];
        double longitude = data['longitude'];
        String bloodBankName = data['name'] ?? 'Blood Bank';

        // Create a marker for each blood bank
        /*Marker marker = Marker(
          markerId: MarkerId(doc.id), // Use the document ID as marker ID
          position: LatLng(latitude, longitude),
          infoWindow: InfoWindow(title: bloodBankName),
        );*/

        Marker marker = Marker(
          markerId: MarkerId(doc.id),
          position: LatLng(latitude, longitude),
          infoWindow: InfoWindow(
            title: bloodBankName,
            snippet: "Tap to view details",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BloodBankDetailsScreen(bloodBankId: doc.id),
                ),
              );
            },
          ),
        );

        setState(() {
          _markers.add(marker); // Add marker to the set
        });
      }
    } catch (e) {
      print("Error fetching blood banks: $e");
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
        title: const Text(
          'Blood Banks Near You',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: GoogleMap(
        myLocationButtonEnabled: true,
        zoomControlsEnabled: true,
        initialCameraPosition: _initialCameraPosition,
        onMapCreated: (controller) => _googleMapController = controller,
        markers: _markers, // Display all the markers on the map
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Styles.primaryColor,
        foregroundColor: Styles.tertiaryColor,
        onPressed: () => _googleMapController.animateCamera(
          CameraUpdate.newCameraPosition(_initialCameraPosition),
        ),
        child: const Icon(Icons.center_focus_strong),
      ),
    );
  }
}*/

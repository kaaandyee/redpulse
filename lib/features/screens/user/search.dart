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
    target: LatLng(10.317870822438445, 123.88928644803421), // Default camera position
    zoom: 11.5,
  );

  late GoogleMapController _googleMapController;
  final Set<Marker> _markers = {}; // Stores all the blood bank markers
  List<Map<String, dynamic>> _bloodBanks = []; // Stores fetched blood banks
  List<Map<String, dynamic>> _filteredBloodBanks = []; // Stores filtered blood banks based on search input
  final TextEditingController _searchController = TextEditingController();

  // Cache for inventory details: maps bloodBankId to list of available blood types
  final Map<String, List<String>> _bloodBankInventoryCache = {};

  // Loading indicator state
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _isLoading = true;
    _getCurrentLocation(); // Automatically fetch location on screen load
    _placeUserLocationMarker();
    _fetchBloodBanks(); // Fetch all blood bank locations and inventory details
    _searchController.addListener(_filterBloodBanks); // Listen for search field changes
  }

  // Fetch blood banks from Firestore and pre-fetch inventory details for caching
  Future<void> _fetchBloodBanks() async {
    try {
      QuerySnapshot snapshot =
      await FirebaseFirestore.instance.collection('bloodbanks').get();

      List<Map<String, dynamic>> fetchedBloodBanks = [];
      for (var doc in snapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        double latitude = data['latitude'];
        double longitude = data['longitude'];
        String bloodBankName = data['bloodBankName'] ?? 'Blood Bank';

        // Pre-fetch inventory details and cache available blood types
        QuerySnapshot inventorySnapshot = await FirebaseFirestore.instance
            .collection('bloodbanks')
            .doc(doc.id)
            .collection('inventories')
            .get();

        List<String> bloodTypes = [];
        List<String> availableBloodTypes = [];
        for (var inventoryDoc in inventorySnapshot.docs) {
          String bloodType = inventoryDoc.id;
          bloodTypes.add(bloodType);
          // Check if the blood type is Available or Low Stock
          var status = inventoryDoc['status'];
          if (status == 'Available' || status == 'Low Stock') {
            availableBloodTypes.add(bloodType);
          }
        }
        // Cache available blood types for this blood bank
        _bloodBankInventoryCache[doc.id] = availableBloodTypes;

        fetchedBloodBanks.add({
          'bloodBankId': doc.id,
          'bloodBankName': bloodBankName,
          'bloodTypes': bloodTypes, // Use for filtering by blood type as well
          'latitude': latitude,
          'longitude': longitude,
        });
      }

      setState(() {
        _bloodBanks = fetchedBloodBanks; // Store the fetched blood banks
        _filteredBloodBanks = fetchedBloodBanks; // Initially show all blood banks
      });

      // Create markers for all fetched blood banks
      _createMarkers();
    } catch (e) {
      print("Error fetching blood banks: $e");
    } finally {
      setState(() {
        _isLoading = false; // Data fetching complete, hide loading indicator
      });
    }
  }

  // Filter the blood banks based on search input and update markers
  void _filterBloodBanks() {
    String query = _searchController.text.trim().toLowerCase();
    print("Search Query: $query");

    setState(() {
      _filteredBloodBanks = _bloodBanks.where((bloodBank) {
        String name = (bloodBank['bloodBankName'] ?? '').trim().toLowerCase();
        List<String> availableBloodTypes =
            _bloodBankInventoryCache[bloodBank['bloodBankId']] ?? [];

        print("Checking: $name");

        // Debugging the matching logic
        if (name.contains(query)) {
          print("Matched Name: $name");
        }
        if (availableBloodTypes.any((bloodType) =>
            bloodType.toLowerCase().contains(query))) {
          print("Matched Blood Type in: $name");
        }

        bool nameMatches = name.contains(query);
        bool bloodTypeMatches = availableBloodTypes.any((bloodType) =>
            bloodType.toLowerCase().contains(query));

        return nameMatches || bloodTypeMatches;
      }).toList();
    });

    _createMarkers();
  }



  // Create markers using pre-fetched inventory details from cache
  void _createMarkers() {
    setState(() {
      _markers.clear(); // Clear existing markers
    });

    for (var bloodBank in _filteredBloodBanks) {
      // Retrieve available blood types from cache
      List<String> availableBloodTypes =
          _bloodBankInventoryCache[bloodBank['bloodBankId']] ?? [];

      // Prepare snippet for info window based on inventory status
      String snippet = availableBloodTypes.isNotEmpty
          ? "Blood Types: ${availableBloodTypes.join(', ')}"
          : "Out of Stock";

      // Debugging: Print the blood bank and its available blood types
      print(
          'Creating marker for ${bloodBank['bloodBankName']} with snippet: $snippet');

      // Create the marker
      Marker marker = Marker(
        markerId: MarkerId(bloodBank['bloodBankId']),
        position: LatLng(bloodBank['latitude'], bloodBank['longitude']),
        infoWindow: InfoWindow(
          title: bloodBank['bloodBankName'],
          snippet: snippet,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    BloodBankDetailsScreen(bloodBankId: bloodBank['bloodBankId']),
              ),
            );
          },
        ),
      );

      setState(() {
        _markers.add(marker);
      });
    }
  }

  // Function to calculate distance and find nearest blood bank
  Future<void> _locateNearestBloodBank() async {
    try {
      Position position = await _getCurrentLocation();
      LatLng userLocation = LatLng(position.latitude, position.longitude);

      double closestDistance = double.infinity;
      Map<String, dynamic>? nearestBloodBank;

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

      if (nearestBloodBank != null) {
        _googleMapController.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(nearestBloodBank['latitude'], nearestBloodBank['longitude']),
            14.0,
          ),
        );

        setState(() {
          if (nearestBloodBank != null &&
              nearestBloodBank['latitude'] != null &&
              nearestBloodBank['longitude'] != null) {
            _markers.clear();
            _markers.add(Marker(
              markerId: MarkerId(nearestBloodBank['bloodBankId']),
              position: LatLng(
                nearestBloodBank['latitude'].toDouble(),
                nearestBloodBank['longitude'].toDouble(),
              ),
              infoWindow: InfoWindow(title: nearestBloodBank['bloodBankName']),
            ));
          } else {
            print("Invalid nearestBloodBank data: Latitude and/or Longitude missing.");
          }
        });
      }
    } catch (e) {
      print("Error locating nearest blood bank: $e");
    }
  }

  // Get the user's current location
  Future<Position> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

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

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  // Place a marker on the user's location
  Future<void> _placeUserLocationMarker() async {
    try {
      Position position = await _getCurrentLocation();
      LatLng userLocation = LatLng(position.latitude, position.longitude);

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
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
          ),
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
          // Google Map as the background
          GoogleMap(
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: true,
            initialCameraPosition: _initialCameraPosition,
            onMapCreated: (controller) => _googleMapController = controller,
            markers: _markers,
          ),

          // Loading indicator overlay when data is being fetched
          if (_isLoading)
            const Center(child: CircularProgressIndicator()),

          // Search bar and location button
          Positioned(
            top: 20,
            left: 10,
            right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextFieldInput(
                        icon: Icons.search,
                        textEditingController: _searchController,
                        hintText: 'Search blood bank name or blood type...',
                        textInputType: TextInputType.text,
                        externalPadding: const EdgeInsets.symmetric(horizontal: 10),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Styles.tertiaryColor,
                        backgroundColor: Styles.primaryColor,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                        ),
                        padding: const EdgeInsets.all(15),
                      ),
                      onPressed: () async {
                        try {
                          Position position = await _getCurrentLocation();
                          LatLng userLocation = LatLng(position.latitude, position.longitude);

                          // Remove existing user location marker if any
                          _markers.removeWhere(
                                  (marker) => marker.markerId == const MarkerId('user_location'));

                          setState(() {
                            _markers.add(
                              Marker(
                                markerId: const MarkerId('user_location'),
                                position: userLocation,
                                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                                infoWindow: const InfoWindow(title: 'Your Location'),
                              ),
                            );
                          });

                          _googleMapController.animateCamera(
                            CameraUpdate.newLatLngZoom(userLocation, 15.0),
                          );
                        } catch (e) {
                          print('Error locating user: $e');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Could not fetch location: $e')),
                          );
                        }
                      },
                      child: const Icon(Icons.location_searching),
                    ),
                  ],
                ),
                // Dropdown list for search results
                if (_searchController.text.isNotEmpty)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    margin: const EdgeInsets.only(top: 10),
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _filteredBloodBanks.length,
                      itemBuilder: (context, index) {
                        final bank = _filteredBloodBanks[index];
                        return ListTile(
                          title: Text(bank['bloodBankName']),
                          subtitle: Text(
                            bank['bloodTypes'].join(', '),
                            style: const TextStyle(fontSize: 12),
                          ),
                          onTap: () {
                            final LatLng position = LatLng(
                              bank['latitude'] as double,
                              bank['longitude'] as double,
                            );
                            _googleMapController.animateCamera(
                              CameraUpdate.newLatLngZoom(position, 14),
                            );
                            _searchController.clear();
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),

          // "Find Nearest Blood Bank" Button at the bottom
          Positioned(
            bottom: 20,
            left: 20,
            right: 60,
            child: ElevatedButton(
              onPressed: _locateNearestBloodBank,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
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

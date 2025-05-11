// ignore_for_file: use_build_context_synchronously, deprecated_member_use
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:redpulse/features/screens/user/sub/bloodbankdetails.dart';
import 'package:redpulse/utilities/constants/enums.dart';
import 'package:redpulse/utilities/constants/styles.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_moving_background/flutter_moving_background.dart';
import 'package:flutter_moving_background/enums/animation_types.dart';
import 'package:animate_do/animate_do.dart';
import 'package:permission_handler/permission_handler.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  SearchScreenState createState() => SearchScreenState();
}

class SearchScreenState extends State<SearchScreen> {
  static const _initialCameraPosition = CameraPosition(
    target: LatLng(10.317870822438445, 123.88928644803421),
    zoom: 11.5,
  );

  late GoogleMapController _googleMapController;
  final Set<Marker> _markers = {};
  List<Map<String, dynamic>> _bloodBanks = [];
  List<Map<String, dynamic>> _filteredBloodBanks = [];
  final TextEditingController _searchController = TextEditingController();
  BloodType? selectedBloodType;

  // Cache for inventory details
  final Map<String, List<String>> _bloodBankInventoryCache = {};

  bool _isLoading = false;
  bool _isSearching = false;
  bool _isMapInitialized = false;

  @override
  void initState() {
    super.initState();
    _isLoading = true;
    _fetchBloodBanks();
    _searchController.addListener(_filterBloodBanks);
  }

  Future<void> _fetchBloodBanks() async {
    try {
      setState(() => _isLoading = true);

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
          'bloodTypes': bloodTypes,
          'latitude': latitude,
          'longitude': longitude,
        });
      }

      setState(() {
        _bloodBanks = fetchedBloodBanks;
        _filteredBloodBanks = fetchedBloodBanks;
      });

      // Create markers for all fetched blood banks
      _createMarkers();

      if (_isMapInitialized) {
        _placeUserLocationMarker();
      }
    } catch (e) {
      print("Error fetching blood banks: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading blood banks: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _filterBloodBanks() {
    String query = _searchController.text.trim().toLowerCase();
    setState(() {
      _isSearching = query.isNotEmpty;
      _filteredBloodBanks = _bloodBanks.where((bloodBank) {
        String name = (bloodBank['bloodBankName'] ?? '').trim().toLowerCase();
        List<String> availableBloodTypes =
            _bloodBankInventoryCache[bloodBank['bloodBankId']] ?? [];

        bool nameMatches = name.contains(query);
        bool bloodTypeMatches = availableBloodTypes
            .any((bloodType) => bloodType.toLowerCase().contains(query));

        return nameMatches || bloodTypeMatches;
      }).toList();
    });

    _createMarkers();
  }

  void _createMarkers() {

    for (var bloodBank in _filteredBloodBanks) {
      List<String> availableBloodTypes =
          _bloodBankInventoryCache[bloodBank['bloodBankId']] ?? [];

      String snippet = availableBloodTypes.isNotEmpty
          ? "Blood Types: ${availableBloodTypes.join(', ')}"
          : "Out of Stock";

      Marker marker = Marker(
        markerId: MarkerId(bloodBank['bloodBankId']),
        position: LatLng(bloodBank['latitude'], bloodBank['longitude']),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(
          title: bloodBank['bloodBankName'],
          snippet: snippet,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BloodBankDetailsScreen(
                    bloodBankId: bloodBank['bloodBankId']),
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

Future<void> _requestLocationPermission() async {
  PermissionStatus status = await Permission.location.request();
  if (status.isGranted) {
    _placeUserLocationMarker();
  } else {
    // Handle permission denied
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Location permission is required to access the user location.'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

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

  Future<void> _placeUserLocationMarker() async {
    try {
      setState(() => _isLoading = true);
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 100, 
        ),
      );
      LatLng userLocation = LatLng(position.latitude, position.longitude);

      // Remove existing user location marker
      _markers.removeWhere((marker) => marker.markerId == const MarkerId('user_location'));

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
        CameraUpdate.newLatLngZoom(userLocation, 14.0),
      );

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      print('Error getting user location: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not fetch location: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

Future<void> _locateNearestBloodBank({BloodType? bloodType}) async {
  setState(() => _isLoading = true);

  try {
    Position position = await _getCurrentLocation();
    double closestDistance = double.infinity;
    Map<String, dynamic>? nearestBloodBank;

    for (var bloodBank in _bloodBanks) {
      final inventory = _bloodBankInventoryCache[bloodBank['bloodBankId']] ?? [];

      // If filtering by blood type, skip banks that don't have it
      if (bloodType != null && !inventory.contains(bloodType.label)) {
        continue;
      }

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
      final distanceInKm = (closestDistance / 1000).toStringAsFixed(1);

      _googleMapController.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(nearestBloodBank['latitude'], nearestBloodBank['longitude']),
          14.0,
        ),
      );

      setState(() {
        _markers.removeWhere((marker) => marker.markerId == const MarkerId('user_location'));

        _markers.add(
          Marker(
            markerId: const MarkerId('user_location'),
            position: LatLng(position.latitude, position.longitude),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
            infoWindow: const InfoWindow(title: 'Your Location'),
          ),
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Found nearest blood bank: ${nearestBloodBank['bloodBankName']} ($distanceInKm km away)',
          ),
          backgroundColor: Colors.green[700],
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            bloodType != null
              ? 'No blood banks found with blood type ${bloodType.label}'
              : 'No blood banks found in the database',
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  } catch (e) {
    print('Error locating nearest blood bank: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Could not find nearest blood bank: $e'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  } finally {
    setState(() => _isLoading = false);
  }
}

  @override
  void dispose() {
    if (_isMapInitialized) {
      _googleMapController.dispose();
    }
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(screenSize.height * 0.11),
        child: FadeInDown(
          duration: const Duration(milliseconds: 800),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Styles.primaryColor,
                  Styles.primaryColor.withOpacity(0.95),
                ],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(25),
                bottomRight: Radius.circular(25),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.2),
                  blurRadius: 15,
                  spreadRadius: 2,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: screenSize.width * 0.06,
                    vertical: screenSize.height * 0.015
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Find Blood Banks",
                      style: GoogleFonts.montserrat(
                        fontSize: screenSize.width * 0.055,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: screenSize.height * 0.005),
                    Text(
                      "Search for blood banks near you",
                      style: GoogleFonts.roboto(
                        fontSize: screenSize.width * 0.035,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      body: MovingBackground(
        animationType: AnimationType.translation,
        backgroundColor: const Color.fromARGB(255, 248, 248, 248),
        circles: const [
          MovingCircle(color: Color.fromARGB(65, 230, 132, 125), radius: 120),
          MovingCircle(color: Color.fromARGB(55, 230, 132, 125), radius: 150),
          MovingCircle(color: Color.fromARGB(45, 230, 132, 125), radius: 180),
          MovingCircle(color: Color.fromARGB(35, 230, 132, 125), radius: 200),
        ],
        child: Stack(
          children: [
            // Google Map
            Positioned.fill(
              top: screenSize.height * 0.11,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
                child: GoogleMap(
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  initialCameraPosition: _initialCameraPosition,
                  onMapCreated: (controller) {
                    _googleMapController = controller;
                    setState(() => _isMapInitialized = true);

                    // Make sure to create markers if data is already loaded
                    if (_filteredBloodBanks.isNotEmpty) {
                      _createMarkers();
                    }

                    if (!_isLoading) {
                      _placeUserLocationMarker();
                    }
                  },
                  markers: _markers,
                ),
              ),
            ),

            // Search bar
            Positioned(
              top: screenSize.height * 0.19,
              left: 15,
              right: 20,
              child:
                  Row(children: [
                    Expanded(child:                   
                        //Search TextField
                        Card(
                          color: Colors.white,
                          elevation: 5,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.search,
                                  color: Styles.primaryColor,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextField(
                                    controller: _searchController,
                                    cursorColor: Colors.black,
                                    decoration: InputDecoration(
                                      hintText: 'Blood Bank or Type...',
                                      hintStyle: GoogleFonts.roboto(
                                        color: Colors.grey[500],
                                      ),
                                      border: InputBorder.none,
                                    ),
                                    onChanged: (value) {
                                      _filterBloodBanks(); // your method for search filtering
                                    },
                                  ),
                                ),
                                if (_searchController.text.isNotEmpty)
                                  IconButton(
                                    icon: Icon(Icons.clear, color: Styles.primaryColor,),
                                    onPressed: () {
                                      setState(() {
                                        _searchController.clear();
                                        _filterBloodBanks();
                                      });
                                    },
                                  ),
                              ],
                            ),
                          ),
                        ),
                        
                    ),
                    // My Location Button
                    FadeInRight(
                      duration: const Duration(milliseconds: 800),
                      child: FloatingActionButton(
                        heroTag: 'locationBtn',
                        backgroundColor: Colors.white,
                        foregroundColor: Styles.primaryColor,
                        mini: false,
                        onPressed: _requestLocationPermission,
                        child: const Icon(Icons.my_location),
                      ),
                    ),
                  ],),
            ),

            // Dropdown list for search results
            if (_isSearching)
              Positioned(
                top: screenSize.height * 0.25 + 20,
                left: 20,
                right: 20,
                child: FadeInDown(
                  duration: const Duration(milliseconds: 400),
                  child: Container(
                    margin: const EdgeInsets.only(top: 5), // Margin from search bar
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 5,
                          spreadRadius: 0,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),

                    constraints: _filteredBloodBanks.isEmpty
                    ? null // No constraints when there are no results
                    : BoxConstraints(
                        maxHeight: (_filteredBloodBanks.length * 75.0).clamp(0.0, screenSize.height 
                        * 0.3),
                      ),
                    child: _filteredBloodBanks.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(15),
                            child: Text(
                              'No results for "${_searchController.text}"',
                              style: GoogleFonts.roboto(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          )
                        : Align(
                            alignment: Alignment.topCenter,
                            child: ListView.separated(
                              shrinkWrap: true,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              itemCount: _filteredBloodBanks.length,
                              separatorBuilder: (context, index) => Divider(
                                color: Colors.grey[200],
                                height: 1,
                              ),
                                  itemBuilder: (context, index) {
                                    final bank = _filteredBloodBanks[index];
                                    List<String> availableBloodTypes =
                                        _bloodBankInventoryCache[bank['bloodBankId']] ?? [];

                                    return ListTile(
                                      title: Text(
                                        bank['bloodBankName'],
                                        style: GoogleFonts.montserrat(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                        ),
                                      ),
                                      subtitle: Text(
                                        availableBloodTypes.isEmpty
                                            ? 'No blood types available'
                                            : 'Available: ${availableBloodTypes.join(', ')}',
                                        style: GoogleFonts.roboto(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      trailing: Icon(
                                        Icons.location_on,
                                        color: Styles.primaryColor,
                                      ),
                                      onTap: () {
                                        setState(() {
                                          _searchController.clear();
                                          _isSearching = false;
                                        });

                                        final LatLng position = LatLng(
                                          bank['latitude'],
                                          bank['longitude'],
                                        );

                                        _googleMapController.animateCamera(
                                          CameraUpdate.newLatLngZoom(position, 15),
                                        );
                                      },
                                    );
                                  },
                                ),
                              ),
                          
                          ),
                  ),
                ),



            // Action buttons
            Positioned(
              bottom: 20,
              right: 20,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Zoom In Button
                  FadeInRight(
                    duration: const Duration(milliseconds: 850),
                    child: FloatingActionButton(
                      heroTag: 'zoomInBtn',
                      backgroundColor: Colors.white,
                      foregroundColor: Styles.primaryColor,
                      mini: false,
                      onPressed: () {
                        _googleMapController.animateCamera(CameraUpdate.zoomIn());
                      },
                      child: const Icon(Icons.add),
                    ),
                  ),
                  const SizedBox(height: 5),
                  // Zoom Out Button
                  FadeInRight(
                    duration: const Duration(milliseconds: 900),
                    child: FloatingActionButton(
                      heroTag: 'zoomOutBtn',
                      backgroundColor: Colors.white,
                      foregroundColor: Styles.primaryColor,
                      mini: false,
                      onPressed: () {
                        _googleMapController.animateCamera(CameraUpdate.zoomOut());
                      },
                      child: const Icon(Icons.remove),
                    ),
                  ),
                ],
              ),
            ),

            // Find Nearest Blood Bank Button
            Positioned(
              bottom: 20,
              left: 20,
              right: 80,
              child: FadeInUp(
                duration: const Duration(milliseconds: 800),
                child: ElevatedButton(
                  onPressed: _locateNearestBloodBank,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 55),
                    backgroundColor: Styles.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 5,
                    shadowColor: Styles.primaryColor.withOpacity(0.5),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.near_me),
                      const SizedBox(width: 5),
                      Text(
                        'Find Nearest Blood Bank',
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Loading Indicator
            if (_isLoading)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.3),
                  child: Center(
                    child: Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(
                              color: Styles.primaryColor,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Loading...',
                              style: GoogleFonts.roboto(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
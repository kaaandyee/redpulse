// ignore_for_file: avoid_print, deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:redpulse/features/models/reservation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:redpulse/features/screens/user/sub/reservationdetails.dart';
import 'package:redpulse/utilities/constants/styles.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_moving_background/flutter_moving_background.dart';
import 'package:flutter_moving_background/enums/animation_types.dart';
import 'package:animate_do/animate_do.dart';

class ReservationScreen extends StatefulWidget {
  const ReservationScreen({super.key});

  @override
  ReservationScreenState createState() => ReservationScreenState();
}

class ReservationScreenState extends State<ReservationScreen> {
  late String userId = '';
  late Stream<List<ReservationModel>> _reservationsStream;
  final Map<String, String> _bloodBankNames = {};
  bool isLoading = true;
  String searchQuery = '';

  // Filter options
  String? selectedStatusFilter;
  String? selectedBloodTypeFilter;
  DateTime? startDateFilter;
  DateTime? endDateFilter;
  int? minQuantityFilter;
  int? maxQuantityFilter;

  final TextEditingController _searchController = TextEditingController();
  final List<String> bloodTypes = [
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-'
  ];
  final List<String> statusTypes = [
    'Pending',
    'Reserved',
    'Cancelled',
    'Completed',
    'All'
  ];

  @override
  void initState() {
    super.initState();
    fetchUserId();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Function to fetch the current user's UID
  Future<void> fetchUserId() async {
    setState(() => isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        userId = user.uid;
      });
      _reservationsStream = FirebaseFirestore.instance
          .collection('reservations')
          .where('userId', isEqualTo: userId)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          return ReservationModel.fromFirestore(doc.id, doc.data());
        }).toList();
      });
      setState(() => isLoading = false);
    } else {
      print('No user is logged in.');
      setState(() => isLoading = false);
    }
  }

  // Fetch blood bank name by ID with caching
  Future<String> getBloodBankName(String bloodBankId) async {
    // Return cached name if available
    if (_bloodBankNames.containsKey(bloodBankId)) {
      return _bloodBankNames[bloodBankId]!;
    }

    try {
      final bloodBankDoc = await FirebaseFirestore.instance
          .collection('bloodbanks')
          .doc(bloodBankId)
          .get();

      if (bloodBankDoc.exists) {
        final name = bloodBankDoc.data()?['bloodBankName'] ??
            'Unknown Blood Bank';
        // Cache the result
        _bloodBankNames[bloodBankId] = name;
        return name;
      }
      return 'Unknown Blood Bank';
    } catch (e) {
      print('Error fetching blood bank name: $e');
      return 'Error Loading Name';
    }
  }

  // Sort reservations by status
  List<ReservationModel> sortReservations(List<ReservationModel> reservations) {
  reservations.sort((a, b) {
    int getStatusPriority(String status) {
      switch (status) {
        case 'Pending':
          return 1;
        case 'Reserved':
          return 2;
        case 'Cancelled':
          return 3;
        case 'Completed':
          return 4;
        default:
          return 5; // Unknown status gets lowest priority
      }
    }

    int priorityA = getStatusPriority(a.status);
    int priorityB = getStatusPriority(b.status);

    if (priorityA != priorityB) {
      return priorityA - priorityB;
    }

    // Same priority → sort by validUntil (descending)
    return b.validUntil.compareTo(a.validUntil);
  });

  return reservations;
}


  // Filter reservations
  List<ReservationModel> filterReservations(
      List<ReservationModel> reservations) {
    return reservations.where((reservation) {
      // Check if reservation matches the search query
      bool matchesSearch = searchQuery.isEmpty ||
          _bloodBankNames[reservation.bloodBankId]?.toLowerCase().contains(
              searchQuery.toLowerCase()) == true ||
          reservation.bloodType.toLowerCase().contains(
              searchQuery.toLowerCase()) ||
          reservation.status.toLowerCase().contains(searchQuery.toLowerCase());

      // Check if reservation matches the selected status filter
      bool matchesStatus = selectedStatusFilter == null ||
          selectedStatusFilter == 'All' ||
          reservation.status == selectedStatusFilter;

      // Check if reservation matches the selected blood type filter
      bool matchesBloodType = selectedBloodTypeFilter == null ||
          reservation.bloodType == selectedBloodTypeFilter;

      // Check if reservation falls within the selected date range
      bool matchesDateRange = true;
      if (startDateFilter != null && endDateFilter != null) {
        matchesDateRange = reservation.validUntil.isAfter(startDateFilter!) &&
            reservation.validUntil.isBefore(
                endDateFilter!.add(const Duration(days: 1)));
      }

      // Check if reservation falls within the quantity range
      bool matchesQuantity = true;
      if (minQuantityFilter != null) {
        matchesQuantity = reservation.quantity >= minQuantityFilter!;
      }
      if (maxQuantityFilter != null && matchesQuantity) {
        matchesQuantity = reservation.quantity <= maxQuantityFilter!;
      }

      return matchesSearch && matchesStatus && matchesBloodType &&
          matchesDateRange && matchesQuantity;
    }).toList();
  }

  // Show filter dialog
  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          StatefulBuilder(
              builder: (context, setModalState) {
                return Container(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery
                        .of(context)
                        .viewInsets
                        .bottom + 20,
                    top: 20,
                    left: 20,
                    right: 20,
                  ),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(25),
                      topRight: Radius.circular(25),
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Filter Reservations',
                              style: GoogleFonts.montserrat(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: Styles.primaryColor,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Status filter
                        Text(
                          'Status',
                          style: GoogleFonts.montserrat(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 10,
                          children: statusTypes.map((status) =>
                              ChoiceChip(
                                label: Text(status),
                                selected: selectedStatusFilter == status,
                                onSelected: (selected) {
                                  setModalState(() {
                                    selectedStatusFilter =
                                    selected ? status : null;
                                  });
                                },
                                selectedColor: Styles.primaryColor,
                                labelStyle: TextStyle(
                                  color: selectedStatusFilter == status ? Colors
                                      .white : Colors.black,
                                ),
                              )
                          ).toList(),
                        ),

                        const SizedBox(height: 20),

                        // Blood Type filter
                        Text(
                          'Blood Type',
                          style: GoogleFonts.montserrat(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 10,
                          children: bloodTypes.map((type) =>
                              ChoiceChip(
                                label: Text(type),
                                selected: selectedBloodTypeFilter == type,
                                onSelected: (selected) {
                                  setModalState(() {
                                    selectedBloodTypeFilter =
                                    selected ? type : null;
                                  });
                                },
                                selectedColor: Styles.primaryColor,
                                labelStyle: TextStyle(
                                  color: selectedBloodTypeFilter == type
                                      ? Colors.white
                                      : Colors.black,
                                ),
                              )
                          ).toList(),
                        ),

                        const SizedBox(height: 20),

                        // Date Range filter
                        Text(
                          'Valid Until Date Range',
                          style: GoogleFonts.montserrat(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: startDateFilter ??
                                        DateTime.now(),
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime(2101),
                                  );
                                  if (picked != null) {
                                    setModalState(() {
                                      startDateFilter = picked;
                                    });
                                  }
                                },
                                child: Text(
                                  startDateFilter != null
                                      ? DateFormat('MM/dd/yyyy').format(
                                      startDateFilter!)
                                      : 'Start Date',
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: endDateFilter ??
                                        DateTime.now(),
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime(2101),
                                  );
                                  if (picked != null) {
                                    setModalState(() {
                                      endDateFilter = picked;
                                    });
                                  }
                                },
                                child: Text(
                                  endDateFilter != null
                                      ? DateFormat('MM/dd/yyyy').format(
                                      endDateFilter!)
                                      : 'End Date',
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Quantity Range filter
                        Text(
                          'Quantity Range',
                          style: GoogleFonts.montserrat(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                decoration: const InputDecoration(
                                  labelText: 'Min',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                                initialValue: minQuantityFilter?.toString(),
                                onChanged: (value) {
                                  if (value.isNotEmpty) {
                                    setModalState(() {
                                      minQuantityFilter = int.tryParse(value);
                                    });
                                  } else {
                                    setModalState(() {
                                      minQuantityFilter = null;
                                    });
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextFormField(
                                decoration: const InputDecoration(
                                  labelText: 'Max',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                                initialValue: maxQuantityFilter?.toString(),
                                onChanged: (value) {
                                  if (value.isNotEmpty) {
                                    setModalState(() {
                                      maxQuantityFilter = int.tryParse(value);
                                    });
                                  } else {
                                    setModalState(() {
                                      maxQuantityFilter = null;
                                    });
                                  }
                                },
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 30),

                        // Apply and Reset buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  setModalState(() {
                                    selectedStatusFilter = null;
                                    selectedBloodTypeFilter = null;
                                    startDateFilter = null;
                                    endDateFilter = null;
                                    minQuantityFilter = null;
                                    maxQuantityFilter = null;
                                  });
                                },
                                child: Text(
                                  'Reset',
                                  style: GoogleFonts.roboto(
                                      color: Colors.grey[700]),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Styles.primaryColor,
                                ),
                                onPressed: () {
                                  setState(() {
                                    // Apply filters
                                  });
                                  Navigator.pop(context);
                                },
                                child: Text(
                                  'Apply',
                                  style: GoogleFonts.roboto(
                                      color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }
          ),
    );
  }

  // Build section header
  Widget _buildSectionHeader(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      margin: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          Container(
            height: 24,
            width: 4,
            decoration: BoxDecoration(
              color: Styles.primaryColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery
        .of(context)
        .size;

    return Scaffold(
      backgroundColor: Color.fromARGB(255, 248, 248, 248),
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
                      "My Reservations",
                      style: GoogleFonts.montserrat(
                        fontSize: screenSize.width * 0.055,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: screenSize.height * 0.005),
                    Text(
                      "Manage your blood reservations",
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
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: Styles.primaryColor))
          : MovingBackground(
        animationType: AnimationType.translation,
        backgroundColor: const Color.fromARGB(255, 248, 248, 248),
        circles: const [
          MovingCircle(color: Color.fromARGB(65, 230, 132, 125), radius: 120),
          MovingCircle(color: Color.fromARGB(55, 230, 132, 125), radius: 150),
          MovingCircle(color: Color.fromARGB(45, 230, 132, 125), radius: 180),
          MovingCircle(color: Color.fromARGB(35, 230, 132, 125), radius: 200),
        ],
        child: StreamBuilder<List<ReservationModel>>(
          stream: _reservationsStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                  child: CircularProgressIndicator(color: Styles.primaryColor));
            }

            if (snapshot.hasError) {
              return Center(
                child: FadeInUp(
                  duration: const Duration(milliseconds: 800),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 60,
                          color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading reservations',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        snapshot.error.toString(),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: FadeInUp(
                  duration: const Duration(milliseconds: 800),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.event_busy, size: 60, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No reservations found',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Make a reservation from a blood bank',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            // Sort and filter the reservations
            var allReservations = snapshot.data!;
            var filteredReservations = filterReservations(allReservations);
            var sortedReservations = sortReservations(filteredReservations);

            // Separate reservations by status
            var pendingReservations = sortedReservations.where((r) =>
            r.status == 'Pending').toList();

            var reservedReservations = sortedReservations.where((r) => 
            r.status == 'Reserved').toList();

            var completedReservations = sortedReservations.where((r) =>
            r.status == 'Completed').toList();

            var cancelledReservations = sortedReservations.where((r) => 
            r.status == 'Cancelled').toList();

            return Column(
              children: [
                // Extra spacing for the AppBar
                SizedBox(height: screenSize.height * 0.18),

                // Search bar and filter button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: FadeInDown(
                    duration: const Duration(milliseconds: 900),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.15),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: _searchController,
                              cursorColor: Colors.black,
                              onChanged: (value) {
                                setState(() {
                                  searchQuery = value;
                                });
                              },
                              decoration: InputDecoration(
                                hintText: 'Reservations...',
                                hintStyle: GoogleFonts.roboto(
                                        color: Colors.grey[500],),
                                prefixIcon: Icon(
                                  Icons.search,
                                  color: Styles.primaryColor,
                                ),
                                suffixIcon: searchQuery.isNotEmpty
                                    ? IconButton(
                                  icon: Icon(
                                      Icons.clear, color: Styles.primaryColor,),
                                  onPressed: () {
                                    setState(() {
                                      _searchController.clear();
                                      searchQuery = '';
                                    });
                                  },
                                )
                                    : null,
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                    vertical: 15),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          decoration: BoxDecoration(
                            color: Styles.primaryColor,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.15),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: IconButton(
                            onPressed: _showFilterDialog,
                            icon: const Icon(
                                Icons.filter_list, color: Colors.white),
                            tooltip: 'Filter reservations',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // Active filters display
                if (selectedStatusFilter != null ||
                    selectedBloodTypeFilter != null ||
                    startDateFilter != null || minQuantityFilter != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: FadeInDown(
                      duration: const Duration(milliseconds: 950),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 15, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: Colors.blue.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.filter_alt_outlined,
                                color: Colors.blue[700], size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Filters applied',
                                style: GoogleFonts.roboto(
                                  color: Colors.blue[700],
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  selectedStatusFilter = null;
                                  selectedBloodTypeFilter = null;
                                  startDateFilter = null;
                                  endDateFilter = null;
                                  minQuantityFilter = null;
                                  maxQuantityFilter = null;
                                });
                              },
                              child: Text(
                                'Clear all',
                                style: GoogleFonts.roboto(
                                  color: Colors.blue[700],
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // Reservations list
                Expanded(
                  child: pendingReservations.isEmpty &&
                      reservedReservations.isEmpty && completedReservations.isEmpty &&
                      cancelledReservations.isEmpty
                      ? Center(
                    child: FadeInUp(
                      duration: const Duration(milliseconds: 800),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off, size: 60,
                              color: Colors.grey[400]),
                          const SizedBox(height: 10),
                          Text(
                            'No Matching Reservations',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 0),
                          Text(
                            'Try adjusting your search filters',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                      : ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 20),
                    children: [
                      // Pending reservations section
                      if (pendingReservations.isNotEmpty) _buildSectionHeader(
                          'Pending Reservations'),
                      if (pendingReservations.isNotEmpty)
                        ...pendingReservations
                            .asMap()
                            .entries
                            .map((entry) {
                          int index = entry.key;
                          ReservationModel reservation = entry.value;
                          return _buildReservationTile(reservation, index);
                        }),

                      // Other reservations section
                      if (reservedReservations.isNotEmpty) _buildSectionHeader(
                          'Approved Reservations'),
                      if (reservedReservations.isNotEmpty)
                        ...reservedReservations
                            .asMap()
                            .entries
                            .map((entry) {
                          int index = entry.key;
                          ReservationModel reservation = entry.value;
                          return _buildReservationTile(reservation, index);
                        }),

                      // Completed reservations section
                      if (completedReservations.isNotEmpty) _buildSectionHeader(
                          'Completed Reservations'),
                      if (completedReservations.isNotEmpty)
                        ...completedReservations
                            .asMap()
                            .entries
                            .map((entry) {
                          int index = entry.key;
                          ReservationModel reservation = entry.value;
                          return _buildReservationTile(reservation, index);
                        }),
                      // Cancelled reservations section
                      if (cancelledReservations.isNotEmpty) 
                        _buildSectionHeader('Cancelled Reservations'),
                      if (cancelledReservations.isNotEmpty) 
                        ...cancelledReservations.asMap().entries.map((entry) {
                          int index = entry.key;
                          ReservationModel reservation = entry.value;
                          return _buildReservationTile(reservation, index);
                        }),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildReservationTile(ReservationModel reservation, int index) {
    // Determine the tile color and icon based on the reservation status
    Color tileColor;
    IconData statusIcon;

    if (reservation.status == 'Pending') {
      tileColor = Styles.frontColor;
      statusIcon = Icons.hourglass_empty;
    } else if (reservation.status == 'Reserved') {
      tileColor = Colors.green[700] ?? Colors.green;
      statusIcon = Icons.check_circle;
    } else if (reservation.status == 'Cancelled') {
      tileColor = Styles.complementColor;
      statusIcon = Icons.cancel;
    } else if (reservation.status == 'Completed') {
      tileColor = Colors.blue[700] ?? Colors.blue;
      statusIcon = Icons.task_alt;
    } else {
      tileColor = Styles.tertiaryColor;
      statusIcon = Icons.info;
    }

    return FadeInUp(
      duration: Duration(milliseconds: 800 + (index * 100)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            contentPadding: const EdgeInsets.symmetric(
                vertical: 16, horizontal: 15),
            tileColor: tileColor,
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                statusIcon,
                size: 30,
                color: Colors.white,
              ),
            ),
            title: FutureBuilder<String>(
              future: getBloodBankName(reservation.bloodBankId),
              builder: (context, nameSnapshot) {
                return Text(
                  nameSnapshot.connectionState == ConnectionState.waiting
                      ? 'Loading...'
                      : nameSnapshot.data ?? 'Unknown Blood Bank',
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                );
              },
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 0.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    'Blood Type ${reservation.bloodType}',
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    '|',
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    '${reservation.quantity} Units',
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            trailing: Icon(
              Icons.arrow_forward_ios,
              color: Colors.white,
              size: 20,
            ),
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ReservationDetailsScreen(
                        reservationId: reservation.reservationId,
                      ),
                ),
              );

              // Show beautiful SnackBar if reservation was cancelled successfully
              if (result == true) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.white),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'Reservation cancelled successfully',
                            style: GoogleFonts.roboto(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: Styles.primaryColor,
                    behavior: SnackBarBehavior.floating,
                    margin: const EdgeInsets.all(16),
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    duration: const Duration(seconds: 3),
                    action: SnackBarAction(
                      label: 'DISMISS',
                      textColor: Colors.white,
                      onPressed: () {
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      },
                    ),
                  ),
                );

                // Refresh the UI if needed
                setState(() {});
              }
            },
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:redpulse/utilities/constants/styles.dart';
import 'package:google_fonts/google_fonts.dart';
import '../user/sub/reservationdetails.dart';

class AdminReservationScreen extends StatefulWidget {
  final String bloodBankId;

  const AdminReservationScreen({Key? key, required this.bloodBankId})
      : super(key: key);

  @override
  State<AdminReservationScreen> createState() => _AdminReservationScreenState();
}

class _AdminReservationScreenState extends State<AdminReservationScreen> {
  List<Map<String, dynamic>> _reservations = [];
  bool _isLoading = true;
  String _errorMessage = '';
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
    'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'
  ];
  final List<String> statusTypes = [
    'Pending', 'Reserved', 'Cancelled', 'Completed', 'All'
  ];

  @override
  void initState() {
    super.initState();
    _fetchReservations();
  }

Future<void> _fetchReservations() async {
  setState(() {
    _isLoading = true;
    _errorMessage = '';
  });

  try {
    // Add debug output to verify bloodBankId
    print("Fetching reservations for bloodBankId: ${widget.bloodBankId}");

    final reservationSnapshot = await FirebaseFirestore.instance
        .collection('reservations')
        .where('bloodBankId', isEqualTo: widget.bloodBankId)
        .get();

    // Debug: Check if query returned documents
    print("Query returned ${reservationSnapshot.docs.length} documents");

    List<Map<String, dynamic>> reservations = [];
    for (var doc in reservationSnapshot.docs) {
      Map<String, dynamic> data = doc.data();
      // Debug: Print document data
      print("Document ID: ${doc.id}, Data: $data");

      String userId = data['userId'] ?? '';
      String userName = 'Unknown User';
      if (userId.isNotEmpty) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();
        if (userDoc.exists) {
          userName = userDoc.data()?['fullName'] ?? 'Unknown User';
        }
      }

      // Safer timestamp handling
      DateTime? reservedAt;
      if (data['reservedAt'] != null) {
        try {
          if (data['reservedAt'] is Timestamp) {
            reservedAt = (data['reservedAt'] as Timestamp).toDate();
          } else if (data['reservedAt'] is String) {
            // Try to parse if it's a string date
            reservedAt = DateTime.tryParse(data['reservedAt']);
          }
        } catch (e) {
          print("Error parsing reservedAt: $e");
        }
      }

      DateTime? validUntil;
      if (data['validUntil'] != null) {
        try {
          if (data['validUntil'] is Timestamp) {
            validUntil = (data['validUntil'] as Timestamp).toDate();
          } else if (data['validUntil'] is String) {
            validUntil = DateTime.tryParse(data['validUntil']);
          }
        } catch (e) {
          print("Error parsing validUntil: $e");
        }
      }

      reservations.add({
        'id': doc.id,
        ...data,
        'userName': userName,
        'reservationDate': reservedAt,
        'validUntil': validUntil,
      });
    }

    setState(() {
      _reservations = reservations;
      _isLoading = false;
    });

    // Debug: Print resulting reservations
    print("Processed ${_reservations.length} reservations");

  } catch (e) {
    print("Error in _fetchReservations: $e");
    setState(() {
      _errorMessage = 'Error loading reservations: $e';
      _isLoading = false;
    });
  }
}

  // --- FILTERS ---
  List<Map<String, dynamic>> filterReservations(List<Map<String, dynamic>> reservations) {
    return reservations.where((reservation) {
      bool matchesSearch = searchQuery.isEmpty ||
          (reservation['userName']?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false) ||
          (reservation['bloodType']?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false) ||
          (reservation['status']?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false);

      bool matchesStatus = selectedStatusFilter == null ||
          selectedStatusFilter == 'All' ||
          reservation['status'] == selectedStatusFilter;

      bool matchesBloodType = selectedBloodTypeFilter == null ||
          reservation['bloodType'] == selectedBloodTypeFilter;

      bool matchesDateRange = true;
      if (startDateFilter != null && endDateFilter != null && reservation['validUntil'] != null) {
        matchesDateRange = reservation['validUntil'].isAfter(startDateFilter!) &&
            reservation['validUntil'].isBefore(endDateFilter!.add(const Duration(days: 1)));
      }

      bool matchesQuantity = true;
      if (minQuantityFilter != null) {
        matchesQuantity = (reservation['quantity'] ?? 0) >= minQuantityFilter!;
      }
      if (maxQuantityFilter != null && matchesQuantity) {
        matchesQuantity = (reservation['quantity'] ?? 0) <= maxQuantityFilter!;
      }

      return matchesSearch && matchesStatus && matchesBloodType && matchesDateRange && matchesQuantity;
    }).toList();
  }

  List<Map<String, dynamic>> sortReservations(List<Map<String, dynamic>> reservations) {
    reservations.sort((a, b) {
      if (a['status'] == 'Pending' && b['status'] != 'Pending') return -1;
      if (a['status'] != 'Pending' && b['status'] == 'Pending') return 1;
      if (a['status'] == 'Completed' && b['status'] != 'Completed') return 1;
      if (a['status'] != 'Completed' && b['status'] == 'Completed') return -1;
      return (b['validUntil'] ?? DateTime(2000)).compareTo(a['validUntil'] ?? DateTime(2000));
    });
    return reservations;
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              top: 20, left: 20, right: 20,
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
                      Text('Filter Reservations',
                        style: GoogleFonts.montserrat(
                          fontSize: 22, fontWeight: FontWeight.w700, color: Styles.primaryColor,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text('Status', style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    children: statusTypes.map((status) =>
                        ChoiceChip(
                          label: Text(status),
                          selected: selectedStatusFilter == status,
                          onSelected: (selected) {
                            setModalState(() {
                              selectedStatusFilter = selected ? status : null;
                            });
                          },
                          selectedColor: Styles.primaryColor,
                          labelStyle: TextStyle(
                            color: selectedStatusFilter == status ? Colors.white : Colors.black,
                          ),
                        )
                    ).toList(),
                  ),
                  const SizedBox(height: 20),
                  Text('Blood Type', style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    children: bloodTypes.map((type) =>
                        ChoiceChip(
                          label: Text(type),
                          selected: selectedBloodTypeFilter == type,
                          onSelected: (selected) {
                            setModalState(() {
                              selectedBloodTypeFilter = selected ? type : null;
                            });
                          },
                          selectedColor: Styles.primaryColor,
                          labelStyle: TextStyle(
                            color: selectedBloodTypeFilter == type ? Colors.white : Colors.black,
                          ),
                        )
                    ).toList(),
                  ),
                  const SizedBox(height: 20),
                  Text('Valid Until Date Range', style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: startDateFilter ?? DateTime.now(),
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
                                ? DateFormat('MM/dd/yyyy').format(startDateFilter!)
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
                              initialDate: endDateFilter ?? DateTime.now(),
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
                                ? DateFormat('MM/dd/yyyy').format(endDateFilter!)
                                : 'End Date',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text('Quantity Range', style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w600)),
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
                            setModalState(() {
                              minQuantityFilter = value.isNotEmpty ? int.tryParse(value) : null;
                            });
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
                            setModalState(() {
                              maxQuantityFilter = value.isNotEmpty ? int.tryParse(value) : null;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
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
                          child: Text('Reset', style: GoogleFonts.roboto(color: Colors.grey[700])),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Styles.primaryColor,
                          ),
                          onPressed: () {
                            setState(() {});
                            Navigator.pop(context);
                          },
                          child: Text('Apply', style: GoogleFonts.roboto(color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Helper methods - moved before build method
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

  Widget _buildReservationTile(Map<String, dynamic> reservation, int index) {
    Color tileColor;
    IconData statusIcon;

    if (reservation['status'] == 'Pending') {
      tileColor = Styles.frontColor;
      statusIcon = Icons.hourglass_empty;
    } else if (reservation['status'] == 'Reserved') {
      tileColor = Colors.green[700] ?? Colors.green;
      statusIcon = Icons.check_circle;
    } else if (reservation['status'] == 'Cancelled') {
      tileColor = Styles.complementColor;
      statusIcon = Icons.cancel;
    } else if (reservation['status'] == 'Completed') {
      tileColor = Colors.blue[700] ?? Colors.blue;
      statusIcon = Icons.task_alt;
    } else {
      tileColor = Styles.tertiaryColor;
      statusIcon = Icons.info;
    }

    return Padding(
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
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          tileColor: tileColor,
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              statusIcon,
              size: 36,
              color: Colors.white,
            ),
          ),
          title: Text(
            reservation['userName'] ?? 'Unknown User',
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildReservationDetail('Blood Type', reservation['bloodType']),
                _buildReservationDetail('Quantity', '${reservation['quantity']} units'),
                _buildReservationDetail('Status', reservation['status']),
                _buildReservationDetail(
                  'Valid Until',
                  reservation['validUntil'] != null
                      ? DateFormat('MM/dd/yyyy').format(reservation['validUntil'])
                      : 'N/A',
                ),
              ],
            ),
          ),
          trailing: Icon(
            Icons.arrow_forward_ios,
            color: Colors.white.withOpacity(0.7),
            size: 20,
          ),
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ReservationDetailsScreen(
                  reservationId: reservation['id'],
                ),
              ),
            );
            _fetchReservations();
          },
        ),
      ),
    );
  }

  Widget _buildReservationDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: GoogleFonts.roboto(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.roboto(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // Add this method to process stream data
  Future<void> _processStreamData(List<QueryDocumentSnapshot> docs) async {
    try {
      List<Map<String, dynamic>> updatedReservations = [];

      for (var doc in docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        // Find existing user name from cached data first
        String userId = data['userId'] ?? '';
        String userName = 'Unknown User';

        // Try to find user name in existing reservations to avoid unnecessary Firebase calls
        for (var existing in _reservations) {
          if (existing['id'] == doc.id && existing['userName'] != 'Unknown User') {
            userName = existing['userName'];
            break;
          }
        }

        // If we couldn't find the username in cache, fetch it from Firebase
        if (userName == 'Unknown User' && userId.isNotEmpty) {
          try {
            final userDoc = await FirebaseFirestore.instance
                .collection('users')
                .doc(userId)
                .get();

            if (userDoc.exists) {
              userName = userDoc.data()?['fullName'] ?? 'Unknown User';
              print("Fetched user: $userName for reservation ${doc.id}");
            }
          } catch (e) {
            print("Error fetching user data: $e");
          }
        }

        // Process timestamps
        DateTime? reservedAt;
        if (data['reservedAt'] != null) {
          if (data['reservedAt'] is Timestamp) {
            reservedAt = (data['reservedAt'] as Timestamp).toDate();
          }
        }

        DateTime? validUntil;
        if (data['validUntil'] != null) {
          if (data['validUntil'] is Timestamp) {
            validUntil = (data['validUntil'] as Timestamp).toDate();
          }
        }

        updatedReservations.add({
          'id': doc.id,
          ...data,
          'userName': userName,
          'reservationDate': reservedAt,
          'validUntil': validUntil,
        });
      }

      if (mounted) {
        setState(() {
          _reservations = updatedReservations;
        });
      }
    } catch (e) {
      print("Error processing stream data: $e");
    }
  }

@override
Widget build(BuildContext context) {
  final screenSize = MediaQuery.of(context).size;

  // Filter and sort reservations
  var filtered = filterReservations(_reservations);
  var sorted = sortReservations(filtered);

  // Section reservations
  var pending = sorted.where((r) => r['status'] == 'Pending').toList();
  var completed = sorted.where((r) => r['status'] == 'Completed').toList();
  var other = sorted.where((r) => r['status'] != 'Pending' && r['status'] != 'Completed').toList();

  return Scaffold(
    extendBodyBehindAppBar: true,
    appBar: PreferredSize(
      preferredSize: Size.fromHeight(screenSize.height * 0.11),
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
              vertical: screenSize.height * 0.015,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.calendar_today,
                        color: Colors.white, size: 32),
                    const SizedBox(width: 12),
                    Text(
                      "Reservations",
                      style: GoogleFonts.montserrat(
                        fontSize: screenSize.width * 0.06,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      onPressed: _fetchReservations,
                    )
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
    body: Column(
      children: [
        SizedBox(height: screenSize.height * 0.18),

        // Search bar and filter button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search reservations...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[200],
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value;
                    });
                  },
                ),
              ),
              const SizedBox(width: 10),
              InkWell(
                onTap: _showFilterDialog,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Styles.primaryColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.filter_list, color: Colors.white),
                ),
              )
            ],
          ),
        ),

        const SizedBox(height: 10),

        // Active filters display
        if (selectedStatusFilter != null ||
            selectedBloodTypeFilter != null ||
            startDateFilter != null ||
            minQuantityFilter != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (selectedStatusFilter != null)
                    Chip(
                      label: Text(selectedStatusFilter!),
                      onDeleted: () => setState(() => selectedStatusFilter = null),
                      backgroundColor: Colors.blue.withOpacity(0.2),
                    ),
                  if (selectedBloodTypeFilter != null)
                    Chip(
                      label: Text(selectedBloodTypeFilter!),
                      onDeleted: () => setState(() => selectedBloodTypeFilter = null),
                      backgroundColor: Colors.red.withOpacity(0.2),
                    ),
                  if (startDateFilter != null && endDateFilter != null)
                    Chip(
                      label: Text('${DateFormat('MM/dd/yy').format(startDateFilter!)} - ${DateFormat('MM/dd/yy').format(endDateFilter!)}'),
                      onDeleted: () => setState(() {
                        startDateFilter = null;
                        endDateFilter = null;
                      }),
                      backgroundColor: Colors.green.withOpacity(0.2),
                    ),
                  if (minQuantityFilter != null || maxQuantityFilter != null)
                    Chip(
                      label: Text(
                        minQuantityFilter != null && maxQuantityFilter != null
                            ? '${minQuantityFilter!} - ${maxQuantityFilter!} units'
                            : minQuantityFilter != null
                                ? '≥ ${minQuantityFilter!} units'
                                : '≤ ${maxQuantityFilter!} units',
                      ),
                      onDeleted: () => setState(() {
                        minQuantityFilter = null;
                        maxQuantityFilter = null;
                      }),
                      backgroundColor: Colors.purple.withOpacity(0.2),
                    ),
                ],
              ),
            ),
          ),

        // Reservations list with Stream and pull-down refresh
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('reservations')
                .where('bloodBankId', isEqualTo: widget.bloodBankId)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return RefreshIndicator(
                  onRefresh: _fetchReservations,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.7,
                        child: Center(
                          child: Text('Error: ${snapshot.error}'),
                        ),
                      ),
                    ],
                  ),
                );
              }

              // Use the stream data if available
              if (snapshot.hasData && snapshot.connectionState == ConnectionState.active) {
                // Process the updated data in the background
                _processStreamData(snapshot.data!.docs);
              }

              return RefreshIndicator(
                onRefresh: _fetchReservations,
                child: pending.isEmpty && other.isEmpty && completed.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.5,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.search_off, size: 60, color: Colors.grey[400]),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No reservations found',
                                    style: GoogleFonts.montserrat(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Pull down to refresh',
                                    style: GoogleFonts.roboto(
                                      fontSize: 14,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      )
                    : ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.only(bottom: 20),
                        children: [
                          if (pending.isNotEmpty) _buildSectionHeader('Pending Reservations'),
                          if (pending.isNotEmpty)
                            ...pending.asMap().entries.map((entry) {
                              int index = entry.key;
                              var reservation = entry.value;
                              return _buildReservationTile(reservation, index);
                            }),
                          if (other.isNotEmpty) _buildSectionHeader('Active Reservations'),
                          if (other.isNotEmpty)
                            ...other.asMap().entries.map((entry) {
                              int index = entry.key;
                              var reservation = entry.value;
                              return _buildReservationTile(reservation, index);
                            }),
                          if (completed.isNotEmpty) _buildSectionHeader('Completed Reservations'),
                          if (completed.isNotEmpty)
                            ...completed.asMap().entries.map((entry) {
                              int index = entry.key;
                              var reservation = entry.value;
                              return _buildReservationTile(reservation, index);
                            }),
                        ],
                      ),
              );
            },
          ),
        ),
      ],
    ),
  );
}
}
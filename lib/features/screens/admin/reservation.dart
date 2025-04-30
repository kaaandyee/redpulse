import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:redpulse/utilities/constants/styles.dart';

import '../user/sub/reservationdetails.dart'; // Import the details screen

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

  @override
  void initState() {
    super.initState();
    _fetchReservations();
  }

// Add this lifecycle method to refresh when returning to the screen
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _fetchReservations();
  }

  Future<void> _fetchReservations() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      print('Fetching reservations for blood bank ID: ${widget.bloodBankId}');

      // Get reservations for this blood bank - Use snapshots() instead of get() for real-time updates
      final Stream<QuerySnapshot> reservationStream = FirebaseFirestore.instance
          .collection('reservations')
          .where('bloodBankId', isEqualTo: widget.bloodBankId)
          .snapshots();

      // Listen to the stream once to populate initial data
      final QuerySnapshot reservationSnapshot = await reservationStream.first;

      print('Found ${reservationSnapshot.docs.length} reservations');

      List<Map<String, dynamic>> reservations = [];

      // Process each reservation
      for (var doc in reservationSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        String userId = data['userId'] ?? '';

        print('Processing reservation: ${doc.id}, userId: $userId');

        // Get user name
        String userName = 'Unknown User';
        if (userId.isNotEmpty) {
          try {
            final userDoc = await FirebaseFirestore.instance
                .collection('users')
                .doc(userId)
                .get();

            if (userDoc.exists) {
              userName = userDoc.data()?['fullName'] ?? 'Unknown User';
              print('Found user: $userName');
            } else {
              print('User document not found for userId: $userId');
            }
          } catch (e) {
            print('Error fetching user data: $e');
          }
        }

        // Handle the difference between reservedAt and reservationDate fields
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

        reservations.add({
          'id': doc.id,
          ...data,
          'userName': userName,
          'reservationDate': reservedAt, // Map reservedAt to reservationDate for compatibility
        });
      }

      setState(() {
        _reservations = reservations;
        _isLoading = false;
      });

    } catch (e) {
      print('Error loading reservations: $e');
      setState(() {
        _errorMessage = 'Error loading reservations: $e';
        _isLoading = false;
      });
    }
  }

  // Function to update reservation status and Firestore
  Future<void> _updateReservationStatus(String reservationId, String newStatus, int quantity) async {
    // Flag to track if dialog is showing
    bool isDialogShowing = false;

    try {
      // Show loading dialog
      isDialogShowing = true;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          return const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text("Updating reservation status..."),
              ],
            ),
          );
        },
      );

      // Fetch the reservation document to get the bloodBankId and bloodType
      final reservationRef = FirebaseFirestore.instance
          .collection('reservations')
          .doc(reservationId);

      final reservationSnapshot = await reservationRef.get();
      if (!reservationSnapshot.exists) {
        if (mounted && Navigator.canPop(context)) {
          Navigator.of(context, rootNavigator: true).pop();
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Reservation not found.')),
          );
        }
        return;
      }

      var reservationData = reservationSnapshot.data();
      String? bloodBankId = reservationData?['bloodBankId'];
      String? bloodType = reservationData?['bloodType'];

      if (bloodBankId == null || bloodType == null) {
        if (mounted && Navigator.canPop(context)) {
          Navigator.of(context, rootNavigator: true).pop();
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Blood bank ID or blood type not found in reservation.')),
          );
        }
        return;
      }

      // Update the reservation status
      // Update the reservation status
      await reservationRef.update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Check if status is 'Cancelled' and update inventory
      if (newStatus == 'Cancelled') {
        // Access the inventory subcollection of the blood bank
        final inventoryRef = FirebaseFirestore.instance
            .collection('bloodbanks')
            .doc(bloodBankId)
            .collection('inventories')
            .doc(bloodType);

        // Fetch current inventory data
        final inventorySnapshot = await inventoryRef.get();
        if (inventorySnapshot.exists) {
          var inventoryData = inventorySnapshot.data();
          int currentStock = inventoryData?['quantity'] ?? 0;

          // Update the inventory by adding the cancelled reservation's quantity
          await inventoryRef.update({
            'quantity': currentStock + quantity,
            'lastUpdated': FieldValue.serverTimestamp(),
          });
        }
      }

      // Close loading dialog and refresh
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      if (mounted) {
        await _fetchReservations();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reservation status updated to $newStatus'),
            backgroundColor: newStatus == 'Reserved' ? Colors.green : Colors.blue,
          ),
        );
      }
    } catch (e) {
      print('Error updating status: $e');

      // Close loading dialog in case of error
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Function to navigate to the reservation details screen
  void _navigateToReservationDetails(String reservationId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReservationDetailsScreen(
          reservationId: reservationId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Styles.tertiaryColor,
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
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  Text(
                    "Reservation Management",
                    style: Styles.headerStyle2.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Styles.tertiaryColor
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _fetchReservations,
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _errorMessage,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchReservations,
              child: const Text('Retry'),
            ),
          ],
        ),
      )
          : _reservations.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 60, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No reservations found for this blood bank',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      )
          : StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reservations')
            .where('bloodBankId', isEqualTo: widget.bloodBankId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting && _reservations.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          // Use the stream data if available, otherwise use the cached reservations
          List<Map<String, dynamic>> displayReservations = _reservations;

          if (snapshot.hasData && snapshot.data != null) {
            final docs = snapshot.data!.docs;
            if (docs.isNotEmpty) {
              // Process the updated reservations list
              List<Map<String, dynamic>> updatedReservations = [];
              for (var doc in docs) {
                Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

                // Find the user name from the cached data to avoid fetching it again
                String userName = 'Unknown User';
                for (var cachedReservation in _reservations) {
                  if (cachedReservation['id'] == doc.id) {
                    userName = cachedReservation['userName'];
                    break;
                  }
                }

                // Handle the difference between reservedAt and reservationDate fields
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
                });
              }
              displayReservations = updatedReservations;
            }
          }

          return ListView.builder(
            itemCount: displayReservations.length,
            itemBuilder: (context, index) {
              final reservation = displayReservations[index];
              String status = reservation['status'];
              int quantity = reservation['quantity'];
              String reservationId = reservation['id'];
              String userName = reservation['userName'];

              // Determine tile color based on status
              Color tileColor;
              IconData statusIcon;

              if (status == 'Pending') {
                tileColor = Styles.frontColor;
                statusIcon = Icons.hourglass_empty;
              } else if (status == 'Reserved') {
                tileColor = Colors.green[700] ?? Colors.green; // Dark green for approved
                statusIcon = Icons.check_circle;
              } else if (status == 'Cancelled') {
                tileColor = Styles.complementColor;
                statusIcon = Icons.cancel;
              } else if (status == 'Completed') {
                tileColor = Colors.blue[700] ?? Colors.blue;
                statusIcon = Icons.task_alt;
              } else {
                tileColor = Styles.tertiaryColor;
                statusIcon = Icons.info;
              }

              return Card(
                margin: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 10),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  // Make the entire card tappable
                  onTap: () => _navigateToReservationDetails(reservationId),
                  borderRadius: BorderRadius.circular(12),
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        tileColor: tileColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        leading: Icon(
                          statusIcon,
                          size: 36,
                          color: Styles.tertiaryColor,
                        ),
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                userName,
                                style: Styles.headerStyle2.copyWith(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Styles.tertiaryColor,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 22,
                              color: Styles.tertiaryColor,
                            ),
                          ],
                        ),
                        subtitle: Text(
                          '___________________________________\nBlood Type: ${reservation['bloodType']}\nQuantity: $quantity units\nStatus: $status\nMedical Reason: ${reservation['medicalReason']}\nReserved At: ${reservation['reservationDate'] != null
                              ? DateFormat('MM/dd/yyyy').format(reservation['reservationDate'])
                              : 'N/A'}\nValid Until: ${reservation['validUntil'] != null && reservation['validUntil'] is Timestamp
                              ? DateFormat('MM/dd/yyyy').format(reservation['validUntil'].toDate())
                              : reservation['validUntil'] != null && reservation['validUntil'] is DateTime
                              ? DateFormat('MM/dd/yyyy').format(reservation['validUntil'])
                              : 'N/A'}',
                          style: Styles.headerStyle5.copyWith(
                            color: Styles.tertiaryColor,
                          ),
                        ),
                      ),

                      // Action buttons for this reservation
                      if (status == 'Pending')
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.check),
                                  label: const Text('Confirm'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                  onPressed: () async {
                                    await _updateReservationStatus(
                                        reservationId, 'Reserved', quantity);
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.cancel),
                                  label: const Text('Deny'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                  onPressed: () async {
                                    await _updateReservationStatus(
                                        reservationId, 'Cancelled', quantity);
                                  },
                                ),
                              ),
                            ],
                          ),
                        )
                      else if (status == 'Reserved')
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.check_circle),
                                  label: const Text('Complete'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                  onPressed: () async {
                                    await _updateReservationStatus(
                                        reservationId, 'Completed', 0);
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.cancel),
                                  label: const Text('Cancel'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                  onPressed: () async {
                                    await _updateReservationStatus(
                                        reservationId, 'Cancelled', quantity);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
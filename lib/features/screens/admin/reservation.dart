import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:redpulse/utilities/constants/styles.dart';

class AdminReservationScreen extends StatefulWidget {
  final String bloodBankId;

  const AdminReservationScreen({Key? key, required this.bloodBankId})
      : super(key: key);

  @override
  State<AdminReservationScreen> createState() => _AdminReservationScreenState();
}

class _AdminReservationScreenState extends State<AdminReservationScreen> {
  late Stream<List<Map<String, dynamic>>> _reservationsStream;

  @override
  void initState() {
    super.initState();
    fetchReservations();
  }

  void fetchReservations() {
    _reservationsStream = FirebaseFirestore.instance
        .collection('reservations')
        .where('bloodBankId', isEqualTo: widget.bloodBankId)
        .snapshots()
        .asyncMap((snapshot) async {
      List<Map<String, dynamic>> reservations = [];
      for (var doc in snapshot.docs) {
        var reservationData = doc.data();
        // Fetch the user's name from 'users' collection using userId
        String userId = reservationData['userId'];
        String userName = await _fetchUserName(userId);

        reservations.add({
          'id': doc.id,
          ...reservationData,
          'userName': userName, // Add fetched userName
        });
      }
      return reservations;
    });
  }

  // Function to fetch user name by userId
  Future<String> _fetchUserName(String userId) async {
    try {
      final userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userSnapshot.exists) {
        return userSnapshot.data()?['fullName'] ?? 'Unknown User';
      } else {
        return 'Unknown User';
      }
    } catch (e) {
      print('Error fetching user name: $e');
      return 'Unknown User';
    }
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
                    "Reservation",
                    style: Styles.headerStyle2.copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.bold, color: Styles.tertiaryColor
                    ),
                  ),     
                ],
              ),
            ),
          ),
        ),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _reservationsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final reservations = snapshot.data ?? [];

          if (reservations.isEmpty) {
            return const Center(child: Text('No reservations found.'));
          }

          return ListView.builder(
            itemCount: reservations.length,
            itemBuilder: (context, index) {
              final reservation = reservations[index];
              String status = reservation['status'];
              int quantity = reservation['quantity']; // Get the quantity from reservation data
    String reservationId = reservation['id'];
              // Determine tile color based on status
              Color tileColor;
              if (status == 'Pending') {
                tileColor = Styles.frontColor;
              } else if (status == 'Reserved') {
                tileColor = Styles.primaryColor;
              } else if (status == 'Cancelled') {
                tileColor = Styles.complementColor;
              } else {
                tileColor = Styles.tertiaryColor;
              }

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: ListTile(
                  shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                  contentPadding: const EdgeInsets.all(20),
                  tileColor: tileColor,
                  title: Text(
                    'Blood Type: ${reservation['bloodType']}',
                    style: Styles.headerStyle2.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Styles.tertiaryColor,
                    ),
                  ),
                  subtitle: /*Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Quantity: ${reservation['quantity']} units'),
                      Text('Medical Reason: ${reservation['medicalReason']}'),
                      Text('Status: ${reservation['status']}'),
                      Text(
                          'Reservation Date: ${reservation['reservationDate']?.toDate().toString().substring(0, 10)}'),
                      Text(
                          'Valid Until: ${reservation['validUntil']?.toDate().toString().substring(0, 10)}'),
                      Text('Reserved By: ${reservation['userName']}'),
                    ],
                  ),*/

                  Text(
                    '___________________________________\nBlood Type: ${reservation['bloodType']}\nQuantity: ${reservation['quantity']}\nStatus: ${reservation['status']}\nMedical Reason: ${reservation['medicalReason']}\nReserved At: ${reservation['reservationDate'] != null 
                    ? DateFormat('MM/dd/yyyy').format(reservation['reservationDate']!.toDate()) 
                    : 'N/A'}\nValid Until: ${reservation['validUntil'] != null ? DateFormat('MM/dd/yyyy').format(reservation['validUntil']!.toDate()) : 'N/A'}',
                                      style: Styles.headerStyle5.copyWith(
                                        color: Styles.tertiaryColor,
                    ),
                  ),
                  trailing: IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () {
                    _showReservationOptions(
                      context, reservation['id'], reservation['status'], reservation
                    );
                  },
                ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Function to show reservation options
  /*void _showReservationOptions(
      BuildContext context, String reservationId, String status) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Wrap(
          children: [
            if (status == 'Pending') // Option to approve reservation
              ListTile(
                leading: const Icon(Icons.check),
                title: const Text('Approve Reservation'),
                onTap: () async {
                  await _updateReservationStatus(reservationId, 'Reserved');
                  Navigator.pop(context);
                },
              ),
            if (status == 'Reserved') ...[
              ListTile(
                leading: const Icon(Icons.check_circle),
                title: const Text('Mark as Completed'),
                onTap: () async {
                  await _updateReservationStatus(reservationId, 'Completed');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.cancel),
                title: const Text('Cancel Reservation'),
                onTap: () async {
                  int quantity = reservation['quantity']; // Get the quantity of blood reserved
    await _updateReservationStatus(reservationId, 'Cancelled', quantity);
    Navigator.pop(context);
                },
              ),
            ],
          ],
        );
      },
    );
  }*/
  // Function to show reservation options
void _showReservationOptions(
    BuildContext context, String reservationId, String status, Map<String, dynamic> reservation) {
  showModalBottomSheet(
    context: context,
    builder: (BuildContext context) {
      return Wrap(
        children: [
          if (status == 'Pending') // Option to approve reservation
            ListTile(
              leading: const Icon(Icons.check),
              title: const Text('Approve Reservation'),
              onTap: () async {
                int quantity = reservation['quantity']; // Get the quantity of blood reserved
                await _updateReservationStatus(reservationId, 'Reserved', quantity);
                Navigator.pop(context);
              },
            ),
          if (status == 'Reserved') ...[
            ListTile(
              leading: const Icon(Icons.check_circle),
              title: const Text('Mark as Completed'),
              onTap: () async {
                await _updateReservationStatus(reservationId, 'Completed', 0); // No inventory update needed
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.cancel),
              title: const Text('Cancel Reservation'),
              onTap: () async {
                int quantity = reservation['quantity']; // Get the quantity of blood reserved
                await _updateReservationStatus(reservationId, 'Cancelled', quantity);
                Navigator.pop(context);
              },
            ),
          ],
        ],
      );
    },
  );
}



  // Function to update reservation status and Firestore
  /*Future<void> _updateReservationStatus(
      String reservationId, String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('reservations')
          .doc(reservationId)
          .update({'status': newStatus});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Reservation status updated to $newStatus')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating status: $e')),
      );
    }
  }*/

  // Function to update reservation status and Firestore
Future<void> _updateReservationStatus(
    String reservationId, String newStatus, int quantity) async {
  try {
    // Fetch the reservation document to get the bloodBankId and bloodType
    final reservationRef = FirebaseFirestore.instance
        .collection('reservations')
        .doc(reservationId);

    final reservationSnapshot = await reservationRef.get();
    if (!reservationSnapshot.exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Reservation not found.')),
      );
      return;
    }

    var reservationData = reservationSnapshot.data();
    String bloodBankId = reservationData?['bloodBankId'];
    String bloodType = reservationData?['bloodType'];

    if (bloodBankId == null || bloodType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Blood bank ID or blood type not found in reservation.')),
      );
      return;
    }

    // Update the reservation status
    await reservationRef.update({'status': newStatus});

    // Check if status is 'Cancelled' and update inventory
    if (newStatus == 'Cancelled') {
      // Access the inventory subcollection of the blood bank
      final inventoryRef = FirebaseFirestore.instance
          .collection('bloodbanks') // Access the bloodBanks collection
          .doc(bloodBankId) // Get the specific blood bank document
          .collection('inventories') // Access the inventories subcollection
          .doc(bloodType); // Use the bloodType as the document ID

      // Fetch current inventory data
      final inventorySnapshot = await inventoryRef.get();
      if (inventorySnapshot.exists) {
        var inventoryData = inventorySnapshot.data();
        int currentStock = inventoryData?['quantity'] ?? 0;

        // Update the inventory by adding the cancelled reservation's quantity
        await inventoryRef.update({
          'quantity': currentStock + quantity,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Inventory updated. ${quantity} unit/s added back.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Inventory not found for this blood bank and blood type.')),
        );
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Reservation status updated to $newStatus')),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error updating status: $e')),
    );
  }
}



/*class AdminReservationScreen extends StatefulWidget {
  final String bloodBankId;

  const AdminReservationScreen({Key? key, required this.bloodBankId})
      : super(key: key);

  @override
  State<AdminReservationScreen> createState() => _AdminReservationScreenState();
}

class _AdminReservationScreenState extends State<AdminReservationScreen> {
  late Stream<List<Map<String, dynamic>>> _reservationsStream;

  @override
  void initState() {
    super.initState();
    fetchReservations();
  }

  void fetchReservations() {
    _reservationsStream = FirebaseFirestore.instance
        .collection('reservations')
        .where('bloodBankId', isEqualTo: widget.bloodBankId)
        .snapshots()
        .asyncMap((snapshot) async {
      List<Map<String, dynamic>> reservations = [];
      for (var doc in snapshot.docs) {
        var reservationData = doc.data();
        // Fetch the user's name from 'users' collection using userId
        String userId = reservationData['userId'];
        String userName = await _fetchUserName(userId);

        reservations.add({
          'id': doc.id,
          ...reservationData,
          'userName': userName, // Add fetched userName
        });
      }
      return reservations;
    });
  }

  // Function to fetch user name by userId
  Future<String> _fetchUserName(String userId) async {
    try {
      final userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userSnapshot.exists) {
        return userSnapshot.data()?['fullName'] ?? 'Unknown User';
      } else {
        return 'Unknown User';
      }
    } catch (e) {
      print('Error fetching user name: $e');
      return 'Unknown User';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Blood Reservations'),
        backgroundColor: Colors.redAccent,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _reservationsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final reservations = snapshot.data ?? [];

          if (reservations.isEmpty) {
            return const Center(child: Text('No reservations found.'));
          }

          return ListView.builder(
            itemCount: reservations.length,
            itemBuilder: (context, index) {
              final reservation = reservations[index];
              return Card(
                margin:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(
                    'Blood Type: ${reservation['bloodType']}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Quantity: ${reservation['quantity']} units'),
                      Text('Medical Reason: ${reservation['medicalReason']}'),
                      Text('Status: ${reservation['status']}'),
                      Text(
                          'Reservation Date: ${reservation['reservationDate']?.toDate().toString().substring(0, 10)}'),
                      Text(
                          'Valid Until: ${reservation['validUntil']?.toDate().toString().substring(0, 10)}'),
                      Text('Reserved By: ${reservation['userName']}'), // Display user name
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () {
                      _showReservationOptions(context, reservation['id']);
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Function to show reservation options
  void _showReservationOptions(BuildContext context, String reservationId) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.check_circle),
              title: const Text('Mark as Completed'),
              onTap: () async {
                await _updateReservationStatus(reservationId, 'Completed');
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.cancel),
              title: const Text('Cancel Reservation'),
              onTap: () async {
                await _updateReservationStatus(reservationId, 'Cancelled');
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  // Function to update reservation status
  Future<void> _updateReservationStatus(
      String reservationId, String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('reservations')
          .doc(reservationId)
          .update({'status': newStatus});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Reservation status updated to $newStatus')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating status: $e')),
      );
    }
  }
}*/
}
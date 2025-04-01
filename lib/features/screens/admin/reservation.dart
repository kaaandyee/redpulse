import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:redpulse/utilities/constants/styles.dart';

class AdminReservationScreen extends StatefulWidget {
  final String bloodBankId;

  const AdminReservationScreen({super.key, required this.bloodBankId});

  @override
  State<AdminReservationScreen> createState() => _AdminReservationScreenState();
}

class _AdminReservationScreenState extends State<AdminReservationScreen> {
  late Stream<List<Map<String, dynamic>>> _reservationsStream;

  @override
  void initState() {
    super.initState();
    _reservationsStream = fetchReservations();
  }

  Stream<List<Map<String, dynamic>>> fetchReservations() {
    return FirebaseFirestore.instance
        .collection('reservations')
        .where('bloodBankId', isEqualTo: widget.bloodBankId)
        .snapshots()
        .asyncMap((snapshot) async {
      List<Map<String, dynamic>> reservations = [];
      for (var doc in snapshot.docs) {
        var reservationData = doc.data();
        String userId = reservationData['userId'];
        String userName = await _fetchUserName(userId);

        reservations.add({
          'id': doc.id,
          ...reservationData,
          'userName': userName,
        });
      }
      return reservations;
    });
  }

  Future<String> _fetchUserName(String userId) async {
    try {
      final userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userSnapshot.exists) {
        return userSnapshot.data()?['fullName'] ?? 'Unknown User';
      }
      return 'Unknown User';
    } catch (e) {
      print('Error fetching user name: $e');
      return 'Unknown User';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Styles.primaryColor,
        title: Text("Reservation",
            style: Styles.headerStyle2.copyWith(color: Styles.tertiaryColor)),
        centerTitle: true,
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
              int quantity = reservation['quantity'];
              String reservationId = reservation['id'];

              Color tileColor;
              switch (status) {
                case 'Pending':
                  tileColor = Styles.frontColor;
                  break;
                case 'Reserved':
                  tileColor = Styles.primaryColor;
                  break;
                case 'Cancelled':
                  tileColor = Styles.complementColor;
                  break;
                default:
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
                  subtitle: Text(
                    '___________________________________\n'
                        'Blood Type: ${reservation['bloodType']}\n'
                        'Quantity: ${reservation['quantity']}\n'
                        'Status: ${reservation['status']}\n'
                        'Medical Reason: ${reservation['medicalReason']}\n'
                        'Reserved At: ${reservation['reservationDate'] != null ? DateFormat('MM/dd/yyyy').format(reservation['reservationDate'].toDate()) : 'N/A'}\n'
                        'Valid Until: ${reservation['validUntil'] != null ? DateFormat('MM/dd/yyyy').format(reservation['validUntil'].toDate()) : 'N/A'}',
                    style: Styles.headerStyle5.copyWith(
                      color: Styles.tertiaryColor,
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () {
                      _showReservationOptions(context, reservationId, status, reservation);
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

  void _showReservationOptions(BuildContext context, String reservationId,
      String status, Map<String, dynamic> reservation) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Wrap(
          children: [
            if (status == 'Pending')
              ListTile(
                leading: const Icon(Icons.check),
                title: const Text('Approve Reservation'),
                onTap: () async {
                  int quantity = reservation['quantity'];
                  await _updateReservationStatus(reservationId, 'Reserved', quantity);
                  Navigator.pop(context);
                },
              ),
            if (status == 'Reserved') ...[
              ListTile(
                leading: const Icon(Icons.check_circle),
                title: const Text('Mark as Completed'),
                onTap: () async {
                  await _updateReservationStatus(reservationId, 'Completed', 0);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.cancel),
                title: const Text('Cancel Reservation'),
                onTap: () async {
                  int quantity = reservation['quantity'];
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

  Future<void> _updateReservationStatus(
      String reservationId, String newStatus, int quantity) async {
    try {
      final reservationRef = FirebaseFirestore.instance
          .collection('reservations')
          .doc(reservationId);

      final reservationSnapshot = await reservationRef.get();
      if (!reservationSnapshot.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reservation not found.')),
        );
        return;
      }

      var reservationData = reservationSnapshot.data();
      String bloodBankId = reservationData?['bloodBankId'];
      String bloodType = reservationData?['bloodType'];

      await reservationRef.update({'status': newStatus});

      if (newStatus == 'Cancelled') {
        final inventoryRef = FirebaseFirestore.instance
            .collection('bloodbanks')
            .doc(bloodBankId)
            .collection('inventories')
            .doc(bloodType);

        final inventorySnapshot = await inventoryRef.get();
        if (inventorySnapshot.exists) {
          var inventoryData = inventorySnapshot.data();
          int currentStock = inventoryData?['quantity'] ?? 0;
          await inventoryRef.update({'quantity': currentStock + quantity});

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Inventory updated. $quantity unit(s) added back.')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Inventory not found for this blood bank and blood type.')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating status: $e')),
      );
    }
  }
}

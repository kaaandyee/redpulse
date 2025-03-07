import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:redpulse/features/models/reservation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:redpulse/features/screens/user/sub/reservationdetails.dart';
import 'package:redpulse/utilities/constants/styles.dart';

class ReservationScreen extends StatefulWidget {
  const ReservationScreen({Key? key}) : super(key: key);

  @override
  ReservationScreenState createState() => ReservationScreenState();
}

class ReservationScreenState extends State<ReservationScreen> {
  late String userId;
  late Stream<List<ReservationModel>> _reservationsStream;
  String bloodBankName = '';

  @override
  void initState() {
    super.initState();
    fetchUserId();
  }

  // Function to fetch the current user's UID
  Future<void> fetchUserId() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        userId = user.uid;  // Set the current user's UID
      });
      _reservationsStream = FirebaseFirestore.instance
          .collection('reservations')
          .where('userId', isEqualTo: userId)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          return ReservationModel.fromFirestore(doc.id, doc.data() as Map<String, dynamic>);
        }).toList();
      });
      await _fetchBloodBankName();
    } else {
      // Handle case if user is not logged in
      print('No user is logged in.');
    }
  }

  // Fetch the blood bank name using the bloodBankId from reservations
  Future<void> _fetchBloodBankName() async {
    try {
      final reservationSnapshot = await FirebaseFirestore.instance
          .collection('reservations')
          .where('userId', isEqualTo: userId)
          .get();

      // Get the first reservation's bloodBankId
      if (reservationSnapshot.docs.isNotEmpty) {
        final reservationData = reservationSnapshot.docs.first.data();
        final bloodBankId = reservationData['bloodBankId'];

        if (bloodBankId.isNotEmpty) {
          final bloodBankDoc = await FirebaseFirestore.instance.collection('bloodbanks').doc(bloodBankId).get();
          if (bloodBankDoc.exists) {
            setState(() {
              bloodBankName = bloodBankDoc.data()?['bloodBankName'] ?? 'Blood Bank'; // Default if name not found
            });
          }
        }
      }
    } catch (e) {
      print('Error fetching blood bank name: $e');
    }
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
                    "Reservation",
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
      body: userId.isEmpty
          ? const Center(child: CircularProgressIndicator())  // Show loading if userId is not fetched yet
          : StreamBuilder<List<ReservationModel>>(
              stream: _reservationsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No reservations found.'));
                }

                final reservations = snapshot.data!;

                return ListView.builder(
                  itemCount: reservations.length,
                  itemBuilder: (context, index) {
                    final reservation = reservations[index];

                    // Determine the tile color based on the reservation status
                    Color tileColor;
                    if (reservation.status == 'Pending') {
                      tileColor = Styles.frontColor; // Pending status color
                    } else if (reservation.status == 'Reserved') {
                      tileColor = Styles.primaryColor; // Approved status color
                    } else if (reservation.status == 'Cancelled') {
                      tileColor = Styles.complementColor; // Cancelled status color
                    } else {
                      tileColor = Styles.tertiaryColor;  // Default color if no status matches
                    }

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                      child: ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: const EdgeInsets.all(20),
                        tileColor: tileColor, // Use the dynamically set tile color
                        title: Text(
                          bloodBankName.isNotEmpty ? bloodBankName: 'Loading...',  // Blood bank name as title
                          style: Styles.headerStyle2.copyWith(fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Styles.tertiaryColor,
                          ),
                        ),
                        subtitle: Text(
                          '____________________________________________\nBlood Type: ${reservation.bloodType}\nQuantity: ${reservation.quantity}\nStatus: ${reservation.status}\nValid Until: ${DateFormat('MM/dd/yyyy').format(reservation.validUntil)}',
                          style: Styles.headerStyle5.copyWith(color: Styles.tertiaryColor),
                        ),
                        onTap: () {
                          // Pass reservationId to the ReservationDetailsScreen
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ReservationDetailsScreen(
                                reservationId: reservation.reservationId, // Pass the reservationId
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
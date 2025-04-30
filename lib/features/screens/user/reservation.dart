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
  // Cache to store blood bank names by ID
  final Map<String, String> _bloodBankNames = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUserId();
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
        final name = bloodBankDoc.data()?['bloodBankName'] ?? 'Unknown Blood Bank';
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
                      "My Reservations",
                      style: GoogleFonts.montserrat(
                        fontSize: screenSize.width * 0.055,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: screenSize.height * 0.005),
                    Text(
                      "View and manage your blood reservations",
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
              return Center(child: CircularProgressIndicator(color: Styles.primaryColor));
            }

            if (snapshot.hasError) {
              return Center(
                child: FadeInUp(
                  duration: const Duration(milliseconds: 800),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 60, color: Colors.grey[400]),
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

            final reservations = snapshot.data!;

            return Padding(
              padding: EdgeInsets.only(top: screenSize.height * 0.13),
              child: ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                itemCount: reservations.length,
                itemBuilder: (context, index) {
                  final reservation = reservations[index];

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
                    child: Card(
                      margin: const EdgeInsets.only(bottom: 15),
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
                            color: Styles.tertiaryColor,
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
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Styles.tertiaryColor,
                              ),
                            );
                          },
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildReservationDetail('Blood Type', reservation.bloodType),
                              _buildReservationDetail('Quantity', '${reservation.quantity} units'),
                              _buildReservationDetail('Status', reservation.status),
                              _buildReservationDetail('Valid Until',
                                  DateFormat('MM/dd/yyyy').format(reservation.validUntil)
                              ),
                            ],
                          ),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ReservationDetailsScreen(
                                reservationId: reservation.reservationId,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildReservationDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: GoogleFonts.roboto(
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.85),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.roboto(
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
// ignore_for_file: avoid_print, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:redpulse/features/models/reservation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:redpulse/utilities/constants/styles.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:lottie/lottie.dart';

class AdminReservationDetailsScreen extends StatefulWidget {
  final String reservationId;

  const AdminReservationDetailsScreen({super.key, required this.reservationId});

  @override
  _AdminReservationDetailsScreenState createState() =>
      _AdminReservationDetailsScreenState();
}

class _AdminReservationDetailsScreenState extends State<AdminReservationDetailsScreen> {
  ReservationModel? reservation;
  String bloodBankName = '';
  String userName = '';
  bool isLoading = true;
  bool isCancelling = false;

  @override
  void initState() {
    super.initState();
    fetchReservationDetails();
  }

  Future<void> fetchReservationDetails() async {
    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('reservations')
          .doc(widget.reservationId)
          .get();

      if (docSnapshot.exists) {
        setState(() {
          reservation = ReservationModel.fromFirestore(
              widget.reservationId, docSnapshot.data() as Map<String, dynamic>);
        });
        await fetchBloodBankName(reservation!.bloodBankId);
        fetchUserName(reservation!.userId);
      } else {
        print('Reservation not found.');
      }
    } catch (e) {
      print('Error fetching reservation details: $e');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

Future<void> fetchUserName(String userId) async {
  try {
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();

    if (userDoc.exists) {
      setState(() {
        //userName = userDoc.data()?['firstName'] + ' ' + userDoc.data()?['lastName'];
        userName = userDoc.data()?['fullName'] ?? 'Unknown User';
      });
    } else {
      print('User not found.');
    }
  } catch (e) {
    print('Error fetching user name: $e');
  }
}

  Future<void> fetchBloodBankName(String bloodBankId) async {
    try {
      final bloodBankDoc = await FirebaseFirestore.instance
          .collection('bloodbanks')
          .doc(bloodBankId)
          .get();

      if (bloodBankDoc.exists) {
        setState(() {
          bloodBankName = bloodBankDoc.data()?['bloodBankName'] ?? 'Unknown';
        });
      } else {
        print('Blood bank not found.');
      }
    } catch (e) {
      print('Error fetching blood bank name: $e');
    }
  }

  Future<void> cancelReservation() async {
    setState(() => isCancelling = true);
    try {
      if (reservation != null) {
        await updateInventory(reservation!.bloodBankId, reservation!.bloodType,
            reservation!.quantity);

        await FirebaseFirestore.instance
            .collection('reservations')
            .doc(widget.reservationId)
            .delete();

        // Navigate back immediately
        Navigator.pop(context, true);

        // Show the SnackBar on the previous screen after navigation
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reservation successfully canceled',
                style: GoogleFonts.roboto()),
            backgroundColor: Styles.primaryColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      print('Error canceling reservation: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to cancel reservation: $e',
              style: GoogleFonts.roboto()),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      setState(() => isCancelling = false);
    }
  }

  Future<void> updateInventory(
      String bloodBankId, String bloodType, int quantityToAdd) async {
    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('bloodbanks')
          .doc(bloodBankId)
          .collection('inventories')
          .doc(bloodType)
          .get();

      if (docSnapshot.exists) {
        final inventoryData = docSnapshot.data() as Map<String, dynamic>;
        int currentQuantity = inventoryData['quantity'] ?? 0;
        int updatedQuantity = currentQuantity + quantityToAdd;

        String updatedStatus;
        if (updatedQuantity == 0) {
          updatedStatus = 'Out of Stock';
        } else if (updatedQuantity < 10) {
          updatedStatus = 'Low Stock';
        } else {
          updatedStatus = 'Available';
        }

        await FirebaseFirestore.instance
            .collection('bloodbanks')
            .doc(bloodBankId)
            .collection('inventories')
            .doc(bloodType)
            .update({
          'quantity': updatedQuantity,
          'status': updatedStatus,
          'lastupdated': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error updating inventory: $e');
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
                padding: EdgeInsets.symmetric(horizontal: screenSize.width * 0.06),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    FadeInLeft(
                      duration: const Duration(milliseconds: 500),
                      child: IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new_outlined,
                          color: Colors.white,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    Text(
                      "Reservation Details",
                      style: GoogleFonts.montserrat(
                        fontSize: screenSize.width * 0.05,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      body: isLoading
          ? _buildLoadingState(context)
          : _buildContent(context, screenSize),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset(
            'assets/animations/blood_loading.json',
            width: 150,
            height: 150,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => const CircularProgressIndicator(
              color: Color.fromARGB(250, 212, 61, 61),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            "Loading reservation details...",
            style: GoogleFonts.roboto(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, Size screenSize) {
    Color tileColor;
    IconData statusIcon;

    final status = reservation?.status ?? 'Unknown';

    if (status == 'Pending') {
      tileColor = Styles.frontColor;
      statusIcon = Icons.hourglass_empty;
    } else if (status == 'Reserved') {
      tileColor = Colors.green[700] ?? Colors.green;
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

    return Container(
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 248, 248, 248),
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.only(
          top: screenSize.height * 0.15,
          bottom: screenSize.height * 0.04,
          left: screenSize.width * 0.06,
          right: screenSize.width * 0.06,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Blood Bank Card
            FadeInDown(
              duration: const Duration(milliseconds: 800),
              child: _buildInfoCard(
                title: "Recipient",
                value: userName,
                icon: Icons.local_hospital_outlined,
                screenSize: screenSize,
              ),
            ),
            SizedBox(height: screenSize.height * 0.02),

            // Blood Details Card
            FadeInDown(
              duration: const Duration(milliseconds: 900),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Styles.primaryColor.withOpacity(0.95),
                      Styles.primaryColor.withOpacity(0.85),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Styles.primaryColor.withOpacity(0.3),
                      spreadRadius: 1,
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                padding: EdgeInsets.all(screenSize.width * 0.05),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Blood Details",
                          style: GoogleFonts.montserrat(
                            fontSize: screenSize.width * 0.045,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),

                      ],
                    ),
                    SizedBox(height: screenSize.height * 0.02),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Blood Type Box (using _buildInfoBox)
                        _buildInfoBox(
                          context: context,
                          label: "Blood Type",
                          value: reservation?.bloodType ?? 'N/A',
                        ),

                        _buildDivider(),

                        // Quantity Box (same height/design as blood type)
                        _buildInfoBox(
                          context: context,
                          label: "Units", 
                          value: "${reservation?.quantity ?? 0}",
                        ),

                        _buildDivider(),
                        _buildInfoBox(
                          context: context,
                          icon: statusIcon,
                          backgroundColor: tileColor, label: reservation?.status ?? 'N/A', value: null,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: screenSize.height * 0.02),

            // Medical Reason Card
            FadeInDown(
              duration: const Duration(milliseconds: 1000),
              child: _buildInfoCard(
                title: "Medical Reason",
                value: reservation?.medicalReason ?? 'Not Provided',
                icon: Icons.medical_information_outlined,
                screenSize: screenSize,
              ),
            ),
            SizedBox(height: screenSize.height * 0.02),

            // Dates Card
            FadeInDown(
              duration: const Duration(milliseconds: 1100),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 2,
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                padding: EdgeInsets.all(screenSize.width * 0.05),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.date_range_outlined,
                          color: Styles.primaryColor,
                          size: screenSize.width * 0.06,
                        ),
                        SizedBox(width: screenSize.width * 0.03),
                        Text(
                          "Reservation Dates",
                          style: GoogleFonts.montserrat(
                            fontSize: screenSize.width * 0.045,
                            fontWeight: FontWeight.w600,
                            color: Styles.primaryColor,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: screenSize.height * 0.02),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Reserved At",
                              style: GoogleFonts.roboto(
                                fontSize: screenSize.width * 0.035,
                                color: Colors.grey[700],
                              ),
                            ),
                            SizedBox(height: screenSize.height * 0.01),
                            Text(
                              DateFormat('MMM dd, yyyy').format(
                                  reservation?.reservedAt ?? DateTime.now()),
                              style: GoogleFonts.montserrat(
                                fontSize: screenSize.width * 0.04,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        Icon(
                          Icons.arrow_forward,
                          color: Colors.grey,
                          size: screenSize.width * 0.05,
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              "Valid Until",
                              style: GoogleFonts.roboto(
                                fontSize: screenSize.width * 0.035,
                                color: Colors.grey[700],
                              ),
                            ),
                            SizedBox(height: screenSize.height * 0.01),
                            Text(
                              DateFormat('MMM dd, yyyy').format(
                                  reservation?.validUntil ?? DateTime.now()),
                              style: GoogleFonts.montserrat(
                                fontSize: screenSize.width * 0.04,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: screenSize.height * 0.04),

            //ADMIN CONTROL
            if (reservation?.status == 'Pending' || reservation?.status == 'Reserved')
              FadeInUp(
                duration: const Duration(milliseconds: 1200),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 0),
                  child: Row(
                    children: [
                      // Confirm / Complete Button
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: Icon(Icons.check, color: Colors.white),
                          label: Text(
                            reservation!.status == 'Pending' ? 'Approve' : 'Complete',
                            style: GoogleFonts.montserrat(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: reservation!.status == 'Pending'
                              ? (Colors.green[700] ?? Colors.green)
                              : (Colors.blue[700] ?? Colors.blue),

                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                            onPressed: () async {
                              final now = Timestamp.now();
                              final newStatus = reservation!.status == 'Pending' ? 'Reserved' : 'Completed';

                              // SHOW CONFIRMATION DIALOG BEFORE PROCEEDING
                              final confirmed = await showDialog<bool>(
                                context: context,
                                barrierDismissible: false,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                  backgroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  title: Row(
                                    children: [
                                      Icon(Icons.safety_check, color: Styles.primaryColor),
                                      const SizedBox(width: 10),
                                      Text(
                                        'Confirm Action',
                                        style: GoogleFonts.montserrat(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                  content: Text(
                                    newStatus == 'Reserved'
                                        ? 'Are you sure you want to approve this reservation?'
                                        : 'Are you sure you want to complete this reservation?',
                                    style: GoogleFonts.montserrat(),
                                  ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, false), // User canceled
                                        child: Text(
                                          'No',
                                          style: GoogleFonts.roboto(color: Colors.grey[700]),
                                        ),
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Styles.primaryColor,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                        onPressed: () => Navigator.pop(context, true), // User confirmed
                                        child: Text(
                                          'Yes',
                                          style: GoogleFonts.roboto(color: Colors.white),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              );
                            // CHECK USER CONFIRMATION
                              if (confirmed == true) {
                                // Proceed with update only if user confirmed
                                await FirebaseFirestore.instance
                                    .collection('reservations')
                                    .doc(widget.reservationId)
                                    .update({
                                  'status': newStatus,
                                  'updatedAt': now,
                                  if (newStatus == 'Reserved') 'reservedAt': now,
                                });
                                fetchReservationDetails.call(); // Optional UI refresh
                              }
                            }
                        ),
                      ),

                      const SizedBox(width: 10),

                      // Cancel Button
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: Icon(Icons.close, color: Colors.white),
                          label: Text(
                            'Cancel',
                            style: GoogleFonts.montserrat(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Styles.primaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () async {
                            bool confirmed = await showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            title: Row(
                              children: [
                                Icon(Icons.warning_amber_rounded, color: Styles.primaryColor),
                                const SizedBox(width: 10),
                                Text(
                                  'Cancel Reservation',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            content: Text(
                              'Are you sure you want to cancel this reservation? This action cannot be undone.',
                              style: GoogleFonts.roboto(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: Text(
                                  'No',
                                  style: GoogleFonts.roboto(color: Colors.grey[700]),
                                ),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Styles.primaryColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                onPressed: () => Navigator.pop(context, true),
                                child: Text(
                                  'Yes',
                                  style: GoogleFonts.roboto(color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                            );

                            if (confirmed) {
                              final now = Timestamp.now();

                              await FirebaseFirestore.instance
                                  .collection('reservations')
                                  .doc(widget.reservationId)
                                  .update({
                                'status': 'Cancelled',
                                'updatedAt': now,
                              });

                              // Optional: Refresh UI
                              fetchReservationDetails.call();
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              )


          ],
        ),
      ),
    );
  }

Widget _buildInfoBox({
  required BuildContext context,
  required String label,
  required dynamic value, // Can be String, IconData, etc.
  Color? backgroundColor,
  IconData? icon,

}) {
  final screenSize = MediaQuery.of(context).size;

  Widget content;

  if (icon != null) {
    // If there's an icon, show icon inside colored circle
    content = Container(
      padding: EdgeInsets.all(screenSize.width * 0.035),
      decoration: BoxDecoration(
        color: backgroundColor ?? Styles.primaryColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: (backgroundColor ?? Styles.primaryColor).withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 4,
          ),
        ],
      ),
      child: Icon(
        icon,
        size: screenSize.width * 0.06,
        color: Colors.white,
      ),
    );
  } else {
    // Otherwise, treat it as text value
    content = Container(
      padding: EdgeInsets.all(screenSize.width * 0.03),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 4,
          ),
        ],
      ),
      child: Text(
        value.toString(),
        style: GoogleFonts.montserrat(
          fontSize: screenSize.width * 0.05,
          fontWeight: FontWeight.w700,
          color: Styles.primaryColor,
        ),
      ),
    );
  }

  return Column(
    children: [
      content,
      SizedBox(height: screenSize.height * 0.008),
      Text(
        label,
        style: GoogleFonts.roboto(
          fontSize: screenSize.width * 0.03,
          color: Colors.white.withOpacity(0.9),
        ),
      ),
    ],
  );
}

  Widget _buildInfoCard({
    required String title,
    required String value,
    required IconData icon,
    required Size screenSize,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: EdgeInsets.all(screenSize.width * 0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: Styles.primaryColor,
                size: screenSize.width * 0.06,
              ),
              SizedBox(width: screenSize.width * 0.03),
              Text(
                title,
                style: GoogleFonts.montserrat(
                  fontSize: screenSize.width * 0.045,
                  fontWeight: FontWeight.w600,
                  color: Styles.primaryColor,
                ),
              ),
            ],
          ),
          SizedBox(height: screenSize.height * 0.01),
          Text(
            value,
            style: GoogleFonts.roboto(
              fontSize: screenSize.width * 0.045,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 40,
      width: 1,
      color: Colors.white.withOpacity(0.3),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:redpulse/features/models/reservation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:redpulse/utilities/constants/styles.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:lottie/lottie.dart';

class ReservationDetailsScreen extends StatefulWidget {
  final String reservationId;

  const ReservationDetailsScreen({super.key, required this.reservationId});

  @override
  _ReservationDetailsScreenState createState() =>
      _ReservationDetailsScreenState();
}

class _ReservationDetailsScreenState extends State<ReservationDetailsScreen> {
  ReservationModel? reservation;
  String bloodBankName = '';
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
        Navigator.pop(context);
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
    } finally {
      if (mounted) {
        setState(() => isCancelling = false);
      }
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
                title: "Blood Bank",
                value: bloodBankName,
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
                        _buildBloodTypeBox(
                          context,
                          reservation?.bloodType ?? 'N/A',
                        ),
                        _buildDivider(),
                        _buildStatItem(
                          context,
                          "${reservation?.quantity ?? 0}",
                          "Quantity",
                          Icons.water_drop_outlined,
                        ),
                        _buildDivider(),
                        _buildStatItem(
                          context,
                          reservation?.status ?? 'N/A',
                          "Status",
                          Icons.info_outline,
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

            // Cancel Button
            FadeInUp(
              duration: const Duration(milliseconds: 1200),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isCancelling ? null : cancelReservation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Styles.primaryColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: screenSize.height * 0.02),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 5,
                    shadowColor: Styles.primaryColor.withOpacity(0.5),
                  ),
                  icon: isCancelling
                      ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : const Icon(Icons.cancel_outlined),
                  label: Text(
                    isCancelling ? "Cancelling..." : "Cancel Reservation",
                    style: GoogleFonts.montserrat(
                      fontSize: screenSize.width * 0.04,
                      fontWeight: FontWeight.w600,
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

  Widget _buildBloodTypeBox(BuildContext context, String bloodType) {
    final screenSize = MediaQuery.of(context).size;

    return Column(
      children: [
        Container(
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
            bloodType,
            style: GoogleFonts.montserrat(
              fontSize: screenSize.width * 0.05,
              fontWeight: FontWeight.w700,
              color: Styles.primaryColor,
            ),
          ),
        ),
        SizedBox(height: screenSize.height * 0.008),
        Text(
          "Blood Type",
          style: GoogleFonts.roboto(
            fontSize: screenSize.width * 0.03,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(BuildContext context, String value, String label, IconData icon) {
    final screenSize = MediaQuery.of(context).size;

    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(screenSize.width * 0.025),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: screenSize.width * 0.05,
          ),
        ),
        SizedBox(height: screenSize.height * 0.008),
        Text(
          value,
          style: GoogleFonts.montserrat(
            fontSize: screenSize.width * 0.045,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
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

  Widget _buildDivider() {
    return Container(
      height: 40,
      width: 1,
      color: Colors.white.withOpacity(0.3),
    );
  }
}
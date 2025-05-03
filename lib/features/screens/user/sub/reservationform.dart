import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:redpulse/features/models/inventory.dart';
import 'package:redpulse/services/auth.dart';
import 'package:redpulse/utilities/constants/styles.dart';
import 'package:action_slider/action_slider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter_moving_background/flutter_moving_background.dart';
import 'package:flutter_moving_background/enums/animation_types.dart';
import 'package:lottie/lottie.dart';

class ReservationFormScreen extends StatefulWidget {
  final String bloodBankId;
  final List<InventoryModel> inventoryList;

  const ReservationFormScreen({super.key, required this.bloodBankId, required this.inventoryList});

  @override
  _ReservationFormScreenState createState() => _ReservationFormScreenState();
}

class _ReservationFormScreenState extends State<ReservationFormScreen> with SingleTickerProviderStateMixin {
  late List<InventoryModel> inventoryList;
  String? selectedBloodType;
  int quantity = 1;
  DateTime reservedAt = DateTime.now();
  TextEditingController medicalReasonController = TextEditingController();
  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();
    inventoryList = widget.inventoryList;
  }

  int getAvailableStock(String bloodType) {
    final inventoryItem = inventoryList.firstWhere(
          (inventory) => inventory.bloodType == bloodType,
      orElse: () => InventoryModel(
        bloodType: bloodType,
        quantity: 0,
        lastUpdated: DateTime.now(),
        status: '',
        bloodBankId: widget.bloodBankId,
      ),
    );
    return inventoryItem.quantity;
  }

  Future<void> _reserveBlood() async {
    setState(() => isSubmitting = true);

    if (quantity > 10) {
      _showErrorSnackBar('Cannot reserve more than 10 units.');
      setState(() => isSubmitting = false);
      return;
    }

    if (selectedBloodType == null || inventoryList.isEmpty) {
      _showErrorSnackBar('Please select a blood type and ensure inventory is loaded.');
      setState(() => isSubmitting = false);
      return;
    }

    final availableStock = getAvailableStock(selectedBloodType!);

    if (quantity > availableStock) {
      _showErrorSnackBar('Only $availableStock unit/s available for this blood type.');
      setState(() => isSubmitting = false);
      return;
    }

    if (medicalReasonController.text.isEmpty) {
      _showErrorSnackBar('Please provide a medical reason for the reservation.');
      setState(() => isSubmitting = false);
      return;
    }

    try {
      final userId = await AuthMethod().getAdminId();
      final validUntil = reservedAt.add(const Duration(days: 7));

      await FirebaseFirestore.instance.collection('reservations').add({
        'bloodType': selectedBloodType,
        'quantity': quantity,
        'bloodBankId': widget.bloodBankId,
        'userId': userId,
        'reservedAt': Timestamp.fromDate(reservedAt),
        'validUntil': Timestamp.fromDate(validUntil),
        'status': 'Pending',
        'medicalReason': medicalReasonController.text,
      });

      await _updateInventory();

      _showSuccessSnackBar('Reservation successful!');
      Navigator.pop(context, true);
    } catch (e) {
      _showErrorSnackBar('Error reserving blood: $e');
      setState(() => isSubmitting = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(10),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(10),
      ),
    );
  }

  Future<void> _updateInventory() async {
    try {
      final inventoryItem = inventoryList.firstWhere(
            (inventory) => inventory.bloodType == selectedBloodType,
      );

      final int updatedQuantity = inventoryItem.quantity - quantity;
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
          .doc(widget.bloodBankId)
          .collection('inventories')
          .doc(inventoryItem.bloodType)
          .update({
        'quantity': updatedQuantity,
        'status': updatedStatus,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      setState(() {
        inventoryItem.quantity = updatedQuantity;
      });
    } catch (e) {
      _showErrorSnackBar('Error updating inventory: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    List<String> availableBloodTypes = inventoryList
        .where((inventory) => inventory.quantity > 0)
        .map((inventory) => inventory.bloodType)
        .toList();

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
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_outlined, size: 20, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          'Blood Reservation',
                          style: GoogleFonts.montserrat(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 40), // Balance for the back button
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      body: inventoryList.isEmpty
          ? Center(
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
              "Loading inventory...",
              style: GoogleFonts.roboto(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      )
          : MovingBackground(
        animationType: AnimationType.translation,
        backgroundColor: const Color.fromARGB(255, 248, 248, 248),
        circles: const [
          MovingCircle(color: Color.fromARGB(65, 230, 132, 125), radius: 120),
          MovingCircle(color: Color.fromARGB(55, 230, 132, 125), radius: 150),
          MovingCircle(color: Color.fromARGB(45, 230, 132, 125), radius: 180),
          MovingCircle(color: Color.fromARGB(35, 230, 132, 125), radius: 200),
        ],
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.only(
            top: screenSize.height * 0.18,
            bottom: screenSize.height * 0.04,
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: screenSize.width * 0.06),
            child: Column(
              children: [
                FadeInDown(
                  duration: const Duration(milliseconds: 800),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Colors.white, Colors.grey.shade50],
                      ),
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
                    padding: EdgeInsets.all(screenSize.width * 0.06),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FadeInLeft(
                          duration: const Duration(milliseconds: 900),
                          child: _buildSectionTitle('Select Blood Type', Icons.water_drop),
                        ),
                        SizedBox(height: screenSize.height * 0.015),
                        FadeInRight(
                          duration: const Duration(milliseconds: 1000),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 15),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(color: Colors.grey.shade300),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isExpanded: true,
                                value: selectedBloodType,
                                hint: Text(
                                  'Select a blood type',
                                  style: GoogleFonts.roboto(
                                    color: Colors.grey[600],
                                    fontSize: 16,
                                  ),
                                ),
                                icon: Icon(Icons.arrow_drop_down, color: Styles.primaryColor),
                                onChanged: (String? value) {
                                  setState(() {
                                    selectedBloodType = value;
                                  });
                                },
                                items: availableBloodTypes.map<DropdownMenuItem<String>>((bloodType) {
                                  return DropdownMenuItem<String>(
                                    value: bloodType,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: Styles.primaryColor.withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              bloodType,
                                              style: GoogleFonts.montserrat(
                                                fontWeight: FontWeight.bold,
                                                color: Styles.primaryColor,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Text(
                                            '${getAvailableStock(bloodType)} units available',
                                            style: GoogleFonts.roboto(
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: screenSize.height * 0.025),

                FadeInDown(
                  duration: const Duration(milliseconds: 900),
                  child: Container(
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
                    padding: EdgeInsets.all(screenSize.width * 0.06),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FadeInLeft(
                          duration: const Duration(milliseconds: 1000),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.format_list_numbered,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Quantity (Units)',
                                style: GoogleFonts.montserrat(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: screenSize.height * 0.02),
                        FadeInRight(
                          duration: const Duration(milliseconds: 1100),
                          child: Column(
                            children: [
                              SliderTheme(
                                data: SliderThemeData(
                                  activeTrackColor: Colors.white,
                                  inactiveTrackColor: Colors.white.withOpacity(0.3),
                                  thumbColor: Colors.white,
                                  overlayColor: Colors.white.withOpacity(0.2),
                                  valueIndicatorColor: Colors.white,
                                  valueIndicatorTextStyle: const TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                child: Slider(
                                  min: 1,
                                  max: 10,
                                  divisions: 9,
                                  value: quantity.toDouble(),
                                  label: quantity.toString(),
                                  onChanged: (value) {
                                    setState(() {
                                      quantity = value.toInt();
                                    });
                                  },
                                ),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '1 Unit',
                                    style: GoogleFonts.roboto(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: 14,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    child: Text(
                                      '$quantity Units',
                                      style: GoogleFonts.montserrat(
                                        fontWeight: FontWeight.bold,
                                        color: Styles.primaryColor,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '10 Units',
                                    style: GoogleFonts.roboto(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: screenSize.height * 0.025),

                FadeInDown(
                  duration: const Duration(milliseconds: 1000),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Colors.white, Colors.grey.shade50],
                      ),
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
                    padding: EdgeInsets.all(screenSize.width * 0.06),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FadeInLeft(
                          duration: const Duration(milliseconds: 1100),
                          child: _buildSectionTitle('Medical Reason', Icons.medical_information),
                        ),
                        SizedBox(height: screenSize.height * 0.015),
                        FadeInRight(
                          duration: const Duration(milliseconds: 1200),
                          child: TextField(
                            controller: medicalReasonController,
                            maxLines: 4,
                            decoration: InputDecoration(
                              hintText: 'Please explain why you need this blood reservation...',
                              hintStyle: GoogleFonts.roboto(color: Colors.grey),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide(color: Styles.primaryColor),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                            ),
                            style: GoogleFonts.roboto(
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: screenSize.height * 0.04),

                FadeInUp(
                  duration: const Duration(milliseconds: 1200),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: ActionSlider.standard(
                      width: double.infinity,
                      backgroundColor: Styles.primaryColor,
                      toggleColor: Colors.white,
                      iconAlignment: Alignment.centerRight,
                      loadingIcon: SizedBox(
                        width: 25,
                        height: 25,
                        child: CircularProgressIndicator(
                          color: Styles.primaryColor,
                          strokeWidth: 3,
                        ),
                      ),
                      successIcon: const Icon(
                        Icons.check,
                        color: Colors.green,
                        size: 30,
                      ),
                      icon: Icon(
                        Icons.arrow_forward_ios,
                        color: Styles.primaryColor,
                        size: 20,
                      ),
                      height: 60,
                      child: Text(
                        'Slide to Confirm Reservation',
                        style: GoogleFonts.montserrat(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      action: (controller) async {
                        if (isSubmitting) return;

                        controller.loading();
                        await Future.delayed(const Duration(milliseconds: 400));

                        bool confirmed = await showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            title: Row(
                              children: [
                                Icon(Icons.help_outline, color: Styles.primaryColor),
                                const SizedBox(width: 10),
                                Text(
                                  'Confirm Reservation',
                                  style: GoogleFonts.montserrat(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            content: Text(
                              'Are you sure you want to reserve $quantity units of ${selectedBloodType ?? "blood"}?',
                              style: GoogleFonts.roboto(
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: Text(
                                  'Cancel',
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
                                  'Confirm',
                                  style: GoogleFonts.roboto(color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        );

                        if (confirmed) {
                          controller.success();
                          await _reserveBlood();
                        } else {
                          controller.reset();
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Styles.primaryColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: Styles.primaryColor,
            size: 24,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: GoogleFonts.montserrat(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter_moving_background/flutter_moving_background.dart';
import 'package:flutter_moving_background/enums/animation_types.dart';
import 'package:redpulse/features/models/inventory.dart';
import 'package:redpulse/features/screens/user/sub/reservationform.dart';
import 'package:redpulse/services/auth.dart';
import 'package:redpulse/utilities/constants/styles.dart';
import 'package:redpulse/widgets/button.dart';
import 'package:redpulse/widgets/statusbadge.dart';

class BloodBankDetailsScreen extends StatefulWidget {
  final String bloodBankId;

  const BloodBankDetailsScreen({super.key, required this.bloodBankId});

  @override
  BloodBankDetailsScreenState createState() => BloodBankDetailsScreenState();
}

class BloodBankDetailsScreenState extends State<BloodBankDetailsScreen> {
  late Future<List<InventoryModel>> _inventoryFuture;
  late Future<String> _bloodBankNameFuture;
  bool _isLoading = false;

  final AuthMethod _authMethod = AuthMethod();

  @override
  void initState() {
    super.initState();
    _inventoryFuture = _loadInventory();
    _bloodBankNameFuture = _authMethod.fetchBloodBankName(widget.bloodBankId);
  }

  // Fetch the inventory of the blood bank
  Future<List<InventoryModel>> _loadInventory() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('bloodbanks')
        .doc(widget.bloodBankId)
        .collection('inventories')
        .get();

    List<InventoryModel> inventoryList = snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;

      return InventoryModel(
        bloodType: data['bloodType'] as String? ?? 'Unknown',
        quantity: data['quantity'] as int? ?? 0,
        lastUpdated:
        (data['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
        status: data['status'] as String? ?? 'Unknown',
        bloodBankId: widget.bloodBankId,
      );
    }).toList();

    return inventoryList;
  }

  // Navigate to the reservation screen
  Future<void> _navigateToReservationScreen(
      List<InventoryModel> inventoryList) async {
    setState(() => _isLoading = true);

    try {
      bool? reserved = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ReservationFormScreen(
            bloodBankId: widget.bloodBankId,
            inventoryList: inventoryList,
          ),
        ),
      );

      if (reserved == true) {
        setState(() {
          _inventoryFuture = _loadInventory();
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return FutureBuilder<String>(
      future: _bloodBankNameFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingScaffold();
        } else if (snapshot.hasError || !snapshot.hasData) {
          return _buildErrorScaffold(snapshot.error?.toString());
        }

        final bloodBankName = snapshot.data!;

        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: PreferredSize(
            preferredSize: Size.fromHeight(screenSize.height * 0.09),
            child: FadeInDown(
              duration: const Duration(milliseconds: 600),
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
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.2),
                      blurRadius: 12,
                      spreadRadius: 2,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  leading: IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new_outlined,
                      size: 22,
                      color: Colors.white,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  title: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.local_hospital, color: Colors.white, size: 22),
                      SizedBox(width: screenSize.width * 0.02),
                      Flexible(
                        child: Text(
                          bloodBankName,
                          style: GoogleFonts.montserrat(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  centerTitle: true,
                ),
              ),
            ),
          ),
          body: MovingBackground(
            animationType: AnimationType.translation,
            backgroundColor: const Color.fromARGB(255, 248, 248, 248),
            circles: const [
              MovingCircle(color: Color.fromARGB(65, 230, 132, 125), radius: 120),
              MovingCircle(color: Color.fromARGB(55, 230, 132, 125), radius: 150),
              MovingCircle(color: Color.fromARGB(45, 230, 132, 125), radius: 180),
              MovingCircle(color: Color.fromARGB(35, 230, 132, 125), radius: 200),
            ],
            child: _buildBody(screenSize),
          ),
        );
      },
    );
  }

  Widget _buildBody(Size screenSize) {
    return FutureBuilder<List<InventoryModel>>(
      future: _inventoryFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: screenSize.height * 0.1),
                CircularProgressIndicator(color: Styles.primaryColor),
                SizedBox(height: 20),
                Text(
                  "Loading inventory...",
                  style: GoogleFonts.roboto(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        } else if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                'Error loading inventory: ${snapshot.error}',
                style: GoogleFonts.roboto(color: Colors.red[700]),
              ),
            ),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inventory_2_outlined,
                    size: 60,
                    color: Colors.grey[400]
                ),
                const SizedBox(height: 16),
                Text(
                  'No inventory available',
                  style: GoogleFonts.roboto(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        final inventoryList = snapshot.data!;

        return Column(
          children: [
            SizedBox(height: screenSize.height * 0.12), // Space for AppBar
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: screenSize.width * 0.06,
                vertical: screenSize.height * 0.01,
              ),
              child: FadeInDown(
                duration: const Duration(milliseconds: 800),
                child: Container(
                  padding: EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Styles.primaryColor.withOpacity(0.9),
                        Styles.primaryColor.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.2),
                        spreadRadius: 1,
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.water_drop_outlined,
                        color: Colors.white,
                        size: screenSize.width * 0.06,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "Available Blood Units",
                          style: GoogleFonts.montserrat(
                            fontSize: screenSize.width * 0.045,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Text(
                        "${inventoryList.length} types",
                        style: GoogleFonts.roboto(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.symmetric(
                  horizontal: screenSize.width * 0.06,
                  vertical: screenSize.height * 0.01,
                ),
                itemCount: inventoryList.length,
                itemBuilder: (context, index) {
                  final inventory = inventoryList[index];
                  return FadeInUp(
                    duration: Duration(milliseconds: 800 + (index * 100)),
                    child: Container(
                      margin: EdgeInsets.only(bottom: 15),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            spreadRadius: 1,
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(15),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Styles.primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    inventory.bloodType,
                                    style: GoogleFonts.robotoMono(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Styles.primaryColor,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 15),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            "Available Units",
                                            style: GoogleFonts.roboto(
                                              fontSize: 16,
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                          StatusBadge(status: inventory.status),
                                        ],
                                      ),
                                      SizedBox(height: 5),
                                      Text(
                                        "${inventory.quantity} units",
                                        style: GoogleFonts.montserrat(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: inventory.quantity > 0
                                              ? Colors.green.shade700
                                              : Colors.red.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: double.infinity,
                            height: 6,
                            decoration: BoxDecoration(
                              color: _getColorForStatus(inventory.status).withOpacity(0.2),
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(15),
                                bottomRight: Radius.circular(15),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            FadeInUp(
              duration: const Duration(milliseconds: 1000),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: screenSize.width * 0.06,
                  vertical: screenSize.height * 0.02,
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : () => _navigateToReservationScreen(inventoryList),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Styles.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 3,
                    ),
                    child: _isLoading
                        ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.0,
                      ),
                    )
                        : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.calendar_today_outlined),
                        const SizedBox(width: 10),
                        Text(
                          "Make Reservation",
                          style: GoogleFonts.montserrat(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Color _getColorForStatus(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return Colors.green;
      case 'low':
        return Colors.orange;
      case 'critical':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildLoadingScaffold() {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Styles.primaryColor),
            const SizedBox(height: 20),
            Text(
              "Loading blood bank details...",
              style: GoogleFonts.roboto(
                  fontSize: 16,
                  color: Colors.grey[700]
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScaffold(String? errorMessage) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Styles.primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Error',
          style: GoogleFonts.montserrat(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 70,
                color: Colors.red[300],
              ),
              const SizedBox(height: 20),
              Text(
                'Something went wrong',
                style: GoogleFonts.montserrat(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                errorMessage ?? "Error loading blood bank details",
                textAlign: TextAlign.center,
                style: GoogleFonts.roboto(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:redpulse/features/screens/admin/register.dart';
import 'package:redpulse/services/auth.dart';
import 'package:redpulse/utilities/constants/styles.dart';
import 'package:flutter_moving_background/flutter_moving_background.dart';
import 'package:flutter_moving_background/enums/animation_types.dart';
import 'package:animate_do/animate_do.dart';
import 'package:lottie/lottie.dart';
import 'package:redpulse/features/models/donation_statistics.dart';

class AdminHome extends StatefulWidget {
  final bool isAdminLinkedToBloodBank;
  final String bloodBankId;

  const AdminHome({
    super.key,
    required this.isAdminLinkedToBloodBank,
    required this.bloodBankId,
  });

  @override
  AdminHomeState createState() => AdminHomeState();
}

class AdminHomeState extends State<AdminHome> with SingleTickerProviderStateMixin {
  late String _bloodBankId;
  late Future<Map<String, dynamic>> _adminDetailsFuture;
  late Future<Map<String, dynamic>> _bloodBankDetailsFuture;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isRefreshing = false;

  // Statistics service and state variables
  final DonationStatisticsService _statisticsService = DonationStatisticsService();
  Map<String, dynamic> _bankStats = {
    'totalDonations': 0,
    'totalBloodDonatedMl': 0,
    'totalLivesSaved': 0,
    'uniqueDonors': 0
  };
  List<Map<String, dynamic>> _bankDonors = [];
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _fetchBloodBankId();
    _adminDetailsFuture = _fetchAdminDetails();
    _bloodBankDetailsFuture = _fetchBloodBankDetails();

    // Fetch blood bank statistics
    _fetchBloodBankStats();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _bloodBankDetailsFuture = _fetchBloodBankDetails();
  }

  // Function to fetch blood bank ID based on admin's user ID
  Future<void> _fetchBloodBankId() async {
    try {
      // Get the admin ID from the AuthMethod class
      String adminId = await AuthMethod().getAdminId();

      // Fetch the corresponding admin document from Firestore to get the bloodBankId
      DocumentSnapshot adminSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(adminId)
          .get();

      if (adminSnapshot.exists) {
        var data = adminSnapshot.data() as Map<String, dynamic>;
        String bloodBankId = data['bloodBankId'] ?? '';

        setState(() {
          _bloodBankId = bloodBankId;
        });
      } else {
        throw Exception("Admin document not found.");
      }
    } catch (e) {
      print("Error fetching blood bank ID: $e");
    }
  }

  // Function to fetch admin details
  Future<Map<String, dynamic>> _fetchAdminDetails() async {
    try {
      String adminId = await AuthMethod().getAdminId();
      DocumentSnapshot adminSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(adminId)
          .get();

      if (adminSnapshot.exists) {
        return adminSnapshot.data() as Map<String, dynamic>;
      } else {
        return {};
      }
    } catch (e) {
      print("Error fetching admin details: $e");
      return {};
    }
  }

  // Function to fetch blood bank details
  Future<Map<String, dynamic>> _fetchBloodBankDetails() async {
    try {
      await _fetchBloodBankId();
      if (_bloodBankId.isEmpty) {
        return {};
      }

      DocumentSnapshot bloodBankSnapshot = await FirebaseFirestore.instance
          .collection('bloodbanks')
          .doc(_bloodBankId)
          .get();

      if (bloodBankSnapshot.exists) {
        return bloodBankSnapshot.data() as Map<String, dynamic>;
      } else {
        return {};
      }
    } catch (e) {
      print("Error fetching blood bank details: $e");
      return {};
    }
  }

  // Fetch blood bank statistics
  Future<void> _fetchBloodBankStats() async {
    try {
      setState(() => _isLoadingStats = true);

      // Wait for blood bank ID to be available
      await _fetchBloodBankId();

      if (_bloodBankId.isNotEmpty) {
        // Get bank statistics
        final stats = await _statisticsService.getBloodBankStats(_bloodBankId);
        final donors = await _statisticsService.getBloodBankDonors(_bloodBankId);

        if (mounted) {
          setState(() {
            _bankStats = stats;
            _bankDonors = donors;
            _isLoadingStats = false;
          });
        }
      }
    } catch (e) {
      print('Error loading blood bank statistics: $e');
      if (mounted) {
        setState(() => _isLoadingStats = false);
      }
    }
  }

  // Refresh data method - similar to the one in UserHome
  Future<void> refreshData() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    try {
      // Refresh both admin and blood bank data
      _adminDetailsFuture = _fetchAdminDetails();
      await _fetchBloodBankId(); // Make sure we have the latest blood bank ID
      _bloodBankDetailsFuture = _fetchBloodBankDetails();

      // Refresh statistics
      await _fetchBloodBankStats();

      // Trigger a rebuild
      setState(() {});
    } catch (e) {
      print('Error refreshing data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to refresh: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
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
                padding: EdgeInsets.symmetric(horizontal: screenSize.width * 0.06, vertical: screenSize.height * 0.015),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        FadeInLeft(
                          duration: const Duration(milliseconds: 500),
                          child: Row(
                            children: [
                              Pulse(
                                duration: const Duration(milliseconds: 2000),
                                infinite: true,
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.white.withOpacity(0.3),
                                        spreadRadius: 1,
                                        blurRadius: 5,
                                      ),
                                    ],
                                  ),
                                  child: Image.asset(
                                    'assets/images/splash_logo.png',
                                    height: screenSize.height * 0.045,
                                    width: screenSize.height * 0.045,
                                  ),
                                ),
                              ),
                              SizedBox(width: screenSize.width * 0.03),
                              Text(
                                "RedPulse",
                                style: GoogleFonts.montserrat(
                                  fontSize: screenSize.width * 0.07,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.2,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      blurRadius: 2.0,
                                      color: Colors.black.withOpacity(0.1),
                                      offset: const Offset(1, 1),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        FadeInRight(
                          duration: const Duration(milliseconds: 600),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.all(8),
                            child: const Icon(
                              Icons.notifications_outlined,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: screenSize.height * 0.01),
                    FadeInRight(
                      duration: const Duration(milliseconds: 700),
                      child: Text(
                        "Saving lives, One drop at a time.",
                        style: GoogleFonts.roboto(
                          fontSize: screenSize.width * 0.038,
                          fontWeight: FontWeight.w400,
                          fontStyle: FontStyle.italic,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: Future.wait([
          _bloodBankDetailsFuture,
          _adminDetailsFuture,
        ]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
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
                    "Loading your profile...",
                    style: GoogleFonts.roboto(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return const Center(child: Text('No data available'));
          } else {
            final bloodBankDetails = snapshot.data![0] as Map<String, dynamic>;
            final adminDetails = snapshot.data![1] as Map<String, dynamic>;

            // Use blood bank details if available, otherwise fall back to admin details
            final email = widget.isAdminLinkedToBloodBank && bloodBankDetails.isNotEmpty
                ? bloodBankDetails['email'] ?? adminDetails['email'] ?? ''
                : adminDetails['email'] ?? '';

            final contact = widget.isAdminLinkedToBloodBank && bloodBankDetails.isNotEmpty
                ? bloodBankDetails['contactNumber'] ?? adminDetails['phoneNumber'] ?? ''
                : adminDetails['phoneNumber'] ?? '';

            final address = widget.isAdminLinkedToBloodBank && bloodBankDetails.isNotEmpty
                ? bloodBankDetails['address'] ?? adminDetails['address'] ?? ''
                : adminDetails['address'] ?? '';

            final bloodBankName = widget.isAdminLinkedToBloodBank && bloodBankDetails.isNotEmpty
                ? bloodBankDetails['bloodBankName'] ?? 'Blood Bank'
                : 'Register Your Blood Bank';

            return MovingBackground(
              animationType: AnimationType.translation,
              backgroundColor: const Color.fromARGB(255, 248, 248, 248),
              circles: const [
                MovingCircle(color: Color.fromARGB(65, 230, 132, 125), radius: 120),
                MovingCircle(color: Color.fromARGB(55, 230, 132, 125), radius: 150),
                MovingCircle(color: Color.fromARGB(45, 230, 132, 125), radius: 180),
                MovingCircle(color: Color.fromARGB(35, 230, 132, 125), radius: 200),
              ],
              child: RefreshIndicator(
                onRefresh: refreshData,
                color: Styles.primaryColor,
                backgroundColor: Colors.white,
                displacement: 20.0,
                strokeWidth: 3.0,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: EdgeInsets.only(
                    top: screenSize.height * 0.18 + 10,
                    bottom: screenSize.height * 0.02,
                  ),
                  child: Column(
                    children: [
                      // Welcome Card
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenSize.width * 0.06,
                          vertical: screenSize.height * 0.015,
                        ),
                        child: FadeInDown(
                          duration: const Duration(milliseconds: 800),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white,
                                  Colors.grey.shade50,
                                ],
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
                            padding: EdgeInsets.all(screenSize.width * 0.04),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  padding: EdgeInsets.all(screenSize.width * 0.025),
                                  decoration: BoxDecoration(
                                    color: Styles.primaryColor.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Styles.primaryColor.withOpacity(0.2),
                                        spreadRadius: 2,
                                        blurRadius: 7,
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.admin_panel_settings,
                                    color: Styles.primaryColor,
                                    size: screenSize.width * 0.08,
                                  ),
                                ),
                                SizedBox(width: screenSize.width * 0.04),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Welcome back,",
                                        style: GoogleFonts.roboto(
                                          fontSize: screenSize.width * 0.035,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      SizedBox(height: screenSize.height * 0.005),
                                      Text(
                                        "$bloodBankName!",
                                        style: GoogleFonts.montserrat(
                                          fontSize: screenSize.width * 0.05,
                                          fontWeight: FontWeight.bold,
                                          color: Styles.primaryColor,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: screenSize.width * 0.03,
                                    vertical: screenSize.height * 0.008,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Styles.primaryColor,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Styles.primaryColor.withOpacity(0.3),
                                        spreadRadius: 1,
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    "ADMIN",
                                    style: GoogleFonts.roboto(
                                      fontSize: screenSize.width * 0.04,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Contact Information Card
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenSize.width * 0.06,
                          vertical: screenSize.height * 0.015,
                        ),
                        child: FadeInUp(
                          duration: const Duration(milliseconds: 900),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white,
                                  Colors.grey.shade50,
                                ],
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
                            padding: EdgeInsets.all(screenSize.width * 0.04),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.contact_mail_outlined,
                                      color: Styles.primaryColor,
                                      size: screenSize.width * 0.06,
                                    ),
                                    SizedBox(width: screenSize.width * 0.02),
                                    Text(
                                      "Contact Information",
                                      style: GoogleFonts.montserrat(
                                        fontSize: screenSize.width * 0.045,
                                        fontWeight: FontWeight.w600,
                                        color: Styles.primaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: screenSize.height * 0.015),
                                _buildContactItem(context, Icons.email_outlined, "Email", email),
                                _buildContactItem(context, Icons.phone_outlined, "Phone", contact),
                                _buildContactItem(context, Icons.location_on_outlined, "Address", address),
                                if (!widget.isAdminLinkedToBloodBank)
                                  Padding(
                                    padding: EdgeInsets.only(top: screenSize.height * 0.015),
                                    child: ElevatedButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => const RegisterForm(),
                                          ),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Styles.primaryColor,
                                        foregroundColor: Colors.white,
                                        padding: EdgeInsets.symmetric(
                                          horizontal: screenSize.width * 0.04,
                                          vertical: screenSize.height * 0.015,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.add),
                                          SizedBox(width: screenSize.width * 0.02),
                                          const Text("Register Your Blood Bank"),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Bank Statistics Card
                      if (widget.isAdminLinkedToBloodBank)
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: screenSize.width * 0.06,
                            vertical: screenSize.height * 0.015,
                          ),
                          child: FadeInUp(
                            duration: const Duration(milliseconds: 1000),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.white,
                                    Colors.grey.shade50,
                                  ],
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
                              padding: EdgeInsets.all(screenSize.width * 0.04),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.analytics_outlined,
                                        color: Styles.primaryColor,
                                        size: screenSize.width * 0.06,
                                      ),
                                      SizedBox(width: screenSize.width * 0.02),
                                      Text(
                                        "Donation Statistics",
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
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      _buildStatItem(
                                        context,
                                        _isLoadingStats ? "..." : _bankStats['totalDonations'].toString(),
                                        "Donations",
                                        Icons.volunteer_activism,
                                        Styles.primaryColor,
                                      ),
                                      _buildStatItem(
                                        context,
                                        _isLoadingStats ? "..." : "${_bankStats['totalBloodDonatedMl']}ml",
                                        "Total Blood",
                                        Icons.water_drop,
                                        Styles.primaryColor,
                                      ),
                                      _buildStatItem(
                                        context,
                                        _isLoadingStats ? "..." : _bankStats['totalLivesSaved'].toString(),
                                        "Lives Saved",
                                        Icons.favorite,
                                        Styles.primaryColor,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                      // Donors List Card
                      if (widget.isAdminLinkedToBloodBank)
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: screenSize.width * 0.06,
                            vertical: screenSize.height * 0.015,
                          ),
                          child: FadeInUp(
                            duration: const Duration(milliseconds: 1100),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.white,
                                    Colors.grey.shade50,
                                  ],
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
                              padding: EdgeInsets.all(screenSize.width * 0.04),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.people_outline,
                                            color: Styles.primaryColor,
                                            size: screenSize.width * 0.06,
                                          ),
                                          SizedBox(width: screenSize.width * 0.02),
                                          Text(
                                            "Recent Donors",
                                            style: GoogleFonts.montserrat(
                                              fontSize: screenSize.width * 0.045,
                                              fontWeight: FontWeight.w600,
                                              color: Styles.primaryColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        "${_bankDonors.length} donors",
                                        style: GoogleFonts.roboto(
                                          fontSize: screenSize.width * 0.035,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: screenSize.height * 0.015),
                                  _isLoadingStats
                                      ? Center(
                                    child: CircularProgressIndicator(
                                      color: Styles.primaryColor,
                                    ),
                                  )
                                      : _bankDonors.isEmpty
                                      ? Padding(
                                    padding: EdgeInsets.all(screenSize.height * 0.02),
                                    child: Text(
                                      "No donors yet",
                                      style: GoogleFonts.roboto(
                                        fontSize: screenSize.width * 0.04,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  )
                                      : ListView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: _bankDonors.length > 5 ? 5 : _bankDonors.length,
                                    itemBuilder: (context, index) {
                                      final donor = _bankDonors[index];
                                      return ListTile(
                                        leading: CircleAvatar(
                                          backgroundImage: donor['profileImageUrl'] != null
                                              ? NetworkImage(donor['profileImageUrl'])
                                              : const AssetImage('assets/images/default_profile.jpg')
                                          as ImageProvider,
                                        ),
                                        title: Text(
                                          donor['name'] ?? 'Unknown',
                                          style: GoogleFonts.roboto(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        subtitle: Text(
                                          "Blood Type: ${donor['bloodType']} • ${donor['donationCount']} donations",
                                        ),
                                        trailing: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Styles.primaryColor.withOpacity(0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.water_drop,
                                            color: Styles.primaryColor,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  if (_bankDonors.length > 5)
                                    TextButton(
                                      onPressed: () {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('View all donors functionality coming soon'),
                                          ),
                                        );
                                      },
                                      child: Text(
                                        "View all donors",
                                        style: TextStyle(color: Styles.primaryColor),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }
        },
      ),
    );
  }

  // Helper method to build contact information items
  Widget _buildContactItem(BuildContext context, IconData icon, String title, String value) {
    final screenSize = MediaQuery.of(context).size;
    return Padding(
      padding: EdgeInsets.only(bottom: screenSize.height * 0.01),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: Colors.grey[600],
            size: screenSize.width * 0.05,
          ),
          SizedBox(width: screenSize.width * 0.02),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                  fontSize: screenSize.width * 0.035,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: screenSize.width * 0.04,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Helper method to build statistics items
  Widget _buildStatItem(
      BuildContext context,
      String value,
      String label,
      IconData icon,
      Color color
      ) {
    final screenSize = MediaQuery.of(context).size;

    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(screenSize.width * 0.025),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: color,
            size: screenSize.width * 0.05,
          ),
        ),
        SizedBox(height: screenSize.height * 0.008),
        Text(
          value,
          style: GoogleFonts.montserrat(
            fontSize: screenSize.width * 0.045,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.roboto(
            fontSize: screenSize.width * 0.03,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
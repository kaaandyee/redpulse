import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:redpulse/features/models/users.dart';
import 'package:provider/provider.dart';
import 'package:redpulse/features/screens/user/sub/userCardsHome.dart';
import 'package:redpulse/utilities/constants/styles.dart';
import 'package:redpulse/features/screens/user/sub/bloodCompatibility.dart';
import 'package:flutter_moving_background/flutter_moving_background.dart';
import 'package:flutter_moving_background/enums/animation_types.dart';
import 'package:animate_do/animate_do.dart';
import 'package:lottie/lottie.dart';

import '../../models/donation_statistics.dart';

class UserHome extends StatefulWidget {
  const UserHome({super.key});

  @override
  State<UserHome> createState() => _UserHomeState();
}

class _UserHomeState extends State<UserHome> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final DonationStatisticsService _statisticsService = DonationStatisticsService();

  // Statistics state variables
  int totalDonations = 0;
  int totalBloodDonatedMl = 0;
  int totalLivesSaved = 0;
  bool isLoadingStats = true;

  @override
  void initState() {
    super.initState();
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

    // Fetch user statistics when widget initializes
    _fetchUserStatistics();
  }

  Future<void> _fetchUserStatistics() async {
    final user = Provider.of<UserAdminModel?>(context, listen: false);
    if (user != null && user.id != null) {
      try {
        setState(() => isLoadingStats = true);

        final stats = await _statisticsService.getUserDonationStats(user.id!);

        setState(() {
          totalDonations = stats['totalDonations'];
          totalBloodDonatedMl = stats['totalBloodDonatedMl'];
          totalLivesSaved = stats['totalLivesSaved'];
          isLoadingStats = false;
        });
      } catch (e) {
        print('Error loading statistics: $e');
        setState(() => isLoadingStats = false);
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserAdminModel?>(context);
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
      body: user == null
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
              "Loading your profile...",
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.only(
                top: screenSize.height * 0.18 + 10, // Account for AppBar height
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
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Styles.primaryColor.withOpacity(0.2),
                                    spreadRadius: 2,
                                    blurRadius: 7,
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: screenSize.width * 0.08,
                                backgroundImage: (user.profileImageUrl != null &&
                                    user.profileImageUrl!.isNotEmpty)
                                    ? NetworkImage(user.profileImageUrl!)
                                    : const AssetImage('assets/images/default_profile.jpg') as ImageProvider,
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
                                    "${user.fullName}!",
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
                            // Blood Type Badge
                            if (user.bloodType != null && user.bloodType!.isNotEmpty)
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
                                  user.bloodType!,
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

                  // Stats Summary
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
                        padding: EdgeInsets.all(screenSize.width * 0.04),
                        child: Column(
                          children: [
                            Text(
                              "Your Donation Impact",
                              style: GoogleFonts.montserrat(
                                fontSize: screenSize.width * 0.045,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: screenSize.height * 0.01),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildStatItem(
                                    context,
                                    isLoadingStats ? "..." : totalDonations.toString(),
                                    "Donations",
                                    Icons.favorite_border
                                ),
                                _buildDivider(),
                                _buildStatItem(
                                    context,
                                    isLoadingStats ? "..." : "${totalBloodDonatedMl}ml",
                                    "Total",
                                    Icons.water_drop_outlined
                                ),
                                _buildDivider(),
                                _buildStatItem(
                                    context,
                                    isLoadingStats ? "..." : totalLivesSaved.toString(),
                                    "Lives Saved",
                                    Icons.person_outline
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: screenSize.height * 0.01),

                  // Blood Compatibility Card
                  FadeInUp(
                    duration: const Duration(milliseconds: 1000),
                    child: const BloodCompatibilityCard(),
                  ),

                  SizedBox(height: screenSize.height * 0.01),

                  // User Cards Home
                  FadeInUp(
                    duration: const Duration(milliseconds: 1100),
                    child: const HeroMode(
                      enabled: true,
                      child: userCardsHome(),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
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
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:redpulse/features/models/users.dart'; // your user model
import 'package:provider/provider.dart';
import 'package:redpulse/features/screens/user/sub/userCardsHome.dart';
import 'package:redpulse/utilities/constants/styles.dart';

class UserHome extends StatelessWidget {
  const UserHome({super.key});

  @override
<<<<<<< Updated upstream
=======
  State<UserHome> createState() => _UserHomeState();
}

class _UserHomeState extends State<UserHome>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final DonationStatisticsService _statisticsService =
      DonationStatisticsService();
  bool _isRefreshing = false;
  bool _isPageRefreshing = false;

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

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserStatistics() async {
    final user = Provider.of<UserAdminModel?>(context, listen: false);
    if (user != null && user.id != null) {
      try {
        setState(() => isLoadingStats = true);

        final stats = await _statisticsService.getUserDonationStats(user.id!);

        if (mounted) {
          setState(() {
            totalDonations = stats['totalDonations'];
            totalBloodDonatedMl = stats['totalBloodDonatedMl'];
            totalLivesSaved = stats['totalLivesSaved'];
            isLoadingStats = false;
          });
        }
      } catch (e) {
        print('Error loading statistics: $e');
        if (mounted) {
          setState(() => isLoadingStats = false);
        }
      }
    }
  }

  Future<void> refreshData() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
      _isPageRefreshing = true;
    });

    try {
      // Refresh user from provider
      final userProvider = Provider.of<UserAdminModel?>(context, listen: false);
      if (userProvider != null && userProvider.id != null) {
        // Refresh user data
        await userProvider.refreshUserData();

        // Refresh statistics
        await _fetchUserStatistics();
      }
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
          _isPageRefreshing = false;
        });
      }
    }
  }

  @override
>>>>>>> Stashed changes
  Widget build(BuildContext context) {
    // Read the latest user data from the Provider.
    final user = Provider.of<UserAdminModel?>(context);

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(120),
        child: AppBar(
          backgroundColor: Styles.primaryColor,
          elevation: 0,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
<<<<<<< Updated upstream
          ),
          flexibleSpace: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 50),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  Text("RED PULSE", style: Styles.headerStyle1),
                  Text(
                    "Saving lives, One drop at a time.",
                    style: Styles.headerStyle3.copyWith(fontSize: 15),
                  ),
                ],
=======
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: screenSize.width * 0.06,
                    vertical: screenSize.height * 0.015),
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
>>>>>>> Stashed changes
              ),
            ),
          ),
        ),
      ),
      body: user == null
<<<<<<< Updated upstream
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                // Row containing the profile image and welcome text.
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 50, vertical: 30),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Profile Image
                      CircleAvatar(
                        radius: 30,
                        backgroundImage: (user.profileImageUrl != null &&
                                user.profileImageUrl!.isNotEmpty)
                            ? NetworkImage(user.profileImageUrl!)
                            : const AssetImage(
                                    'assets/images/default_profile.jpg')
                                as ImageProvider,
                      ),
                      const SizedBox(width: 15),
                      // Welcome Text
                      Expanded(
                        child: Text(
                          "Welcome, ${user.fullName}!",
                          style: GoogleFonts.robotoMono(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Styles.primaryColor,
                          ),
=======
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Lottie.asset(
                    'assets/animations/blood_loading.json',
                    width: 150,
                    height: 150,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const CircularProgressIndicator(
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
                MovingCircle(
                    color: Color.fromARGB(65, 230, 132, 125), radius: 120),
                MovingCircle(
                    color: Color.fromARGB(55, 230, 132, 125), radius: 150),
                MovingCircle(
                    color: Color.fromARGB(45, 230, 132, 125), radius: 180),
                MovingCircle(
                    color: Color.fromARGB(35, 230, 132, 125), radius: 200),
              ],
              child: RefreshIndicator(
                onRefresh: refreshData,
                color: Styles.primaryColor,
                backgroundColor: Colors.white,
                displacement: 40.0,
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
                          child: Stack(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: _isPageRefreshing
                                        ? [
                                            Colors.grey.shade100,
                                            Colors.grey.shade200
                                          ]
                                        : [Colors.white, Colors.grey.shade50],
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
                                padding:
                                    EdgeInsets.all(screenSize.width * 0.04),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Styles.primaryColor
                                                .withOpacity(0.2),
                                            spreadRadius: 2,
                                            blurRadius: 7,
                                          ),
                                        ],
                                      ),
                                      child: CircleAvatar(
                                        radius: screenSize.width * 0.08,
                                        backgroundImage: (user
                                                        .profileImageUrl !=
                                                    null &&
                                                user.profileImageUrl!
                                                    .isNotEmpty)
                                            ? NetworkImage(
                                                user.profileImageUrl!)
                                            : const AssetImage(
                                                    'assets/images/default_profile.jpg')
                                                as ImageProvider,
                                      ),
                                    ),
                                    SizedBox(width: screenSize.width * 0.04),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            "Welcome back,",
                                            style: GoogleFonts.roboto(
                                              fontSize:
                                                  screenSize.width * 0.035,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          SizedBox(
                                            height: screenSize.height * 0.005,
                                            width: 10,
                                          ),
                                          Text(
                                            "${user.fullName}!",
                                            style: GoogleFonts.montserrat(
                                              fontSize:
                                                  screenSize.width * 0.042,
                                              fontWeight: FontWeight.bold,
                                              color: Styles.primaryColor,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            textAlign: TextAlign.left,
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Blood Type Badge
                                    if (user.bloodType != null &&
                                        user.bloodType.isNotEmpty)
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: screenSize.width * 0.03,
                                          vertical: screenSize.height * 0.008,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Styles.primaryColor,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Styles.primaryColor
                                                  .withOpacity(0.3),
                                              spreadRadius: 1,
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Text(
                                          user.bloodType,
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
                              if (_isPageRefreshing)
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.7),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Center(
                                      child: SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          color: Styles.primaryColor,
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
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
                          child: Stack(
                            children: [
                              Container(
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
                                      color:
                                          Styles.primaryColor.withOpacity(0.3),
                                      spreadRadius: 1,
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                padding:
                                    EdgeInsets.all(screenSize.width * 0.04),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          "Your Donation Impact",
                                          style: GoogleFonts.montserrat(
                                            fontSize: screenSize.width * 0.045,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                        if (_isPageRefreshing)
                                          Padding(
                                            padding: EdgeInsets.only(left: 8.0),
                                            child: SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    SizedBox(height: screenSize.height * 0.01),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        _buildStatItem(
                                            context,
                                            isLoadingStats || _isPageRefreshing
                                                ? "..."
                                                : totalDonations.toString(),
                                            "Donations",
                                            Icons.favorite_border),
                                        _buildDivider(),
                                        _buildStatItem(
                                            context,
                                            isLoadingStats || _isPageRefreshing
                                                ? "..."
                                                : "${totalBloodDonatedMl}ml",
                                            "Total",
                                            Icons.water_drop_outlined),
                                        _buildDivider(),
                                        _buildStatItem(
                                            context,
                                            isLoadingStats || _isPageRefreshing
                                                ? "..."
                                                : totalLivesSaved.toString(),
                                            "Lives Saved",
                                            Icons.person_outline),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              if (_isPageRefreshing && !isLoadingStats)
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color:
                                          Styles.primaryColor.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Center(
                                      child: SizedBox(
                                        width: 30,
                                        height: 30,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: screenSize.height * 0.01),

                      // Blood Compatibility Card with refresh state
                      FadeInUp(
                        duration: const Duration(milliseconds: 1000),
                        child: Stack(
                          children: [
                            const BloodCompatibilityCard(),
                            if (_isPageRefreshing)
                              Positioned.fill(
                                child: Container(
                                  margin: EdgeInsets.symmetric(
                                      horizontal: screenSize.width * 0.06),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.6),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      color: Styles.primaryColor,
                                      strokeWidth: 2.5,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                      SizedBox(height: screenSize.height * 0.01),

                      // User Cards Home with refresh state
                      FadeInUp(
                        duration: const Duration(milliseconds: 1100),
                        child: Stack(
                          children: [
                            const HeroMode(
                              enabled: true,
                              child: userCardsHome(),
                            ),
                            if (_isPageRefreshing)
                              Positioned.fill(
                                child: Container(
                                  margin: EdgeInsets.symmetric(
                                      horizontal: screenSize.width * 0.06),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.6),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      color: Styles.primaryColor,
                                      strokeWidth: 2.5,
                                    ),
                                  ),
                                ),
                              ),
                          ],
>>>>>>> Stashed changes
                        ),
                      ),
                    ],
                  ),
                ),
<<<<<<< Updated upstream
                // Other content on the home screen.
                const userCardsHome(),
              ],
            ),
    );
  }
=======
              ),
            ),
    );
  }

  // Updated _buildStatItem method to handle both local and global refresh states
  Widget _buildStatItem(
      BuildContext context, String value, String label, IconData icon) {
    final screenSize = MediaQuery.of(context).size;
    final isLoading = isLoadingStats || _isPageRefreshing;

    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(screenSize.width * 0.025),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: isLoading
              ? SizedBox(
                  width: screenSize.width * 0.05,
                  height: screenSize.width * 0.05,
                  child: const CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Icon(
                  icon,
                  color: Colors.white,
                  size: screenSize.width * 0.05,
                ),
        ),
        SizedBox(height: screenSize.height * 0.008),
        isLoading
            ? Container(
                width: screenSize.width * 0.15,
                height: screenSize.width * 0.045,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
              )
            : Text(
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
>>>>>>> Stashed changes
}

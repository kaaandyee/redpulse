import 'package:flutter/material.dart';
import 'package:liquid_swipe/liquid_swipe.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class OnBoardingScreen extends StatefulWidget {
  const OnBoardingScreen({super.key});

  @override
  State<OnBoardingScreen> createState() => _OnBoardingScreenState();
}

class _OnBoardingScreenState extends State<OnBoardingScreen> {
  final controller = LiquidController();

  int currentPage = 0;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(alignment: Alignment.center, children: [
        LiquidSwipe(
          pages: [
            Container(
                padding: const EdgeInsets.all(35),
                color: Colors.white,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      "Life Starts Here",
                      style:
                          TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(
                      height: size.height * 0.3,
                      child: Image.asset(
                        'assets/images/onboarding_images/onboard_image1.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                    Column(
                      children: [
                        Text(
                          "Welcome to Red Pulse! Find nearby blood banks and save lives with ease.",
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w300),
                          textAlign: TextAlign.center,
                        )
                      ],
                    ),
                    Text(
                      "1/5",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(
                      height: 50,
                    ),
                  ],
                )),
            Container(
                color: const Color.fromARGB(255, 178, 229, 253),
                padding: const EdgeInsets.all(35),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      "Find in a Flash",
                      style:
                          TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(
                      height: size.height * 0.3,
                      child: Image.asset(
                        'assets/images/onboarding_images/onboard_image2.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                    Column(
                      children: [
                        Text(
                          "Discover blood banks near you in real-time!",
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w300),
                          textAlign: TextAlign.center,
                        )
                      ],
                    ),
                    Text(
                      "2/5",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(
                      height: 50,
                    ),
                  ],
                )),
            Container(
                color: const Color.fromARGB(255, 235, 255, 213),
                padding: const EdgeInsets.all(35),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      "Stock at a Glance",
                      style:
                          TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(
                      height: size.height * 0.3,
                      child: Image.asset(
                        'assets/images/onboarding_images/onboard_image3.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                    Column(
                      children: [
                        Text(
                          "See updates on blood stock levels before you visit!",
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w300),
                          textAlign: TextAlign.center,
                        )
                      ],
                    ),
                    Text(
                      "3/5",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(
                      height: 40,
                    ),
                  ],
                )),
            Container(
                color: const Color.fromARGB(255, 247, 220, 252),
                padding: const EdgeInsets.all(35),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      "Reserve with Ease",
                      style:
                          TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(
                      height: size.height * 0.3,
                      child: Image.asset(
                        'assets/images/onboarding_images/onboard_image4.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                    Column(
                      children: [
                        Text(
                          "Reserve blood instantly for emergencies or planned needs!",
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w300),
                          textAlign: TextAlign.center,
                        )
                      ],
                    ),
                    Text(
                      "4/5",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(
                      height: 40,
                    ),
                  ],
                )),
            Container(
                color: const Color.fromARGB(255, 252, 219, 169),
                padding: const EdgeInsets.all(35),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      "Join the Pulse",
                      style:
                          TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(
                      height: size.height * 0.3,
                      child: Image.asset(
                        'assets/images/onboarding_images/onboard_image5.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                    Column(
                      children: [
                        Text(
                          "Join the mission to save lives—sign up now!",
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w300),
                          textAlign: TextAlign.center,
                        )
                      ],
                    ),
                    Text(
                      "5/5",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(
                      height: 40,
                    ),
                  ],
                ))
          ],
          //slideIconWidget: Icon(Icons.arrow_back_ios_new),
          //enableSideReveal: false,
          liquidController: controller,
          onPageChangeCallback: onPageChangedCallback,
          fullTransitionValue: 800,
          enableLoop: false,
          waveType: WaveType.liquidReveal,
        ),
        Positioned(
          bottom: 90,
          child: currentPage != 4
              ? OutlinedButton(
                  onPressed: () {
                    int nextPage = controller.currentPage + 1;
                    controller.animateToPage(page: nextPage);
                  },
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.black26),
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(20),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: Color(0xff272727),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_forward_ios),
                  ),
                )
              : ElevatedButton(
                  onPressed: () async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool(
                        'seenOnboarding', true); // Save that onboarding is done
                    Navigator.pushReplacementNamed(context, '/wrapper');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xff272727),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'Get Started',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
        ),
        if (currentPage != 4)
          Positioned(
            top: 50,
            right: 20,
            child: TextButton(
              onPressed: () => controller.jumpToPage(page: 4),
              child: const Text(
                "Skip",
                style: TextStyle(color: Colors.grey, fontSize: 18),
              ),
            ),
          ),
        Positioned(
            bottom: 25,
            child: AnimatedSmoothIndicator(
              activeIndex: controller.currentPage,
              count: 5,
              effect: WormEffect(
                activeDotColor: Color.fromARGB(255, 243, 77, 77),
                dotHeight: 5.0,
              ),
            )),
      ]),
    );
  }

  void onPageChangedCallback(int activePageIndex) {
    setState(() {
      currentPage = activePageIndex;
    });
  }
}

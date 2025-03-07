import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

// Data model for a blood group
class BloodGroup {
  final String group;
  final String imageUrl;
  final String description;

  BloodGroup({
    required this.group,
    required this.imageUrl,
    required this.description,
  });
}

// Simulated API call that fetches blood group data
Future<List<BloodGroup>> fetchBloodGroups() async {
  // Simulate network delay
  await Future.delayed(const Duration(seconds: 2));

  // Return sample data for blood groups with placeholder images
  return [
    BloodGroup(
      group: "A+",
      imageUrl: "https://picsum.photos/300/200",
      description:
      "- People with A+ blood can donate to A+ and AB+ blood types.\n- They can receive blood from A+, A-, O+ and O- blood types.",
    ),
    BloodGroup(
      group: "A-",
      imageUrl: "https://picsum.photos/300/200",
      description:
      "- People with A- blood can donate to A-, A+, AB- and AB+ blood types.\n- They can receive blood from A- and O- blood types.",
    ),
    BloodGroup(
      group: "AB+",
      imageUrl: "https://picsum.photos/300/200",
      description:
      "- People with AB+ blood are universal recipients, meaning they can receive blood from all blood types.\n- They can only donate to AB+ blood types.",
    ),
    BloodGroup(
      group: "AB-",
      imageUrl: "https://picsum.photos/300/200",
      description:
      "- People with AB- blood can donate to AB- and AB+ blood types.\n- They can receive blood from A-, B-, AB- and O- blood types.",
    ),
    BloodGroup(
      group: "B+",
      imageUrl: "https://picsum.photos/300/200",
      description:
      "- People with B+ blood can donate to B+ and AB+ blood types.\n- They can receive blood from B+, B-, O+ and O- blood types.",
    ),
    BloodGroup(
      group: "B-",
      imageUrl: "https://picsum.photos/300/200",
      description:
      "- People with B- blood can donate to B-, B+, AB- and AB+ blood types.\n- They can receive blood from B- and O- blood types.",
    ),
    BloodGroup(
      group: "O+",
      imageUrl: "https://picsum.photos/300/200",
      description:
      "- People with O+ blood can donate to A+, B+, AB+ and O+ blood types.\n- They can receive blood from O+ and O- blood types.",
    ),
    BloodGroup(
      group: "O-",
      imageUrl: "https://picsum.photos/300/200",
      description:
      "- People with O- blood are universal donors, meaning they can donate to all blood types.\n- They can only receive blood from O- blood types.",
    ),
  ];
}

class userCardsHome extends StatefulWidget {
  const userCardsHome({super.key});

  @override
  State<userCardsHome> createState() => _userCardsHomeState();
}

class _userCardsHomeState extends State<userCardsHome> {
  late Future<List<BloodGroup>> bloodGroupsFuture;

  @override
  void initState() {
    super.initState();
    bloodGroupsFuture = fetchBloodGroups();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<BloodGroup>>(
      future: bloodGroupsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return const Center(child: Text("Error fetching blood groups"));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("No blood group data available"));
        } else {
          final bloodGroups = snapshot.data!;
          return LayoutBuilder(
            builder: (context, constraints) {
              // Set a maximum container width (e.g., 1200px).
              const double maxContainerWidth = 1200.0;
              final containerWidth = constraints.maxWidth < maxContainerWidth
                  ? constraints.maxWidth
                  : maxContainerWidth;

              // Determine number of columns based on the available width.
              final int crossAxisCount =
              containerWidth < 600 ? 1 : (containerWidth / 300).floor();

              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: maxContainerWidth),
                  child: MasonryGridView.count(
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: 20,
                    crossAxisSpacing: 20,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: bloodGroups.length,
                    itemBuilder: (context, index) {
                      final group = bloodGroups[index];
                      return Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Display the blood group image.
                            ClipRRect(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(15),
                                topRight: Radius.circular(15),
                              ),
                              child: Image.network(
                                group.imageUrl,
                                height: 150,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                            // Display the blood group name and description.
                            Padding(
                              padding: const EdgeInsets.all(15),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    group.group,
                                    style: GoogleFonts.robotoMono(
                                      fontSize: 30,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    group.description,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          );
        }
      },
    );
  }
}
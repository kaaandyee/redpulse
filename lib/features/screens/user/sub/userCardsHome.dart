import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:redpulse/features/models/blood_group_details.dart';
import 'package:redpulse/features/models/blood_group_model.dart';

Future<List<BloodGroup>> fetchBloodGroups() async {
  await Future.delayed(const Duration(seconds: 1));

  return [
    BloodGroup(
      group: "A+",
      imageUrl: "https://picsum.photos/300/200?random=1",
      description: "People with A+ blood can donate to A+ and AB+ blood types.",
    ),
    BloodGroup(
      group: "A-",
      imageUrl: "https://picsum.photos/300/200?random=2",
      description: "People with A- blood can donate to A-, A+, AB-, and AB+.",
    ),
    BloodGroup(
      group: "B+",
      imageUrl: "https://picsum.photos/300/200?random=3",
      description: "People with B+ blood can donate to B+ and AB+.",
    ),
    BloodGroup(
      group: "B-",
      imageUrl: "https://picsum.photos/300/200?random=4",
      description: "People with B- blood can donate to B-, B+, AB-, and AB+.",
    ),
    BloodGroup(
      group: "AB+",
      imageUrl: "https://picsum.photos/300/200?random=5",
      description: "Universal recipient for plasma. Can donate only to AB+.",
    ),
    BloodGroup(
      group: "AB-",
      imageUrl: "https://picsum.photos/300/200?random=6",
      description: "Can donate to AB- and AB+.",
    ),
    BloodGroup(
      group: "O+",
      imageUrl: "https://picsum.photos/300/200?random=7",
      description: "Can donate to all positive blood types.",
    ),
    BloodGroup(
      group: "O-",
      imageUrl: "https://picsum.photos/300/200?random=8",
      description: "Universal donor. Can donate to all blood types.",
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
              const double maxContainerWidth = 1200.0;
              final containerWidth = constraints.maxWidth < maxContainerWidth
                  ? constraints.maxWidth
                  : maxContainerWidth;
              final int crossAxisCount =
              containerWidth < 600 ? 1 : (containerWidth / 300).floor();

              return Center(
                child: ConstrainedBox(
                  constraints:
                  const BoxConstraints(maxWidth: maxContainerWidth),
                  child: MasonryGridView.count(
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: 20,
                    crossAxisSpacing: 20,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: bloodGroups.length,
                    itemBuilder: (context, index) {
                      final group = bloodGroups[index];
                      return InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BloodGroupDetailsScreen(
                                bloodGroup: group,
                              ),
                            ),
                          );
                        },
                        child: Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Hero(
                                tag: 'blood-image-${group.group}',
                                child: ClipRRect(
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
                              ),
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
                                      style:
                                      const TextStyle(fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
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

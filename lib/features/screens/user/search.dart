import 'package:flutter/material.dart';
import 'package:redpulse/utilities/constants/map.dart';
import 'package:redpulse/utilities/constants/styles.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Styles.accentColor,
      ),
      home:const MapScreen(),
    );
  }
}














































/*import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:redpulse/utilities/styles.dart';
//import 'package:redpulse/widgets/button.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Styles.tertiaryColor,
      body: ListView(
        children: [
          Column(
            children: [
              Container(
                height: 150,
                color: Styles.primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 50),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("RED PULSE", style: Styles.headerStyle1),
                        Text("Saving lives, One drop at a time.", style: Styles.headerStyle3),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(
                height: 2400,
                child: content(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget content() {
    return FlutterMap(
      options: const MapOptions(
        initialCenter: LatLng(10.31672, 123.89071),
        initialZoom: 11,
        interactionOptions: InteractionOptions(flags: ~InteractiveFlag.doubleTapZoom),
      ),
      children: [
        openStreetMapTileLayer,
      ],
    );
  }
}

TileLayer get openStreetMapTileLayer => TileLayer(
  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  userAgentPackageName: 'dev.fleaflet.flutter_map.example',
);*/
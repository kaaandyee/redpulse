Hello, if naa gani Firebase Default Error or something similar, adto sa main.dart 
then sa:

 if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

add lang og random name like

 if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      name: "RedPulse" // If sigeg balik error gani, e change2x lng ni, thank youu
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

import 'package:cloud_firestore/cloud_firestore.dart';

class Inventory {
  final String bloodType;
  final String status;
  final int quantity;
  final String bloodBankId;
  final int donated;
  final DateTime expiration;
  final DateTime lastUpdated;

  Inventory({
    required this.bloodType,
    required this.status,
    required this.quantity,
    required this.bloodBankId,
    required this.donated,
    required this.expiration,
    required this.lastUpdated,
  });

  // Convert a Firestore document to an Inventory object
  factory Inventory.fromFirestore(Map<String, dynamic> firestoreData) {
    return Inventory(
      bloodType: firestoreData['inventory_bloodtype'],
      status: firestoreData['inventory_status'],
      quantity: firestoreData['inventory_quantity'],
      bloodBankId: firestoreData['bloodbank_id'],
      donated: firestoreData['inventory_donated'],
      expiration: (firestoreData['inventory_expiration'] as Timestamp).toDate(),
      lastUpdated: (firestoreData['inventory_updated'] as Timestamp).toDate(),
    );
  }

  // Convert an Inventory object to a Firestore-compatible map
  Map<String, dynamic> toMap() {
    return {
      'inventory_bloodtype': bloodType,
      'inventory_status': status,
      'inventory_quantity': quantity,
      'bloodbank_id': bloodBankId,
      'inventory_donated': donated,
      'inventory_expiration': expiration,
      'inventory_updated': lastUpdated,
    };
  }

  @override
  String toString() {
    return 'Inventory(bloodType: $bloodType, status: $status, quantity: $quantity, bloodBankId: $bloodBankId, donated: $donated, expiration: $expiration, lastUpdated: $lastUpdated)';
  }

  // Method to initialize blood type inventory with default values
  static Future<void> initializeBloodTypeInventory(String bloodBankId) async {
    // Blood types to initialize
    List<String> bloodTypes = ['A+', 'A-', 'B+', 'B-',  'O+', 'O-', 'AB+', 'AB-'];

    // Loop through each blood type and initialize with default values
    for (String bloodType in bloodTypes) {
      DocumentReference docRef = FirebaseFirestore.instance
          .collection('bloodbanks')
          .doc(bloodBankId)
          .collection('inventories')
          .doc(bloodType);

      // Check if the document already exists
      DocumentSnapshot snapshot = await docRef.get();
      if (!snapshot.exists) {
        // If it doesn't exist, initialize with default values
        Inventory newInventory = Inventory(
          bloodType: bloodType,
          status: 'unavailable',  // Default status
          quantity: 0,            // Default quantity
          bloodBankId: bloodBankId,
          donated: 0,             // Default donated
          expiration: DateTime(2100, 1, 1), // Default expiration date (far future)
          lastUpdated: DateTime.now(),  // Current time
        );

        // Set the document in Firestore
        await docRef.set(newInventory.toMap());
        print('Inventory for $bloodType initialized.');
      }
    }
  }

  // Access the inventory for a specific blood bank and blood type
  static Future<Inventory?> getInventory(String bloodBankId, String bloodType) async {
    DocumentSnapshot snapshot = await FirebaseFirestore.instance
        .collection('bloodbanks')
        .doc(bloodBankId)
        .collection('inventories')
        .doc(bloodType)
        .get();

    if (snapshot.exists) {
      return Inventory.fromFirestore(snapshot.data() as Map<String, dynamic>);
    } else {
      print('Inventory for $bloodType not found.');
      return null;
    }
  }

  // Update or add inventory document in Firestore
  Future<void> updateInventory() async {
    DocumentReference docRef = FirebaseFirestore.instance
        .collection('bloodbanks')
        .doc(bloodBankId)
        .collection('inventories')
        .doc(bloodType);

    await docRef.set(this.toMap(), SetOptions(merge: true)); // Merge to avoid overwriting existing data
  }

  // Update the inventory quantity (for example, after a donation or reservation)
  Future<void> updateInventoryQuantity(int newQuantity) async {
    DocumentReference docRef = FirebaseFirestore.instance
        .collection('bloodbanks')
        .doc(bloodBankId)
        .collection('inventories')
        .doc(bloodType);

    await docRef.update({'inventory_quantity': newQuantity, 'inventory_updated': FieldValue.serverTimestamp()});
  }
}

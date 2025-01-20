import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:redpulse/features/screens/admin/inventory.dart';

class InventoryModel {
  final String bloodType;
  final String status;
  int quantity;
  final String bloodBankId;
  final DateTime lastUpdated;

  InventoryModel({
    required this.bloodType,
    required this.status,
    required this.quantity,
    required this.bloodBankId,
    required this.lastUpdated,
  });

  // Factory method to convert Firestore document to an InventoryModel object
  factory InventoryModel.fromFirestore(String bloodBankId, Map<String, dynamic> data) {
    // Safely retrieve and handle nullable Firestore fields
    int quantity = (data['quantity'] as int?) ?? 0;
    String bloodType = (data['bloodType'] as String?) ?? 'Unknown';
    DateTime lastUpdated =
        (data['lastupdated'] as Timestamp?)?.toDate() ?? DateTime.now();

    // Determine status based on quantity
    String status;
    if (quantity == 0) {
      status = 'Out of Stock';
    } else if (quantity < 10) {
      status = 'Low Stock';
    } else {
      status = 'Available';
    }

    // Update status in Firestore only if necessary
    _updateStatusIfNecessary(bloodBankId, bloodType, status, data['status'] as String?);

    return InventoryModel(
      bloodType: bloodType,
      status: status,
      quantity: quantity,
      bloodBankId: bloodBankId,
      lastUpdated: lastUpdated,
    );
  }

  // Update status in Firestore only if it has changed
  static Future<void> _updateStatusIfNecessary(
      String bloodBankId, String bloodType, String newStatus, String? currentStatus) async {
    if (currentStatus != newStatus) {
      DocumentReference docRef = FirebaseFirestore.instance
          .collection('bloodbanks')
          .doc(bloodBankId)
          .collection('inventories')
          .doc(bloodType);

      await docRef.update({
        'status': newStatus,
        'lastupdated': FieldValue.serverTimestamp(),
      });
    }
  }

  // Convert an Inventory object to a Firestore-compatible map
  Map<String, dynamic> toMap() {
    return {
      'bloodType': bloodType,
      'status': status,
      'quantity': quantity,
      'bloodBankId': bloodBankId,
      'lastupdated': lastUpdated,
    };
  }

  // Initialize inventory for all blood types
  static Future<void> initializeBloodTypeInventory(String bloodBankId) async {
    List<String> bloodTypes = ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'];

    for (String bloodType in bloodTypes) {
      DocumentReference docRef = FirebaseFirestore.instance
          .collection('bloodbanks')
          .doc(bloodBankId)
          .collection('inventories')
          .doc(bloodType);

      DocumentSnapshot snapshot = await docRef.get();
      if (!snapshot.exists) {
        InventoryModel newInventory = InventoryModel(
          bloodType: bloodType,
          status: 'Out of Stock', // Default status
          quantity: 0,
          bloodBankId: bloodBankId,
          lastUpdated: DateTime.now(),
        );
        await docRef.set(newInventory.toMap());
        print('Inventory for $bloodType initialized.');
      }
    }
  }

  // Fetch an inventory item from Firestore
  static Future<InventoryModel?> getInventory(String bloodBankId, String bloodType) async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('bloodbanks')
          .doc(bloodBankId)
          .collection('inventories')
          .doc(bloodType)
          .get();

      if (doc.exists) {
        return InventoryModel.fromFirestore(bloodBankId, doc.data() as Map<String, dynamic>);
      } else {
        return null;
      }
    } catch (e) {
      print("Error fetching inventory: $e");
      return null;
    }
  }

  // Update inventory quantity and persist the new status
  Future<void> updateInventoryQuantity(int newQuantity) async {
    String updatedStatus;

    // Determine status based on new quantity
    if (newQuantity == 0) {
      updatedStatus = 'Out of Stock';
    } else if (newQuantity < 10) {
      updatedStatus = 'Low Stock';
    } else {
      updatedStatus = 'Available';
    }

    await FirebaseFirestore.instance
        .collection('bloodbanks')
        .doc(bloodBankId)
        .collection('inventories')
        .doc(bloodType)
        .update({
      'quantity': newQuantity,
      'status': updatedStatus,
      'lastupdated': FieldValue.serverTimestamp(),
    });
  }

  
}




/*class InventoryModel {
  final String bloodType;
  final String status;
  final int quantity;
  final String bloodBankId;
  final DateTime lastUpdated;

  InventoryModel({
    required this.bloodType,
    required this.status,
    required this.quantity,
    required this.bloodBankId,
    required this.lastUpdated,
  });

  // Convert a Firestore document to an Inventory object
  factory InventoryModel.fromFirestore(Map<String, dynamic> firestoreData) {
    return InventoryModel(
      bloodType: firestoreData['inventory_bloodtype'],
      status: firestoreData['inventory_status'],
      quantity: firestoreData['inventory_quantity'],
      bloodBankId: firestoreData['bloodbank_id'],
      lastUpdated: (firestoreData['inventory_lastupdated'] as Timestamp).toDate(),
    );
  }

  // Convert an Inventory object to a Firestore-compatible map
  Map<String, dynamic> toMap() {
    return {
      'inventory_bloodtype': bloodType,
      'inventory_status': status,
      'inventory_quantity': quantity,
      'bloodbank_id': bloodBankId,
      'inventory_lastupdated': lastUpdated,
    };
  }

  // Initialize inventory for all blood types
  static Future<void> initializeBloodTypeInventory(String bloodBankId) async {
    List<String> bloodTypes = ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'];

    for (String bloodType in bloodTypes) {
      DocumentReference docRef = FirebaseFirestore.instance
          .collection('bloodbanks')
          .doc(bloodBankId)
          .collection('inventories')
          .doc(bloodType);

      DocumentSnapshot snapshot = await docRef.get();
      if (!snapshot.exists) {
        InventoryModel newInventory = InventoryModel(
          bloodType: bloodType,
          status: 'Unavailable',
          quantity: 0,
          bloodBankId: bloodBankId,
          lastUpdated: DateTime.now(),
        );
        await docRef.set(newInventory.toMap());
        print('Inventory for $bloodType initialized.');
      }
    }
  }

  // Update the inventory status based on the quantity
  Future<void> updateInventoryStatus() async {
    DocumentReference docRef = FirebaseFirestore.instance
        .collection('bloodbanks')
        .doc(bloodBankId)
        .collection('inventories')
        .doc(bloodType);

    String updatedStatus;
    if (quantity == 0) {
      updatedStatus = 'Out of Stock';
    } else if (quantity < 10) {
      updatedStatus = 'Low Stock';
    } else {
      updatedStatus = 'Available';
    }

    await docRef.update({
      'inventory_status': updatedStatus,
      'inventory_lastupdated': FieldValue.serverTimestamp(),
    });
  }

  // Method to fetch an inventory item from Firestore by bloodBankId and bloodType
  static Future<InventoryModel?> getInventory(String bloodBankId, String bloodType) async {
    try {
      // Fetch the inventory item document from Firestore
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('bloodbanks')
          .doc(bloodBankId)
          .collection('inventories')
          .doc(bloodType) // Assuming the bloodType is stored as document ID
          .get();

      if (doc.exists) {
        // If the document exists, return the InventoryModel instance
        return InventoryModel.fromFirestore(doc.data() as Map<String, dynamic>);
      } else {
        // If the document doesn't exist, return null
        return null;
      }
    } catch (e) {
      print("Error fetching inventory: $e");
      return null;
    }
  }

  // Update inventory quantity
  Future<void> updateInventoryQuantity(int newQuantity) async {
    DocumentReference docRef = FirebaseFirestore.instance
        .collection('bloodbanks')
        .doc(bloodBankId)
        .collection('inventories')
        .doc(bloodType);

    await docRef.update({
      'inventory_quantity': newQuantity,
      'inventory_lastupdated': FieldValue.serverTimestamp(),
    });
  }
}*/


/*class InventoryModel {
  final String bloodType;
  final String status;
  final int quantity;
  final String bloodBankId;
  //final int donated;
  //final DateTime expiration;
  final DateTime lastUpdated;

  InventoryModel({
    required this.bloodType,
    required this.status,
    required this.quantity,
    required this.bloodBankId,
    //required this.donated,
    //required this.expiration,
    required this.lastUpdated,
  });

  // Convert a Firestore document to an Inventory object
  factory InventoryModel.fromFirestore(Map<String, dynamic> firestoreData) {
    return InventoryModel(
      bloodType: firestoreData['inventory_bloodtype'],
      status: firestoreData['inventory_status'],
      quantity: firestoreData['inventory_quantity'],
      bloodBankId: firestoreData['bloodbank_id'],
      //donated: firestoreData['inventory_donated'],
      //expiration: (firestoreData['inventory_expiration'] as Timestamp).toDate(),
      lastUpdated: (firestoreData['inventory_lastupdated'] as Timestamp).toDate(),
    );
  }

  // Convert an Inventory object to a Firestore-compatible map
  Map<String, dynamic> toMap() {
    return {
      'inventory_bloodtype': bloodType,
      'inventory_status': status,
      'inventory_quantity': quantity,
      'bloodbank_id': bloodBankId,
      //'inventory_donated': donated,
      //'inventory_expiration': expiration,
      'inventory_lastupdated': lastUpdated,
    };
  }

  @override
  String toString() {
    return 'Inventory(bloodType: $bloodType, status: $status, quantity: $quantity, bloodBankId: $bloodBankId, lastUpdated: $lastUpdated)';
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
        InventoryModel newInventory = InventoryModel(
          bloodType: bloodType,
          status: 'unavailable',  // Default status
          quantity: 0,            // Default quantity
          bloodBankId: bloodBankId,
          //donated: 0,             // Default donated
          //expiration: DateTime(2100, 1, 1), // Default expiration date (far future)
          lastUpdated: DateTime.now(),  // Current time
        );

        // Set the document in Firestore
        await docRef.set(newInventory.toMap());
        print('Inventory for $bloodType initialized.');
      }
    }
  }

  // Access the inventory for a specific blood bank and blood type
  /*static Future<Inventory?> getInventory(String bloodBankId, String bloodType) async {
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
  }*/

  // Static method to access the inventory for a specific blood bank and blood type
  static Future<InventoryModel?> getInventory(String bloodBankId, String bloodType) async {
    DocumentSnapshot snapshot = await FirebaseFirestore.instance
        .collection('bloodbanks')
        .doc(bloodBankId)
        .collection('inventories')
        .doc(bloodType)
        .get();

    if (snapshot.exists) {
      return InventoryModel.fromFirestore(snapshot.data() as Map<String, dynamic>);
    } else {
      print('Inventory for $bloodType not found.');
      return null;
    }
  }

  // Update or add inventory document in Firestore
  /*Future<void> updateInventory() async {
    DocumentReference docRef = FirebaseFirestore.instance
        .collection('bloodbanks')
        .doc(bloodBankId)
        .collection('inventories')
        .doc(bloodType);

    await docRef.set(this.toMap(), SetOptions(merge: true)); // Merge to avoid overwriting existing data
  }*/

  // Update or add inventory document in Firestore
  Future<void> updateInventory() async {
    DocumentReference docRef = FirebaseFirestore.instance
        .collection('bloodbanks')
        .doc(bloodBankId)
        .collection('inventories')
        .doc(bloodType);

    // Use Firestore serverTimestamp for automatic update of lastUpdated field
    await docRef.set({
      'inventory_bloodtype': bloodType,
      'inventory_status': status,
      'inventory_quantity': quantity,
      'bloodbank_id': bloodBankId,
      //'inventory_donated': donated,
      //'inventory_expiration': expiration,
      'inventory_lastupdated': FieldValue.serverTimestamp(), // Use serverTimestamp for lastUpdated field
    }, SetOptions(merge: true)); // Merge to avoid overwriting existing data
  }


  // Update the inventory quantity (for example, after a donation or reservation)
  /*Future<void> updateInventoryQuantity(int newQuantity) async {
    DocumentReference docRef = FirebaseFirestore.instance
        .collection('bloodbanks')
        .doc(bloodBankId)
        .collection('inventories')
        .doc(bloodType);

    await docRef.update({'inventory_quantity': newQuantity, 'inventory_updated': FieldValue.serverTimestamp()});
  }*/

  // Update the inventory quantity (for example, after a donation or reservation)
  Future<void> updateInventoryQuantity(int newQuantity) async {
    DocumentReference docRef = FirebaseFirestore.instance
        .collection('bloodbanks')
        .doc(bloodBankId)
        .collection('inventories')
        .doc(bloodType);

    // Update inventory quantity and lastUpdated using Firestore's server timestamp
    await docRef.update({
      'inventory_quantity': newQuantity,
      'inventory_lastupdated': FieldValue.serverTimestamp(), // Use serverTimestamp to update the lastUpdated field
    });
  }

}

class InventoryItemModel {
  final String bloodType;
  final int quantity;
  final String status;
  //final int donated;
  //final DateTime expiration;
  final DateTime lastUpdated;

  InventoryItemModel({
    required this.bloodType,
    required this.quantity,
    required this.status,
    //required this.donated,
    //required this.expiration,
    required this.lastUpdated,
  });

  // Factory method to create InventoryItem from Firestore document data
  factory InventoryItemModel.fromFirestore(Map<String, dynamic> data) {
    String status;
    int quantity = data['inventory_quantity'] as int;

    // Determine the status based on the quantity
    if (quantity == 0) {
      status = 'Out of Stock';
    } else if (quantity < 10) {
      status = 'Low Stock';
    } else {
      status = 'Available';
    }

    return InventoryItemModel(
      bloodType: data['inventory_bloodtype'] as String,
      quantity: quantity,
      status: status,
      //donated: data['inventory_donated'] as int,
      //expiration: (data['inventory_expiration'] as Timestamp).toDate(),
      lastUpdated: (data['inventory_lastupdated'] as Timestamp).toDate(),
    );
  }

  // Convert InventoryItem to JSON (for update or other operations)
  Map<String, dynamic> toJson() {
    return {
      'inventory_bloodtype': bloodType,
      'inventory_quantity': quantity,
      'inventory_status': status,
      //'inventory_donated': donated,
      //'inventory_expiration': expiration,
      'inventory_lastupdated': lastUpdated,
    };
  }
}*/
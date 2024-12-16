import 'package:cloud_firestore/cloud_firestore.dart';

Future<String> addOrUpdateInventory({
  required String bloodBankId,
  required String inventoryId,
  required String bloodType,
  required int quantity,
  required String status, // "Available" or "Expired"
  required bool donated,
  required Timestamp expirationDate,
}) async {
  try {
    // Reference to the specific inventory document
    DocumentReference inventoryDocRef = FirebaseFirestore.instance
        .collection('bloodBankInventory')
        .doc(inventoryId);

    // Create or update the inventory document
    await inventoryDocRef.set({
      'inventory_bloodtype': bloodType,
      'inventory_status': status,
      'inventory_quantity': quantity,
      'inventory_donated': donated,
      'inventory_expiration': expirationDate,
      'inventory_updated': Timestamp.now(), // Current time
      'bloodbank_id': bloodBankId,
    });

    return "Inventory updated successfully.";
  } catch (e) {
    return "Error updating inventory: $e";
  }
}

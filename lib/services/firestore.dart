import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:redpulse/features/models/bloodbank.dart';
import 'package:redpulse/features/models/users.dart';

class FirestoreService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Fetch blood bank info by ID
  static Future<BloodBankModel?> getBloodBankInfo(String bloodBankId) async {
    try {
      DocumentSnapshot doc = await _db.collection('bloodbanks').doc(bloodBankId).get();
      if (doc.exists) {
        return BloodBankModel.fromJson(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Error fetching blood bank info: $e');
      return null;
    }
  }

  // Update blood bank info
  static Future<void> updateBloodBankInfo(String bloodBankId, BloodBankModel updatedBloodBank) async {
    try {
      await _db.collection('bloodbanks').doc(bloodBankId).update(updatedBloodBank.toJson());
    } catch (e) {
      print('Error updating blood bank info: $e');
    }
  }

  static Future<UserAdminModel?> getUserInfo(String userId) async {
    if (userId.isEmpty) {
      throw Exception('User ID cannot be empty');
    }

    try {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId) // Ensure this is a valid document ID
          .get();

      if (snapshot.exists) {
        return UserAdminModel.fromJson(snapshot.data() as Map<String, dynamic>, snapshot.id);
      } else {
        return null;
      }
    } catch (e) {
      print('Error fetching user info: $e');
      throw Exception('Error fetching user info');
    }
  }
}

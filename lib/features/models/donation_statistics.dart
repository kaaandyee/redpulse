import 'package:cloud_firestore/cloud_firestore.dart';

class DonationStatisticsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Constants
  static const int mlPerDonation = 100; // 100ml per unit of donation
  static const int livesSavedPerDonation = 3; // Each donation saves 3 lives

  // Get donation statistics for a specific user
  Future<Map<String, dynamic>> getUserDonationStats(String userId) async {
    try {
      // Query reservations where status is complete/successful
      final reservationsSnapshot = await _firestore
          .collection('reservations')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'Completed')
          .get();

      // Count total donations (number of completed reservations)
      final int totalDonations = reservationsSnapshot.docs.length;

      // Calculate total blood donated in ml
      int totalQuantity = 0;
      for (var doc in reservationsSnapshot.docs) {
        final reservationData = doc.data();
        totalQuantity += (reservationData['quantity'] as int? ?? 0);
      }

      // Calculate blood donated in ml (each quantity unit equals 100ml)
      final int totalBloodDonatedMl = totalQuantity * mlPerDonation;

      // Calculate lives saved (each donation saves 3 lives)
      final int totalLivesSaved = totalDonations * livesSavedPerDonation;

      return {
        'totalDonations': totalDonations,
        'totalBloodDonatedMl': totalBloodDonatedMl,
        'totalLivesSaved': totalLivesSaved,
      };
    } catch (e) {
      print('Error fetching donation statistics: $e');
      return {
        'totalDonations': 0,
        'totalBloodDonatedMl': 0,
        'totalLivesSaved': 0,
      };
    }
  }

  // Get next scheduled donation for a user
  Future<Map<String, dynamic>?> getNextScheduledDonation(String userId) async {
    try {
      final now = DateTime.now();

      // Query for upcoming reservations (reserved but not completed)
      final upcomingReservationsSnapshot = await _firestore
          .collection('reservations')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'Reserved')
          .where('validUntil', isGreaterThan: now)
          .orderBy('validUntil')
          .limit(1)
          .get();

      if (upcomingReservationsSnapshot.docs.isNotEmpty) {
        final nextDonation = upcomingReservationsSnapshot.docs.first;
        final data = nextDonation.data();

        // Get blood bank details
        final bloodBankSnapshot = await _firestore
            .collection('bloodbanks')
            .doc(data['bloodBankId'])
            .get();

        final bloodBankData = bloodBankSnapshot.data();
        final bloodBankName =
            bloodBankData?['bloodBankName'] ?? 'Unknown Blood Bank';
        final bloodBankLocation =
            bloodBankData?['address'] ?? 'Unknown Location';

        // Convert Timestamp to DateTime if needed
        final validUntil = data['validUntil'] is Timestamp
            ? (data['validUntil'] as Timestamp).toDate()
            : data['validUntil'];

        return {
          'reservationId': nextDonation.id,
          'bloodBankName': bloodBankName,
          'bloodBankLocation': bloodBankLocation,
          'scheduledDate': validUntil,
          'bloodType': data['bloodType'],
          'quantity': data['quantity'],
          'medicalReason': data['medicalReason'],
        };
      }

      return null; // No upcoming donation
    } catch (e) {
      print('Error fetching next scheduled donation: $e');
      return null;
    }
  }

  // Add this method to DonationStatisticsService class
  Future<Map<String, dynamic>> getBloodBankStats(String bloodBankId) async {
    try {
      // Query completed reservations for this blood bank
      final reservationsSnapshot = await _firestore
          .collection('reservations')
          .where('bloodBankId', isEqualTo: bloodBankId)
          .where('status', isEqualTo: 'Completed')
          .get();

      // Count total donations
      final int totalDonations = reservationsSnapshot.docs.length;

      // Calculate total blood donated
      int totalQuantity = 0;
      Set<String> uniqueDonorIds = {};

      for (var doc in reservationsSnapshot.docs) {
        final reservationData = doc.data();
        totalQuantity += (reservationData['quantity'] as int? ?? 0);
        if (reservationData['userId'] != null) {
          uniqueDonorIds.add(reservationData['userId']);
        }
      }

      final int totalBloodDonatedMl = totalQuantity * mlPerDonation;
      final int totalLivesSaved = totalDonations * livesSavedPerDonation;

      return {
        'totalDonations': totalDonations,
        'totalBloodDonatedMl': totalBloodDonatedMl,
        'totalLivesSaved': totalLivesSaved,
        'uniqueDonors': uniqueDonorIds.length,
      };
    } catch (e) {
      print('Error fetching blood bank statistics: $e');
      return {
        'totalDonations': 0,
        'totalBloodDonatedMl': 0,
        'totalLivesSaved': 0,
        'uniqueDonors': 0,
      };
    }
  }

  // Add this method to fetch donors
  Future<List<Map<String, dynamic>>> getBloodBankDonors(
      String bloodBankId) async {
    try {
      // Get all completed reservations for this blood bank
      final reservationsSnapshot = await _firestore
          .collection('reservations')
          .where('bloodBankId', isEqualTo: bloodBankId)
          .where('status', isEqualTo: 'Completed')
          .get();

      // Get unique donor IDs
      Set<String> uniqueDonorIds = {};
      Map<String, int> donorDonations = {};

      for (var doc in reservationsSnapshot.docs) {
        final data = doc.data();
        final String userId = data['userId'];
        uniqueDonorIds.add(userId);
        donorDonations[userId] = (donorDonations[userId] ?? 0) + 1;
      }

      // Get donor details for each unique donor
      List<Map<String, dynamic>> donors = [];

      for (String donorId in uniqueDonorIds) {
        final userDoc = await _firestore.collection('users').doc(donorId).get();
        if (userDoc.exists) {
          final userData = userDoc.data()!;
          donors.add({
            'id': donorId,
            'name': userData['fullName'] ??
                '${userData['firstName']} ${userData['lastName']}',
            'bloodType': userData['bloodType'] ?? 'Unknown',
            'donationCount': donorDonations[donorId] ?? 0,
            'profileImageUrl': userData['profileImageUrl'],
          });
        }
      }

      // Sort by donation count (highest first)
      donors.sort((a, b) => b['donationCount'].compareTo(a['donationCount']));

      return donors;
    } catch (e) {
      print('Error fetching blood bank donors: $e');
      return [];
    }
  }
}

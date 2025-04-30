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
        final bloodBankName = bloodBankData?['bloodBankName'] ?? 'Unknown Blood Bank';
        final bloodBankLocation = bloodBankData?['address'] ?? 'Unknown Location';

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
}
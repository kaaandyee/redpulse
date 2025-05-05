import 'package:cloud_firestore/cloud_firestore.dart';

class ReservationModel {
  final String reservationId;
  final String userId;
  final String bloodBankId;
  final String bloodType;
  final int quantity;
  final String status; // "Pending", "Reserved" or "Cancelled"
  final DateTime reservedAt; // Time when the reservation was made
  final DateTime updatedAt; // Time when the reservation was last updated
  final DateTime validUntil; // The deadline for the reservation's validity
  final String medicalReason; // The medical reason behind the reservation

  ReservationModel({
    required this.reservationId,
    required this.userId,
    required this.bloodBankId,
    required this.bloodType,
    required this.quantity,
    required this.status,
    required this.reservedAt,
    required this.updatedAt,
    required this.validUntil,
    required this.medicalReason, // Add medicalReason to constructor
  });


  factory ReservationModel.fromFirestore(
      String reservationId, Map<String, dynamic> data) {
    // Safe handling for possible null string values
    String userId =
        data['userId'] as String? ?? ''; // Default to an empty string if null
    String bloodBankId = data['bloodBankId'] as String? ??
        ''; // Default to an empty string if null
    String bloodType = data['bloodType'] as String? ??
        ''; // Default to an empty string if null
    String status =
        data['status'] as String? ?? ''; // Default to an empty string if null
    String medicalReason = data['medicalReason'] as String? ??
        ''; // Default to an empty string if null

    // Safe handling for possible null Timestamp values
    Timestamp? reservedAtTimestamp = data['reservedAt'] as Timestamp?;
    Timestamp? updatedAtTimestamp = data['updatedAt'] as Timestamp?;
    Timestamp? validUntilTimestamp = data['validUntil'] as Timestamp?;

    return ReservationModel(
      reservationId: reservationId,
      userId: userId,
      bloodBankId: bloodBankId,
      bloodType: bloodType,
      quantity: data['quantity'] as int,
      status: status,
      medicalReason: medicalReason, // Include the medicalReason field
      reservedAt: reservedAtTimestamp?.toDate() ??
          DateTime.now(), // Default to now if null
      updatedAt: updatedAtTimestamp?.toDate() ??
          DateTime.now(), // Default to now if null
      validUntil: validUntilTimestamp?.toDate() ??
          DateTime.now(), // Default to now if null
    );
  }

  // Convert ReservationModel to Firestore-compatible map
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'bloodBankId': bloodBankId,
      'bloodType': bloodType,
      'quantity': quantity,
      'status': status,
      'reservedAt': reservedAt,
      'updatedAt': updatedAt,
      'validUntil': validUntil,
      'medicalReason': medicalReason, // Include medicalReason in map
    };
  }

  // Log a new reservation with validUntil (one week from reservedAt)
  static Future<void> createReservation({
    required String userId,
    required String bloodBankId,
    required String bloodType,
    required int quantity,
    required String status, // 'Reserved' or 'Cancelled'
    required String medicalReason, // The medical reason behind the reservation
  }) async {
    final reservationId =
        FirebaseFirestore.instance.collection('reservations').doc().id;

    final reservedAt = DateTime.now();
    final updatedAt = DateTime.now();
    final validUntil = reservedAt.add(const Duration(
        days: 7)); // Set the validity to one week after reservedAt

    final newReservation = ReservationModel(
      reservationId: reservationId,
      userId: userId,
      bloodBankId: bloodBankId,
      bloodType: bloodType,
      quantity: quantity,
      status: status,
      reservedAt: reservedAt,
      updatedAt: updatedAt,
      validUntil: validUntil, // Add validUntil
      medicalReason: medicalReason, // Pass medicalReason
    );

    await FirebaseFirestore.instance
        .collection('reservations')
        .doc(reservationId)
        .set(newReservation.toMap());
  }
}


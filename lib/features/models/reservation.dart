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

  // Factory constructor to create ReservationModel from Firestore data
  /*factory ReservationModel.fromFirestore(String reservationId, Map<String, dynamic> data) {
    return ReservationModel(
      reservationId: reservationId,
      userId: data['userId'] as String,
      bloodBankId: data['bloodBankId'] as String,
      bloodType: data['bloodType'] as String,
      quantity: data['quantity'] as int,
      status: data['status'] as String,
      reservedAt: (data['reservedAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      validUntil: (data['validUntil'] as Timestamp).toDate(),
      medicalReason: data['medicalReason'] as String, // Parse medicalReason from Firestore data
    );
  }*/

  factory ReservationModel.fromFirestore(String reservationId, Map<String, dynamic> data) {
    // Safe handling for possible null string values
    String userId = data['userId'] as String? ?? ''; // Default to an empty string if null
    String bloodBankId = data['bloodBankId'] as String? ?? ''; // Default to an empty string if null
    String bloodType = data['bloodType'] as String? ?? ''; // Default to an empty string if null
    String status = data['status'] as String? ?? ''; // Default to an empty string if null
    String medicalReason = data['medicalReason'] as String? ?? ''; // Default to an empty string if null

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
      reservedAt: reservedAtTimestamp?.toDate() ?? DateTime.now(), // Default to now if null
      updatedAt: updatedAtTimestamp?.toDate() ?? DateTime.now(),   // Default to now if null
      validUntil: validUntilTimestamp?.toDate() ?? DateTime.now(), // Default to now if null
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
    final reservationId = FirebaseFirestore.instance.collection('reservations').doc().id;

    final reservedAt = DateTime.now();
    final updatedAt = DateTime.now();
    final validUntil = reservedAt.add(Duration(days: 7)); // Set the validity to one week after reservedAt

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


/*class ReservationModel {
  final String reservationId;
  final String userId;
  final String bloodBankId;
  final String bloodType;
  final int quantity;
  final String status; // "Pending' 'Reserved' or 'Cancelled'
  final DateTime reservedAt; // Time when the reservation was made
  final DateTime updatedAt; // Time when the reservation was last updated
  final DateTime validUntil; // The deadline for the reservation's validity

  ReservationModel({
    required this.reservationId,
    required this.userId,
    required this.bloodBankId,
    required this.bloodType,
    required this.quantity,
    required this.status,
    required this.reservedAt,
    required this.updatedAt,
    required this.validUntil, // Add validUntil to constructor
  });

  // Factory constructor to create ReservationModel from Firestore data
  factory ReservationModel.fromFirestore(String reservationId, Map<String, dynamic> data) {
    return ReservationModel(
      reservationId: reservationId,
      userId: data['userId'] as String,
      bloodBankId: data['bloodBankId'] as String,
      bloodType: data['bloodType'] as String,
      quantity: data['quantity'] as int,
      status: data['status'] as String,
      reservedAt: (data['reservedAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      validUntil: (data['validUntil'] as Timestamp).toDate(), // Parse validUntil from Firestore data
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
      'validUntil': validUntil, // Include validUntil in map
    };
  }

  // Log a new reservation with validUntil (one week from reservedAt)
  static Future<void> createReservation({
    required String userId,
    required String bloodBankId,
    required String bloodType,
    required int quantity,
    required String status, // 'Reserved' or 'Cancelled'
  }) async {
    final reservationId = FirebaseFirestore.instance.collection('reservations').doc().id;

    final reservedAt = DateTime.now();
    final updatedAt = DateTime.now();
    final validUntil = reservedAt.add(Duration(days: 7)); // Set the validity to one week after reservedAt

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
    );

    await FirebaseFirestore.instance
        .collection('reservations')
        .doc(reservationId)
        .set(newReservation.toMap());
  }
}*/


/*class ReservationModel {
  final String reservationId;
  final String userId;
  final String bloodBankId;
  final String bloodType;
  final int quantity;
  final String status; // 'Reserved' or 'Cancelled'
  final DateTime reservedAt; // Time when the reservation was made
  final DateTime updatedAt; // Time when the reservation was last updated

  ReservationModel({
    required this.reservationId,
    required this.userId,
    required this.bloodBankId,
    required this.bloodType,
    required this.quantity,
    required this.status,
    required this.reservedAt,
    required this.updatedAt,
  });

  // Factory constructor to create ReservationModel from Firestore data
  factory ReservationModel.fromFirestore(String reservationId, Map<String, dynamic> data) {
    return ReservationModel(
      reservationId: reservationId,
      userId: data['userId'] as String,
      bloodBankId: data['bloodBankId'] as String,
      bloodType: data['bloodType'] as String,
      quantity: data['quantity'] as int,
      status: data['status'] as String,
      reservedAt: (data['reservedAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
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
    };
  }

  // Log a new reservation
  static Future<void> createReservation({
    required String userId,
    required String bloodBankId,
    required String bloodType,
    required int quantity,
    required String status, // 'Reserved' or 'Cancelled'
  }) async {
    final reservationId = FirebaseFirestore.instance.collection('reservations').doc().id;

    final reservedAt = DateTime.now();
    final updatedAt = DateTime.now();

    final newReservation = ReservationModel(
      reservationId: reservationId,
      userId: userId,
      bloodBankId: bloodBankId,
      bloodType: bloodType,
      quantity: quantity,
      status: status,
      reservedAt: reservedAt,
      updatedAt: updatedAt,
    );

    await FirebaseFirestore.instance
        .collection('reservations')
        .doc(reservationId)
        .set(newReservation.toMap());
  }

  // Fetch a reservation by its ID
  static Future<ReservationModel?> fetchReservationById(String reservationId) async {
    DocumentSnapshot snapshot = await FirebaseFirestore.instance
        .collection('reservations')
        .doc(reservationId)
        .get();

    if (snapshot.exists) {
      final data = snapshot.data() as Map<String, dynamic>;
      return ReservationModel.fromFirestore(reservationId, data);
    } else {
      return null; // Reservation not found
    }
  }

  // Fetch all reservations for a specific user
  static Future<List<ReservationModel>> fetchReservationsByUserId(String userId) async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('reservations')
        .where('userId', isEqualTo: userId)
        .orderBy('reservedAt', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      return ReservationModel.fromFirestore(doc.id, doc.data() as Map<String, dynamic>);
    }).toList();
  }

  // Fetch all reservations for a specific blood bank
  static Future<List<ReservationModel>> fetchReservationsByBloodBankId(String bloodBankId) async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('reservations')
        .where('bloodBankId', isEqualTo: bloodBankId)
        .orderBy('reservedAt', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      return ReservationModel.fromFirestore(doc.id, doc.data() as Map<String, dynamic>);
    }).toList();
  }

  // Fetch reservations by status (e.g., 'Reserved', 'Cancelled')
  static Future<List<ReservationModel>> fetchReservationsByStatus(String status) async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('reservations')
        .where('status', isEqualTo: status)
        .orderBy('reservedAt', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      return ReservationModel.fromFirestore(doc.id, doc.data() as Map<String, dynamic>);
    }).toList();
  }

  // Update the status of an existing reservation
  static Future<void> updateReservationStatus({
    required String reservationId,
    required String status,
  }) async {
    final updatedAt = DateTime.now();

    await FirebaseFirestore.instance.collection('reservations').doc(reservationId).update({
      'status': status,
      'updatedAt': updatedAt,
    });
  }

  // Cancel a reservation (set status to 'Cancelled')
  static Future<void> cancelReservation(String reservationId) async {
    await updateReservationStatus(reservationId: reservationId, status: 'Cancelled');
  }
}*/
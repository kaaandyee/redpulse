class BloodBankModel {
  final String? bloodBankId;
  final String? adminId;
  String bloodBankName;
  String email;
  String address;
  String contactNumber;
  double latitude;
  double longitude;
  String? inventoryId; // New property for inventory association
  DateTime dateCreated;

  BloodBankModel({
    required this.bloodBankId,
    required this.adminId,
    required this.bloodBankName,
    required this.email,
    required this.address,
    required this.contactNumber,
    required this.latitude,
    required this.longitude,
    this.inventoryId, // Mark as optional for backward compatibility
    required this.dateCreated,
  });

  // CopyWith method
  BloodBankModel copyWith({
    String? bloodBankId,
    String? adminId,
    String? bloodBankName,
    String? email,
    String? address,
    String? contactNumber,
    double? latitude,
    double? longitude,
    String? inventoryId,
    DateTime? dateCreated,
  }) {
    return BloodBankModel(
      bloodBankId: bloodBankId ?? this.bloodBankId,
      adminId: adminId ?? this.adminId,
      bloodBankName: bloodBankName ?? this.bloodBankName,
      email: email ?? this.email,
      address: address ?? this.address,
      contactNumber: contactNumber ?? this.contactNumber,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      inventoryId: inventoryId ?? this.inventoryId, // Include inventoryId
      dateCreated: dateCreated ?? this.dateCreated,
    );
  }

  // Convert BloodBank object to JSON (Map<String, dynamic>)
  Map<String, dynamic> toJson() {
    return {
      'bloodBankId': bloodBankId,
      'adminId': adminId,
      'bloodBankName': bloodBankName,
      'email': email,
      'address': address,
      'contactNumber': contactNumber,
      'latitude': latitude,
      'longitude': longitude,
      'inventoryId': inventoryId, // Include inventoryId in JSON
      'dateCreated': dateCreated.toIso8601String(), // Format date as ISO8601
    };
  }

  // Create a BloodBank object from JSON (Map<String, dynamic>)
  factory BloodBankModel.fromJson(Map<String, dynamic> json) {
    return BloodBankModel(
      bloodBankId: json['bloodBankId'],
      adminId: json['adminId'],
      bloodBankName: json['bloodBankName'],
      email: json['email'],
      address: json['address'],
      contactNumber: json['contactNumber'],
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      inventoryId: json['inventoryId'], // Parse inventoryId
      dateCreated: DateTime.parse(json['dateCreated']), // Parse date as DateTime
    );
  }
}





/*class BloodBankModel {
  final String? bloodBankId;
  final String? adminId;
  String bloodBankName;
  String email;
  String address;
  String contactNumber;
  double latitude;
  double longitude;
  DateTime dateCreated;

  BloodBankModel({
    required this.bloodBankId,
    required this.adminId,
    required this.bloodBankName,
    required this.email,
    required this.address,
    required this.contactNumber,
    required this.latitude,
    required this.longitude,
    required this.dateCreated,
  });

  // CopyWith method
  BloodBankModel copyWith({
    String? bloodBankId,
    String? adminId,
    String? bloodBankName,
    String? email,
    String? address,
    String? contactNumber,
    double? latitude,
    double? longitude,
    DateTime? dateCreated,
  }) {
    return BloodBankModel(
      bloodBankId: bloodBankId ?? this.bloodBankId,
      adminId: adminId ?? this.adminId,
      bloodBankName: bloodBankName ?? this.bloodBankName,
      email: email ?? this.email,
      address: address ?? this.address,
      contactNumber: contactNumber ?? this.contactNumber,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      dateCreated: dateCreated ?? this.dateCreated,
    );
  }
  // Convert BloodBank object to JSON (Map<String, dynamic>)
  Map<String, dynamic> toJson() {
    return {
      'bloodBankId': bloodBankId,
      'adminId': adminId,
      'bloodBankName': bloodBankName,
      'email': email,
      'address': address,
      'contactNumber': contactNumber,
      'latitude': latitude,
      'longitude': longitude,
      'dateCreated': dateCreated,
    };
  }

  // Create a BloodBank object from JSON (Map<String, dynamic>)
  factory BloodBankModel.fromJson(Map<String, dynamic> json) {
    return BloodBankModel(
      bloodBankId: json['bloodBankId'],
      adminId: json['adminId'],
      bloodBankName: json['bloodBankName'],
      email: json['email'],
      address: json['address'],
      contactNumber: json['contactNumber'],
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      dateCreated: json['dateCreated'],
    );
  }
}*/

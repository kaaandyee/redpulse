import 'dart:core';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:redpulse/utilities/constants/enums.dart';

class UserAdminModel {
  final String? id;
  String firstName;
  String lastName;
  String fullName;
  String email;
  String phoneNumber;
  String address;
  String bloodType;
  String password;
  String role;
  DateTime dateCreated;
  DateTime? lastLogin;
  final String? bloodBankId; //For admin only

  //Constructor for User Model
  UserAdminModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.address,
    required this.bloodType,
    required this.password,
    required this.role,
    required this.dateCreated,
    this.lastLogin,
    this.bloodBankId,
  });

  void updateFullName() {
    fullName = '$firstName $lastName';
  }
  //Helper Methods
  //String get fullName => '$firstName $lastName';
  //CREATE TFORMATTER
  //String get formattedCreated => TFormatter.formatdate(dateCreated);
  //String get formattedUpdated => TFormatter.formatdate(lastLogin);
  //String get formattedPhoneNo => => TFormatter.formatPhoneNumber(phoneNumber);

  //Static function to create empty user model
  //static User empty() => User(email: '');

// CopyWith method for making changes to the existing UserAdminModel
  UserAdminModel copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? fullName,
    String? email,
    String? phoneNumber,
    String? address,
    String? bloodType,
    String? password,
    String? role,
    DateTime? dateCreated,
    DateTime? lastLogin,
    String? bloodBankId,
  }) {
    return UserAdminModel(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      fullName: fullName ?? '$firstName $lastName',
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      bloodType: bloodType ?? this.bloodType,
      password: password ?? this.password,
      role: role ?? this.role,
      dateCreated: dateCreated ?? this.dateCreated,
      lastLogin: lastLogin ?? this.lastLogin,
      bloodBankId: bloodBankId ?? this.bloodBankId,
    );
  }

  // Convert UserAdminModel to JSON (for Firebase)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstNam' : firstName,
      'lastName' : lastName,
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'address': address,
      'bloodType': bloodType.toString().split('.').last,
      'password': password,
      'role': role.toString().split('.').last,
      'dateCreated': dateCreated.toIso8601String(),
      'lastLogin': lastLogin?.toIso8601String(),
      if (role == AppRole.admin) 'bloodBankID': bloodBankId, // Only include bloodBankId for Admins
    };
  }

  // Create User Model from JSON (from Firebase)
  factory UserAdminModel.fromJson(Map<String, dynamic> json, String documentId) {
    return UserAdminModel(
      id: documentId,
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '', 
      fullName: json['fullName'] ?? '${json['firstName'] ?? ''} ${json['lastName'] ?? ''}',
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      address: json['address'] ?? '',
      bloodType: json['bloodType'] ?? '',
      password: json['password'] ?? '',
      role: json['role'] ?? 'User', // Default to 'User'
      dateCreated: DateTime.parse(json['dateCreated']),
      lastLogin: json['lastLogin'] != null ? DateTime.parse(json['lastLogin']) : null,
      bloodBankId: json['bloodBankId'],   // Only for Admins
    );
  }
}


/*class UserAdminModel {
  final String? id;
  String firstName;
  String lastName;
  String email;
  String phoneNumber;
  String address;
  String bloodType;
  String password;
  AppRole role; // Changed from String to AppRole
  DateTime dateCreated;
  DateTime? lastLogin;
  final String? bloodBankId; // For admin only

  UserAdminModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    required this.address,
    required this.bloodType,
    required this.password,
    required this.role, // Changed to AppRole
    required this.dateCreated,
    this.lastLogin,
    this.bloodBankId,
  });

  // Helper method to get full name
  String get fullName => '$firstName $lastName';

  // CopyWith method to create a modified version of the current model
  UserAdminModel copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? email,
    String? phoneNumber,
    String? address,
    String? bloodType,
    String? password,
    AppRole? role, // Changed to AppRole
    DateTime? dateCreated,
    DateTime? lastLogin,
    String? bloodBankId,
  }) {
    return UserAdminModel(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      bloodType: bloodType ?? this.bloodType,
      password: password ?? this.password,
      role: role ?? this.role, // Changed to AppRole
      dateCreated: dateCreated ?? this.dateCreated,
      lastLogin: lastLogin ?? this.lastLogin,
      bloodBankId: bloodBankId ?? this.bloodBankId,
    );
  }

  // Convert UserAdminModel to JSON (for Firestore)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'address': address,
      'bloodType': bloodType,
      'password': password,
      'role': role.label, // Convert the role to string using label
      'dateCreated': dateCreated.toIso8601String(),
      'lastLogin': lastLogin?.toIso8601String(),
      if (role == AppRole.admin) 'bloodBankID': bloodBankId, // Include bloodBankId only for admins
    };
  }

  // Create UserAdminModel from JSON (from Firestore)
  factory UserAdminModel.fromJson(Map<String, dynamic> json, String documentId) {
    return UserAdminModel(
      id: documentId,
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      address: json['address'] ?? '',
      bloodType: json['bloodType'] ?? '',
      password: json['password'] ?? '',
      role: json['role'] ?? 'User', // Use the fromString method for role
      dateCreated: DateTime.parse(json['dateCreated']),
      lastLogin: json['lastLogin'] != null ? DateTime.parse(json['lastLogin']) : null,
      bloodBankId: json['bloodBankId'], // Only for admins
    );
  }
}

Future<void> saveUserToFirestore(UserAdminModel user) async {
  FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Assuming `systemGeneratedId` is a unique identifier for the user
  //String systemGeneratedId = userAdmin.id;

  // Determine the subcollection based on the user role (user or admin)
  String subCollection = user.role == AppRole.admin ? 'admin' : 'user';

  try {
    // Save user data under the 'users' collection, with either 'user' or 'admin' subcollections
    await _firestore
        .collection('users')                           
        .doc(subCollection)                             // Subcollection based on role (either 'user' or 'admin')
        .collection(subCollection)                      // Create subcollection under 'user' or 'admin'
        .doc(user.id)                         // Document ID (user ID)
        .set(user.toJson());                    // Save the user data in the document
    print("User data saved successfully in Firestore!");
  } catch (e) {
    print("Error saving user data: $e");
  }
}


/*Future<void> saveUserToFirestore(UserAdminModel user) async {
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  // Determine the subcollection based on the user role
  String subCollection = user.role == AppRole.admin ? 'admin' : 'user';

  // Reference to the user's document
  DocumentReference userRef = firestore
      .collection('users')
      .doc(user.id) // Assuming `id` is unique for both users and admins
      .collection(subCollection)
      .doc(user.id);

  // Save the user data in Firestore
  await userRef.set(user.toJson());
}*/

Future<UserAdminModel?> getUserFromFirestore(String userId) async {
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  // First, check the 'user' subcollection
  DocumentSnapshot userSnapshot = await firestore
      .collection('users')
      .doc(userId)
      .collection('user')
      .doc(userId)
      .get();

  if (userSnapshot.exists) {
    return UserAdminModel.fromJson(userSnapshot.data() as Map<String, dynamic>, userSnapshot.id);
  }

  // If not found in 'user', check the 'admin' subcollection
  DocumentSnapshot adminSnapshot = await firestore
      .collection('users')
      .doc(userId)
      .collection('admin')
      .doc(userId)
      .get();

  if (adminSnapshot.exists) {
    return UserAdminModel.fromJson(adminSnapshot.data() as Map<String, dynamic>, adminSnapshot.id);
  }

  return null; // Return null if user is not found in either subcollection
}*/
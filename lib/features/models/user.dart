import 'dart:core';

import 'package:redpulse/utilities/constants/enums.dart';

class UserAdminModel {
  final String? id;
  String firstName;
  String lastName;
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

  //Helper Methods
  String get fullName => '$firstName $lastName';
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
      //fullName: json['fullName'] ?? '',
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
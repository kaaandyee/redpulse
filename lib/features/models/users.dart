import 'dart:core';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  final String? bloodBankId; // For admin only
  final String? profileImageUrl; // Profile image URL

  // Constructor for User Model
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
    this.profileImageUrl,
  });

  void updateFullName() {
    fullName = '$firstName $lastName';
  }

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
    String? profileImageUrl,
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
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
    );
  }

  // Convert UserAdminModel to JSON (for Firebase)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'address': address,
      'bloodType': bloodType,
      'password': password,
      'role': role,
      'dateCreated': dateCreated.toIso8601String(),
      'lastLogin': lastLogin?.toIso8601String(),
      'profileImageUrl': profileImageUrl,
      if (role == 'Admin') 'bloodBankId': bloodBankId,
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
      role: json['role'] ?? 'User',
      dateCreated: DateTime.parse(json['dateCreated']),
      lastLogin: json['lastLogin'] != null ? DateTime.parse(json['lastLogin']) : null,
      bloodBankId: json['bloodBankId'],
      profileImageUrl: json['profileImageUrl'],
    );
  }
}
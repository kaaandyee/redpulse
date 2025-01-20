import 'package:redpulse/features/models/inventory.dart';

bool isValidEmail(String email) {
  final emailRegex = RegExp(r'^[a-zA-Z0-9._%-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$');
  return emailRegex.hasMatch(email);
}

bool isValidPhoneNumber(String phoneNumber) {
  final phoneRegex = RegExp(r'^09\d{9}$'); // Matches Philippine phone numbers starting with '09' followed by 9 digits
  return phoneRegex.hasMatch(phoneNumber);
}

bool isValidLatitude(String latitude) {
  final double? lat = double.tryParse(latitude);
  return lat != null && lat >= -90 && lat <= 90;
}

bool isValidLongitude(String longitude) {
  final double? lon = double.tryParse(longitude);
  return lon != null && lon >= -180 && lon <= 180;
}

void registerBloodBank(String bloodBankId) async {
  await InventoryModel.initializeBloodTypeInventory(bloodBankId);
  print('Blood bank inventory initialized.');
}



bool isValidEmail(String email) {
  final emailRegex = RegExp(r'^[a-zA-Z0-9._%-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$');
  return emailRegex.hasMatch(email);
}

bool isValidPhoneNumber(String phoneNumber) {
  final phoneRegex = RegExp(r'^09\d{9}$'); // Matches Philippine phone numbers starting with '09' followed by 9 digits
  return phoneRegex.hasMatch(phoneNumber);
}



import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:redpulse/features/models/user.dart';
import 'package:redpulse/utilities/constants/enums.dart';

class AuthMethod {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // SignUp User or Admin
  Future<String> signupUser({
    required String email,
    required String phoneNumber,
    required String address,
    required String password,
    required String firstName,
    required String lastName,
    required BloodType bloodType,
    required AppRole userRole, // Use enum instead of raw strings
    String? bloodBankId, // Only for Admins
  }) async {
    String res = "Some error Occurred";
    try {
      if (email.isNotEmpty && password.isNotEmpty && firstName.isNotEmpty && lastName.isNotEmpty && phoneNumber.isNotEmpty && address.isNotEmpty) {
        // Register user in auth with email and password
        UserCredential cred = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        //AppRole userRole = AppRole.values.firstWhere((e) => e.toString().split('.').last == role);

        // Generate a unique Firestore ID
        String systemGeneratedId = _firestore.collection("users").doc().id;

        // Create a UserAdminModel based on role and add to Firestore
        UserAdminModel userAdmin = UserAdminModel(
          id: systemGeneratedId,
          firstName: firstName,
          lastName: lastName,
          email: email,
          phoneNumber: phoneNumber,
          address: address,
          bloodType: bloodType.label, // If the property expects a string
          role: userRole.label,      // For string roles
          password: password,
          dateCreated: DateTime.now(),
        );

        // If the user is an Admin, include bloodBankId
        if (userRole == AppRole.admin && bloodBankId != null) {
          userAdmin = userAdmin.copyWith(bloodBankId: bloodBankId);
        }

        // Save user data to Firestore
        await _firestore.collection("users").doc(systemGeneratedId).set(userAdmin.toJson());

        res = "success";
      } else {
        res = "Please fill in all the fields.";
      }
    } catch (err) {
      return err.toString();
    }
    return res;
  }

  // Log in User or Admin
  Future<String> loginUser({
    required String email,
    required String password,
  }) async {
    String res = "Some error Occurred";
    try {
      if (email.isNotEmpty && password.isNotEmpty) {
        // Log in user with email and password
        await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        res = "success";
      } else {
        res = "Please enter all the fields";
      }
    } catch (err) {
      return err.toString();
    }
    return res;
  }

  // SignOut User
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Fetch the first name of the currently signed-in user
  Future<String> getUserFirstName() async {
    try {
      // Get the currently authenticated user
      User? currentUser = _auth.currentUser;

      if (currentUser != null) {
        // Fetch the user's document from Firestore
        DocumentSnapshot userDoc = await _firestore
            .collection('users')
            .doc(currentUser.uid)
            .get();

        // Check if the document exists and return the first name
        if (userDoc.exists) {
          return userDoc['firstName'] ?? "User"; // Default to "User" if the field is null
        } else {
          throw Exception("User document does not exist");
        }
      } else {
        throw Exception("No user is signed in");
      }
    } catch (e) {
      print("Error fetching user first name: $e");
      return "User"; // Fallback value
    }
  }

  Future<AppRole> getUserRole(String email) async {
  try {
    // Fetch user data from Firestore using the email
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: email)
        .get();

    if (snapshot.docs.isNotEmpty) {
      // Get the first document (since email is assumed to be unique)
      var userDoc = snapshot.docs[0];

      // Check if the 'role' field exists in the document
      if (userDoc.exists && userDoc.data() != null) {
        String role = userDoc['role'];

        // Return role as AppRole enum (admin or user)
        if (role == 'Admin') {
          return AppRole.admin;
        } else {
          return AppRole.user;
        }
      } else {
        throw Exception("Role field is missing or document is malformed");
      }
    } else {
      // If the user is not found
      throw Exception("User not found");
    }
  } catch (e) {
    // Handle errors (e.g., network issues, Firestore issues)
    throw Exception("Failed to fetch user role: $e");
  }
}

}

/*
class AuthMethod {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // SignUp User
  Future<String> signupUser({
    required String email,
    required String password,
    required String name,
  }) async {
    String res = "Some error Occurred";
    try {
      if (email.isNotEmpty ||
          password.isNotEmpty ||
          name.isNotEmpty) {
        // register user in auth with email and password
        UserCredential cred = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        // add user to your  firestore database
        print(cred.user!.uid);
        await _firestore.collection("users").doc(cred.user!.uid).set({
          'name': name,
          'uid': cred.user!.uid,
          'email': email,
        });

        res = "success";
      }
    } catch (err) {
      return err.toString();
    }
    return res;
  }

  // logIn user
  Future<String> loginUser({
    required String email,
    required String password,
  }) async {
    String res = "Some error Occurred";
    try {
      if (email.isNotEmpty || password.isNotEmpty) {
        // logging in user with email and password
        await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        res = "success";
      } else {
        res = "Please enter all the fields";
      }
    } catch (err) {
      return err.toString();
    }
    return res;
  }

  // for sighout
  signOut() async {
    // await _auth.signOut();
  }
}
 */
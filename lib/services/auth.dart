import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:redpulse/features/models/inventory.dart';
import 'package:redpulse/features/models/bloodbank.dart';
import 'package:redpulse/features/models/users.dart';
import 'package:redpulse/features/screens/admin/home.dart';
import 'package:redpulse/features/screens/admin/start.dart';
import 'package:redpulse/features/screens/user/start.dart';
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
        //String systemGeneratedId = _firestore.collection("users").doc().id;
        // Get the current user's UID
        String uid = cred.user?.uid ?? '';
        String systemGeneratedId = uid;

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
          fullName: '$firstName $lastName',
        );

        // If the user is an Admin, include bloodBankId
        /*if (userRole == AppRole.admin && bloodBankId != null) {
          userAdmin = userAdmin.copyWith(bloodBankId: bloodBankId);
        }*/

        // If the user is an Admin and no bloodBankId is provided, set bloodBankId to null
        if (userRole == AppRole.admin) {
          userAdmin = userAdmin.copyWith(bloodBankId: bloodBankId ?? null); // Use null if no bloodBankId
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

  /*Future<String> signupUser({
    required String email,
    required String phoneNumber,
    required String address,
    required String password,
    required String firstName,
    required String lastName,
    required BloodType bloodType, // Assuming `BloodType` is an enum or similar
    required AppRole userRole, // Use enum instead of raw strings
    String? bloodBankId, // Only for Admins
  }) async {
    String res = "Some error Occurred";
    try {
      // Check if all necessary fields are filled
      if (email.isNotEmpty &&
          password.isNotEmpty &&
          firstName.isNotEmpty &&
          lastName.isNotEmpty &&
          phoneNumber.isNotEmpty &&
          address.isNotEmpty) {

        // Register user in Firebase Authentication with email and password
        UserCredential cred = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        // Get the current user's UID
        String uid = cred.user?.uid ?? '';
        String systemGeneratedId = uid;

        // Create a UserAdminModel based on the role and add to Firestore
        UserAdminModel userAdmin = UserAdminModel(
          id: systemGeneratedId,
          firstName: firstName,
          lastName: lastName,
          email: email,
          phoneNumber: phoneNumber,
          address: address,
          bloodType: bloodType.toString().split('.').last, // Ensure bloodType is converted to string
          role: userRole,  // Set the AppRole enum directly
          password: password,
          dateCreated: DateTime.now(),
        );

        // If the user is an Admin, include bloodBankId
        if (userRole == AppRole.admin) {
          userAdmin = userAdmin.copyWith(bloodBankId: bloodBankId ?? null); // Use null if no bloodBankId is provided
        }

        // Save user data to Firestore
        saveUserToFirestore(userAdmin);
        //await _firestore.collection("users").doc(systemGeneratedId).set(userAdmin.toJson());

        res = "success"; // Indicate success
      } else {
        res = "Please fill in all the fields."; // Error message if fields are empty
      }
    } catch (err) {
      res = err.toString(); // Return error message if an exception occurs
    }
    return res; // Return result (success or error message)
}*/


  // Log in User or Admin
  Future<String> loginUser({
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    String res = "Some error Occurred";
    try {
      if (email.isNotEmpty && password.isNotEmpty) {
        // Log in user with email and password
        UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        // Get the user from FirebaseAuth instance
        final User? user = userCredential.user;

        if (user != null) {
          // Fetch the user document from Firestore
          DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

          if (!userSnapshot.exists) {
            return "User document not found.";
          }

          // Get the user's data as a Map
          Map<String, dynamic> userData = userSnapshot.data() as Map<String, dynamic>;

          // Get the user's role and check if they are an admin
          String role = userData['role'];
          bool isAdmin = role == 'Admin';

          // If the user is an admin, check if they are linked to a blood bank
          bool isAdminLinkedToBloodBank = false;
          if (isAdmin) {
            // Safely check if bloodBankId exists in the document
            String? bloodBankId = userData['bloodBankId'];
            isAdminLinkedToBloodBank = bloodBankId != null && bloodBankId.isNotEmpty;
          }

          // Navigate based on the user role
          if (isAdmin) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => AdminStart(
                  isAdminLinkedToBloodBank: isAdminLinkedToBloodBank,
                ),
              ),
            );
          } else {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => const UserStart(), // Regular user homepage
              ),
            );
          }

          res = "success";
        }
      } else {
        res = "Please enter all the fields";
      }
    } catch (err) {
      return err.toString();
    }
    return res;
  }

  /*Future<String> loginUser({
  required String email,
  required String password,
  required BuildContext context,
}) async {
  String res = "Some error Occurred";
  try {
    if (email.isNotEmpty && password.isNotEmpty) {
      // Log in user with email and password
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Get the user from FirebaseAuth instance
      final User? user = userCredential.user;

      if (user != null) {
        // Fetch the user document from Firestore
        DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (!userSnapshot.exists) {
          return "User document not found.";
        }

        // Get the user's data as a Map
        Map<String, dynamic> userData = userSnapshot.data() as Map<String, dynamic>;

        // Get the user's role and check if they are an admin
        String role = userData['role'];
        AppRole appRole = AppRole.values.firstWhere(
          (e) => e.label == role,
          orElse: () => AppRole.user, // Default to 'user' if not found
        );

        bool isAdmin = appRole == AppRole.admin;

        // If the user is an admin, check if they are linked to a blood bank
        bool isAdminLinkedToBloodBank = false;
        if (isAdmin) {
          // Safely check if bloodBankId exists in the document
          String? bloodBankId = userData['bloodBankId'];
          isAdminLinkedToBloodBank = bloodBankId != null && bloodBankId.isNotEmpty;
        }

        // Navigate based on the user role
        if (isAdmin) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => AdminStart(
                isAdminLinkedToBloodBank: isAdminLinkedToBloodBank,
              ),
            ),
          );
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const UserStart(), // Regular user homepage
            ),
          );
        }

        res = "success"; // Indicate success
      }
    } else {
      res = "Please enter all the fields"; // Error message if fields are empty
    }
  } catch (err) {
    res = err.toString(); // Return error message if an exception occurs
  }
  return res; // Return result (success or error message)
}*/


  // SignOut User
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Fetch the first name of the currently signed-in user
  Future<String> getUserName() async {
  try {
    // Get the currently authenticated user
    User? currentUser = _auth.currentUser;

    if (currentUser != null) {
      // Fetch the user's document from Firestore
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();

      // Check if the document exists and safely access the 'fullName' field
      if (userDoc.exists) {
        // Cast the document data to a Map and access the 'fullName' field
        var userData = userDoc.data() as Map<String, dynamic>?;
        return userData?['fullName'] ?? "User"; // Use fallback if fullName is not found
      } else {
        throw Exception("User document does not exist");
      }
    } else {
      throw Exception("No user is signed in");
    }
  } catch (e) {
    // Log the error message for debugging purposes
    print("Error fetching user full name: $e");

    // Return a fallback value
    return "User";
  }
}

/*Future<String> getAdminName() async {
  try {
    // Get the currently authenticated user
    User? currentUser = _auth.currentUser;

    if (currentUser != null) {
      // Fetch the user's document from Firestore
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();

      // Check if the document exists and safely access the 'fullName' field
      if (userDoc.exists) {
        // Cast the document data to a Map and access the 'fullName' field
        var userData = userDoc.data() as Map<String, dynamic>?;
        return userData?['fullName'] ?? "Admin"; // Use fallback if fullName is not found
      } else {
        throw Exception("User document does not exist");
      }
    } else {
      throw Exception("No user is signed in");
    }
  } catch (e) {
    // Log the error message for debugging purposes
    print("Error fetching user full name: $e");

    // Return a fallback value
    return "Admin";
  }
}*/

Future<String> getAdminName() async {
  try {
    // Get the currently authenticated user
    User? currentUser = _auth.currentUser;

    if (currentUser != null) {
      // Fetch the user's document from Firestore using the user's UID
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();

      // Check if the document exists and access the 'id' field
      if (userDoc.exists) {
        // Cast the document data to a Map and access the 'id' field
        var userData = userDoc.data() as Map<String, dynamic>?;
        print("User data: $userData");  // Debugging line
        String adminId = userData?['id'] ?? '';
        print("Admin ID: $adminId");  // Debugging line

        if (adminId.isNotEmpty) {
          // Query Firestore to find the document with the matching 'id' and 'role' as 'Admin'
          QuerySnapshot adminQuerySnapshot = await _firestore
              .collection('users')
              .where('id', isEqualTo: adminId)
              .where('role', isEqualTo: 'Admin')
              .get();

          print("Admin query result: ${adminQuerySnapshot.docs}");  // Debugging line

          if (adminQuerySnapshot.docs.isNotEmpty) {
            var adminDoc = adminQuerySnapshot.docs.first;
            var adminData = adminDoc.data() as Map<String, dynamic>?;
            print("Admin data: $adminData");  // Debugging line
            return adminData?['fullName'] ?? "Admin"; // Return full name or fallback
          } else {
            throw Exception("Admin document with the specified id and role not found");
          }
        } else {
          throw Exception("Admin ID not found");
        }
      } else {
        throw Exception("User document does not exist");
      }
    } else {
      throw Exception("No user is signed in");
    }
  } catch (e) {
    // Log the error message for debugging purposes
    print("Error fetching admin full name: $e");

    // Return a fallback value in case of errors
    return "Admin";
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

  Future<String> getAdminId() async {
    try {
      // Fetch the current authenticated user
      final User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("Admin is not logged in.");
      }

      // Use the user's UID to fetch the corresponding document
      DocumentSnapshot adminSnapshot =
          await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

      if (!adminSnapshot.exists) {
        throw Exception("Admin document not found.");
      }

      // The document ID is the user's UID, no need to fetch the 'id' field
      String adminId = user.uid; // Return the UID of the logged-in user
      return adminId;
    } catch (error) {
      print("Error fetching admin ID: $error");
      throw Exception("Failed to fetch admin ID.");
    }
  }

  Future<String> fetchBloodBankName(String bloodBankId) async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('bloodbanks')
          .doc(bloodBankId)
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        return data['bloodBankName'] ?? 'Unnamed Blood Bank'; // Fallback for missing name
      } else {
        return 'Blood Bank Not Found';
      }
    } catch (e) {
      print('Error fetching blood bank name: $e');
      return 'Error fetching name';
    }
  }
  /// Registers a blood bank in the Firestore database.
  Future<String> registerBloodBank({
    required String bloodBankName,
    required String email,
    required String address,
    required String contactNumber,
    required double latitude,
    required double longitude,
  }) async {
    try {
      // Get the currently authenticated user
      final User? user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        return "No authenticated user found.";
      }

      // Call getAdminId() to fetch the admin ID
      String adminId = await getAdminId();

      // Generate unique Firestore IDs
      String bloodBankId = _firestore.collection("bloodbanks").doc().id;
      String inventoryId = _firestore.collection("inventories").doc().id;

      // Create a BloodBankModel object with inventoryId
      BloodBankModel bloodBank = BloodBankModel(
        bloodBankId: bloodBankId,
        adminId: adminId,
        bloodBankName: bloodBankName,
        email: email,
        address: address,
        contactNumber: contactNumber,
        latitude: latitude,
        longitude: longitude,
        dateCreated: DateTime.now(),
        inventoryId: inventoryId,
      );

      // Save blood bank data to Firestore
      await _firestore.collection("bloodbanks").doc(bloodBankId).set(bloodBank.toJson());

      // Initialize inventory for the blood bank by calling the Inventory class's method
      await InventoryModel.initializeBloodTypeInventory(bloodBankId);

      // Update the admin's document with the new blood bank ID
      await _firestore.collection('users').doc(user.uid).update({
        'bloodBankId': bloodBankId, // Link the blood bank to the admin
      });

      return "Blood bank successfully registered.";
    } catch (error) {
      // Log the error (for debugging purposes)
      print("Error registering blood bank: $error");

      // Return error message
      return "Failed to register blood bank. Please try again.";
    }
}



  /*Future<String> registerBloodBank({
    required String bloodBankName,
    required String email,
    required String address,
    required String contactNumber,
    required double latitude,
    required double longitude,
  }) async {
    try {
      // Get the currently authenticated user
      final User? user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        return "No authenticated user found.";
      }

      // Call getAdminId() to fetch the admin ID
      String adminId = await getAdminId();

      // Generate unique Firestore IDs
      String bloodBankId = _firestore.collection("bloodbanks").doc().id;
      String inventoryId = _firestore.collection("inventories").doc().id;

      // Create a BloodBankModel object with inventoryId
      BloodBankModel bloodBank = BloodBankModel(
        bloodBankId: bloodBankId,
        adminId: adminId,
        bloodBankName: bloodBankName,
        email: email,
        address: address,
        contactNumber: contactNumber,
        latitude: latitude,
        longitude: longitude,
        dateCreated: DateTime.now(),
        inventoryId: inventoryId, // Link the inventory to the blood bank
      );

      // Save blood bank data to Firestore
      await _firestore.collection("bloodbanks").doc(bloodBankId).set(bloodBank.toJson());

      // Initialize inventory for the blood bank
      await _firestore.collection("inventories").doc(inventoryId).set({
        'inventoryId': inventoryId,
        'bloodBankId': bloodBankId,
        'bloodTypes': {
          'A+': 0,
          'A-': 0,
          'B+': 0,
          'B-': 0,
          'O+': 0,
          'O-': 0,
          'AB+': 0,
          'AB-': 0,
        },
        'lastUpdated': DateTime.now(),
      });

      // Update the admin's document with the new blood bank ID
      await _firestore.collection('users').doc(user.uid).update({
        'bloodBankId': bloodBankId, // Link the blood bank to the admin
      });

      return "Blood bank successfully registered.";
    } catch (error) {
      // Log the error (for debugging purposes)
      print("Error registering blood bank: $error");

      // Return error message
      return "Failed to register blood bank. Please try again.";
    }
  }*/
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
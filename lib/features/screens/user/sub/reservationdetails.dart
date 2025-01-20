import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:redpulse/features/models/reservation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:redpulse/utilities/constants/styles.dart';
import 'package:redpulse/widgets/button.dart';

class ReservationDetailsScreen extends StatefulWidget {
  final String reservationId;  // Accept reservationId as a parameter

  const ReservationDetailsScreen({Key? key, required this.reservationId}) : super(key: key);

  @override
  _ReservationDetailsScreenState createState() => _ReservationDetailsScreenState();
}

class _ReservationDetailsScreenState extends State<ReservationDetailsScreen> {
  ReservationModel? reservation;  // Make reservation nullable
  String bloodBankName = ''; 

  @override
  void initState() {
    super.initState();
    fetchReservationDetails();
  }

  // Fetch reservation details using the reservationId
  Future<void> fetchReservationDetails() async {
    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('reservations')
          .doc(widget.reservationId)  // Use the passed reservationId
          .get();

      if (docSnapshot.exists) {
        setState(() {
          reservation = ReservationModel.fromFirestore(
              widget.reservationId, docSnapshot.data() as Map<String, dynamic>);
        });
        await fetchBloodBankName(reservation!.bloodBankId);
      } else {
        print('Reservation not found.');
      }
    } catch (e) {
      print('Error fetching reservation details: $e');
    }
  }

  // Fetch the blood bank name using the bloodBankId
  Future<void> fetchBloodBankName(String bloodBankId) async {
    try {
      final bloodBankDoc = await FirebaseFirestore.instance
          .collection('bloodbanks')
          .doc(bloodBankId)
          .get();

      if (bloodBankDoc.exists) {
        setState(() {
          bloodBankName = bloodBankDoc.data()?['bloodBankName'] ?? 'Unknown'; // Fetch the name field
        });
      } else {
        print('Blood bank not found.');
      }
    } catch (e) {
      print('Error fetching blood bank name: $e');
    }
  }

  // Cancel the reservation and update inventory
  Future<void> cancelReservation() async {
    try {
      if (reservation != null) {
        // First, update the inventory by adding back the quantity
        await updateInventory(reservation!.bloodBankId, reservation!.bloodType, reservation!.quantity);

        // Now, delete the reservation from Firestore
        await FirebaseFirestore.instance
            .collection('reservations')
            .doc(widget.reservationId)
            .delete();

        // Show success message and pop the screen
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reservation has been canceled.')),
        );
        Navigator.pop(context); // Navigate back after cancellation
      }
    } catch (e) {
      print('Error canceling reservation: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error canceling reservation: $e')),
      );
    }
  }

  // Function to update the inventory by adding back the quantity
  /*Future<void> updateInventory(String bloodBankId, int quantityToAdd) async {
    try {
      // Fetch the current inventory from Firestore
      final docSnapshot = await FirebaseFirestore.instance
          .collection('inventories')
          .doc(bloodBankId)
          .get();

      if (docSnapshot.exists) {
        final inventoryData = docSnapshot.data() as Map<String, dynamic>;
        int currentQuantity = inventoryData['quantity'] ?? 0;

        // Update the inventory by adding back the quantity
        await FirebaseFirestore.instance
            .collection('inventories')
            .doc(bloodBankId)
            .update({
          'quantity': currentQuantity + quantityToAdd,
        });
      } else {
        print('Inventory not found for this blood bank.');
      }
    } catch (e) {
      print('Error updating inventory: $e');
    }
  }*/

  // Function to update the inventory by adding back the quantity and updating the status
  // Function to update the inventory by adding back the quantity and updating the status
Future<void> updateInventory(String bloodBankId, String bloodType, int quantityToAdd) async {
  try {
    // Fetch the specific blood type document from the inventories subcollection
    final docSnapshot = await FirebaseFirestore.instance
        .collection('bloodbanks')        // Main collection
        .doc(bloodBankId)                // Blood bank document
        .collection('inventories')       // Subcollection for inventories
        .doc(bloodType)                  // Specific blood type document
        .get();

    if (docSnapshot.exists) {
      final inventoryData = docSnapshot.data() as Map<String, dynamic>;

      // Extract current quantity
      int currentQuantity = inventoryData['quantity'] ?? 0;

      // Calculate updated quantity
      int updatedQuantity = currentQuantity + quantityToAdd;

      // Determine updated status based on the new quantity
      String updatedStatus;
      if (updatedQuantity == 0) {
        updatedStatus = 'Out of Stock';
      } else if (updatedQuantity < 10) {
        updatedStatus = 'Low Stock';
      } else {
        updatedStatus = 'Available';
      }

      // Update the specific blood type document with new quantity and status
      await FirebaseFirestore.instance
          .collection('bloodbanks')
          .doc(bloodBankId)
          .collection('inventories')
          .doc(bloodType)
          .update({
        'quantity': updatedQuantity,
        'status': updatedStatus,
        'lastupdated': FieldValue.serverTimestamp(),
      });

      print('Inventory updated successfully: New Quantity = $updatedQuantity, Status = $updatedStatus');
    } else {
      print('Inventory document for blood type "$bloodType" not found.');
    }
  } catch (e) {
    print('Error updating inventory: $e');
  }
}



  @override
  Widget build(BuildContext context) {
    if (reservation == null) {
      return Scaffold(
        appBar: AppBar(
            backgroundColor: Styles.primaryColor,
            leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_outlined, size: 20, color: Colors.white), onPressed: () {Navigator.pop(context);},),
            title: Text("Reservation Details", style: Styles.headerStyle2.copyWith(fontSize: 18, fontWeight: FontWeight.bold, color: Styles.tertiaryColor,)),
          ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Styles.tertiaryColor,
      appBar: AppBar(
            backgroundColor: Styles.primaryColor,
            leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_outlined, size: 20, color: Colors.white), onPressed: () {Navigator.pop(context);},),
            title: Text("Reservation Details", style: Styles.headerStyle2.copyWith(fontSize: 18, fontWeight: FontWeight.bold, color: Styles.tertiaryColor,)),
          ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Blood Bank:', style: Styles.headerStyle5.copyWith(fontSize: 18, color: Styles.accentColor)),  // Display blood bank name
            Text(bloodBankName, style: Styles.headerStyle5.copyWith(fontSize: 20, fontWeight: FontWeight.bold, color: Styles.accentColor)),
            SizedBox(height: 15),

            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text('Blood Type:', style: Styles.headerStyle5.copyWith(fontSize: 18, color: Styles.accentColor)),
                SizedBox(width: 62),
                Text('Quantity:', style: Styles.headerStyle5.copyWith(fontSize: 18, color: Styles.accentColor)),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text('${reservation?.bloodType}', style: Styles.headerStyle5.copyWith(fontSize: 20, fontWeight: FontWeight.bold, color: Styles.accentColor)),
                SizedBox(width: 138),
                Text('${reservation?.quantity}', style: Styles.headerStyle5.copyWith(fontSize: 20, fontWeight: FontWeight.bold, color: Styles.accentColor)),
              ],
            ),
            SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text('Status:', style: Styles.headerStyle5.copyWith(fontSize: 18, color: Styles.accentColor)),
                SizedBox(width: 100),
                Text('Medical Reason:', style: Styles.headerStyle5.copyWith(fontSize: 18, color: Styles.accentColor)),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text('${reservation?.status}', style: Styles.headerStyle5.copyWith(fontSize: 20, fontWeight: FontWeight.bold, color: Styles.accentColor)),
                SizedBox(width: 83),
                Text(reservation?.medicalReason ?? 'Not Provided', style: Styles.headerStyle5.copyWith(fontSize: 20, fontWeight: FontWeight.bold, color: Styles.accentColor)),
              ],
            ),
            SizedBox(height: 15),
            Row(
              children: [
                Text('Reserved At:', style: Styles.headerStyle5.copyWith(fontSize: 18, color: Styles.accentColor)),
                SizedBox(width: 56),
                Text('Valid Until:', style: Styles.headerStyle5.copyWith(fontSize: 18, color: Styles.accentColor)),
              ],
            ),
            Row(
              children: [
                Text(DateFormat('MM/dd/yyyy').format(reservation?.reservedAt ?? DateTime.now()), style: Styles.headerStyle5.copyWith(fontSize: 20, fontWeight: FontWeight.bold, color: Styles.accentColor)),
                SizedBox(width: 50),
                Text(DateFormat('MM/dd/yyyy').format(reservation?.validUntil ?? DateTime.now()), style: Styles.headerStyle5.copyWith(fontSize: 20, fontWeight: FontWeight.bold, color: Styles.accentColor)),
              ],
            ),
            SizedBox(height: 30),
            
            
            /*Text('Blood Type:', style: Styles.headerStyle5.copyWith(fontSize: 15, color: Styles.accentColor)),
            Text(reservation!.bloodType, style: Styles.headerStyle5.copyWith(fontSize: 18, fontWeight: FontWeight.bold, color: Styles.accentColor)),
            SizedBox(height: 10),

            Text('Quantity:', style: Styles.headerStyle5.copyWith(fontSize: 15, color: Styles.accentColor)),
            Text('${reservation?.quantity}', style: Styles.headerStyle5.copyWith(fontSize: 18, fontWeight: FontWeight.bold, color: Styles.accentColor)),
            SizedBox(height: 10),

            Text('Status:', style: Styles.headerStyle5.copyWith(fontSize: 15, color: Styles.accentColor)),
            Text('${reservation?.status}', style: Styles.headerStyle5.copyWith(fontSize: 18, fontWeight: FontWeight.bold, color: Styles.accentColor)),
            SizedBox(height: 10),

            Text('Reserved At:', style: Styles.headerStyle5.copyWith(fontSize: 15, color: Styles.accentColor)),
            Text(DateFormat('MM/dd/yyyy').format(reservation?.reservedAt ?? DateTime.now()), style: Styles.headerStyle5.copyWith(fontSize: 18, fontWeight: FontWeight.bold, color: Styles.accentColor)),
            SizedBox(height: 10),
            
            Text('Valid Until:', style: Styles.headerStyle5.copyWith(fontSize: 15, color: Styles.accentColor)),
            Text(DateFormat('MM/dd/yyyy').format(reservation?.validUntil ?? DateTime.now()), style: Styles.headerStyle5.copyWith(fontSize: 18, fontWeight: FontWeight.bold, color: Styles.accentColor)),
            SizedBox(height: 10),
            
            Text('Medical Reason:', style: Styles.headerStyle5.copyWith(fontSize: 15, color: Styles.accentColor)),
            Text(reservation?.medicalReason ?? 'Not Provided', style: Styles.headerStyle5.copyWith(fontSize: 18, fontWeight: FontWeight.bold, color: Styles.accentColor)),
            SizedBox(height: 10),*/

            // Cancel Reservation Button
            /*MyButtons(
            onTap: () async {
              await cancelReservation(); // Call the async cancelReservation method
            },
            text: 'Cancel Reservation',
          )*/
          Positioned(
            bottom: 20,
            left: 20,
            right: 60,
            child: ElevatedButton(
              onPressed: () async{await cancelReservation();},
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50), // Make the button full width
                backgroundColor: Styles.primaryColor,
                foregroundColor: Styles.tertiaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Cancel Reservation',
                style: Styles.headerStyle6.copyWith(color: Styles.tertiaryColor),
              ),
            ),
          ),
          ],
        ),
      ),
    );
  }
}


/*class ReservationDetailsScreen extends StatefulWidget {
  final String reservationId;  // Accept reservationId as a parameter

  const ReservationDetailsScreen({Key? key, required this.reservationId}) : super(key: key);

  @override
  _ReservationDetailsScreenState createState() => _ReservationDetailsScreenState();
}

class _ReservationDetailsScreenState extends State<ReservationDetailsScreen> {
  //late ReservationModel reservation;

  ReservationModel? reservation;  // Make reservation nullable


  @override
  void initState() {
    super.initState();
    fetchReservationDetails();
  }

  // Fetch reservation details using the reservationId
  Future<void> fetchReservationDetails() async {
    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('reservations')
          .doc(widget.reservationId)  // Use the passed reservationId
          .get();

      if (docSnapshot.exists) {
        setState(() {
          reservation = ReservationModel.fromFirestore(
              widget.reservationId, docSnapshot.data() as Map<String, dynamic>);
        });
      } else {
        // Handle case where reservation doesn't exist
        print('Reservation not found.');
      }
    } catch (e) {
      print('Error fetching reservation details: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (reservation == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Reservation Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reservation Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Blood Type: ${reservation?.bloodType}', style: TextStyle(fontSize: 20)),
            SizedBox(height: 10),
            Text('Quantity: ${reservation?.quantity}', style: TextStyle(fontSize: 20)),
            SizedBox(height: 10),
            Text('Status: ${reservation?.status}', style: TextStyle(fontSize: 20)),
            SizedBox(height: 10),
            Text('Valid Until: ${reservation?.validUntil.toString().substring(0, 10)}', style: TextStyle(fontSize: 20)),
            // Add more details if needed
          ],
        ),
      ),
    );
  }
}*/

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:redpulse/features/models/inventory.dart';
import 'package:redpulse/services/auth.dart';
import 'package:redpulse/utilities/constants/styles.dart';
import 'package:redpulse/widgets/button.dart';

class ReservationFormScreen extends StatefulWidget {
  final String bloodBankId;
  final List<InventoryModel> inventoryList;

  const ReservationFormScreen({Key? key, required this.bloodBankId, required this.inventoryList}) : super(key: key);

  @override
  _ReservationFormScreenState createState() => _ReservationFormScreenState();
}

class _ReservationFormScreenState extends State<ReservationFormScreen> {
  late List<InventoryModel> inventoryList;
  String? selectedBloodType;
  int quantity = 1;
  DateTime reservedAt = DateTime.now();
  TextEditingController medicalReasonController = TextEditingController(); // Controller for medical reason text field

  @override
  void initState() {
    super.initState();
    inventoryList = widget.inventoryList; // Initialize the list from the passed parameter
  }

  // Function to get the available stock for the selected blood type
  int getAvailableStock(String bloodType) {
    final inventoryItem = inventoryList.firstWhere((inventory) => inventory.bloodType == bloodType, orElse: () => InventoryModel(bloodType: bloodType, quantity: 0, lastUpdated: DateTime.now(), status: '', bloodBankId: widget.bloodBankId));
    return inventoryItem.quantity;
  }

  // Handle reservation of blood
  Future<void> _reserveBlood() async {
    if (quantity > 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot reserve more than 10 units.')),
      );
      return;
    }

    if (selectedBloodType == null || inventoryList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a blood type and ensure inventory is loaded.')),
      );
      return;
    }

    final availableStock = getAvailableStock(selectedBloodType!);

    if (quantity > availableStock) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Only $availableStock unit/s available for this blood type.')),
      );
      return;
    }

    if (medicalReasonController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide a medical reason for the reservation.')),
      );
      return;
    }

    try {
      final userId = await AuthMethod().getAdminId();

      // Calculate validUntil date (one week after the reservation date)
      final validUntil = reservedAt.add(Duration(days: 7));

      // Add reservation to Firestore
      /*await FirebaseFirestore.instance.collection('reservations').add({
        'bloodType': selectedBloodType,
        'quantity': quantity,
        'bloodBankId': widget.bloodBankId,
        'userId': userId,
        'reservationDate': Timestamp.fromDate(reservedAt),
        'validUntil': Timestamp.fromDate(validUntil),  // Add validUntil date
        'status': 'Pending',
        'medicalReason': medicalReasonController.text,  // Store medical reason
      });*/

      DocumentReference reservationRef = await FirebaseFirestore.instance.collection('reservations').add({
      'bloodType': selectedBloodType,
      'quantity': quantity,
      'bloodBankId': widget.bloodBankId,
      'userId': userId,
      'reservedAt': Timestamp.fromDate(reservedAt),
      'validUntil': Timestamp.fromDate(validUntil),  // Add validUntil date
      'status': 'Pending',
      'medicalReason': medicalReasonController.text,  // Store medical reason
      });

      // Get the auto-generated reservation ID
      String reservationId = reservationRef.id;

      // Update the inventory after reservation
      await _updateInventory();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reservation successful!')),
      );

      Navigator.pop(context, true); // Return true to indicate reservation success
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error reserving blood: $e')),
      );
    }
  }

  // Function to update the inventory after reservation
  /*Future<void> _updateInventory() async {
    try {
      // Get the blood type item from inventory
      final inventoryItem = inventoryList.firstWhere((inventory) => inventory.bloodType == selectedBloodType);

      // Deduct the reserved quantity
      final updatedQuantity = inventoryItem.quantity - quantity;

      // Update Firestore inventory for this blood type
      await FirebaseFirestore.instance
          .collection('bloodbanks')
          .doc(widget.bloodBankId)
          .collection('inventories')
          .doc(inventoryItem.bloodType)
          .update({
        'quantity': updatedQuantity,
        'lastUpdated': Timestamp.fromDate(DateTime.now()),
      });

      // Update local list of inventory items
      setState(() {
        inventoryItem.quantity = updatedQuantity;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating inventory: $e')),
      );
    }
  }*/
  Future<void> _updateInventory() async {
  try {
    // Get the blood type item from the local inventory list
    final inventoryItem = inventoryList.firstWhere(
      (inventory) => inventory.bloodType == selectedBloodType,
    );

    // Deduct the reserved quantity
    final int updatedQuantity = inventoryItem.quantity - quantity;

    // Determine inventory status based on updated quantity
    String updatedStatus;
    if (updatedQuantity == 0) {
      updatedStatus = 'Out of Stock';
    } else if (updatedQuantity < 10) {
      updatedStatus = 'Low Stock';
    } else {
      updatedStatus = 'Available';
    }

    // Update Firestore inventory for this blood type
    await FirebaseFirestore.instance
        .collection('bloodbanks')
        .doc(widget.bloodBankId)
        .collection('inventories')
        .doc(inventoryItem.bloodType)
        .update({
      'quantity': updatedQuantity,
      'status': updatedStatus,
      'lastupdated': FieldValue.serverTimestamp(),
    });

    // Update local list of inventory items
    setState(() {
      inventoryItem.quantity = updatedQuantity;
    });

    // Success feedback
    /*ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Inventory updated successfully!')),
    );*/
  } catch (e) {
    // Error feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error updating inventory: $e')),
    );
  }
}


  @override
  Widget build(BuildContext context) {
    // Filter inventory to only show available blood types
    List<String> availableBloodTypes = inventoryList
        .where((inventory) => inventory.quantity > 0)
        .map((inventory) => inventory.bloodType)
        .toList();

    return Scaffold(
      backgroundColor: Styles.tertiaryColor,
      appBar: AppBar(
            backgroundColor: Styles.primaryColor,
            leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_outlined, size: 20, color: Colors.white), onPressed: () {Navigator.pop(context);},),
            title: Text('Reservation', style: Styles.headerStyle2.copyWith(fontSize: 18, fontWeight: FontWeight.bold, color: Styles.tertiaryColor,)),
            centerTitle: true,
          ),
      body: inventoryList.isEmpty
          ? const Center(child: CircularProgressIndicator()) // Show a loading spinner until inventory is loaded
          : Padding(
            padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 80),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 30),
                Text(
                  'Blood Type',
                  style: Styles.headerStyle5.copyWith(fontSize: 20, fontWeight: FontWeight.bold, color: Styles.accentColor),
                ),
                DropdownButton<String>(
                  dropdownColor: Styles.tertiaryColor,
                  isExpanded: true,
                  value: selectedBloodType,
                  hint: const Text('Select a blood type'),
                  onChanged: (String? value) {
                    setState(() {
                      selectedBloodType = value;
                    });
                  },
                  items: availableBloodTypes.map<DropdownMenuItem<String>>((bloodType) {
                    return DropdownMenuItem<String>(
                      value: bloodType,
                      child: Text(bloodType, style: Styles.headerStyle5.copyWith(fontSize: 18, color: Styles.accentColor)),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 30),
                Text(
                  'Quantity (Limit of 10 Units)',
                  style: Styles.headerStyle5.copyWith(fontSize: 20, fontWeight: FontWeight.bold, color: Styles.accentColor),
                ),
                Slider(
                  activeColor: Styles.primaryColor,
                  min: 1,
                  max: 10,
                  divisions: 10,
                  value: quantity.toDouble(),
                  onChanged: (value) {
                    setState(() {
                      quantity = value.toInt();
                    });
                  },
                ),
                Text('Selected: $quantity', style: Styles.headerStyle5.copyWith(fontSize: 18, color: Styles.accentColor)),
                const SizedBox(height: 30),
                Text(
                  'Medical Reason',
                  style: Styles.headerStyle5.copyWith(fontSize: 20, fontWeight: FontWeight.bold, color: Styles.accentColor),
                ),
                TextField(
                  controller: medicalReasonController,
                  decoration: const InputDecoration(
                    hintText: 'Enter the medical reason',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 20),
                // Using MyButtons widget
                Positioned(
                  bottom: 20,
                  left: 20,
                  right: 60,
                  child: ElevatedButton(
                    onPressed: _reserveBlood,
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity, 50), // Make the button full width
                      backgroundColor: Styles.primaryColor,
                      foregroundColor: Styles.tertiaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Reserve Blood',
                      style: Styles.headerStyle6.copyWith(color: Styles.tertiaryColor),
                    ),
                  ),
                ),
                /*MyButtons(
                  text: 'Reserve Blood',
                  onTap: _reserveBlood,
                ),*/
              ],
            ),
          ),

    );
  }
}
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:redpulse/features/models/inventory.dart';
import 'package:redpulse/services/auth.dart';
import 'package:redpulse/utilities/constants/styles.dart';
import 'package:redpulse/widgets/button.dart';
import 'package:redpulse/widgets/textfield.dart';

class UpdateInventory extends StatefulWidget {
  final String bloodBankId;

  const UpdateInventory({super.key, required this.bloodBankId});

  @override
  UpdateInventoryState createState() => UpdateInventoryState();
}

class UpdateInventoryState extends State<UpdateInventory> {
  late Future<List<InventoryModel>> _inventoryFuture;
  final Map<String, TextEditingController> _quantityControllers = {};
  late Future<String> _bloodBankNameFuture;
  final AuthMethod _authMethod = AuthMethod();

  @override
  void initState() {
    super.initState();
    _inventoryFuture = _loadInventory();
    _bloodBankNameFuture = _authMethod.fetchBloodBankName(widget.bloodBankId);
  }

  // Function to load the inventory from Firestore
  Future<List<InventoryModel>> _loadInventory() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('bloodbanks')
        .doc(widget.bloodBankId)
        .collection('inventories')
        .get();

    List<InventoryModel> inventoryList = [];
    for (var doc in snapshot.docs) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      InventoryModel inventory =
          InventoryModel.fromFirestore(widget.bloodBankId, data);
      inventoryList.add(inventory);
    }
    return inventoryList;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _bloodBankNameFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        } else if (snapshot.hasError || !snapshot.hasData) {
          return Scaffold(
              body: Center(child: Text('Error: ${snapshot.error}')));
        }

        final bloodBankName = snapshot.data!;

        return FutureBuilder<List<InventoryModel>>(
          future: _inventoryFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                  body: Center(child: CircularProgressIndicator()));
            } else if (snapshot.hasError || !snapshot.hasData) {
              return Scaffold(
                  body: Center(child: Text('Error: ${snapshot.error}')));
            }

            final inventoryList = snapshot.data!;

            // Initialize controllers for each blood type
            for (var inventory in inventoryList) {
              if (!_quantityControllers.containsKey(inventory.bloodType)) {
                _quantityControllers[inventory.bloodType] =
                    TextEditingController();
              }
            }

            return Scaffold(
              backgroundColor: Colors.white,
              appBar: PreferredSize(
                preferredSize: const Size.fromHeight(100),
                child: AppBar(
                  backgroundColor: Styles.primaryColor,
                  elevation: 0,
                  iconTheme: const IconThemeData(color: Colors.white),
                  flexibleSpace: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Align(
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 20),
                          Text(
                            bloodBankName,
                            style: Styles.headerStyle2.copyWith(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Styles.tertiaryColor),
                          ),
                          Text(
                            'Update Inventory',
                            style: Styles.headerStyle2.copyWith(
                                fontSize: 18, color: Styles.tertiaryColor),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              body: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: inventoryList.length,
                        itemBuilder: (context, index) {
                          final inventory = inventoryList[index];
                          final controller =
                              _quantityControllers[inventory.bloodType]!;

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16.0),
                                  child: Text(
                                    'Blood Type: ${inventory.bloodType}',
                                    style: Styles.headerStyle2
                                        .copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ),
                                TextFieldInput(
                                  textEditingController: controller,
                                  hintText: 'Enter new quantity',
                                  textInputType: TextInputType.number,
                                  icon: Icons.bloodtype_outlined,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    MyButtons(
                      onTap: () async {
                        try {
                          bool updated = false;
                          // Show loading indicator
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) => const Center(
                                child: CircularProgressIndicator()),
                          );

                          // Iterate over all blood types and update them if necessary
                          for (var inventory in inventoryList) {
                            final controller =
                                _quantityControllers[inventory.bloodType];
                            final newQuantityText = controller!.text.trim();

                            // Only update if a value was entered
                            if (newQuantityText.isNotEmpty) {
                              final newQuantity = int.tryParse(newQuantityText);

                              if (newQuantity != null) {
                                // Direct update to Firebase
                                await FirebaseFirestore.instance
                                    .collection('bloodbanks')
                                    .doc(widget.bloodBankId)
                                    .collection('inventories')
                                    .doc(inventory.bloodType)
                                    .update({
                                  'quantity': newQuantity,
                                  'lastUpdated': FieldValue.serverTimestamp(),
                                });

                                updated = true;
                                print(
                                    'Updated $newQuantity units of ${inventory.bloodType}');
                              }
                            }
                          }

                          // Close loading dialog
                          Navigator.of(context, rootNavigator: true).pop();

                          if (updated) {
                            // Show success message
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                    Text('Inventory Updated Successfully!'),
                                backgroundColor: Colors.green,
                              ),
                            );

                            // Return to previous screen with indication of success
                            Navigator.pop(context, true);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'No changes were made. Please enter values to update.'),
                                backgroundColor: Colors.orange,
                              ),
                            );
                          }
                        } catch (e) {
                          // Handle errors
                          Navigator.of(context, rootNavigator: true)
                              .pop(); // Close loading dialog
                          print('Error updating inventory: $e');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Error updating inventory: ${e.toString()}'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      text: "Save Changes",
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:redpulse/features/models/inventory.dart';
import 'package:redpulse/services/auth.dart';
import 'package:redpulse/utilities/constants/styles.dart';
import 'package:intl/intl.dart';
import 'package:redpulse/widgets/button.dart';
import 'package:animate_do/animate_do.dart';

class Inventory extends StatefulWidget {
  final String bloodBankId;

  const Inventory({super.key, required this.bloodBankId});

  @override
  InventoryState createState() => InventoryState();
}

class InventoryState extends State<Inventory> {
  late Future<List<InventoryModel>> _inventoryFuture;
  late Future<String> _bloodBankNameFuture;

  final AuthMethod _authMethod = AuthMethod();
  final TextEditingController _quantityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _inventoryFuture = _loadInventory();
    _bloodBankNameFuture = _authMethod.fetchBloodBankName(widget.bloodBankId);
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  Future<List<InventoryModel>> _loadInventory() async {
    try {
      await InventoryModel.initializeBloodTypeInventory(widget.bloodBankId);
      QuerySnapshot inventorySnapshot = await FirebaseFirestore.instance
          .collection('bloodbanks')
          .doc(widget.bloodBankId)
          .collection('inventories')
          .get();

      List<InventoryModel> inventoryList = inventorySnapshot.docs.map((doc) {
        return InventoryModel.fromFirestore(
          widget.bloodBankId,
          doc.data() as Map<String, dynamic>,
        );
      }).toList();

      inventoryList.sort((a, b) => a.bloodType.compareTo(b.bloodType));
      return inventoryList;
    } catch (e) {
      print('Error loading inventory: $e');
      return [];
    }
  }

  Future<void> _updateSingleInventory(String bloodType, int newQuantity) async {
    try {
      await FirebaseFirestore.instance
          .collection('bloodbanks')
          .doc(widget.bloodBankId)
          .collection('inventories')
          .doc(bloodType)
          .update({
        'quantity': newQuantity,
        'lastUpdated': FieldValue.serverTimestamp(),
        'status': _determineStatus(newQuantity),
      });

      setState(() {
        _inventoryFuture = _loadInventory();
      });
    } catch (e) {
      print('Error updating inventory: $e');
    }
  }

  Future<void> _updateAllInventory(int newQuantity) async {
    try {
      QuerySnapshot inventorySnapshot = await FirebaseFirestore.instance
          .collection('bloodbanks')
          .doc(widget.bloodBankId)
          .collection('inventories')
          .get();

      WriteBatch batch = FirebaseFirestore.instance.batch();

      for (var doc in inventorySnapshot.docs) {
        batch.update(doc.reference, {
          'quantity': newQuantity,
          'lastUpdated': FieldValue.serverTimestamp(),
          'status': _determineStatus(newQuantity),
        });
      }

      await batch.commit();

      setState(() {
        _inventoryFuture = _loadInventory();
      });
    } catch (e) {
      print('Error updating all inventory: $e');
    }
  }

  String _determineStatus(int quantity) {
    if (quantity <= 0) {
      return 'out of stock';
    } else if (quantity < 20) {
      return 'low stock';
    } else {
      return 'available';
    }
  }

  void _showUpdateDialog(String bloodType, int currentQuantity) {
    _quantityController.text = currentQuantity.toString();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Update $bloodType Units',
            style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: _quantityController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'New Quantity',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: GoogleFonts.roboto()),
            ),
            ElevatedButton(
              onPressed: () {
                int? newQuantity = int.tryParse(_quantityController.text);
                if (newQuantity != null && newQuantity >= 0) {
                  _updateSingleInventory(bloodType, newQuantity);
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Styles.accentColor,
              ),
              child: Text('Update',
                  style: GoogleFonts.roboto(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showUpdateAllDialog() {
    _quantityController.text = '';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Update All Blood Types',
            style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: _quantityController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'New Quantity For All',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: GoogleFonts.roboto()),
            ),
            ElevatedButton(
              onPressed: () {
                int? newQuantity = int.tryParse(_quantityController.text);
                if (newQuantity != null && newQuantity >= 0) {
                  _updateAllInventory(newQuantity);
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Styles.accentColor,
              ),
              child: Text('Update All',
                  style: GoogleFonts.roboto(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return FutureBuilder<String>(
      future: _bloodBankNameFuture,
      builder: (context, snapshot) {
        String bloodBankName = snapshot.data ?? 'Blood Bank';

        return Scaffold(
          backgroundColor: const Color.fromARGB(255, 248, 248, 248),
          appBar: PreferredSize(
            preferredSize: Size.fromHeight(screenSize.height * 0.13),
            child: FadeInDown(
              duration: const Duration(milliseconds: 800),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Styles.primaryColor,
                      Styles.primaryColor.withOpacity(0.95),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(25),
                    bottomRight: Radius.circular(25),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.2),
                      blurRadius: 15,
                      spreadRadius: 2,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: screenSize.width * 0.06,
                        vertical: screenSize.height * 0.015),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.inventory_2_rounded,
                                color: Colors.white, size: 32),
                            const SizedBox(width: 12),
                            Text(
                              bloodBankName,
                              style: GoogleFonts.montserrat(
                                fontSize: screenSize.width * 0.06,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Inventory',
                          style: GoogleFonts.roboto(
                            fontSize: screenSize.width * 0.045,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          body: FutureBuilder<List<InventoryModel>>(
            future: _inventoryFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator(color: Colors.red));
              } else if (snapshot.hasError) {
                return Center(
                    child: Text('Error: ${snapshot.error}',
                        style: GoogleFonts.roboto()));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                    child: Text('No inventory found.',
                        style: GoogleFonts.roboto()));
              }

              final inventoryList = snapshot.data!;

              return Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenSize.width * 0.06,
                        vertical: screenSize.height * 0.015,
                      ),
                      itemCount: inventoryList.length,
                      itemBuilder: (context, index) {
                        final inventory = inventoryList[index];

                        return FadeInUp(
                          duration: Duration(milliseconds: 700 + index * 100),
                          child: BloodInventoryCard(
                            inventory: inventory,
                            onUpdateTap: () {
                              _showUpdateDialog(
                                  inventory.bloodType, inventory.quantity);
                            },
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: screenSize.width * 0.06,
                        vertical: screenSize.height * 0.01),
                    child: MyButtons(
                      onTap: _showUpdateAllDialog,
                      text: "Update All Inventory",
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class BloodInventoryCard extends StatelessWidget {
  final InventoryModel inventory;
  final VoidCallback? onUpdateTap;

  const BloodInventoryCard({
    super.key,
    required this.inventory,
    this.onUpdateTap,
  });

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return Colors.green;
      case 'low stock':
        return Colors.orange;
      case 'out of stock':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Colors.grey.shade50],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.18),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(screenSize.width * 0.045),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    BloodDropIcon(bloodType: inventory.bloodType),
                    const SizedBox(width: 12),
                    Text(
                      'Blood Type ${inventory.bloodType}',
                      style: GoogleFonts.montserrat(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Styles.primaryColor,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(inventory.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _getStatusColor(inventory.status),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    inventory.status,
                    style: GoogleFonts.roboto(
                      color: _getStatusColor(inventory.status),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            // Quantity Row
            Row(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 60,
                      height: 60,
                      child: CircularProgressIndicator(
                        value: inventory.quantity / 100,
                        strokeWidth: 8,
                        backgroundColor: Colors.grey.withOpacity(0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getStatusColor(inventory.status),
                        ),
                      ),
                    ),
                    Text(
                      '${inventory.quantity}',
                      style: GoogleFonts.montserrat(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Styles.primaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'units available',
                    style: GoogleFonts.roboto(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Last updated
            Row(
              children: [
                const Icon(Icons.update, color: Colors.grey, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Last updated: ${DateFormat('MMM dd, yyyy').format(inventory.lastUpdated)}',
                    style: GoogleFonts.roboto(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            // Update button
            if (onUpdateTap != null)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onUpdateTap,
                    icon: const Icon(Icons.edit),
                    label: Text("Update Unit",
                        style: GoogleFonts.montserrat(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        )),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[700],
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class BloodDropIcon extends StatelessWidget {
  final String bloodType;

  const BloodDropIcon({
    super.key,
    required this.bloodType,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 54,
      child: CustomPaint(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 5),
          ),
        ),
      ),
    );
  }
}

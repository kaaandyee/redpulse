import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:redpulse/features/models/inventory.dart';
import 'package:redpulse/services/auth.dart';
import 'package:redpulse/utilities/constants/styles.dart';
import 'package:intl/intl.dart';
import 'package:redpulse/widgets/button.dart';

class Inventory extends StatefulWidget {
  final String bloodBankId;

  const Inventory({Key? key, required this.bloodBankId}) : super(key: key);

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
      // First, ensure all blood types are initialized
      await InventoryModel.initializeBloodTypeInventory(widget.bloodBankId);

      // Then fetch the inventory data
      QuerySnapshot inventorySnapshot = await FirebaseFirestore.instance
          .collection('bloodbanks')
          .doc(widget.bloodBankId)
          .collection('inventories')
          .get();

      // Convert documents to InventoryModel objects
      List<InventoryModel> inventoryList = inventorySnapshot.docs.map((doc) {
        return InventoryModel.fromFirestore(
          widget.bloodBankId,
          doc.data() as Map<String, dynamic>,
        );
      }).toList();

      // Sort by blood type for consistent display
      inventoryList.sort((a, b) => a.bloodType.compareTo(b.bloodType));

      return inventoryList;
    } catch (e) {
      print('Error loading inventory: $e');
      return [];
    }
  }

  // Update a single blood type inventory
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

      // Reload inventory after update
      setState(() {
        _inventoryFuture = _loadInventory();
      });
    } catch (e) {
      print('Error updating inventory: $e');
    }
  }

  // Update all blood types with the same quantity
  Future<void> _updateAllInventory(int newQuantity) async {
    try {
      // Get all blood types
      QuerySnapshot inventorySnapshot = await FirebaseFirestore.instance
          .collection('bloodbanks')
          .doc(widget.bloodBankId)
          .collection('inventories')
          .get();

      // Update each blood type
      WriteBatch batch = FirebaseFirestore.instance.batch();

      for (var doc in inventorySnapshot.docs) {
        batch.update(
            doc.reference,
            {
              'quantity': newQuantity,
              'lastUpdated': FieldValue.serverTimestamp(),
              'status': _determineStatus(newQuantity),
            }
        );
      }

      await batch.commit();

      // Reload inventory after update
      setState(() {
        _inventoryFuture = _loadInventory();
      });
    } catch (e) {
      print('Error updating all inventory: $e');
    }
  }

  // Determine status based on quantity
  String _determineStatus(int quantity) {
    if (quantity <= 0) {
      return 'out of stock';
    } else if (quantity < 20) {
      return 'low stock';
    } else {
      return 'available';
    }
  }

  // Show dialog to update single blood type
  void _showUpdateDialog(String bloodType, int currentQuantity) {
    _quantityController.text = currentQuantity.toString();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Update $bloodType Units'),
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
              child: const Text('Cancel'),
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
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  // Show dialog to update all blood types
  void _showUpdateAllDialog() {
    _quantityController.text = '';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Update All Blood Types'),
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
              child: const Text('Cancel'),
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
              child: const Text('Update All'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _bloodBankNameFuture,
      builder: (context, snapshot) {
        String bloodBankName = snapshot.data ?? 'Blood Bank';

        return Scaffold(
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(120),
            child: AppBar(
              backgroundColor: Styles.primaryColor,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              elevation: 0,
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
                          color: Styles.tertiaryColor,
                        ),
                      ),
                      Text(
                        'Inventory',
                        style: Styles.headerStyle2.copyWith(
                          fontSize: 18,
                          color: Styles.tertiaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          body: FutureBuilder<List<InventoryModel>>(
            future: _inventoryFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('No inventory found.'));
              }

              final inventoryList = snapshot.data!;

              return Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: inventoryList.length,
                      itemBuilder: (context, index) {
                        final inventory = inventoryList[index];

                        return BloodInventoryCard(
                          inventory: inventory,
                          onUpdateTap: () {
                            _showUpdateDialog(inventory.bloodType, inventory.quantity);
                          },
                        );
                      },
                    ),
                  ),
                  MyButtons(
                    onTap: _showUpdateAllDialog,
                    text: "Update All Inventory",
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

// Blood Inventory Card Widget
class BloodInventoryCard extends StatelessWidget {
  final InventoryModel inventory;
  final VoidCallback? onUpdateTap;

  const BloodInventoryCard({
    Key? key,
    required this.inventory,
    this.onUpdateTap,
  }) : super(key: key);

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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Blood drop shape with blood type
              BloodDropIcon(bloodType: inventory.bloodType),
              const SizedBox(width: 16),

              // Inventory details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status indicator
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Blood Type ${inventory.bloodType}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                            style: TextStyle(
                              color: _getStatusColor(inventory.status),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Quantity with circular indicator
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
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Text(
                            'units available',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Last updated info
                    Row(
                      children: [
                        const Icon(Icons.update, color: Colors.grey, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Last updated: ${DateFormat('MMM dd, yyyy').format(inventory.lastUpdated)}',
                            style: const TextStyle(
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
                            label: const Text("Update Unit"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Styles.accentColor,
                              foregroundColor: Colors.white,
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
            ],
          ),
        ),
      ),
    );
  }
}

// Custom Blood Drop Icon Widget
class BloodDropIcon extends StatelessWidget {
  final String bloodType;

  const BloodDropIcon({
    Key? key,
    required this.bloodType,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 60,
      height: 80,
      child: CustomPaint(
        painter: BloodDropPainter(Styles.primaryColor),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Text(
              bloodType,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Custom Painter for Blood Drop Shape
class BloodDropPainter extends CustomPainter {
  final Color color;

  BloodDropPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final double width = size.width;
    final double height = size.height;

    final Path path = Path();

    // Start from the top center
    path.moveTo(width / 2, 0);

    // Right curve
    path.quadraticBezierTo(
        width, height / 3,
        width / 2, height
    );

    // Left curve
    path.quadraticBezierTo(
        0, height / 3,
        width / 2, 0
    );

    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
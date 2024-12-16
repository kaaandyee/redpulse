import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:redpulse/services/update.dart';

class Inventory extends StatefulWidget {
  final String bloodBankId;
  const Inventory({Key? key, required this.bloodBankId}) : super(key: key);

  @override
  InventoryState createState() => InventoryState();
}

class InventoryState extends State<Inventory> {
  late Future<List<InventoryItem>> _inventoryFuture;

  @override
  void initState() {
    super.initState();
    _inventoryFuture = _loadInventory();
  }

  Future<List<InventoryItem>> _loadInventory() async {
    // Load all inventory items for a specific blood bank
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('bloodbanks')
        .doc(widget.bloodBankId)
        .collection('inventories')
        .get();

    // Map each document to an InventoryItem object
    return snapshot.docs.map((doc) {
      return InventoryItem.fromFirestore(doc.data() as Map<String, dynamic>);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inventory')),
      body: FutureBuilder<List<InventoryItem>>(
        future: _inventoryFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No inventory found.'));
          }

          final inventoryList = snapshot.data!;

          return ListView.builder(
            itemCount: inventoryList.length,
            itemBuilder: (context, index) {
              final inventory = inventoryList[index];
              return ListTile(
                contentPadding: const EdgeInsets.all(16),
                title: Text('Blood Type: ${inventory.bloodType}', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Quantity: ${inventory.quantity}'),
                    Text('Donated: ${inventory.donated}'),
                    Text('Expiration: ${inventory.expiration.toLocal()}'),
                    Text('Last Updated: ${inventory.lastUpdated.toLocal()}'),
                  ],
                ),
                trailing: _buildStatusBadge(inventory.status),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color badgeColor;
    String statusText;

    // Define color and status text based on the status
    switch (status) {
      case 'Low Stock':
        badgeColor = Colors.orange;
        statusText = 'Low Stock';
        break;
      case 'Out of Stock':
        badgeColor = Colors.red;
        statusText = 'Out of Stock';
        break;
      default:
        badgeColor = Colors.green;
        statusText = 'Available';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        statusText,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }
}

class InventoryItem {
  final String bloodType;
  final int quantity;
  final String status;
  final int donated;
  final DateTime expiration;
  final DateTime lastUpdated;

  InventoryItem({
    required this.bloodType,
    required this.quantity,
    required this.status,
    required this.donated,
    required this.expiration,
    required this.lastUpdated,
  });

  // Factory method to create InventoryItem from Firestore document data
  factory InventoryItem.fromFirestore(Map<String, dynamic> data) {
    String status;
    int quantity = data['inventory_quantity'] as int;

    // Determine the status based on the quantity
    if (quantity == 0) {
      status = 'Out of Stock';  // Special handling for zero quantity
    } else if (quantity < 10) {
      status = 'Low Stock';  // Handle low stock scenario
    } else {
      status = 'Available';  // Available for other quantities
    }

    return InventoryItem(
      bloodType: data['inventory_bloodtype'] as String,
      quantity: quantity,
      status: status,
      donated: data['inventory_donated'] as int,
      expiration: (data['inventory_expiration'] as Timestamp).toDate(),
      lastUpdated: (data['inventory_updated'] as Timestamp).toDate(),
    );
  }

  // Convert InventoryItem to JSON (for update or other operations)
  Map<String, dynamic> toJson() {
    return {
      'inventory_bloodtype': bloodType,
      'inventory_quantity': quantity,
      'inventory_status': status,
      'inventory_donated': donated,
      'inventory_expiration': expiration,
      'inventory_updated': lastUpdated,
    };
  }
}


/*class Inventory extends StatefulWidget {
  final String bloodBankId;
  const Inventory({Key? key, required this.bloodBankId}) : super(key: key);

  @override
  InventoryState createState() => InventoryState();
}

class InventoryState extends State<Inventory> {
  late Future<List<InventoryItem>> _inventoryFuture;

  @override
  void initState() {
    super.initState();
    _inventoryFuture = _loadInventory();
  }

  Future<List<InventoryItem>> _loadInventory() async {
    // Load all inventory items for a specific blood bank
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('bloodbanks')
        .doc(widget.bloodBankId)
        .collection('inventories')
        .get();

    // Map each document to an InventoryItem object
    return snapshot.docs.map((doc) {
      return InventoryItem.fromFirestore(doc.data() as Map<String, dynamic>);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inventory')),
      body: FutureBuilder<List<InventoryItem>>(
        future: _inventoryFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No inventory found.'));
          }

          final inventoryList = snapshot.data!;

          return ListView.builder(
            itemCount: inventoryList.length,
            itemBuilder: (context, index) {
              final inventory = inventoryList[index];
              return ListTile(
                title: Text('Blood Type: ${inventory.bloodType}'),
                subtitle: Text('Quantity: ${inventory.quantity}'),
                /*trailing: IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    // Navigate to the inventory update screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => InventoryUpdatePage(inventory: inventory),
                      ),
                    );
                  },
                ),*/
              );
            },
          );
        },
      ),
    );
  }
}

class InventoryItem {
  final String bloodType;
  final int quantity;

  InventoryItem({required this.bloodType, required this.quantity});

  // Factory method to create InventoryItem from Firestore document data
  factory InventoryItem.fromFirestore(Map<String, dynamic> data) {
    return InventoryItem(
      bloodType: data['bloodType'] as String,
      quantity: data['quantity'] as int,
    );
  }

  // Convert InventoryItem to JSON (for update or other operations)
  Map<String, dynamic> toJson() {
    return {
      'bloodType': bloodType,
      'quantity': quantity,
    };
  }
}*/


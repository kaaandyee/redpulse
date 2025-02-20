import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:redpulse/features/models/inventory.dart';
import 'package:redpulse/features/screens/admin/sub/updateinventory.dart';
import 'package:redpulse/services/auth.dart';
import 'package:redpulse/utilities/constants/styles.dart';
import 'package:intl/intl.dart';
import 'package:redpulse/widgets/button.dart';
import 'package:redpulse/widgets/statusbadge.dart';

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

  @override
  void initState() {
    super.initState();
    _inventoryFuture = _loadInventory();
    _bloodBankNameFuture = _authMethod.fetchBloodBankName(widget.bloodBankId);
  }

  /*Future<List<InventoryModel>> _loadInventory() async {
    // Load inventory for the specified blood bank
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('bloodbanks')
        .doc(widget.bloodBankId)
        .collection('inventories')
        .get();

    return snapshot.docs.map((doc) {
      return InventoryModel.fromFirestore(doc.data() as Map<String, dynamic>);
    }).toList();
  }*/
  
  Future<List<InventoryModel>> _loadInventory() async {
  // Load inventory for the specified blood bank
  QuerySnapshot snapshot = await FirebaseFirestore.instance
      .collection('bloodbanks')
      .doc(widget.bloodBankId)
      .collection('inventories')
      .get();

  // Map each document to an InventoryModel instance with status handling
  List<InventoryModel> inventoryList = [];

  for (QueryDocumentSnapshot doc in snapshot.docs) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // Get inventory model with updated status logic
    InventoryModel inventory = InventoryModel.fromFirestore(widget.bloodBankId, data);
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
          return Scaffold(
            backgroundColor: Styles.tertiaryColor,
            body: const Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasError || !snapshot.hasData) {
          return Scaffold(
            backgroundColor: Styles.tertiaryColor,
            appBar: AppBar(title: const Text('Error'), backgroundColor: Colors.white),
            body: Center(child: Text(snapshot.error?.toString() ?? "Error loading name")),
          );
        }

        final bloodBankName = snapshot.data!;

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

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                title: Text(
                                  'Blood Type: ${inventory.bloodType}',
                                  style: Styles.headerStyle2.copyWith(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Quantity: ${inventory.quantity}',
                                      style: Styles.headerStyle5.copyWith(color: Styles.accentColor),
                                    ),
                                    Text(
                                      'Last Updated: ${DateFormat('MM/dd/yyyy').format(inventory.lastUpdated)}',
                                      style: Styles.headerStyle5.copyWith(color: Styles.accentColor),
                                    ),
                                  ],
                                ),
                                trailing: StatusBadge(status: inventory.status), // Use the status from InventoryModel
                              ),
                              if (index < inventoryList.length - 1) const Divider(),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  MyButtons(
                    onTap: () async {
                      // Navigate to UpdateInventory and wait for a result
                      bool? updated = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UpdateInventory(
                            bloodBankId: widget.bloodBankId,
                          ),
                        ),
                      );

                      // If update occurred, refresh inventory
                      if (updated == true) {
                        setState(() {
                          _inventoryFuture = _loadInventory(); // Reload inventory
                        });
                      }
                    },
                    text: "Update Inventory",
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



/*class Inventory extends StatefulWidget {
  final String bloodBankId;

  const Inventory({Key? key, required this.bloodBankId}) : super(key: key);

  @override
  InventoryState createState() => InventoryState();
}

class InventoryState extends State<Inventory> {
  late Future<List<InventoryItemModel>> _inventoryFuture;
  late Future<String> _bloodBankNameFuture;

  final AuthMethod _authMethod = AuthMethod();

  @override
  void initState() {
    super.initState();
    _inventoryFuture = _loadInventory();
    _bloodBankNameFuture = _authMethod.fetchBloodBankName(widget.bloodBankId);
  }

  Future<List<InventoryItemModel>> _loadInventory() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('bloodbanks')
        .doc(widget.bloodBankId)
        .collection('inventories')
        .get();

    return snapshot.docs.map((doc) {
      return InventoryItemModel.fromFirestore(doc.data() as Map<String, dynamic>);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _bloodBankNameFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: Styles.tertiaryColor,
            //appBar: AppBar(title: const Text('Loading...'), backgroundColor: Colors.white),
            body: const Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasError || !snapshot.hasData) {
          return Scaffold(
            backgroundColor: Styles.tertiaryColor,
            appBar: AppBar(title: const Text('Error'), backgroundColor: Colors.white),
            body: Center(child: Text(snapshot.error?.toString() ?? "Error loading name")),
          );
        }

        final bloodBankName = snapshot.data!;

        return Scaffold(
          backgroundColor: Styles.tertiaryColor,
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(100),
            child: AppBar(
              backgroundColor: Styles.primaryColor,
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
                          fontWeight: FontWeight.bold, color: Styles.tertiaryColor
                        ),
                      ),
                      Text(
                        'Inventory',
                        style: Styles.headerStyle2.copyWith(
                          fontSize: 18,
                          color: Styles.tertiaryColor
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          body: FutureBuilder<List<InventoryItemModel>>(
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

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                title: Text(
                                  'Blood Type: ${inventory.bloodType}',
                                  style: Styles.headerStyle2.copyWith(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Quantity: ${inventory.quantity}',
                                      style: Styles.headerStyle5.copyWith(color: Styles.accentColor),
                                    ),
                                    Text(
                                      'Last Updated: ${DateFormat('MM/dd/yyyy').format(inventory.lastUpdated)}',
                                      style: Styles.headerStyle5.copyWith(color: Styles.accentColor),
                                    ),
                                  ],
                                ),
                                trailing: StatusBadge(status: inventory.status),

                              ),
                              if (index < inventoryList.length - 1) const Divider(),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  MyButtons(
                    onTap: () async {
                      // Navigate to UpdateInventory and wait for a result
                      bool? updated = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UpdateInventory(
                            bloodBankId: widget.bloodBankId,
                          ),
                        ),
                      );

                      // If update occurred, refresh inventory
                      if (updated == true) {
                        setState(() {
                          _inventoryFuture = _loadInventory(); // Reload inventory
                        });
                      }
                    },
                    text: "Update Inventory",
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}*/

/*class Inventory extends StatefulWidget {
  final String bloodBankId;

  const Inventory({Key? key, required this.bloodBankId}) : super(key: key);

  @override
  InventoryState createState() => InventoryState();
}

class InventoryState extends State<Inventory> {
  late Future<List<InventoryItem>> _inventoryFuture;
  late Future<String> _bloodBankNameFuture;

  final AuthMethod _authMethod = AuthMethod(); // Instance of AuthMethod

  @override
  void initState() {
    super.initState();
    _inventoryFuture = _loadInventory();
    _bloodBankNameFuture = _authMethod.fetchBloodBankName(widget.bloodBankId);
  }

  Future<List<InventoryItem>> _loadInventory() async {
    // Load all inventory items for a specific blood bank
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('bloodbanks')
        .doc(widget.bloodBankId)
        .collection('inventories')
        .get();

    return snapshot.docs.map((doc) {
      return InventoryItem.fromFirestore(doc.data() as Map<String, dynamic>);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _bloodBankNameFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: const Text('Loading...'), backgroundColor: Colors.white),
            body: const Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasError || !snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(title: const Text('Error'), backgroundColor: Colors.white),
            body: Center(child: Text(snapshot.error?.toString() ?? "Error loading name")),
          );
        }

        final bloodBankName = snapshot.data!;

        return Scaffold(
          backgroundColor: Styles.tertiaryColor,
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(100),
            child: AppBar(
              backgroundColor: Styles.primaryColor,
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
                          fontWeight: FontWeight.bold, color: Styles.tertiaryColor
                        ),
                      ),
                      Text(
                        'Inventory',
                        style: Styles.headerStyle2.copyWith(
                          fontSize: 18,
                          color: Styles.tertiaryColor
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          body: FutureBuilder<List<InventoryItem>>(
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

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                title: Text(
                                  'Blood Type: ${inventory.bloodType}',
                                  style: Styles.headerStyle2.copyWith(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Quantity: ${inventory.quantity}',
                                      style: Styles.headerStyle5.copyWith(color: Styles.accentColor),
                                    ),
                                    Text(
                                      'Last Updated: ${DateFormat('MM/dd/yyyy').format(inventory.lastUpdated)}',
                                      style: Styles.headerStyle5.copyWith(color: Styles.accentColor),
                                    ),
                                  ],
                                ),
                                trailing: _buildStatusBadge(inventory.status),
                              ),
                              if (index < inventoryList.length - 1) const Divider(),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  MyButtons(
                    onTap: () async {
                      // Navigate to UpdateInventory and wait for a result
                      bool? updated = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UpdateInventory(
                            bloodBankId: widget.bloodBankId,
                          ),
                        ),
                      );

                      // If update occurred, refresh inventory
                      if (updated == true) {
                        setState(() {
                          _inventoryFuture = _loadInventory();
                        });
                      }
                    },
                    text: "Update Inventory",
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }*/
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:redpulse/features/models/inventory.dart';
import 'package:redpulse/features/screens/user/sub/reservationform.dart';
import 'package:redpulse/services/auth.dart';
import 'package:redpulse/utilities/constants/styles.dart';
import 'package:redpulse/widgets/button.dart';
import 'package:redpulse/widgets/statusbadge.dart';

class BloodBankDetailsScreen extends StatefulWidget {
  final String bloodBankId;

  const BloodBankDetailsScreen({Key? key, required this.bloodBankId}) : super(key: key);

  @override
  BloodBankDetailsScreenState createState() => BloodBankDetailsScreenState();
}

class BloodBankDetailsScreenState extends State<BloodBankDetailsScreen> {
  late Future<List<InventoryModel>> _inventoryFuture;
  late Future<String> _bloodBankNameFuture;

  final AuthMethod _authMethod = AuthMethod();

  @override
  void initState() {
    super.initState();
    _inventoryFuture = _loadInventory();
    _bloodBankNameFuture = _authMethod.fetchBloodBankName(widget.bloodBankId);
  }

  // Fetch the inventory of the blood bank
  Future<List<InventoryModel>> _loadInventory() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('bloodbanks')
        .doc(widget.bloodBankId)
        .collection('inventories')
        .get();

    List<InventoryModel> inventoryList = snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;

      return InventoryModel(
        bloodType: data['bloodType'] as String? ?? 'Unknown',
        quantity: data['quantity'] as int? ?? 0,
        lastUpdated: (data['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
        status: data['status'] as String? ?? 'Unknown',
        bloodBankId: widget.bloodBankId,
      );
    }).toList();

    return inventoryList;
  }

  // Navigate to the reservation screen
  Future<void> _navigateToReservationScreen(List<InventoryModel> inventoryList) async {
    bool? reserved = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReservationFormScreen(
          bloodBankId: widget.bloodBankId,
          inventoryList: inventoryList, // Pass the inventory list here
        ),
      ),
    );

    if (reserved == true) {
      setState(() {
        _inventoryFuture = _loadInventory(); // Reload inventory after reservation
      });
    }
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
          backgroundColor: Styles.tertiaryColor,
          appBar: AppBar(
            backgroundColor: Styles.primaryColor,
            leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_outlined, size: 20, color: Colors.white), onPressed: () {Navigator.pop(context);},),
            title: Text(bloodBankName, style: Styles.headerStyle2.copyWith(fontSize: 18, fontWeight: FontWeight.bold, color: Styles.tertiaryColor,)),
            centerTitle: true,
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
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                title: Text(
                                  'Blood Type: ${inventory.bloodType}',
                                  style: Styles.headerStyle2.copyWith(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Quantity: ${inventory.quantity}',
                                      style: Styles.headerStyle5.copyWith(fontSize: 16, color: Styles.accentColor),
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
                    onTap: () {
                      _navigateToReservationScreen(inventoryList); // Pass the inventoryList here
                    },
                    text: "Reservation",
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



/*class BloodBankDetailsScreen extends StatefulWidget {
  final String bloodBankId;

  const BloodBankDetailsScreen({Key? key, required this.bloodBankId}) : super(key: key);

  @override
  BloodBankDetailsScreenState createState() => BloodBankDetailsScreenState();
}

class BloodBankDetailsScreenState extends State<BloodBankDetailsScreen> {
  late Future<List<InventoryModel>> _inventoryFuture;
  late Future<String> _bloodBankNameFuture;

  final AuthMethod _authMethod = AuthMethod();

  @override
  void initState() {
    super.initState();
    _inventoryFuture = _loadInventory();
    _bloodBankNameFuture = _authMethod.fetchBloodBankName(widget.bloodBankId);
  }

  // Fetch the inventory of the blood bank
  Future<List<InventoryModel>> _loadInventory() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('bloodbanks')
        .doc(widget.bloodBankId)
        .collection('inventories')
        .get();

    List<InventoryModel> inventoryList = snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;

      return InventoryModel(
        bloodType: data['bloodType'] as String? ?? 'Unknown',
        quantity: data['quantity'] as int? ?? 0,
        lastUpdated: (data['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
        status: data['status'] as String? ?? 'Unknown',
        bloodBankId: widget.bloodBankId,
      );
    }).toList();

    return inventoryList;
  }

  // Navigate to the reservation screen
  Future<void> _navigateToReservationScreen() async {
    bool? reserved = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReservationScreen(
          bloodBankId: widget.bloodBankId,
        ),
      ),
    );

    if (reserved == true) {
      setState(() {
        _inventoryFuture = _loadInventory(); // Reload inventory after reservation
      });
    }
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
          backgroundColor: Styles.tertiaryColor,
          appBar: AppBar(
            backgroundColor: Styles.primaryColor,
            leading: IconButton(icon: const Icon(Icons.arrow_circle_left, size: 25, color: Colors.white), onPressed: () {Navigator.pop(context);},),
            title: Text(bloodBankName, style: Styles.headerStyle2.copyWith(fontSize: 20, fontWeight: FontWeight.bold, color: Styles.tertiaryColor,),),
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
                                      style: Styles.headerStyle5.copyWith(fontSize: 18, color: Styles.accentColor),
                                    ),
                                    /*Text(
                                      'Last Updated: ${DateFormat('MM/dd/yyyy').format(inventory.lastUpdated)}',
                                      style: Styles.headerStyle5.copyWith(color: Styles.accentColor),
                                    ),*/
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
                          builder: (context) => ReservationScreen(
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
                    text: "Reservation",
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


/*class BloodBankDetailsScreen extends StatefulWidget {
  final String bloodBankId;

  const BloodBankDetailsScreen({Key? key, required this.bloodBankId}) : super(key: key);

  @override
  BloodBankDetailsScreenState createState() => BloodBankDetailsScreenState();
}

class BloodBankDetailsScreenState extends State<BloodBankDetailsScreen> {
  late Future<List<InventoryModel>> _inventoryFuture;
  late Future<String> _bloodBankNameFuture;

  final AuthMethod _authMethod = AuthMethod();

  @override
  void initState() {
    super.initState();
    _inventoryFuture = _loadInventory();
    _bloodBankNameFuture = _authMethod.fetchBloodBankName(widget.bloodBankId);
  }

  // Fetch the inventory of the blood bank
  Future<List<InventoryModel>> _loadInventory() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('bloodbanks')
        .doc(widget.bloodBankId)
        .collection('inventories')
        .get();

    List<InventoryModel> inventoryList = snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;

      return InventoryModel(
        bloodType: data['bloodType'] as String? ?? 'Unknown',
        quantity: data['quantity'] as int? ?? 0,
        lastUpdated: (data['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
        status: data['status'] as String? ?? 'Unknown',
        bloodBankId: widget.bloodBankId,
      );
    }).toList();

    return inventoryList;
  }

  // Reserve a blood type
  Future<void> _reserveBlood(String bloodType, int quantity) async {
    try {
      final userId = await _authMethod.getAdminId(); // Retrieve current user ID
      
      // Create a new reservation document in the 'reservations' collection
      final reservationRef = await FirebaseFirestore.instance.collection('reservations').add({
        'bloodType': bloodType,
        'quantity': quantity,
        'bloodBankId': widget.bloodBankId,
        'userId': userId,
        'reservationDate': Timestamp.now(),
        'status': 'Reserved',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Blood reserved successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error reserving blood: $e')),
      );
    }
  }

  // Confirm reservation action
  Future<void> _confirmAndReserve(String bloodType) async {
    final shouldReserve = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Reservation'),
          content: Text('Do you want to reserve 1 unit of blood type $bloodType?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Reserve'),
            ),
          ],
        );
      },
    );

    if (shouldReserve == true) {
      await _reserveBlood(bloodType, 1);
    }
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
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
            title: Column(
              children: [
                Text(
                  bloodBankName,
                  style: Styles.headerStyle2.copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'Available Blood Inventory',
                  style: TextStyle(fontSize: 18, color: Colors.black),
                ),
              ],
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

              return ListView.separated(
                itemCount: inventoryList.length,
                separatorBuilder: (context, _) => const Divider(),
                itemBuilder: (context, index) {
                  final inventory = inventoryList[index];

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListTile(
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
                              style: Styles.headerStyle5.copyWith(color: Colors.grey),
                            ),
                          ],
                        ),
                        trailing: StatusBadge(status: inventory.status),
                        onTap: () => _confirmAndReserve(inventory.bloodType),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}*/
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:redpulse/features/screens/admin/inventory.dart';
import 'package:redpulse/features/screens/admin/start.dart';
import 'package:redpulse/services/auth.dart';
import 'package:redpulse/utilities/constants/styles.dart';
import 'package:redpulse/widgets/abottombar.dart';
import 'package:redpulse/widgets/button.dart';
import 'package:redpulse/widgets/textfield.dart';
import 'package:redpulse/features/models/inventory.dart';

class UpdateInventory extends StatefulWidget {
  final String bloodBankId;

  const UpdateInventory({Key? key, required this.bloodBankId}) : super(key: key);

  @override
  UpdateInventoryState createState() => UpdateInventoryState();
}

class UpdateInventoryState extends State<UpdateInventory> {
  late Future<List<InventoryModel>> _inventoryFuture;
  final Map<String, TextEditingController> _quantityControllers = {}; // Store controllers for each blood type
  late Future<String> _bloodBankNameFuture;

  final AuthMethod _authMethod = AuthMethod(); // Instance of AuthMethod

  @override
  void initState() {
    super.initState();
    _inventoryFuture = _loadInventory();
    _bloodBankNameFuture = _authMethod.fetchBloodBankName(widget.bloodBankId); // Fetch blood bank name
  }

  // Function to load the inventory from Firestore
  /*Future<List<InventoryModel>> _loadInventory() async {
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
      future: _bloodBankNameFuture, // Fetch blood bank name
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        } else if (snapshot.hasError || !snapshot.hasData) {
          return Scaffold(body: Center(child: Text('Error: ${snapshot.error}')));
        }

        final bloodBankName = snapshot.data!;

        return FutureBuilder<List<InventoryModel>>(
          future: _inventoryFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            } else if (snapshot.hasError || !snapshot.hasData) {
              return Scaffold(body: Center(child: Text('Error: ${snapshot.error}')));
            }

            final inventoryList = snapshot.data!;

            // Initialize controllers for each blood type
            for (var inventory in inventoryList) {
              if (!_quantityControllers.containsKey(inventory.bloodType)) {
                _quantityControllers[inventory.bloodType] = TextEditingController();
              }
            }

            return Scaffold(
              backgroundColor: Colors.white,
              appBar: AppBar(
                backgroundColor: Styles.primaryColor,
                leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_outlined, size: 20, color: Colors.white), onPressed: () {Navigator.pop(context);},),
                title: Text('Update Inventory', style: Styles.headerStyle2.copyWith(fontSize: 18, fontWeight: FontWeight.bold, color: Styles.tertiaryColor,)),
                centerTitle: true,
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

                          // Get the controller for the current blood type
                          final controller = _quantityControllers[inventory.bloodType]!;

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16.0), // Horizontal padding only
                                  child: Text(
                                    'Blood Type: ${inventory.bloodType}',
                                    style: Styles.headerStyle2.copyWith(fontWeight: FontWeight.bold),
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
                        bool updated = false;
                        // Iterate over all the blood types and update them if necessary
                        for (var inventory in inventoryList) {
                          final controller = _quantityControllers[inventory.bloodType];
                          final newQuantity = int.tryParse(controller!.text);
                          if (newQuantity != null) {
                            // Fetch the Inventory instance for the blood type
                            final inventoryInstance = await InventoryModel.getInventory(widget.bloodBankId, inventory.bloodType);
                            
                            if (inventoryInstance != null) {
                              // Update the inventory quantity
                              await inventoryInstance.updateInventoryQuantity(newQuantity);
                              updated = true;
                            }
                          }
                        }

                        if (updated) {
                          // Show success message
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Inventory Updated Successfully!')),
                          );

                          // Navigate back to the previous screen with 'true' to indicate success
                          Navigator.pop(context, true);
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


/*class UpdateInventory extends StatefulWidget {
  final String bloodBankId;

  const UpdateInventory({Key? key, required this.bloodBankId}) : super(key: key);

  @override
  UpdateInventoryState createState() => UpdateInventoryState();
}

class UpdateInventoryState extends State<UpdateInventory> {
  late Future<List<InventoryItemModel>> _inventoryFuture;
  final Map<String, TextEditingController> _quantityControllers = {}; // Store controllers for each blood type
  late Future<String> _bloodBankNameFuture;

  final AuthMethod _authMethod = AuthMethod(); // Instance of AuthMethod

  @override
  void initState() {
    super.initState();
    _inventoryFuture = _loadInventory();
    _bloodBankNameFuture = _authMethod.fetchBloodBankName(widget.bloodBankId); // Fetch blood bank name
  }

  // Function to load the inventory from Firestore
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
      future: _bloodBankNameFuture, // Fetch blood bank name
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        } else if (snapshot.hasError || !snapshot.hasData) {
          return Scaffold(body: Center(child: Text('Error: ${snapshot.error}')));
        }

        final bloodBankName = snapshot.data!;

        return FutureBuilder<List<InventoryItemModel>>(
          future: _inventoryFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            } else if (snapshot.hasError || !snapshot.hasData) {
              return Scaffold(body: Center(child: Text('Error: ${snapshot.error}')));
            }

            final inventoryList = snapshot.data!;

            // Initialize controllers for each blood type
            for (var inventory in inventoryList) {
              if (!_quantityControllers.containsKey(inventory.bloodType)) {
                _quantityControllers[inventory.bloodType] = TextEditingController();
              }
            }

            return Scaffold(
              backgroundColor: Colors.white,
              /*appBar: PreferredSize(
                preferredSize: const Size.fromHeight(100), // Adjust the height of the AppBar
                child: AppBar(
                  backgroundColor: Styles.primaryColor,
                  elevation: 0,
                  iconTheme: const IconThemeData(color: Colors.white),
                  flexibleSpace: Padding(
                    padding: const EdgeInsets.all(20), // Add horizontal padding
                    child: Align(
                      alignment: Alignment.center, // Align to the left
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center, // Vertically center the content
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
                            'Update Inventory',
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
              ),*/

              appBar: AppBar(
                backgroundColor: Styles.primaryColor,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_circle_left, size: 25, color: Colors.white), // White back icon
                  onPressed: () {
                    Navigator.pop(context); // Navigate back to the previous screen (AdminHome)
                  },
                ),
                title: Text("Update Inventory", style: Styles.headerStyle2.copyWith(fontSize: 20, fontWeight: FontWeight.bold, color: Styles.tertiaryColor,),
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

                          // Get the controller for the current blood type
                          final controller = _quantityControllers[inventory.bloodType]!;

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16.0), // Horizontal padding only
                                  child: Text(
                                    'Blood Type: ${inventory.bloodType}',
                                    style: Styles.headerStyle2.copyWith(fontWeight: FontWeight.bold),
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
                        bool updated = false;
                        // Iterate over all the blood types and update them if necessary
                        for (var inventory in inventoryList) {
                          final controller = _quantityControllers[inventory.bloodType];
                          final newQuantity = int.tryParse(controller!.text);
                          if (newQuantity != null) {
                            // Fetch the Inventory instance for the blood type
                            final inventoryInstance = await InventoryModel.getInventory(widget.bloodBankId, inventory.bloodType);
                            
                            if (inventoryInstance != null) {
                              // Update the inventory quantity
                              await inventoryInstance.updateInventoryQuantity(newQuantity);
                              updated = true;
                            }
                          }
                        }

                        if (updated) {
                          // Show success message
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Inventory Updated Successfully!')),
                          );

                          // Navigate back to the previous screen with 'true' to indicate success
                          Navigator.pop(context, true);
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
}*/

/*class UpdateInventory extends StatefulWidget {
  final String bloodBankId;

  const UpdateInventory({Key? key, required this.bloodBankId}) : super(key: key);

  @override
  UpdateInventoryState createState() => UpdateInventoryState();
}

class UpdateInventoryState extends State<UpdateInventory> {
  late Future<List<InventoryItem>> _inventoryFuture;
  final Map<String, TextEditingController> _quantityControllers = {}; // Store controllers for each blood type
  late Future<String> _bloodBankNameFuture;

  final AuthMethod _authMethod = AuthMethod(); // Instance of AuthMethod

  @override
  void initState() {
    super.initState();
    _inventoryFuture = _loadInventory();
    _bloodBankNameFuture = _authMethod.fetchBloodBankName(widget.bloodBankId); // Fetch blood bank name
  }

  // Function to load the inventory from Firestore
  Future<List<InventoryItem>> _loadInventory() async {
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
      future: _bloodBankNameFuture, // Fetch blood bank name
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        } else if (snapshot.hasError || !snapshot.hasData) {
          return Scaffold(body: Center(child: Text('Error: ${snapshot.error}')));
        }

        final bloodBankName = snapshot.data!;

        return FutureBuilder<List<InventoryItem>>(
          future: _inventoryFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            } else if (snapshot.hasError || !snapshot.hasData) {
              return Scaffold(body: Center(child: Text('Error: ${snapshot.error}')));
            }

            final inventoryList = snapshot.data!;

            // Initialize controllers for each blood type
            for (var inventory in inventoryList) {
              if (!_quantityControllers.containsKey(inventory.bloodType)) {
                _quantityControllers[inventory.bloodType] = TextEditingController();
              }
            }

            return Scaffold(
              backgroundColor: Colors.white,
              appBar: PreferredSize(
                preferredSize: const Size.fromHeight(100), // Adjust the height of the AppBar
                child: AppBar(
                  backgroundColor: Styles.primaryColor,
                  elevation: 0,
                  iconTheme: const IconThemeData(color: Colors.white),
                  flexibleSpace: Padding(
                    padding: const EdgeInsets.all(20), // Add horizontal padding
                    child: Align(
                      alignment: Alignment.center, // Align to the left
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center, // Vertically center the content
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
                            'Update Inventory',
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
              body: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: inventoryList.length,
                        itemBuilder: (context, index) {
                          final inventory = inventoryList[index];

                          // Get the controller for the current blood type
                          final controller = _quantityControllers[inventory.bloodType]!;

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16.0), // Horizontal padding only
                                  child: Text(
                                    'Blood Type: ${inventory.bloodType}',
                                    style: Styles.headerStyle2.copyWith(fontWeight: FontWeight.bold),
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
                        bool updated = false;
                        // Iterate over all the blood types and update them if necessary
                        for (var inventory in inventoryList) {
                          final controller = _quantityControllers[inventory.bloodType];
                          final newQuantity = int.tryParse(controller!.text);
                          if (newQuantity != null) {
                            // Fetch the Inventory instance for the blood type
                            final inventoryInstance = await InventoryModel.getInventory(widget.bloodBankId, inventory.bloodType);
                            
                            if (inventoryInstance != null) {
                              // Update the inventory quantity
                              await inventoryInstance.updateInventoryQuantity(newQuantity);
                              updated = true;
                            }
                          }
                        }

                        if (updated) {
                          // Show success message
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Inventory Updated Successfully!')),
                          );

                          // Navigate to the AdminStart screen after updating the inventory
                          /*Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (context) => const AdminStart(isAdminLinkedToBloodBank: true),
                            ),
                            (route) => false, // Remove all previous routes to avoid stack overflow
                          );*/
                        }
                      },
                      text: "Update Inventory",
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
}*/
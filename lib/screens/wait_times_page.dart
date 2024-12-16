import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class ProviderInfo {
  final String firstName;
  final String lastName;
  final String specialty;
  final String title;
  int? waitTime;
  final String docId;

  ProviderInfo({
    required this.firstName,
    required this.lastName,
    required this.specialty,
    required this.title,
    this.waitTime,
    required this.docId,
  });

  factory ProviderInfo.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProviderInfo(
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      specialty: data['specialty'] ?? '',
      title: data['title'] ?? '',
      waitTime: data['waitTime'],
      docId: doc.id,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'specialty': specialty,
      'title': title,
      'waitTime': waitTime,
    };
  }

  String get displayName => '$lastName, ${firstName[0]}. | $title';
}

class WaitTimesPage extends StatefulWidget {
  final TabController tabController;

  WaitTimesPage({required this.tabController});

  @override
  _WaitTimesPageState createState() => _WaitTimesPageState();
}

class _WaitTimesPageState extends State<WaitTimesPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<ProviderInfo> providerList = [];
  List<ProviderInfo> selectedProviders = [];

  @override
  void initState() {
    super.initState();
    loadProvidersFromFirestore();

    // Add listener to refresh data when switching back to WaitTimesPage
    widget.tabController.addListener(() {
      if (widget.tabController.index == 0) {
        loadProvidersFromFirestore(); // Refresh data when tab switches to WaitTimesPage
      }
    });
  }

  Future<void> loadProvidersFromFirestore() async {
    final snapshot = await _firestore.collection('providers').get();
    setState(() {
      providerList =
          snapshot.docs.map((doc) => ProviderInfo.fromFirestore(doc)).toList();
      // Populate selectedProviders with providers who already have a waitTime
      selectedProviders =
          providerList.where((provider) => provider.waitTime != null).toList();
    });
  }

  Future<void> saveAllWaitTimes() async {
    for (var provider in selectedProviders) {
      if (provider.waitTime != null) {
        await _firestore.collection('providers').doc(provider.docId).update({
          'waitTime': provider.waitTime,
          'lastChanged': Timestamp.now(), // Add current timestamp
        });
      }
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Wait times saved successfully')),
    );
  }

  Future<void> _updateWaitTime(
      ProviderInfo provider, String newWaitTime) async {
    int? updatedWaitTime = int.tryParse(newWaitTime);
    if (updatedWaitTime != null) {
      setState(() {
        provider.waitTime = updatedWaitTime;
      });

      // Update the Firestore document with the new wait time
      await _firestore.collection('providers').doc(provider.docId).update({
        'waitTime': updatedWaitTime,
        'lastChanged': Timestamp.now(), // Update timestamp
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Wait time updated successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a valid wait time')),
      );
    }
  }

  void openProviderSelection() async {
    // Filter out providers that already have a wait time from the providerList
    final availableProviders =
        providerList.where((provider) => provider.waitTime == null).toList();

    final selected = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ProviderSelectionPage(providerList: availableProviders),
      ),
    );
    if (selected != null && selected is List<ProviderInfo>) {
      setState(() {
        selectedProviders.addAll(selected); // Add newly selected providers
      });
    }
  }

  Future<void> removeProvider(ProviderInfo provider) async {
    // Show a confirmation dialog
    bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Delete Wait Time"),
          content: Text(
              "Are you sure you want to delete this provider's wait time?"),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // User chose 'No'
              },
              child: Text("No"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true); // User chose 'Yes'
              },
              child: Text("Yes"),
            ),
          ],
        );
      },
    );

    // If the user confirmed the deletion, proceed with removing the wait time
    if (shouldDelete == true) {
      setState(() {
        selectedProviders.remove(provider);
        provider.waitTime = null; // Set wait time to null in the local state
      });

      // Update Firestore to remove waitTime and set the lastChanged field
      await _firestore.collection('providers').doc(provider.docId).update({
        'waitTime':
            FieldValue.delete(), // Removes the waitTime field in Firestore
        'lastChanged': FieldValue.delete(), // Delete timestamp
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Wait time removed and timestamp updated successfully')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Container(
          alignment: Alignment.center,
          child: Text('Wait Times'),
        ),
        actions: [
          IconButton(
            icon: Icon(CupertinoIcons.add),
            onPressed: openProviderSelection,
          ),
        ],
      ),
      body: Padding(
        padding:
            const EdgeInsets.all(16.0), // Adjust the padding values as needed
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: selectedProviders.length,
                itemBuilder: (context, index) {
                  final provider = selectedProviders[index];
                  final TextEditingController waitTimeController =
                      TextEditingController(
                    text: provider.waitTime?.toString() ?? '',
                  );

                  return Column(
                    children: [
                      ListTile(
                        title: Text(provider.displayName),
                        subtitle: Text('${provider.specialty}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Wait time input field
                            SizedBox(
                              width: 60,
                              child: TextField(
                                controller: waitTimeController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(labelText: 'Time'),
                                onChanged: (value) {
                                  provider.waitTime = int.tryParse(value);
                                },
                              ),
                            ),
                            // Update button
                            IconButton(
                              icon: Icon(Icons.update, color: Colors.blue),
                              onPressed: () => _updateWaitTime(
                                  provider, waitTimeController.text),
                            ),
                            // Remove button
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () => removeProvider(provider),
                            ),
                          ],
                        ),
                      ),
                      const Divider(
                        thickness: 1.0, // Thickness of the line
                        color: Colors.grey, // Color of the line
                      ),
                    ],
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: Center(
                child: Column(
      mainAxisSize: MainAxisSize.min, // Minimize the column's height
      children: [
        Text(
          'Save All',
          style: TextStyle(
            fontSize: 16, // Adjust the size as needed
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8), // Space between the text and the button
        IconButton(
                  icon: Icon(CupertinoIcons.checkmark_alt, size: 40),
                  onPressed: saveAllWaitTimes,
                ),
],
    ),
              ),
            ),

          ],
        ),
      ),
    );
  }
}

class ProviderSelectionPage extends StatefulWidget {
  final List<ProviderInfo> providerList;

  ProviderSelectionPage({required this.providerList});

  @override
  _ProviderSelectionPageState createState() => _ProviderSelectionPageState();
}

class _ProviderSelectionPageState extends State<ProviderSelectionPage> {
  List<ProviderInfo> selectedProviders = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Container(
          alignment: Alignment.center,
          child: Text('Select Providers'),
        ),
        actions: [
          IconButton(
            icon: Icon(CupertinoIcons.checkmark_alt),
            onPressed: () => Navigator.pop(context, selectedProviders),
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: widget.providerList.length,
        itemBuilder: (context, index) {
          final provider = widget.providerList[index];
          return CheckboxListTile(
            title: Text(provider.displayName),
            subtitle: Text(provider.specialty),
            value: selectedProviders.contains(provider),
            onChanged: (isSelected) {
              setState(() {
                if (isSelected == true) {
                  selectedProviders.add(provider);
                } else {
                  selectedProviders.remove(provider);
                }
              });
            },
          );
        },
      ),
    );
  }
}

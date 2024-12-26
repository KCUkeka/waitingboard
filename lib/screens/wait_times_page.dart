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
  final List<String> locations;
  String? selectedLocation; // Add selectedLocation field

  ProviderInfo({
    required this.firstName,
    required this.lastName,
    required this.specialty,
    required this.title,
    this.waitTime,
    required this.docId,
    required this.locations,
    this.selectedLocation, // Include in the constructor
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
      locations: List<String>.from(data['locations'] ?? []),
      selectedLocation: data['selectedLocation'], // Retrieve from Firestore
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'specialty': specialty,
      'title': title,
      'waitTime': waitTime,
      'locations': locations,
      'selectedLocation': selectedLocation, // Save to Firestore
    };
  }

  String get displayName {
    final locationInfo = selectedLocation != null ? ' ($selectedLocation)' : '';
    return '$lastName, ${firstName[0]}. | $title$locationInfo';
  }
}

class WaitTimesPage extends StatefulWidget {
  final TabController tabController;
  final String selectedLocation; // Add selectedLocation here

  WaitTimesPage({required this.tabController, required this.selectedLocation});

  @override
  _WaitTimesPageState createState() => _WaitTimesPageState();
}

class _WaitTimesPageState extends State<WaitTimesPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<ProviderInfo> providerList = [];
  List<ProviderInfo> selectedProviders = [];
  Map<ProviderInfo, String> selectedLocations =
      {}; // Map to store selected locations for each provider

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
    try {
      // Query providers based on the selected location
      final snapshot = await _firestore
          .collection('providers')
          .where('locations', arrayContains: widget.selectedLocation)
          .get();

      setState(() {
        providerList = snapshot.docs
            .map((doc) => ProviderInfo.fromFirestore(doc))
            .toList();
        selectedProviders = providerList
            .where((provider) => provider.waitTime != null)
            .toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load providers: ${e.toString()}')),
      );
    }
  }

  Future<void> saveAllWaitTimes() async {
    for (var provider in selectedProviders) {
      if (provider.waitTime != null) {
        await _firestore.collection('providers').doc(provider.docId).update({
          'waitTime': provider.waitTime,
          'lastChanged': Timestamp.now(),
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
      await _firestore.collection('providers').doc(provider.docId).update({
        'waitTime': updatedWaitTime,
        'lastChanged': Timestamp.now(),
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

Future<void> removeProvider(ProviderInfo provider) async {
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
      provider.selectedLocation = null; // Set selectedLocation to null locally
    });

    await _firestore.collection('providers').doc(provider.docId).update({
      'waitTime': FieldValue.delete(), // Removes the waitTime field in Firestore
      'selectedLocation': FieldValue.delete(), // Removes selectedLocation field
      'lastChanged': FieldValue.delete(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content:
              Text('Wait time and selected location removed successfully')),
    );
  }
}


// Function to delete all wait times
  Future<void> deleteAllWaitTimes() async {
// Show confirmation dialog
    bool? shouldDeleteAll = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Delete All Wait Times"),
          content: Text("Are you sure you want to delete all wait times?"),
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

    if (shouldDeleteAll == true) {
      // Delete all wait times in Firestore
      for (var provider in selectedProviders) {
        await _firestore.collection('providers').doc(provider.docId).update({
          'waitTime': FieldValue.delete(), // Removes the waitTime field
          'lastChanged': FieldValue.delete(),
        });
      }

      setState(() {
        selectedProviders.clear(); // Clear the selectedProviders list
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('All wait times deleted successfully')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Container(
          alignment: Alignment.center,
          child: Text('${widget.selectedLocation} Wait Times'),
        ),
        actions: [
          IconButton(
            icon: Icon(CupertinoIcons.add),
            onPressed: openProviderSelection,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
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
                            IconButton(
                              icon: Icon(Icons.update, color: Colors.blue),
                              onPressed: () => _updateWaitTime(
                                  provider, waitTimeController.text),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () => removeProvider(provider),
                            ),
                          ],
                        ),
                      ),
                      const Divider(),
                    ],
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Save All',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
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
      floatingActionButton: FloatingActionButton(
        onPressed:
            deleteAllWaitTimes, // Trigger the deleteAllWaitTimes function
        tooltip: 'Delete All Wait Times',
        child: Icon(Icons.delete_forever),
      ),
    );
  }

  // Provider selection function (if needed)
  void openProviderSelection() async {
    final availableProviders =
        providerList.where((provider) => provider.waitTime == null).toList();
    final selected = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ProviderSelectionPage(providerList: availableProviders),
      ),
    );
    if (selected != null && selected is List<Map<String, dynamic>>) {
      setState(() {
        selected.forEach((selection) {
          final provider = selection['provider'] as ProviderInfo;
          final location = selection['location'] as String;

          // Add the provider and location to your selectedProviders
          selectedProviders.add(provider);
          // Optionally, you can store the location in the selectedLocations map if you need to use it later
          selectedLocations[provider] = location;
        });
      });
    }
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
  Map<ProviderInfo, String> selectedLocations =
      {}; // Map to store selected locations for each provider

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
            onPressed: () {
              Navigator.pop(
                context,
                selectedProviders.map((provider) {
                  return {
                    'provider': provider,
                    'location': selectedLocations[
                        provider], // Use the selected location
                  };
                }).toList(),
              );
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: widget.providerList.length,
        itemBuilder: (context, index) {
          final provider = widget.providerList[index];
          final providerLocations = provider.locations;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CheckboxListTile(
                title: Text(provider.displayName),
                subtitle: Text(provider.specialty),
                value: selectedProviders.contains(provider),
                onChanged: (isSelected) {
                  setState(() {
                    if (isSelected == true) {
                      selectedProviders.add(provider);
                      selectedLocations[provider] = providerLocations.first;
                    } else {
                      selectedProviders.remove(provider);
                      selectedLocations.remove(provider);
                      provider.selectedLocation = null; // Clear selection
                    }
                  });
                  // Save the selected location immediately to Firestore
                  if (isSelected == true) {
                    FirebaseFirestore.instance
                        .collection('providers')
                        .doc(provider.docId)
                        .update({
                      'selectedLocation': provider.locations.first,
                    });
                  } else {
                    FirebaseFirestore.instance
                        .collection('providers')
                        .doc(provider.docId)
                        .update({
                      'selectedLocation': FieldValue.delete(),
                    });
                  }
                },
              ),
              if (selectedProviders.contains(provider))
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: DropdownButtonFormField<String>(
                    value: selectedLocations[provider],
                    items: providerLocations.map((location) {
                      return DropdownMenuItem(
                        value: location,
                        child: Text(location),
                      );
                    }).toList(),
                    onChanged: (selectedLocation) async {
                      setState(() {
                        selectedLocations[provider] = selectedLocation!;
                        provider.selectedLocation =
                            selectedLocation; // Update the selectedLocation locally
                      });

                      // Save the selectedLocation to Firestore
                      await FirebaseFirestore.instance
                          .collection('providers')
                          .doc(provider.docId)
                          .update({
                        'selectedLocation': selectedLocation,
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'Select Location',
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 10.0, horizontal: 12.0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a location';
                      }
                      return null;
                    },
                  ),
                ),
              const Divider(),
            ],
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LocationManagementPage extends StatelessWidget {
  final List<String> locations;

  LocationManagementPage({required this.locations});

  Future<void> deleteLocation(String locationName) async {
    // Query to find and delete the location from Firestore
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('locations')
        .where('name', isEqualTo: locationName)
        .get();

    for (QueryDocumentSnapshot doc in querySnapshot.docs) {
      await doc.reference.delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Manage Locations")),
      body: ListView.builder(
        itemCount: locations.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(locations[index]),
            trailing: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () async {
                await deleteLocation(locations[index]);
                // Optionally, update the UI if necessary
              },
            ),
          );
        },
      ),
    );
  }
}

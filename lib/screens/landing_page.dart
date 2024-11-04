import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import '../services/location_management.dart';

class LandingPage extends StatefulWidget {
  @override
  _LandingPageState createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  String? selectedRole;
  String? selectedLocation;

  final List<String> roles = ['Clinical', 'Front Desk'];
  List<String> locations = [];  // Initialize an empty list for locations

  @override
  void initState() {
    super.initState();
    fetchLocations();  // Fetch locations when the widget initializes
  }

  // Method to fetch locations from Firestore
  Future<void> fetchLocations() async {
    final querySnapshot = await FirebaseFirestore.instance.collection('locations').get();
    setState(() {
      locations = querySnapshot.docs.map((doc) => doc['name'] as String).toList();
    });
  }

  // Method to save role and location to Firestore
  Future<void> saveUserSelection() async {
    if (selectedRole != null && selectedLocation != null) {
      await FirebaseFirestore.instance.collection('users').add({
        'role': selectedRole,
        'location': selectedLocation,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
  }

  void onLogin() async {
    if (selectedRole != null && selectedLocation != null) {
      await saveUserSelection();
      Navigator.pushNamed(context, '/home', arguments: {
        'role': selectedRole,
        'location': selectedLocation,
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select both role and location")),
      );
    }
  }

// Method to add a new location
Future<void> addLocation() async {
  String? newLocation = await showDialog<String>(
    context: context,
    builder: (context) {
      String locationName = "";
      return AlertDialog(
        title: const Text("Add New Location"),
        content: TextField(
          onChanged: (value) {
            locationName = value;
          },
          decoration: const InputDecoration(hintText: "Enter location name"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, locationName),
            child: const Text("Add"),
          ),
        ],
      );
    },
  );

  if (newLocation != null && newLocation.isNotEmpty) {
    // Check if location already exists in the current list
    if (locations.contains(newLocation)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Location '$newLocation' is already added")),
      );
      return;
    }

    // Check if location already exists in Firestore
    final querySnapshot = await FirebaseFirestore.instance
        .collection('locations')
        .where('name', isEqualTo: newLocation)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      // Location already exists in Firestore
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Location '$newLocation' already exists")),
      );
    } else {
      // Add the location to Firestore
      await FirebaseFirestore.instance.collection('locations').add({
        'name': newLocation,
      });

      // Update the locations list in the UI
      setState(() {
        locations.add(newLocation);
        selectedLocation = newLocation;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Location '$newLocation' has been added")),
      );
    }
  }
}


  // Navigate to location management page
  void goToLocationManagement() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LocationManagementPage(locations: locations)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Container(
          alignment: Alignment.center,
          child: const Text('Select Role and Location', textAlign: TextAlign.center)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'Manage Locations') {
                  goToLocationManagement();
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'Manage Locations',
                  child: Text('Manage Locations'),
                ),
              ],
              child: const Icon(Icons.more_vert, size: 30),
            ),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text('Select Your Role', style: TextStyle(fontSize: 20)),
              DropdownButton<String>(
                value: selectedRole,
                hint: const Text("Select Role"),
                items: roles.map((role) {
                  return DropdownMenuItem(value: role, child: Text(role));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedRole = value;
                  });
                },
              ),
              const SizedBox(height: 20),
              const Text('Select Your Location', style: TextStyle(fontSize: 20)),
              DropdownButton<String>(
                value: selectedLocation,
                hint: const Text("Select Location"),
                items: locations.map((location) {
                  return DropdownMenuItem(value: location, child: Text(location));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedLocation = value;
                  });
                },
              ),
              TextButton(
                onPressed: addLocation,
                child: const Text("Add New Location"),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: onLogin,
                child: const Text("Continue"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LocationManagementPage extends StatefulWidget {
  final List<String> locations;

  LocationManagementPage({required this.locations});

  @override
  _LocationManagementPageState createState() => _LocationManagementPageState();
}

class _LocationManagementPageState extends State<LocationManagementPage> {
  // Method to delete a location with confirmation dialog
  Future<void> _confirmDelete(BuildContext context, String locationName, int index) async {
    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Delete Location"),
          content: Text("Are you sure you want to delete '$locationName'?"),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      // Delete location from Firestore
      await FirebaseFirestore.instance
          .collection('locations')
          .where('name', isEqualTo: locationName)
          .get()
          .then((querySnapshot) {
        for (var doc in querySnapshot.docs) {
          doc.reference.delete();
        }
      });

      // Update UI by removing the location from the list
      setState(() {
        widget.locations.removeAt(index);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("'$locationName' has been deleted")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Manage Locations")),
      body: ListView.builder(
        itemCount: widget.locations.length,
        itemBuilder: (context, index) {
          String location = widget.locations[index];
          return ListTile(
            title: Text(location),
            trailing: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                _confirmDelete(context, location, index);
              },
            ),
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddProviderPage extends StatefulWidget {
  @override
  _AddProviderPageState createState() => _AddProviderPageState();
}

class _AddProviderPageState extends State<AddProviderPage> {
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController newLocationController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? selectedSpecialty;
  String? selectedTitle;
  List<String> selectedLocations = [];
  String? currentUserRole; // To store the user's role

// List of specialties and titles
  final List<String> specialties = [
    'Spine',
    'Total Joint',
    'Upper Extremity',
    'Shoulder',
    'Knee',
    'Podiatry',
    'Rheumatology',
    'Pain Management',
    'Urgent Care',
    'Sports Medicine',
    'Trauma',
    'Pediatrics',
  ];

  final List<String> titles = [
    'Dr.',
    'PA',
    'PA-C',
    'DPM Fellow',
  ];

// List to hold locations fetched from Firestore
  List<String> locations = [];

  @override
  void initState() {
    super.initState();
    fetchLocations();
    fetchCurrentUserRole();
  }

// Fetch locations from Firestore
  Future<void> fetchLocations() async {
    final snapshot = await _firestore.collection('locations').get();
    setState(() {
      locations = snapshot.docs.map((doc) => doc['name'] as String).toList();
    });
  }

  Future<void> fetchCurrentUserRole() async {
    final user = _auth.currentUser;
    if (user != null) {
      final snapshot = await _firestore.collection('users').doc(user.uid).get();
      setState(() {
        currentUserRole = snapshot['role']; // Assuming role is stored in Firestore
      });
    }
  }

  Future<void> addLocation() async {
    final newLocation = newLocationController.text.trim();
    if (newLocation.isNotEmpty) {
      final existingLocation = locations.contains(newLocation);
      if (existingLocation) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location already exists')),
        );
        return;
      }
      await _firestore.collection('locations').add({'name': newLocation});
      setState(() {
        locations.add(newLocation); // Update the local list
      });
      newLocationController.clear(); // Clear the text field
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Location added successfully')),
      );
    }
  }

// Method to save the provider information to Firebase
  Future<void> saveProvider() async {
    final firstName = firstNameController.text.trim();
    final lastName = lastNameController.text.trim();
    final specialty = selectedSpecialty;
    final title = selectedTitle;

    if (firstName.isNotEmpty && lastName.isNotEmpty && specialty != null && title != null && selectedLocations.isNotEmpty) {
// Query Firestore to check for duplicates
      final querySnapshot = await _firestore.collection('providers')
          .where('firstName', isEqualTo: firstName)
          .where('lastName', isEqualTo: lastName)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Provider already listed')),
        );
      } else {
// Add new provider if no duplicate is found
        await _firestore.collection('providers').add({
          'firstName': firstName,
          'lastName': lastName,
          'specialty': specialty,
          'title': title,
          'locations': selectedLocations,
          'waitTime': null,
        });

// Clear the text fields after saving
        firstNameController.clear();
        lastNameController.clear();
        selectedSpecialty = null;
        selectedTitle = null;
        selectedLocations = [];

// Navigate back after saving
        Navigator.pop(context);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('All fields are required')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Container(
          alignment: Alignment.center,
          child: Text('Add Provider'),
),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: firstNameController,
                decoration: InputDecoration(labelText: 'First Name'),
              ),
              TextField(
                controller: lastNameController,
                decoration: InputDecoration(labelText: 'Last Name'),
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: 'Specialty'),
                value: selectedSpecialty,
                items: specialties.map((specialty) {
                  return DropdownMenuItem<String>(
                    value: specialty,
                    child: Text(specialty),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedSpecialty = value;
                  });
                },
                hint: Text('Select Specialty'),
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: 'Title'),
                value: selectedTitle,
                items: titles.map((title) {
                  return DropdownMenuItem<String>(
                    value: title,
                    child: Text(title),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedTitle = value;
                  });
                },
                hint: Text('Select Title'),
              ),
              SizedBox(height: 16),
              Text('Select Locations'),
              Wrap(
                spacing: 8.0,
                children: locations.map((location) {
                  return FilterChip(
                    label: Text(location),
                    selected: selectedLocations.contains(location),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          selectedLocations.add(location);
                        } else {
                          selectedLocations.remove(location);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              SizedBox(height: 16),
              if (currentUserRole == 'admin')
                ElevatedButton(
                  onPressed: () {
// Open dialog to add a new location
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text('Add New Location'),
                          content: TextField(
                            controller: newLocationController,
                            decoration: InputDecoration(hintText: 'Enter location name'),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: Text('Cancel'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                addLocation();
                                Navigator.of(context).pop();
                              },
                              child: Text('Add'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  child: Text('Add New Location'),
                ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: saveProvider,
                child: Text('Save Provider'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

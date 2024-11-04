import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddProviderPage extends StatefulWidget {
  @override
  _AddProviderPageState createState() => _AddProviderPageState();
}

class _AddProviderPageState extends State<AddProviderPage> {
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? selectedSpecialty;
  String? selectedTitle;
  List<String> selectedLocations = [];

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
  }

  // Fetch locations from Firestore
  Future<void> fetchLocations() async {
    final snapshot = await _firestore.collection('locations').get();
    setState(() {
      locations = snapshot.docs.map((doc) => doc['name'] as String).toList();
    });
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
        // Show a message if a duplicate is found
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
          'locations': selectedLocations,  // Save multiple locations as a list
          'waitTime': null,  // Initialize wait time as null
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
      // Show error if fields are empty
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
            // Multi-select Location List
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
            ElevatedButton(
              onPressed: saveProvider,
              child: Text('Save Provider'),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:waitingboard/services/api_service.dart';

class AddProviderPage extends StatefulWidget {
  @override
  _AddProviderPageState createState() => _AddProviderPageState();
}

class _AddProviderPageState extends State<AddProviderPage> {
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController newLocationController = TextEditingController();
  
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
    'Hip',
    'Knee',
    'Podiatry',
    'Rheumatology',
    'Pain Management',
    'Urgent Care',
    'Sports Medicine',
    'Trauma',
    'Pediatrics',
    'ESP',
  ];

  final List<String> titles = [
    'Dr.',
    'PA',
    'PA-C',
    'DPM',
    'DPM Fellow',
  ];

  // List to hold locations fetched from MySQL
  List<String> locations = [];

  @override
  void initState() {
    super.initState();
    fetchLocations();
  }

  // Fetch locations from Flask Api
Future<void> fetchLocations() async {
  const String apiUrl = '${ApiService.baseUrl}/locations'; // Replace with your Flask server URL

  try {
    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);

      setState(() {
        locations = data.map((location) => location['name'] as String).toList();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch locations: ${response.body}')),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to fetch locations: $e')),
    );
  }
}




  // Add a new location to Flask Api
Future<void> addLocation() async {
  const String apiUrl = '${ApiService.baseUrl}/locations'; // Replace with your Flask server URL

  final newLocation = newLocationController.text.trim();

  if (newLocation.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Location name cannot be empty')),
    );
    return;
  }

  try {
    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'name': newLocation}),
    );

    if (response.statusCode == 201) {
      await fetchLocations(); // Refresh the locations
      newLocationController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Location added successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add location: ${response.body}')),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to add location: $e')),
    );
  }
}


// Save the provider information to Flask API
Future<void> saveProvider() async {
  final firstName = firstNameController.text.trim();
  final lastName = lastNameController.text.trim();
  final specialty = selectedSpecialty;
  final title = selectedTitle;

  // Convert the selectedLocations list to a comma-separated string
  final locationsString = selectedLocations.join(',');

  //Print to debug what is being sent
  // print('First Name: $firstName');
  // print('Last Name: $lastName');
  // print('Specialty: $specialty');
  // print('Title: $title');
  // print('Locations: $locationsString');

  if (firstName.isEmpty || lastName.isEmpty || specialty == null || title == null || locationsString.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('All fields are required')),
    );
    return;
  }

  try {
    // Use the addProvider method from ApiService
    await ApiService.addProvider(
      firstName,
      lastName,
      specialty,
      title,
      locationsString,  // Pass the locations as a comma-separated string
    );

    // Clear fields after successful save
    firstNameController.clear();
    lastNameController.clear();
    selectedSpecialty = null;
    selectedTitle = null;
    selectedLocations = [];

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Provider added successfully')),
    );

    Navigator.pop(context); // Navigate back
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to save provider: $e')),
    );
  }
}



  // Show the Add Location dialog
  void _showAddLocationDialog() {
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
              onPressed: () => Navigator.of(context).pop(),
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
              ElevatedButton(
                onPressed: _showAddLocationDialog,
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

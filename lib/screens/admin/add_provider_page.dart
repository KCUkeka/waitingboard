import 'package:flutter/material.dart';
import 'package:waitingboard/logic/models/mysql.dart';

class AddProviderPage extends StatefulWidget {
  @override
  _AddProviderPageState createState() => _AddProviderPageState();
}

class _AddProviderPageState extends State<AddProviderPage> {
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController newLocationController = TextEditingController();

  final Mysql db = Mysql();

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

  // List to hold locations fetched from MySQL
  List<String> locations = [];

  @override
  void initState() {
    super.initState();
    fetchLocations();
    fetchCurrentUserRole();
  }

  // Fetch locations from MySQL
  Future<void> fetchLocations() async {
    try {
      var conn = await db.getConnection();
      var results = await conn.query('SELECT name FROM locations');
      setState(() {
        locations = results.map((row) => row['name'] as String).toList();
      });
      await conn.close();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch locations: $e')),
      );
    }
  }

  // Fetch the current user's role from MySQL
  Future<void> fetchCurrentUserRole() async {
    try {
      var conn = await db.getConnection();
      // Assume user_id is obtained from shared preferences or a session
      int userId = 1; // Replace with the actual user ID
      var results = await conn.query('SELECT role FROM users WHERE id = ?', [userId]);

      if (results.isNotEmpty) {
        setState(() {
          currentUserRole = results.first['role'];
        });
      }
      await conn.close();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch user role: $e')),
      );
    }
  }

  // Add a new location to MySQL
  Future<void> addLocation() async {
    final newLocation = newLocationController.text.trim();

    if (newLocation.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Location name cannot be empty')),
      );
      return;
    }

    if (locations.contains(newLocation)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Location already exists')),
      );
      return;
    }

    try {
      var conn = await db.getConnection();
      await conn.query('INSERT INTO locations (name) VALUES (?)', [newLocation]);
      await fetchLocations(); // Refresh the list
      newLocationController.clear();
      await conn.close();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Location added successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add location: $e')),
      );
    }
  }

  // Save the provider information to MySQL
  Future<void> saveProvider() async {
    final firstName = firstNameController.text.trim();
    final lastName = lastNameController.text.trim();
    final specialty = selectedSpecialty;
    final title = selectedTitle;

    if (firstName.isEmpty || lastName.isEmpty || specialty == null || title == null || selectedLocations.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('All fields are required')),
      );
      return;
    }

    try {
      var conn = await db.getConnection();
      var duplicateCheck = await conn.query(
        'SELECT id FROM providers WHERE firstName = ? AND lastName = ?',
        [firstName, lastName],
      );

      if (duplicateCheck.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Provider already listed')),
        );
        await conn.close();
        return;
      }

      // Add new provider
      await conn.query(
        'INSERT INTO providers (firstName, lastName, specialty, title, locations) VALUES (?, ?, ?, ?, ?)',
        [
          firstName,
          lastName,
          specialty,
          title,
          selectedLocations.join(','), // Store locations as a comma-separated string
        ],
      );

      await conn.close();

      // Clear the text fields after saving
      firstNameController.clear();
      lastNameController.clear();
      selectedSpecialty = null;
      selectedTitle = null;
      selectedLocations = [];

      // Navigate back after saving
      Navigator.pop(context);
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

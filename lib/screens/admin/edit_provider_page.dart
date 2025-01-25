import 'package:flutter/material.dart';
import 'package:waitingboard/services/api_service.dart'; // Import ApiService

class EditProviderPage extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> providerData;

  const EditProviderPage({Key? key, required this.docId, required this.providerData}) : super(key: key);

  @override
  _EditProviderPageState createState() => _EditProviderPageState();
}

class _EditProviderPageState extends State<EditProviderPage> {
  late TextEditingController firstNameController;
  late TextEditingController lastNameController;
  late String selectedSpecialty;
  late String selectedTitle;
  List<String> selectedLocations = [];
  List<String> locations = [];

  final List<String> specialties = [
    'Spine', 'Total Joint', 'Upper Extremity', 'Shoulder', 'Knee',
    'Podiatry', 'Rheumatology', 'Pain Management', 'Urgent Care', 'Sports Medicine'
  ];

  final List<String> titles = ['Dr.', 'PA', 'PA-C', 'DPM Fellow'];

@override
void initState() {
  super.initState();
  firstNameController = TextEditingController(text: widget.providerData['firstName']?.toString() ?? '');
  lastNameController = TextEditingController(text: widget.providerData['lastName']?.toString() ?? '');

  // Ensure the selected values are valid
  selectedSpecialty = specialties.contains(widget.providerData['specialty'])
      ? widget.providerData['specialty']
      : specialties.first;
  selectedTitle = titles.contains(widget.providerData['title']) ? widget.providerData['title'] : titles.first;

  // Initialize selected locations (convert from string if necessary)
  selectedLocations = List<String>.from(widget.providerData['locations'] ?? []);

  // If locations are received as a comma-separated string, split them into a list
  if (widget.providerData['locations'] is String) {
    selectedLocations = widget.providerData['locations'].split(',');
  }

  _fetchLocations();
}

  Future<void> _fetchLocations() async {
  try {
    // Fetch locations from the API
    final fetchedLocations = await ApiService.fetchLocations();

    // Debug: Check what is being fetched
    print(fetchedLocations);


    setState(() {
      locations = fetchedLocations;

      // Ensure selectedLocations only contains valid locations from the fetched list
      selectedLocations = selectedLocations
          .where((location) => fetchedLocations.contains(location))
          .toList();
    });
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to fetch locations: $e')),
    );
  }
}


  Future<void> _updateProvider() async {
    if (firstNameController.text.isEmpty ||
        lastNameController.text.isEmpty ||
        selectedSpecialty.isEmpty ||
        selectedTitle.isEmpty ||
        selectedLocations.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('All fields are required')),
      );
      return;
    }
  // Debug the data being sent
  print({
    'firstName': firstNameController.text.trim(),
    'lastName': lastNameController.text.trim(),
    'specialty': selectedSpecialty,
    'title': selectedTitle,
    'locations': selectedLocations.join(','), // Send as comma-separated string
  });

    try {
      await ApiService.updateProvider(
        widget.docId,
        {
          'firstName': firstNameController.text.trim(),
          'lastName': lastNameController.text.trim(),
          'specialty': selectedSpecialty,
          'title': selectedTitle,
          'locations': selectedLocations.join(','), // Send as comma-separated string
        },
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Provider updated successfully')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update provider: $e')),
      );
    }
  }

Widget _buildLocationsFilterChips() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Locations', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      Wrap(
        spacing: 8.0,
        children: locations.map((location) {
          return FilterChip(
            label: Text(location),
            selected: selectedLocations.contains(location), // Mark as selected if it's in selectedLocations
            onSelected: (selected) {
              setState(() {
                if (selected) {
                  // Add location to selectedLocations if selected
                  selectedLocations.add(location);
                } else {
                  // Remove location from selectedLocations if unselected
                  selectedLocations.remove(location);
                }
              });
            },
          );
        }).toList(),
      ),
    ],
  );
}



  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Provider'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: firstNameController,
                decoration: InputDecoration(labelText: 'First Name'),
              ),
              TextField(
                controller: lastNameController,
                decoration: InputDecoration(labelText: 'Last Name'),
              ),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: 'Specialty'),
                value: selectedSpecialty,
                items: specialties.map((specialty) {
                  return DropdownMenuItem(
                    value: specialty,
                    child: Text(specialty),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      selectedSpecialty = value;
                    });
                  }
                },
              ),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: 'Title'),
                value: selectedTitle,
                items: titles.map((title) {
                  return DropdownMenuItem(
                    value: title,
                    child: Text(title),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      selectedTitle = value;
                    });
                  }
                },
              ),
              _buildLocationsFilterChips(),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _updateProvider,
                child: Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

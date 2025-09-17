import 'package:flutter/material.dart';
import 'package:waitingboard/services/api_service.dart';

class EditProviderPage extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> providerData;

  const EditProviderPage(
      {Key? key, required this.docId, required this.providerData})
      : super(key: key);

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
    'Spine',
    'Total Joint',
    'Upper Extremity',
    'Shoulder',
    'Hip',
    'Knee',
    'Podiatry',
    'Pain Management',
    'Urgent Care',
    'Sports Medicine',
    'Trauma',
    'Pediatrics',
    'Rheumatology',
    'Infusion',
    'ANC',
    'General',
  ];

  final List<String> titles = ['', 'Dr.', 'PA', 'PA-C', 'DPM Fellow'];

  @override
  void initState() {
    super.initState();
    firstNameController = TextEditingController(
        text: widget.providerData['first_name']?.toString() ?? '');
    lastNameController = TextEditingController(
        text: widget.providerData['last_name']?.toString() ?? '');

    // Ensure the selected values are valid
    selectedSpecialty = specialties.contains(widget.providerData['specialty'])
        ? widget.providerData['specialty']
        : specialties.first;
    selectedTitle = titles.contains(widget.providerData['title'])
        ? widget.providerData['title']
        : titles.first;

    // Initialize selected locations (supports List<String> or comma-separated String)
    if (widget.providerData['provider_locations'] != null) {
  final rawLocations = widget.providerData['provider_locations'];

  if (rawLocations is List) {
    selectedLocations = rawLocations
        .map((loc) => loc.toString().trim())
        .where((loc) => loc.isNotEmpty)
        .toList();
  } else if (rawLocations is String) {
    selectedLocations = rawLocations
        .split(RegExp(r'[,;]')) // split on commas or semicolons
        .map((loc) => loc.trim())
        .where((loc) => loc.isNotEmpty)
        .toList();
  } else {
    selectedLocations = [];
  }
} else {
  selectedLocations = [];
}


  _fetchLocations();
  }

  Future<void> _fetchLocations() async {
  try {
    final fetchedLocations = await ApiService.fetchLocations();


    setState(() {
      locations = fetchedLocations;

      // Normalize both sides
      final normalizedFetched = fetchedLocations
          .map((loc) => loc.trim().toLowerCase())
          .toList();

      selectedLocations = selectedLocations
          .map((loc) => loc.trim())
          .where((loc) => normalizedFetched.contains(loc.toLowerCase()))
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
        selectedLocations.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('All fields are required')),
      );
      return;
    }

    try {
      await ApiService.updateProviderDetails(
        widget.docId,
        {
          'first_name': firstNameController.text.trim(),
          'last_name': lastNameController.text.trim(),
          'specialty': selectedSpecialty,
          'title': selectedTitle,
          'provider_locations': selectedLocations.join(','), // convert List<String> → string
          'last_changed': DateTime.now().toIso8601String(), // track update time
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
        Text('Locations',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Wrap(
          spacing: 8.0,
          children: locations.map((location) {
            return FilterChip(
              label: Text(location),
              selected: selectedLocations.contains(location),
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    if (!selectedLocations.contains(location)) {
                      selectedLocations.add(location);
                    }
                  } else {
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

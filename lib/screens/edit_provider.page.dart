import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditProviderPage extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> providerData;

  const EditProviderPage({Key? key, required this.docId, required this.providerData}) : super(key: key);

  @override
  _EditProviderPageState createState() => _EditProviderPageState();
}

class _EditProviderPageState extends State<EditProviderPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late TextEditingController firstNameController;
  late TextEditingController lastNameController;
  late String selectedSpecialty;
  late String selectedTitle;
  late String selectedLocation;

  final List<String> specialties = [
    'Spine', 'Total Joint', 'Upper Extremity', 'Shoulder', 'Knee',
    'Podiatry', 'Rheumatology', 'Pain Management', 'Urgent Care', 'Sports Medicine'
  ];

  final List<String> titles = ['Dr.', 'PA', 'PA-C', 'DPM Fellow'];
  List<String> locations = [];

  @override
  void initState() {
    super.initState();
    firstNameController = TextEditingController(text: widget.providerData['firstName'] ?? '');
    lastNameController = TextEditingController(text: widget.providerData['lastName'] ?? '');
    
    // Ensure the selected values are valid
    selectedSpecialty = specialties.contains(widget.providerData['specialty']) ? widget.providerData['specialty'] : specialties.first;
    selectedTitle = titles.contains(widget.providerData['title']) ? widget.providerData['title'] : titles.first;
    selectedLocation = widget.providerData['location'] ?? ''; // This will be set later if empty
    _fetchLocations();
  }

  Future<void> _fetchLocations() async {
    final querySnapshot = await _firestore.collection('locations').get();
    setState(() {
      locations = querySnapshot.docs.map((doc) => doc['name'] as String).toList();
      if (selectedLocation.isEmpty && locations.isNotEmpty) {
        selectedLocation = locations.first; // Set default location if not already set
      }
    });
  }

  Future<void> _updateProvider() async {
    if (firstNameController.text.isEmpty || lastNameController.text.isEmpty || 
        selectedSpecialty.isEmpty || selectedTitle.isEmpty || selectedLocation.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('All fields are required')),
      );
      return;
    }

    try {
      await _firestore.collection('providers').doc(widget.docId).update({
        'firstName': firstNameController.text.trim(),
        'lastName': lastNameController.text.trim(),
        'specialty': selectedSpecialty,
        'title': selectedTitle,
        'location': selectedLocation,
      });
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
              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: 'Location'),
                value: selectedLocation.isEmpty ? null : selectedLocation,
                items: locations.map((location) {
                  return DropdownMenuItem(
                    value: location,
                    child: Text(location),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      selectedLocation = value;
                    });
                  }
                },
              ),
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

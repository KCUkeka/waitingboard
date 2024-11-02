import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProviderListPage extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void showEditDialog(BuildContext context, String docId, Map<String, dynamic> providerData) {
    TextEditingController firstNameController = TextEditingController(text: providerData['firstName']);
    TextEditingController lastNameController = TextEditingController(text: providerData['lastName']);
    String selectedSpecialty = providerData['specialty'];
    String selectedTitle = providerData['title'];

    final List<String> specialties = [
      'Spine', 'Total Joint', 'Upper Extremity', 'Shoulder', 'Knee',
      'Podiatry', 'Rheumatology', 'Pain Management', 'Urgent Care', 'Sports Medicine'
    ];

    final List<String> titles = ['Dr.', 'PA', 'PA-C', 'DPM Fellow'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Provider'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
                  selectedSpecialty = value!;
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
                  selectedTitle = value!;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await _firestore.collection('providers').doc(docId).update({
                'firstName': firstNameController.text.trim(),
                'lastName': lastNameController.text.trim(),
                'specialty': selectedSpecialty,
                'title': selectedTitle,
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Provider updated successfully')),
              );
            },
            child: Text('Save', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
  }

  Future<void> deleteProvider(BuildContext context, String docId) async {
    await _firestore.collection('providers').doc(docId).delete();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Provider deleted successfully')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Container(
        alignment: Alignment.center,
        child: const Text('Providers List'))),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('providers').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No providers available'));
          }

          final providerDocs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: providerDocs.length,
            itemBuilder: (context, index) {
              final provider = providerDocs[index];
              final providerData = provider.data() as Map<String, dynamic>;

              return ListTile(
                title: Text('${providerData['firstName']} ${providerData['lastName']}'),
                subtitle: Text('${providerData['specialty']} - ${providerData['title']}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => showEditDialog(context, provider.id, providerData),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () => deleteProvider(context, provider.id),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

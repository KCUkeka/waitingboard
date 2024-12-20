import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FrontdeskprovidersList extends StatefulWidget {
  @override
  _FrontdeskProviderListPageState createState() => _FrontdeskProviderListPageState();
}

class _FrontdeskProviderListPageState extends State<FrontdeskprovidersList> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _selectedLocation;

  @override
  void initState() {
    super.initState();
    _loadSelectedLocation();
  }

  Future<void> _loadSelectedLocation() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedLocation = prefs.getString('selectedLocation');
    });
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Container(
          alignment: Alignment.center,
          child: const Text('Providers List'),
        ),
      ),
      body: _selectedLocation == null
          ? Center(child: CircularProgressIndicator())
          : StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('providers')
                  .where('locations', arrayContains: _selectedLocation)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('No providers available for this location.'));
                }

                final providerDocs = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: providerDocs.length,
                  itemBuilder: (context, index) {
                    final provider = providerDocs[index];
                    final providerData = provider.data() as Map<String, dynamic>;

                    return ListTile(
                      title: Text('${providerData['firstName']} ${providerData['lastName']}'),
                      subtitle: Text(
                        '${providerData['specialty'] ?? "N/A"} - ${providerData['title'] ?? "N/A"}',
                      ),
                      );
                  },
                );
              },
            ),
    );
  }
}

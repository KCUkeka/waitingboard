import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:waitingboard/screens/admin/edit_provider_page.dart';
class EditProvidersList extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<String>> _fetchLocations() async {
    final querySnapshot = await _firestore.collection('locations').get();
    return querySnapshot.docs.map((doc) => doc['name'] as String).toList();
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
      appBar: AppBar(
        title: Container(
          alignment: Alignment.center,
          child: const Text('Providers List'),
        ),
      ),
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
                subtitle: Text(
                  '${providerData['specialty']} - ${providerData['title']}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit, color: Colors.blue),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditProviderPage(
                              docId: provider.id,
                              providerData: providerData,
                            ),
                          ),
                        );
                      },
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

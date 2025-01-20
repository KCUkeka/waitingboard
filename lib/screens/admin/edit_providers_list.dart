import 'package:flutter/material.dart';
import 'package:waitingboard/screens/admin/edit_provider_page.dart';
import 'package:waitingboard/services/api_service.dart'; // Import the API service

class EditProvidersList extends StatelessWidget {

  // Method to fetch the list of providers from the API
  Future<List<Map<String, dynamic>>> _fetchProviders() async {
    try {
      // Fetching provider data from the API
      final providers = await ApiService.fetchProviders();
      return providers.map((provider) => provider as Map<String, dynamic>).toList();
    } catch (e) {
      throw Exception('Error fetching providers: $e');
    }
  }

  // Method to delete a provider from the API
  Future<void> deleteProvider(BuildContext context, String providerId) async {
    // Show a confirmation dialog
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Deletion'),
        content: Text('Are you sure you want to delete this provider?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(false); // User chose "No"
            },
            child: Text('No'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(true); // User chose "Yes"
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey,
            ),
            child: Text('Yes'),
          ),
        ],
      ),
    );

    // If user confirms deletion
    if (shouldDelete == true) {
      try {
        // Call the API to delete the provider
        await ApiService.deleteProvider(providerId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Provider deleted successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting provider: $e')),
        );
      }
    }
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
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchProviders(), // Fetch providers via the API
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No providers available'));
          }

          final providerData = snapshot.data!;

          return ListView.builder(
            itemCount: providerData.length,
            itemBuilder: (context, index) {
              final provider = providerData[index];

              return ListTile(
                title: Text('${provider['firstName']} ${provider['lastName']}'),
                subtitle: Text(
                  '${provider['specialty']} - ${provider['title']}',
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
                              docId: provider['id'], // Assuming the API returns a field 'id'
                              providerData: provider,
                            ),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () => deleteProvider(context, provider['id']),
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

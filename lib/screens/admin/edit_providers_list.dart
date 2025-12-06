import 'package:flutter/material.dart';
import 'package:waitingboard/screens/admin/edit_provider_page.dart';
import 'package:waitingboard/services/api_service.dart';

class EditProvidersList extends StatefulWidget {
  @override
  _EditProvidersListState createState() => _EditProvidersListState();
}

class _EditProvidersListState extends State<EditProvidersList> {
  bool _isDeleting = false;

  // Method to fetch the list of providers from the API
  Future<List<Map<String, dynamic>>> _fetchProviders() async {
    try {
      final providers = await ApiService.fetchProviders();
      return providers
          .map((provider) => provider as Map<String, dynamic>)
          .toList();
    } catch (e) {
      throw Exception('Error fetching providers: $e');
    }
  }

  // Method to delete a provider from the API
  Future<void> deleteProvider(BuildContext context, String providerId) async {
    if (_isDeleting) return;

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: const Text('Are you sure you want to delete this provider?'),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(context).pop(false), // User chose "No"
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.of(context).pop(true), // User chose "Yes"
            style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
            child: const Text('Yes'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      setState(() => _isDeleting = true); // Set deleting state to true
      try {
        // Call the API to delete the provider
        await ApiService.deleteProvider(providerId);

        // Show success snackbar and refresh the list
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Provider deleted successfully')),
        );

        setState(() {}); // Refresh the provider list
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting provider: $e')),
        );
      } finally {
        setState(() => _isDeleting = false); // Reset deleting state
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
        future: _fetchProviders(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No providers available'));
          }

          final providerData = snapshot.data!;
          
          return Padding(
            padding: EdgeInsets.all(16.0),
            child: ListView.builder(
              itemCount: providerData.length,
              itemBuilder: (context, index) {
                final provider = providerData[index];
                final firstName = provider['first_name']?.toString() ?? '';
                final lastName = provider['last_name']?.toString() ?? '';
                final specialty = provider['specialty']?.toString() ?? '';
                final title = provider['title']?.toString() ?? '';
                
                return Column(
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        '$lastName, $firstName',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 4),
                          Text(
                            specialty,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                          if (title.isNotEmpty)
                            Text(
                              title,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () {
                              print(provider);
                              print(provider['id'].runtimeType);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EditProviderPage(
                                    docId: provider['id'].toString(),
                                    providerData: provider,
                                  ),
                                ),
                              );
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              print('Provider ID: ${provider['id']}, Type: ${provider['id'].runtimeType}');
                              deleteProvider(context, provider['id'].toString());
                            },
                          ),
                        ],
                      ),
                    ),
                    Divider(),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }
}
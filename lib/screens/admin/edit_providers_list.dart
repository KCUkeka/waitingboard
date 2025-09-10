import 'package:flutter/material.dart';
import 'package:waitingboard/model/provider_info.dart';
import 'package:waitingboard/screens/admin/edit_provider_page.dart';
import 'package:waitingboard/services/api_service.dart'; // Import the API service

class EditProvidersList extends StatefulWidget {
  @override
  _EditProvidersListState createState() => _EditProvidersListState();
}

class _EditProvidersListState extends State<EditProvidersList> {
  bool _isDeleting = false; // Track deletion state

  // Method to fetch the list of providers from the API
Future<List<ProviderInfo>> _fetchProviders() async {
  try {
    final providers = await ApiService.fetchProviders();
    return providers; // Already a list of ProviderInfo
  } catch (e) {
    throw Exception('Error fetching providers: $e');
  }
}


  // Method to delete a provider from the API
  Future<void> deleteProvider(BuildContext context, String providerId) async {
    if (_isDeleting) return; // Prevent multiple requests

    // Show a confirmation dialog
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
        // Show error snackbar
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
      body: FutureBuilder<List<ProviderInfo>>(
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

    return ListView.builder(
      itemCount: providerData.length,
      itemBuilder: (context, index) {
        final provider = providerData[index];

        return ListTile(
          title: Text('${provider.firstName} ${provider.lastName}'),
          subtitle: Text('${provider.specialty} - ${provider.title}'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditProviderPage(
                        docId: provider.docId,
                        providerData: provider.toApi(), // 👈 add toJson to ProviderInfo
                      ),
                    ),
                  );
                },
              ),
              IconButton(
                icon: Icon(Icons.delete, color: Colors.red),
                onPressed: () {
                  deleteProvider(context, provider.docId);
                },
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

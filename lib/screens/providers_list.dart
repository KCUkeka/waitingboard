import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http; // For HTTP requests
import 'dart:convert'; // For JSON decoding
import '../model/provider_info.dart';
import '../services/api_service.dart';

class ProviderListPage extends StatefulWidget {
  @override
  _ProviderListPageState createState() => _ProviderListPageState();
}

class _ProviderListPageState extends State<ProviderListPage> {
  String? _selectedLocation;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _loadSelectedLocation();
  }

  Future<void> _loadSelectedLocation() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final selectedLocation = prefs.getString('selectedLocation') ?? '';

    if (mounted) {
      setState(() {
        _selectedLocation = selectedLocation;
      });
    }

  }

  // API call to fetch provider data
  Future<List<ProviderInfo>> fetchProviders() async {
    final String baseUrl = 'http://127.0.0.1:5000/providers';
    final String url = '$baseUrl?location_id=$_selectedLocation';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        
        final providers = data.map<ProviderInfo>((provider) {
          List<String> locations = (provider['locationName'] ?? '')
              .toString()
              .split(',')
              .map((e) => e.trim())
              .toList();
          
          return ProviderInfo.fromWaitTimeApi(provider, provider['id']?.toString() ?? '', locations);
        }).toList();

        return providers;
      } else {
        throw Exception('Failed to load providers: ${response.body}');
      }
    } catch (e) {
      print('Error fetching providers: $e');
      throw Exception('Error fetching providers: $e');
    }
  }

  // API call to mark a provider as deleted (sets deleteFlag to 1)
  Future<void> deleteProvider(BuildContext context, String providerId) async {
    if (_isDeleting) return;

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: const Text('Are you sure you want to delete this provider?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
            child: const Text('Yes'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      setState(() => _isDeleting = true);
      try {
        await ApiService.deleteProvider(providerId);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Provider deleted successfully')),
        );

        setState(() {}); // Refresh the list
      } catch (e) {
        print('Error during deletion: $e'); // Debug print
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting provider: $e')),
        );
      } finally {
        setState(() => _isDeleting = false);
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
      body: _selectedLocation == null
          ? Center(child: CircularProgressIndicator())
          : FutureBuilder<List<ProviderInfo>>(
              future: fetchProviders(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('No providers available for this location.'));
                }

                final filteredProviders = snapshot.data!
                    .where((p) => p.locations.contains(_selectedLocation))
                    .toList();

                return ListView.builder(
                  itemCount: filteredProviders.length,
                  itemBuilder: (context, index) {
                    final provider = filteredProviders[index];

        return ListTile(
          title: Text('${provider.firstName} ${provider.lastName}'),
          subtitle: Text('${provider.specialty} - ${provider.title}'),
          trailing: IconButton(
            icon: Icon(Icons.delete),
            onPressed: () => deleteProvider(context, provider.docId),
          ),
        );
      },
    );
  },
),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http; // For HTTP requests
import 'dart:convert'; // For JSON decoding

class ProviderListPage extends StatefulWidget {
  @override
  _ProviderListPageState createState() => _ProviderListPageState();
}

class _ProviderListPageState extends State<ProviderListPage> {
  String? _selectedLocation;

  @override
  void initState() {
    super.initState();
    _loadSelectedLocation();
  }

Future<void> _loadSelectedLocation() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();

  setState(() {
    _selectedLocation = prefs.getString('selectedLocation') ?? ''; // Default to empty string
  });
}


  // API call to fetch provider data
Future<List<Map<String, dynamic>>> fetchProviders() async {
  final String baseUrl = 'http://127.0.0.1:5000/providers'; // Replace with actual API URL

  // Check if _selectedLocation is null or empty
  final String url = (_selectedLocation == null || _selectedLocation!.isEmpty)
      ? baseUrl // No filtering if location is not set
      : '$baseUrl?location_id=$_selectedLocation'; // Add location_id as a query parameter

  try {
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map<Map<String, dynamic>>((provider) => provider as Map<String, dynamic>).toList();
    } else {
      throw Exception('Failed to load providers: ${response.body}');
    }
  } catch (e) {
    throw Exception('Error fetching providers: $e');
  }
}

  // API call to mark a provider as deleted (sets deleteFlag to 1)
  Future<void> deleteProvider(String providerId) async {
    final url = 'http://127.0.0.1:5000/providers/$providerId'; // Your API URL

    try {
      final response = await http.patch(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'deleteFlag': 1}), // Mark as deleted
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Provider marked as deleted successfully')),
        );
      } else {
        throw Exception('Failed to mark provider as deleted');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error marking provider as deleted')),
      );
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
          : FutureBuilder<List<Map<String, dynamic>>>(
              // Fetch the providers
              future: fetchProviders(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                      child: Text('No providers available for this location.'));
                }

                final providerData = snapshot.data!;

                return ListView.builder(
                  itemCount: providerData.length,
                  itemBuilder: (context, index) {
                    final provider = providerData[index];

                    return ListTile(
                      title: Text(
                          '${provider['firstName']} ${provider['lastName']}'),
                      subtitle: Text(
                        '${provider['specialty'] ?? "N/A"} - ${provider['title'] ?? "N/A"}',
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () => deleteProvider(provider['id']),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}

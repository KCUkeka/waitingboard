import 'package:flutter/foundation.dart'; // Import to access kIsWeb
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Import for date formatting
import 'package:http/http.dart' as http; // For HTTP requests
import 'dart:convert'; // For JSON decoding

class ProviderInfo {
  final String firstName;
  final String lastName;
  final String specialty;
  final String title;
  final int? waitTime;
  final DateTime? lastChanged; // New field for last updated timestamp

  ProviderInfo({
    required this.firstName,
    required this.lastName,
    required this.specialty,
    required this.title,
    this.waitTime,
    this.lastChanged,
  });

  factory ProviderInfo.fromApi(Map<String, dynamic> data) {
    return ProviderInfo(
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      specialty: data['specialty'] ?? '',
      title: data['title'] ?? '',
      waitTime: data['waitTime'],
      lastChanged: data['lastChanged'] != null
          ? DateTime.parse(data['lastChanged'])
          : null,
    );
  }

  String get displayName => '$lastName, ${firstName[0]}. | $title';
}

class FullScreenDashboardPage extends StatelessWidget {
  final String selectedLocation; // Add selectedLocation as a parameter

  // Constructor to accept selectedLocation
  FullScreenDashboardPage({required this.selectedLocation});

  // Method to format the lastChanged timestamp
  String formatTimestamp(DateTime? timestamp) {
    if (timestamp == null) return "N/A";

    final formattedDate = DateFormat('hh:mm a, MM/dd').format(timestamp);
    return formattedDate;
  }

  // API call to fetch provider data (replace with your API service call)
  Future<List<ProviderInfo>> fetchProviders() async {
    final url = 'http://127.0.0.1:5000/providers'; // Replace with your API URL

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => ProviderInfo.fromApi(item)).toList();
      } else {
        throw Exception('Failed to load providers');
      }
    } catch (e) {
      throw Exception('Error fetching providers: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Container(
          alignment: Alignment.center,
          child: Text('Wait Times - $selectedLocation'), // Display selectedLocation in AppBar
        ),
        automaticallyImplyLeading: !kIsWeb, // Hide back button on web platform
      ),
      body: FutureBuilder<List<ProviderInfo>>(
        future: fetchProviders(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text('Error loading providers'));
          }

          final providers = snapshot.data ?? [];

          return SingleChildScrollView(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Determine the number of columns based on screen width
                int crossAxisCount = (constraints.maxWidth / 200).floor();
                crossAxisCount = crossAxisCount > 0 ? crossAxisCount : 1; // Ensure at least 1 column

                return GridView.builder(
                  physics: const NeverScrollableScrollPhysics(), // Disable GridView scrolling
                  shrinkWrap: true, // Make GridView take only the necessary space
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    childAspectRatio: 1, // Adjust aspect ratio to fit more content
                    crossAxisSpacing: 16.0, // Space between columns
                    mainAxisSpacing: 16.0, // Space between rows
                  ),
                  padding: const EdgeInsets.all(16.0),
                  itemCount: providers.length,
                  itemBuilder: (context, index) {
                    final provider = providers[index];

                    return Card(
                      elevation: 4.0,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min, // Minimize height of the card
                          children: [
                            Text(
                              provider.displayName,
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center, // Center text
                            ),
                            const SizedBox(height: 8),
                            Text(
                              provider.specialty, // Display specialty on the second line
                              style: const TextStyle(fontSize: 16),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            const Text('Wait Time:', style: TextStyle(fontSize: 16)),
                            Text(
                              '${provider.waitTime} mins',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            const Text('Last Changed:', style: TextStyle(fontSize: 16)),
                            Text(
                              formatTimestamp(provider.lastChanged),
                              style: const TextStyle(fontSize: 14),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}

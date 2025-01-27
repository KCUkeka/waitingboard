import 'package:flutter/material.dart';
import 'package:waitingboard/services/api_service.dart'; // Flask API service
import 'package:intl/intl.dart'; // Import for date formatting

class AdminDashboardPage extends StatefulWidget {
  final String selectedLocation;

  AdminDashboardPage({required this.selectedLocation});

  @override
  _AdminDashboardPageState createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  // Format the lastChanged timestamp
  String formatTimestamp(String? timestamp) {
    if (timestamp == null) return "N/A";

    final dateTime = DateTime.parse(timestamp);
    final formattedDate = DateFormat('hh:mm a').format(dateTime);
    return formattedDate;
  }

  // Fetch and group providers by location
  Future<Map<String, List<ProviderInfo>>> fetchProvidersGroupedByLocation() async {
    try {
      final response = await ApiService.fetchProviders(); // Replace with your actual API call
      Map<String, List<ProviderInfo>> groupedProviders = {};

      for (var providerData in response) {
        final provider = ProviderInfo.fromJson(providerData);

        if (provider.waitTime != null) {
          for (var location in provider.locations) {
            if (!groupedProviders.containsKey(location)) {
              groupedProviders[location] = [];
            }
            groupedProviders[location]!.add(provider);
          }
        }
      }

      return groupedProviders;
    } catch (e) {
      print('Error fetching providers: $e');
      return {};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Stack(
          children: [
            Align(
              alignment: Alignment.center,
              child: Text(
                'Dashboard',
                style: const TextStyle(fontSize: 20,),
              ),
            ),
          ],
        ),
      ),
      body: FutureBuilder<Map<String, List<ProviderInfo>>>(
        future: fetchProvidersGroupedByLocation(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text('Error loading providers'));
          }

          final groupedProviders = snapshot.data ?? {};

          return SingleChildScrollView(
            child: Column(
              children: groupedProviders.entries.map((entry) {
                final location = entry.key;
                final providers = entry.value;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
                      child: Text(
                        location,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        int crossAxisCount = (constraints.maxWidth / 200).floor();
                        crossAxisCount = crossAxisCount > 0 ? crossAxisCount : 1;

                        return GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            childAspectRatio: 1,
                            crossAxisSpacing: 16.0,
                            mainAxisSpacing: 16.0,
                          ),
                          padding: const EdgeInsets.all(8.0),
                          itemCount: providers.length,
                          itemBuilder: (context, index) {
                            final provider = providers[index];

                            return Card(
                              elevation: 4.0,
                              child: Padding(
                                padding: const EdgeInsets.all(6.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      provider.displayName,
                                      style: const TextStyle(
                                          fontSize: 20, fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      provider.specialty,
                                      style: const TextStyle(fontSize: 16),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 8),
                                    const Text('Wait Time:', style: TextStyle(fontSize: 16)),
                                    Text(
                                      '${provider.waitTime} mins',
                                      style: const TextStyle(
                                          fontSize: 18, fontWeight: FontWeight.bold),
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
                  ],
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }
}

// Updated ProviderInfo model
class ProviderInfo {
  final String firstName;
  final String lastName;
  final String specialty;
  final String title;
  final int? waitTime;
  final String? lastChanged; // Changed to String to match API format
  final List<String> locations;

  ProviderInfo({
    required this.firstName,
    required this.lastName,
    required this.specialty,
    required this.title,
    this.waitTime,
    this.lastChanged,
    required this.locations,
  });

  factory ProviderInfo.fromJson(Map<String, dynamic> json) {
    return ProviderInfo(
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      specialty: json['specialty'] ?? '',
      title: json['title'] ?? '',
      waitTime: json['waitTime'],
      lastChanged: json['lastChanged'],
      locations: List<String>.from(json['locations'] ?? []),
    );
  }

  String get displayName => '$lastName, ${firstName[0]}. | $title';
}

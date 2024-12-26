import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart'; // Import for date formatting

class AdminDashboardPage extends StatefulWidget {
  final String selectedLocation;

  AdminDashboardPage({required this.selectedLocation});

  @override
  _AdminDashboardPageState createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Format the lastChanged timestamp
  String formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return "N/A";

    final dateTime = timestamp.toDate();
    final formattedDate = DateFormat('hh:mm a').format(dateTime);
    return formattedDate;
  }

  // Stream to fetch and group providers by location, filtering for non-null wait times
  Stream<Map<String, List<ProviderInfo>>> getProvidersGroupedByLocation() {
    return _firestore.collection('providers').snapshots().map((snapshot) {
      Map<String, List<ProviderInfo>> groupedProviders = {};

      for (var doc in snapshot.docs) {
        final provider = ProviderInfo.fromFirestore(doc);

        // Only include providers with non-null wait times
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
    });
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
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () async {
                  if (kIsWeb) {
                    final url = Uri.base.origin + '/#/fullscreendashboard';
                    await launchUrl(Uri.parse(url),
                        webOnlyWindowName: '_blank');
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AdminDashboardPage(
                          selectedLocation: widget.selectedLocation,
                        ),
                      ),
                    );
                  }
                },
                child: const Text('Full Screen'),
              ),
            ),
          ],
        ),
      ),
      body: StreamBuilder<Map<String, List<ProviderInfo>>>(
        stream: getProvidersGroupedByLocation(),
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
                      padding:
                          const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
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
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      provider.specialty,
                                      style: const TextStyle(fontSize: 16),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 8),
                                    const Text('Wait Time:',
                                        style: TextStyle(fontSize: 16)),
                                    Text(
                                      '${provider.waitTime} mins',
                                      style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text('Last Changed:',
                                        style: TextStyle(fontSize: 16)),
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

// Updated ProviderInfo model to include locations
class ProviderInfo {
  final String firstName;
  final String lastName;
  final String specialty;
  final String title;
  final int? waitTime;
  final Timestamp? lastChanged;
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

  factory ProviderInfo.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProviderInfo(
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      specialty: data['specialty'] ?? '',
      title: data['title'] ?? '',
      waitTime: data['waitTime'],
      lastChanged:
          data['lastChanged'] as Timestamp?, // Convert from Firestore Timestamp
      locations: List<String>.from(data['locations'] ?? []),
    );
  }

  String get displayName => '$lastName, ${firstName[0]}. | $title';
}

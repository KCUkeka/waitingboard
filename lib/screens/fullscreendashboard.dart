import 'package:flutter/foundation.dart'; // Import to access kIsWeb
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // Import for date formatting

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

  factory ProviderInfo.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProviderInfo(
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      specialty: data['specialty'] ?? '',
      title: data['title'] ?? '',
      waitTime: data['waitTime'],
      lastChanged: data['lastChanged'] != null
          ? (data['lastChanged'] as Timestamp).toDate()
          : null,
    );
  }

  String get displayName => '$lastName, ${firstName[0]}. | $title';
}

class FullScreenDashboardPage extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Method to format the lastChanged timestamp
  String formatTimestamp(DateTime? timestamp) {
    if (timestamp == null) return "N/A";

    final formattedDate = DateFormat('hh:mm a').format(timestamp);
    return formattedDate;
  }

  Stream<List<ProviderInfo>> getProvidersStream() {
    return _firestore.collection('providers').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => ProviderInfo.fromFirestore(doc))
          .where((provider) => provider.waitTime != null)
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Container(
          alignment: Alignment.center,
          child: const Text('Wait times'),
        ),
        automaticallyImplyLeading: !kIsWeb, // Hide back button on web platform
      ),
      body: StreamBuilder<List<ProviderInfo>>(
        stream: getProvidersStream(),
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

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:waitingboard/screens/fullscreendashboard.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart'; // Import for date formatting

class DashboardPage extends StatefulWidget {
  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Method to format the lastChanged timestamp
  String formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return "N/A";

    final dateTime = timestamp.toDate();
    final formattedDate = DateFormat('hh:mm a').format(dateTime);
    return formattedDate;
  }

  // Stream to fetch providers with a non-null wait time
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
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Dashboard'),
            ElevatedButton(
              onPressed: () async {
                if (kIsWeb) {
                  // Open the fullscreen dashboard in a new browser tab for web
                  final url = Uri.base.origin + '/#/fullscreendashboard';
                  await launchUrl(Uri.parse(url), webOnlyWindowName: '_blank');
                } else {
                  // Navigate within the app for non-web platforms
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => FullScreenDashboardPage()),
                  );
                }
              },
              child: const Text('Full Screen'),
            ),
          ],
        ),
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
                  padding: const EdgeInsets.all(16.0),
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
                            const Text('Wait Time:',
                                style: TextStyle(fontSize: 16)),
                            Text(
                              '${provider.waitTime} mins',
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
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
          );
        },
      ),
    );
  }
}

// ProviderInfo model
class ProviderInfo {
  final String firstName;
  final String lastName;
  final String specialty;
  final String title;
  final int? waitTime;
  final Timestamp? lastChanged;

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
      lastChanged: data['lastChanged'] as Timestamp?, // Convert from Firestore Timestamp
    );
  }

  String get displayName => '$lastName, ${firstName[0]}. | $title';
}

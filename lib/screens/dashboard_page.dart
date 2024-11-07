import 'dart:html' as html; // For web-specific functionality
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:waitingboard/screens/fullscreendashboard.dart';
import 'package:url_launcher/url_launcher.dart';

class DashboardPage extends StatefulWidget {
  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

              // This was to just open up a fullscreen page
              // onPressed: () {
              //   Navigator.push(
              //     context,
              //     MaterialPageRoute(builder: (context) => FullScreenDashboardPage()),
              //   );
              // },

              onPressed: () async {
                if (kIsWeb) {
                  // Construct the full URL with route for web-based navigation
                  final url = Uri.base.origin + '/#/fullscreendashboard';

                  // Open the full screen dashboard in a new browser tab
                  await launchUrl(Uri.parse(url), webOnlyWindowName: '_blank');
                } else {
                  // For non-web, navigate within the app
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
                        padding: const EdgeInsets.all(16.0),
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

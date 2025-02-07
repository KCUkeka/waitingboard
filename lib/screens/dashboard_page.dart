import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:waitingboard/screens/fullscreendashboard.dart';
import 'package:waitingboard/model/provider_info.dart' as model;
import 'package:waitingboard/services/api_service.dart'; // Import the API service

//------------------------------------------------------- Dashboard Page ---------------------------------------------- 
class DashboardPage extends StatefulWidget {
  final String selectedLocation; // Accept location as a parameter

  DashboardPage({required this.selectedLocation}); // Require the location

  @override
  _DashboardPageState createState() => _DashboardPageState();
}

//------------------------------------------------------- timestamp farmat ----------------------------------------------

class _DashboardPageState extends State<DashboardPage> {
  // Method to format the lastChanged timestamp
  String formatTimestamp(DateTime? dateTime) {
    if (dateTime == null) return "N/A";

    final formattedDate = DateFormat('hh:mm a, MM/dd').format(dateTime);
    return formattedDate;
  }

  // Method to fetch providers data from the API
Future<List<model.ProviderInfo>> _fetchProviders() {
  try {
    return ApiService.fetchActiveProviders();
  } catch (e) {
    print('Error fetching active providers: $e');
    throw Exception('Error fetching active providers: $e');
  }
}

//------------------------------------------------------- Dashboard build ----------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Stack(
          children: [
            Align(
              alignment: Alignment.center,
              child: Text(
                '${widget.selectedLocation} Dashboard', // Include the location
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
                        builder: (context) => FullScreenDashboardPage(
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
      body: FutureBuilder<List<model.ProviderInfo>>(
        future: _fetchProviders(), // Fetch providers from the API
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
             print('Error in FutureBuilder: ${snapshot.error}'); // Debug print
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
                              (() {
                                return provider.dashboardName;
                              })(),
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
                              '${provider.formattedWaitTime} mins',
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            const Text('Last Changed:',
                                style: TextStyle(fontSize: 16)),
                            Text(
                              formatTimestamp(provider.last_changed),
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

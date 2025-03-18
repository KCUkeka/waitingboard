import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:waitingboard/screens/fullscreendashboard.dart';
import 'package:waitingboard/model/provider_info.dart' as model;
import 'package:waitingboard/services/api_service.dart'; // Import the API service
import 'dart:async'; // Import dart:async for Timer

//------------------------------------------------------- Dashboard Page ----------------------------------------------
class DashboardPage extends StatefulWidget {
  final String selectedLocation; // Accept location as a parameter

  DashboardPage({required this.selectedLocation}); // Require the location

  @override
  _DashboardPageState createState() => _DashboardPageState();
}

//------------------------------------------------------- timestamp farmat ----------------------------------------------

class _DashboardPageState extends State<DashboardPage> {
  Timer? _timer; // Declare the timer variable
  late Future<List<model.ProviderInfo>>
      _providersFuture; // Declare the future variable

  @override
  void initState() {
    super.initState();
    _providersFuture = _fetchProviders(); // Initialize the future
    _startTimer(); // Start the timer
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      setState(() {
        _providersFuture =
            _fetchProviders(); // Fetch providers every 10 seconds
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancel the timer when the widget is disposed
    super.dispose();
  }

  // Method to format the lastChanged timestamp
  String formatTimestamp(DateTime? dateTime) {
    if (dateTime == null) return "N/A";

    // Logic to show time change
    final now = DateTime.now();

    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  // Method to fetch providers data from the API
  Future<List<model.ProviderInfo>> _fetchProviders() async {
    try {
      final List<model.ProviderInfo> providers =
          await ApiService.fetchProvidersByLocation(widget.selectedLocation);

      // Filter providers by current_location
      final filteredProviders = providers.where((provider) {
        return provider.current_location == widget.selectedLocation;
      }).toList();
      ;

      return filteredProviders;
    } catch (e) {
      print('Error fetching providers: $e');
      throw Exception('Error fetching providers: $e');
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
        future: _providersFuture, // Use the future variable
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            print('Error in FutureBuilder: ${snapshot.error}'); // Debug print
            return const Center(child: Text('Error loading providers'));
          }

          // Should show Filtered providers based on selectedLocation
          final providers = snapshot.data ?? [];

          if (providers.isEmpty) {
            return Container(
              alignment: Alignment.center,
              child: Text(
                'No active times in ${widget.selectedLocation}',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            );
          }

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
                              provider.dashboardName,
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

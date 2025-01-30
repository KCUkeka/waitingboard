import 'dart:async'; // Import for Timer
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:waitingboard/model/provider_info.dart' as model;
import 'package:waitingboard/services/api_service.dart'; // For API calls

class FullScreenDashboardPage extends StatefulWidget {
  final String selectedLocation;

  const FullScreenDashboardPage({Key? key, required this.selectedLocation}) : super(key: key);

  @override
  _FullScreenDashboardPageState createState() => _FullScreenDashboardPageState();
}

class _FullScreenDashboardPageState extends State<FullScreenDashboardPage> {
  late Future<List<model.ProviderInfo>> _providersFuture;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _providersFuture = _fetchProviders();
    _startTimer(); // Start the timer to refresh data
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancel the timer when the widget is disposed
    super.dispose();
  }

  // Fetch providers data from API
  Future<List<model.ProviderInfo>> _fetchProviders() async {
    try {
      return ApiService.fetchActiveProviders();
    } catch (e) {
      print('Error fetching active providers: $e');
      throw Exception('Error fetching active providers: $e');
    }
  }

  // Refresh data every 10 seconds
  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      setState(() {
        _providersFuture = _fetchProviders();
      });
    });
  }

  // Format timestamp
  String formatTimestamp(DateTime? timestamp) {
    if (timestamp == null) return "N/A";
    return DateFormat('hh:mm a, MM/dd').format(timestamp);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text('Wait Times - ${widget.selectedLocation}'),
        ),
        automaticallyImplyLeading: !kIsWeb, // Hide back button on web
      ),
      body: FutureBuilder<List<model.ProviderInfo>>(
        future: _providersFuture, // Use stored future
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
                              provider.displayName,
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                              '${provider.waitTime ?? 0} mins',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            const Text('Last Changed:', style: TextStyle(fontSize: 16)),
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

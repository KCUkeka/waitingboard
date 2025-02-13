import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:waitingboard/model/provider_info.dart' as model;
import 'package:waitingboard/services/api_service.dart';

class FullScreenDashboardPage extends StatefulWidget {
  final String selectedLocation;

  const FullScreenDashboardPage({Key? key, required this.selectedLocation})
      : super(key: key);

  @override
  _FullScreenDashboardPageState createState() =>
      _FullScreenDashboardPageState();
}

class _FullScreenDashboardPageState extends State<FullScreenDashboardPage> {
  late Future<List<model.ProviderInfo>> _providersFuture;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _providersFuture = _fetchProviders();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<List<model.ProviderInfo>> _fetchProviders() async {
    try {
      final providers =
          await ApiService.fetchProvidersByLocation(widget.selectedLocation);
      return providers
          .where((provider) =>
              provider.current_location == widget.selectedLocation)
          .toList();
    } catch (e) {
      print('Error fetching providers: $e');
      throw Exception('Error fetching providers: $e');
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      setState(() {
        _providersFuture = _fetchProviders();
      });
    });
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text('${widget.selectedLocation} Wait Times'),
        ),
        automaticallyImplyLeading: !kIsWeb,
      ),
      body: FutureBuilder<List<model.ProviderInfo>>(
        future: _providersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            print('Error in FutureBuilder: ${snapshot.error}');
            return const Center(child: Text('Error loading providers'));
          }

          final providers = snapshot.data ?? [];

          if (providers.isEmpty) {
            return const Center(
                child: Text('No providers available for this location'));
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

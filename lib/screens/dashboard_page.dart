import 'package:flutter/material.dart';
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

  // Method to format wait time inputted
  String _formatWaitTime(String waitTimeStr) {
    final int? mins = int.tryParse(waitTimeStr);
    if (mins == null) return 'N/A';

    if (mins >= 60) {
      final hours = mins ~/ 60;
      final remainingMins = mins % 60;
      if (remainingMins == 0) {
        return '$hours hour${hours > 1 ? 's' : ''}';
      } else {
        return '$hours hour${hours > 1 ? 's' : ''} $remainingMins min${remainingMins > 1 ? 's' : ''}';
      }
    } else {
      return '$mins min${mins != 1 ? 's' : ''}';
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
          ],
        ),
      ),
      body: FutureBuilder<List<model.ProviderInfo>>(
        future: _fetchProviders(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            print('Error in FutureBuilder: ${snapshot.error}');
            return const Center(child: Text('Error loading providers'));
          }

          final providers = snapshot.data ?? [];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start, 
              children: [
                // Main Dashboard Grid - Left Panel
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (providers.isEmpty)
                        Center(
                          child: Text(
                            'No active times in ${widget.selectedLocation}',
                            style: TextStyle(fontStyle: FontStyle.italic),
                          ),
                        )
                      else
                        LayoutBuilder(
                          builder: (context, constraints) {
                            int crossAxisCount =
                                (constraints.maxWidth / 200).floor();
                            crossAxisCount =
                                crossAxisCount > 0 ? crossAxisCount : 1;

                            final nonAncProviders = providers
                                .where(
                                    (p) => p.specialty.toUpperCase() != 'ANC')
                                .toList();

                            return GridView.builder(
                              physics: NeverScrollableScrollPhysics(),
                              shrinkWrap: true,
                              padding: EdgeInsets.only(right: 16),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                childAspectRatio: 1,
                                crossAxisSpacing: 16.0,
                                mainAxisSpacing: 16.0,
                              ),
                              itemCount: nonAncProviders.length,
                              itemBuilder: (context, index) {
                                final provider = nonAncProviders[index];
                                return Card(
                                  elevation: 4.0,
                                  child: Padding(
                                    padding: const EdgeInsets.all(6.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          provider.dashboardName,
                                          style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold),
                                          textAlign: TextAlign.center,
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          provider.specialty,
                                          style: TextStyle(fontSize: 16),
                                          textAlign: TextAlign.center,
                                        ),
                                        SizedBox(height: 8),
                                        Text('Wait Time:',
                                            style: TextStyle(fontSize: 16)),
                                        Text(
                                          _formatWaitTime(
                                              provider.formattedWaitTime),
                                          style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold),
                                        ),
                                        SizedBox(height: 8),
                                        Text('Last Changed:',
                                            style: TextStyle(fontSize: 16)),
                                        Text(
                                          formatTimestamp(
                                              provider.last_changed),
                                          style: TextStyle(fontSize: 14),
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
                  ),
                ),

                // Slim Right Panel - Ancillary Services
                Container(
                  margin: EdgeInsets.only(left: 16),
                  width: 300,
                  color: Colors.grey.shade200,
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ancillary Services',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 16),

                      // ANC Specialty Cards
                      ...providers
                          .where((p) => p.specialty.toUpperCase() == 'ANC')
                          .map((p) => Card(
                                margin: EdgeInsets.only(bottom: 12),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        p.dashboardName,
                                        style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                          'Wait Time: ${_formatWaitTime(p.formattedWaitTime)}'),
                                      SizedBox(height: 4),
                                      Text(
                                          'Updated: ${formatTimestamp(p.last_changed)}'),
                                    ],
                                  ),
                                ),
                              ))
                          .toList(),

                      // Show message if no ANC providers found
                      if (providers
                          .where((p) => p.specialty.toUpperCase() == 'ANC')
                          .isEmpty)
                        Text(
                          'No ANC wait times available.',
                          style: TextStyle(fontStyle: FontStyle.italic),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

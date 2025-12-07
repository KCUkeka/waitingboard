import 'package:flutter/material.dart';
import 'package:waitingboard/model/provider_info.dart' as model;
import 'package:waitingboard/services/api_service.dart';
import 'dart:async';

//------------------------------------------------------- Dashboard Page ----------------------------------------------
class DashboardPage extends StatefulWidget {
  final String selectedLocation;
  DashboardPage({required this.selectedLocation});

  @override
  _DashboardPageState createState() => _DashboardPageState();
}

//------------------------------------------------------- timestamp format ----------------------------------------------
class _DashboardPageState extends State<DashboardPage> {
  Timer? _refreshTimer;
  List<model.ProviderInfo> _providers = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProviders();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _stopAutoRefresh();
    super.dispose();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      _loadProviders();
    });
  }

  void _stopAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  Future<void> _manualRefresh() async {
    await _loadProviders();
  }

  Future<void> _loadProviders() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }
    try {
      final List<model.ProviderInfo> providers =
          await ApiService.fetchProvidersByLocation(widget.selectedLocation);

      final filteredProviders = providers.where((provider) {
        return provider.current_location == widget.selectedLocation;
      }).toList();

      if (mounted) {
        setState(() {
          _providers = filteredProviders;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching providers: $e');
      if (mounted) {
        setState(() {
          _error = 'Error loading providers: $e';
          _isLoading = false;
        });
      }
    }
  }

  String formatTimestamp(DateTime? dateTime) {
    if (dateTime == null) return "N/A";

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

  String _formatWaitTime(String waitTimeStr) {
    if (waitTimeStr == 'On Time' || waitTimeStr == 'Delayed') {
      return waitTimeStr;
    }
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

// General specialty or missing first name
  String _formatProviderName(
      String lastName, String firstName, String specialty) {
    if (firstName.isEmpty || firstName.trim().isEmpty) {
      return lastName;
    } else {
      if (specialty.toUpperCase() == 'GENERAL') {
        return lastName;
      }
      return '$lastName, $firstName';
    }
  }

// Formatting for card with title consideration
  String _formatProviderNameWithTitle(
      String lastName, String firstName, String title, String specialty) {
    final normalizedTitle = title.toUpperCase().trim();
    final normalizedSpecialty = specialty.toUpperCase().trim();

    final hasFirstName = firstName.trim().isNotEmpty;
    final hasTitle = title.trim().isNotEmpty;

    // Titles that should show "Last, First"
    final isPhysicianAssistant = normalizedTitle == 'PA' ||
        normalizedTitle == 'PA-C' ||
        normalizedTitle == 'NP';

    // --- RULE 1: If BOTH title and first name are missing → only last name ---
    if (!hasFirstName && !hasTitle) {
      return lastName;
    }

    // --- RULE 2: ANC, GENERAL, INFUSION always show last name ---
    if (normalizedSpecialty == 'ANC' ||
        normalizedSpecialty == 'GENERAL' ||
        normalizedSpecialty == 'INFUSION') {
      return lastName;
    }

    // --- RULE 3: If first name missing but title exists ---
    if (!hasFirstName) {
      if (isPhysicianAssistant) {
        return lastName;
      }
      return '$title $lastName';
    }

    // --- RULE 4: First name exists ---
    if (isPhysicianAssistant) {
      return '$lastName, $firstName';
    }

    // --- RULE 5: Default Dr. format ---
    final firstInitial = firstName[0].toUpperCase();
    return 'Dr. $lastName, $firstInitial';
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
                '${widget.selectedLocation} Dashboard',
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _isLoading ? null : _manualRefresh,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Error loading providers',
                        style: TextStyle(fontSize: 16, color: Colors.red),
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _manualRefresh,
                        child: Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _manualRefresh,
                  child: _buildDashboardContent(),
                ),
    );
  }

  Widget _buildDashboardContent() {
    final providers = _providers;
    const rightPanelSpecialties = {'ANC', 'INFUSION'};
    final rightPanelProviders = providers
        .where((p) => rightPanelSpecialties.contains(p.specialty.toUpperCase()))
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      physics: AlwaysScrollableScrollPhysics(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ---------------Main Dashboard Grid - Left Panel-------------------------
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
                      int crossAxisCount = (constraints.maxWidth / 200).floor();
                      crossAxisCount = crossAxisCount > 0 ? crossAxisCount : 1;
                      final nonRightPanelProviders = providers
                          .where((p) => !rightPanelSpecialties
                              .contains(p.specialty.toUpperCase()))
                          .toList();
                      return GridView.builder(
                        physics: NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        padding: EdgeInsets.only(right: 16),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          childAspectRatio: 1,
                          crossAxisSpacing: 16.0,
                          mainAxisSpacing: 16.0,
                        ),
                        itemCount: nonRightPanelProviders.length,
                        itemBuilder: (context, index) {
                          final provider = nonRightPanelProviders[index];
                          final normalizedTitle =
                              provider.title.toUpperCase().trim();
                          final isPhysicianAssistant =
                              normalizedTitle == 'PA' ||
                                  normalizedTitle == 'PA-C' ||
                                  normalizedTitle == 'NP';

                          return Card(
                            elevation: 4.0,
                            child: Padding(
                              padding: const EdgeInsets.all(6.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Display the formatted name
                                  Text(
                                    _formatProviderNameWithTitle(
                                        provider.lastName,
                                        provider.firstName,
                                        provider.title,
                                        provider.specialty),
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),

                                  // Display Full name and gray text for PA/PA-C
                                  if (isPhysicianAssistant &&
                                      provider.title.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4.0),
                                      child: RichText(
                                        textAlign: TextAlign.center,
                                        text: TextSpan(
                                          children: [
                                            TextSpan(
                                              text: provider.title,
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey[600],
                                                fontStyle: FontStyle.italic,
                                              ),
                                            ),
                                            TextSpan(
                                              text: ' | ',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                            TextSpan(
                                              text: provider.specialty,
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),

                                  SizedBox(
                                      height: isPhysicianAssistant ? 4 : 8),

                                  // Display specialty for non-PA providers
                                  if (!isPhysicianAssistant)
                                    Text(
                                      provider.specialty,
                                      style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey[600]),
                                      textAlign: TextAlign.center,
                                    ),

                                  if (!isPhysicianAssistant)
                                    SizedBox(height: 8),

                                  if (_formatWaitTime(
                                              provider.formattedWaitTime) !=
                                          'On Time' &&
                                      _formatWaitTime(
                                              provider.formattedWaitTime) !=
                                          'Delayed')
                                    Text('Wait time:',
                                        style: TextStyle(fontSize: 16)),

                                  Text(
                                    _formatWaitTime(provider.formattedWaitTime),
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold),
                                  ),

                                  SizedBox(height: 8),

                                  Text('Updated:',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey[600],
                                      )),

                                  Text(
                                    formatTimestamp(provider.last_changed),
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
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
          // -----------------Right Panel ---------------------
          if (rightPanelProviders.isNotEmpty)
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
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),
                  // Simplified Cards - Only Last Name, Wait Time, Last Updated
                  ...rightPanelProviders.map((p) => Card(
                        margin: EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Last Name Only
                              Text(
                                p.lastName,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              // Wait Time
                              Text(
                                _formatWaitTime(p.formattedWaitTime),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              // Last Updated
                              Text(
                                'Updated: ${formatTimestamp(p.last_changed)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      )),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

import 'dart:async'; // Import for Timer
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:waitingboard/model/provider_info.dart';
import 'package:waitingboard/screens/providerselection.dart';
import 'package:waitingboard/services/api_service.dart';

class WaitTimesPage extends StatefulWidget {
  final TabController tabController;
  final String selectedLocation;

  WaitTimesPage({required this.tabController, required this.selectedLocation});

  @override
  _WaitTimesPageState createState() => _WaitTimesPageState();
}

class _WaitTimesPageState extends State<WaitTimesPage> {
  List<ProviderInfo> providerList = [];
  List<ProviderInfo> selectedProviders = [];
  List<ProviderInfo> currentlocationProviders = [];
  final Map<String, TextEditingController> _waitTimeControllers = {};
  Timer? _tabRefreshTimer; // Timer for refreshing the TabController

  @override
  void initState() {
    super.initState();
    loadProvidersFromApi();

    // Start a timer to refresh the TabController every 10 second
    _tabRefreshTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted && widget.tabController.index == 0) {
        loadProvidersFromApi(); // Refresh data if on the first tab
      }
    });

    // Add listener to refresh data when switching back to WaitTimesPage
    widget.tabController.addListener(() {
      if (widget.tabController.index == 0 && mounted) {
        loadProvidersFromApi();
      }
    });
  }

  @override
  void dispose() {
    _tabRefreshTimer?.cancel(); // Cancel the timer when the widget is disposed
    // Dispose all TextEditingControllers
    for (var controller in _waitTimeControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  // ------------------------------------------ Define functions  ------------------------------------------------------

  void _initializeControllers() {
    for (var provider in selectedProviders) {
      _waitTimeControllers[provider.docId] = TextEditingController(
        text: provider.waitTime?.toString() ?? '',
      );
    }
  }

  Future<bool?> _showConfirmationDialog(
      BuildContext context, String title, String content) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('No')),
            TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text('Yes')),
          ],
        );
      },
    );
  }

  Future<void> loadProvidersFromApi() async {
    try {
      final List<dynamic> fetchedProviders =
          await ApiService.fetchProvidersByLocation(widget.selectedLocation);

      if (!mounted) return;

      setState(() {
        // providers that have null wait time and are same location as selected location
        providerList = fetchedProviders
            .map((providerData) {
              if (providerData is Map<String, dynamic>) {
                List<String> locations = [
                  (providerData['provider_locations'] ?? '').toString()
                ];
                return ProviderInfo.fromWaitTimeApi(providerData,
                    providerData['id']?.toString() ?? '', locations);
              } else if (providerData is ProviderInfo) {
                return providerData; // If it's already a ProviderInfo object, just return it
              } else {
                throw Exception(
                    'Unexpected data type: ${providerData.runtimeType}');
              }
            })
            .where((provider) => provider.locations
                .contains(widget.selectedLocation)) // Filter providers
            .toList();
        selectedProviders = providerList
            .where((provider) =>
                provider.waitTime != null &&
                provider.current_location == widget.selectedLocation)
            .toList();
        _initializeControllers();

        // Update currentlocationProviders within setState
        currentlocationProviders = selectedProviders
            .where((provider) =>
                provider.current_location == widget.selectedLocation)
            .toList();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load providers: ${e.toString()}')),
      );
    }
  }

  Future<void> saveAllWaitTimes() async {
    // Show confirmation dialog
    bool? shouldSave = await _showConfirmationDialog(
      context,
      'Confirm Update',
      'Are you sure you want to update all wait times?',
    );

    // If the user confirmed, proceed with saving
    if (shouldSave == true) {
      try {
        for (var provider in selectedProviders) {
          final controller = _waitTimeControllers[provider.docId];
          if (controller != null && controller.text.isNotEmpty) {
            final waitTime = int.tryParse(controller.text);
            if (waitTime != null) {
              await ApiService.updateProvider(provider.docId, {
                'waitTime': waitTime,
                'currentLocation': widget.selectedLocation,
              });
            }
          }
        }

        await loadProvidersFromApi(); // Refresh the list after saving

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Wait times saved successfully')),
        );
      } catch (e) {
        print('Error saving wait times: $e'); // Debug print
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save wait times: $e')),
        );
      }
    }
  }

  Future<void> _updateWaitTime(
      ProviderInfo provider, String newWaitTime) async {
    int? updatedWaitTime = int.tryParse(newWaitTime);
    if (updatedWaitTime != null) {
      try {
        // Create the update data
        Map<String, dynamic> updateData = {
          'waitTime': updatedWaitTime,
          'currentLocation': widget.selectedLocation,
          'id': provider.docId
        };

        await ApiService.updateProvider(provider.docId, updateData);

        setState(() {
          provider.waitTime = updatedWaitTime;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Wait time updated successfully')),
        );
      } catch (e) {
        print('Error updating wait time: $e'); // Debug print
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update wait time: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid wait time')),
      );
    }
  }

  Future<void> removeProvider(ProviderInfo provider) async {
    bool? shouldDelete = await _showConfirmationDialog(
      context,
      'Delete Wait Time',
      "Are you sure you want to delete this provider's wait time?",
    );

    if (shouldDelete == true) {
      try {
        // Check if the provider has a wait time
        if (provider.waitTime == null) {
          // If no wait time, just remove the provider from selectedProviders
          setState(() {
            selectedProviders.remove(provider);
            _waitTimeControllers.remove(provider.docId);
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Provider removed from selection')),
          );
          return;
        }

        // If the provider has a wait time, call the API to remove it
        await ApiService.removeProviderWaitTime(provider.docId);

        setState(() {
          selectedProviders.remove(provider);
          _waitTimeControllers.remove(provider.docId);
          provider.waitTime = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Wait time removed successfully')),
        );

        await loadProvidersFromApi(); // Refresh the list
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to remove wait time: $e')),
        );
      }
    }
  }

  Future<void> deleteAllWaitTimes() async {
    bool? shouldDeleteAll = await _showConfirmationDialog(
      context,
      'Delete All Wait Times',
      'Are you sure you want to delete all wait times?',
    );

    if (shouldDeleteAll == true) {
      try {
        // Create a list to store providers without wait times
        List<ProviderInfo> providersWithoutWaitTime = [];

        for (var provider in selectedProviders) {
          if (provider.waitTime == null) {
            // Add providers without wait times to the list
            providersWithoutWaitTime.add(provider);
          } else {
            // Call the API to remove wait times for providers with wait times
            await ApiService.removeProviderWaitTime(provider.docId);
          }
        }

        // Update the state
        setState(() {
          // Remove all providers from selectedProviders
          selectedProviders.clear();
          _waitTimeControllers.clear();

          // Add providers without wait times back to providerList
          providerList.addAll(providersWithoutWaitTime);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All wait times removed successfully')),
        );

        await loadProvidersFromApi(); // Refresh the list
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete all wait times: $e')),
        );
      }
    }
  }

  void openProviderSelection() async {
    final availableProviders = providerList
        .where((p) =>
            p.locations.contains(widget.selectedLocation) &&
            !selectedProviders.any((selected) => selected.docId == p.docId))
        .toList();

    final List<ProviderInfo>? selected = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProviderSelectionPage(
          providers: availableProviders,
          selectedLocation: widget.selectedLocation, // Pass the location here
        ),
      ),
    );

    if (selected != null && selected.isNotEmpty) {
      setState(() {
        selectedProviders.addAll(selected);
        for (var provider in selected) {
          _waitTimeControllers[provider.docId] = TextEditingController();
        }
      });
    }
  }

  // ------------------------------------------ Build methods ------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Align(
          alignment: Alignment.center,
          child: Text(
            '${widget.selectedLocation} Wait Times',
            style: const TextStyle(fontSize: 20),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(CupertinoIcons.add),
            onPressed: openProviderSelection,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Display current location providers section
            if (currentlocationProviders.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: currentlocationProviders.length,
                  itemBuilder: (context, index) {
                    final provider = currentlocationProviders[index];
                    final controller = _waitTimeControllers[provider.docId]!;
                    return Column(
                      children: [
                        ListTile(
                          title: Text(provider.displayName.split('|').first.trim()),
                          subtitle: Text(provider.specialty),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 60,
                                child: TextField(
                                  controller: controller,
                                  keyboardType: TextInputType.number,
                                  decoration:
                                      InputDecoration(labelText: 'Time'),
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.update, color: Colors.blue),
                                onPressed: () =>
                                    _updateWaitTime(provider, controller.text),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () => removeProvider(provider),
                              ),
                            ],
                          ),
                        ),
                        const Divider(),
                      ],
                    );
                  },
                ),
              )
            else
              // Display selected providers with time controls
              Container(
                alignment: Alignment.center,
                child: Text(
                  'No active times in ${widget.selectedLocation}',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: Stack(
        children: [
          // FloatingActionButton for deleting all wait times
          Positioned(
            bottom: 16,
            left: MediaQuery.of(context).size.width / 2 -
                60, // Center horizontally
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton(
                  heroTag: 'deleteBtn',
                  onPressed: deleteAllWaitTimes,
                  tooltip: 'Delete All Wait Times',
                  child: Icon(Icons.delete_forever),
                ),
                SizedBox(width: 16), // Space between buttons
                FloatingActionButton(
                  heroTag: 'saveBtn',
                  onPressed: saveAllWaitTimes,
                  tooltip: 'Save All Wait Times',
                  child: Icon(CupertinoIcons.checkmark_alt),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

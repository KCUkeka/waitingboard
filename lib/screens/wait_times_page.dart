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
  final Map<String, TextEditingController> _waitTimeControllers = {};

  @override
  void initState() {
    super.initState();
    loadProvidersFromApi();

    // Add listener to refresh data when switching back to WaitTimesPage
    widget.tabController.addListener(() {
      if (widget.tabController.index == 0) {
        loadProvidersFromApi();
      }
    });
  }

  @override
  void dispose() {
    // Dispose all TextEditingControllers
    for (var controller in _waitTimeControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  // ------------------------------------------ Define methods ------------------------------------------------------

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

      setState(() {
        providerList = fetchedProviders.map((providerData) {
          if (providerData is Map<String, dynamic>) {
            List<String> locations = [
              (providerData['locationName'] ?? '').toString()
            ];
            return ProviderInfo.fromWaitTimeApi(
                providerData, providerData['id']?.toString() ?? '', locations);
          } else if (providerData is ProviderInfo) {
            return providerData; // If it's already a ProviderInfo object, just return it
          } else {
            throw Exception(
                'Unexpected data type: ${providerData.runtimeType}');
          }
        }).toList();
        selectedProviders = providerList
            .where((provider) => provider.waitTime != null)
            .toList();
        _initializeControllers();
      });
    } catch (e) {
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
        for (var provider in selectedProviders) {
          await ApiService.removeProviderWaitTime(provider.docId);
        }

        setState(() {
          selectedProviders.clear();
          _waitTimeControllers.clear();
        });

        await loadProvidersFromApi();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('All wait times deleted successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Failed to delete all wait times: ${e.toString()}')),
        );
      }
    }
  }

  void openProviderSelection() async {
    final availableProviders = providerList
        .where((p) =>
                p.locations.contains(widget.selectedLocation) &&
                !selectedProviders.any((selected) =>
                    selected.docId ==
                    p.docId) // Check if provider is already selected
            )
        .toList();

    final selected = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ProviderSelectionPage(providers: availableProviders),
      ),
    );

    if (selected != null) {
      setState(() {
        selectedProviders.add(selected);
        _waitTimeControllers[selected.docId] = TextEditingController();
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
            style: const TextStyle(
              fontSize: 20,
            ),
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
            Expanded(
              child: ListView.builder(
                itemCount: selectedProviders.length,
                itemBuilder: (context, index) {
                  final provider = selectedProviders[index];
                  final controller = _waitTimeControllers[provider.docId]!;

                  return Column(
                    children: [
                      ListTile(
                        title: Text(provider.displayName),
                        subtitle: Text(provider.specialty),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 60,
                              child: TextField(
                                controller: controller,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(labelText: 'Time'),
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
            ),
            IconButton(
              icon: Icon(CupertinoIcons.checkmark_alt, size: 40),
              onPressed: saveAllWaitTimes,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: deleteAllWaitTimes,
        tooltip: 'Delete All Wait Times',
        child: Icon(Icons.delete_forever),
      ),
    );
  }
}

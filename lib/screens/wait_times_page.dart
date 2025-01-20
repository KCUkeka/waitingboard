import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:waitingboard/model/provider_info.dart';
import 'package:waitingboard/screens/providerselection.dart';
import 'package:waitingboard/services/api_service.dart';

class WaitTimesPage extends StatefulWidget {
  final TabController tabController;
  final String selectedLocation; // Add selectedLocation here

  WaitTimesPage({required this.tabController, required this.selectedLocation});

  @override
  _WaitTimesPageState createState() => _WaitTimesPageState();
}

class _WaitTimesPageState extends State<WaitTimesPage> {
  List<ProviderInfo> providerList = [];
  List<ProviderInfo> selectedProviders = [];
  Map<ProviderInfo, String> selectedLocations = {}; // Map to store selected locations for each provider

  @override
  void initState() {
    super.initState();
    loadProvidersFromApi();

// Add listener to refresh data when switching back to WaitTimesPage
    widget.tabController.addListener(() {
      if (widget.tabController.index == 0) {
        loadProvidersFromApi(); // Refresh data when tab switches to WaitTimesPage
      }
    });
  }

Future<void> loadProvidersFromApi() async {
  try {
    final List<dynamic> fetchedProviders =
        await ApiService.fetchProvidersByLocation(widget.selectedLocation);

    setState(() {
      providerList = fetchedProviders
          .map((providerData) => ProviderInfo.fromApi(providerData, providerData['docId']))
          .toList();
      selectedProviders = providerList
          .where((provider) => provider.waitTime != null)
          .toList();
    });
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to load providers: ${e.toString()}')),
    );
  }
}


  Future<void> saveAllWaitTimes() async {
    try {
      for (var provider in selectedProviders) {
        if (provider.waitTime != null) {
          await ApiService.updateProvider(provider.docId, {
            'waitTime': provider.waitTime,
            'selectedLocation': provider.selectedLocation,
          });
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Wait times saved successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save wait times: ${e.toString()}')),
      );
    }
  }

  Future<void> _updateWaitTime(ProviderInfo provider, String newWaitTime) async {
    int? updatedWaitTime = int.tryParse(newWaitTime);
    if (updatedWaitTime != null) {
      setState(() {
        provider.waitTime = updatedWaitTime;
      });
      try {
        await ApiService.updateProvider(provider.docId, {
          'waitTime': updatedWaitTime,
          'selectedLocation': provider.selectedLocation,
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Wait time updated successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update wait time: ${e.toString()}')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a valid wait time')),
      );
    }
  }

  Future<void> removeProvider(ProviderInfo provider) async {
    bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Delete Wait Time"),
          content: Text("Are you sure you want to delete this provider's wait time?"),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false), // User chose 'No'
              child: Text("No"),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true), // User chose 'Yes'
              child: Text("Yes"),
            ),
          ],
        );
      },
    );

// If the user confirmed the deletion, proceed with removing the wait time
    if (shouldDelete == true) {
      setState(() {
        selectedProviders.remove(provider);
        provider.waitTime = null; // Set wait time to null in the local state
        provider.selectedLocation = null; // Set selectedLocation to null locally
      });

      try {
        await ApiService.updateProvider(provider.docId, {
          'waitTime': null,
          'selectedLocation': null,
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Wait time and selected location removed successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to remove wait time: ${e.toString()}')),
        );
      }
    }
  }

// Function to delete all wait times
  Future<void> deleteAllWaitTimes() async {
// Show confirmation dialog
    bool? shouldDeleteAll = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Delete All Wait Times"),
          content: Text("Are you sure you want to delete all wait times?"),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false), // User chose 'No'
              child: Text("No"),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true), // User chose 'Yes'
              child: Text("Yes"),
            ),
          ],
        );
      },
    );

    if (shouldDeleteAll == true) {
      // Delete all wait times
      try {
        for (var provider in selectedProviders) {
          await ApiService.updateProvider(provider.docId, {
            'waitTime': null,
            'selectedLocation': null,
          });
        }

        setState(() {
          selectedProviders.clear(); // Clear the selectedProviders list
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('All wait times deleted successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete all wait times: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Container(
          alignment: Alignment.center,
          child: Text('${widget.selectedLocation} Wait Times'),
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
                  final TextEditingController waitTimeController = TextEditingController(
                    text: provider.waitTime?.toString() ?? '',
                  );

                  return Column(
                    children: [
                      ListTile(
                        title: Text(provider.displayName),
                        subtitle: Text('${provider.specialty}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 60,
                              child: TextField(
                                controller: waitTimeController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(labelText: 'Time'),
                                onChanged: (value) {
                                  provider.waitTime = int.tryParse(value);
                                },
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.update, color: Colors.blue),
                              onPressed: () => _updateWaitTime(provider, waitTimeController.text),
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
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Save All',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    IconButton(
                      icon: Icon(CupertinoIcons.checkmark_alt, size: 40),
                      onPressed: saveAllWaitTimes,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: deleteAllWaitTimes, // Trigger the deleteAllWaitTimes function
        tooltip: 'Delete All Wait Times',
        child: Icon(Icons.delete_forever),
      ),
    );
  }
  
// Provider selection function (if needed)
  void openProviderSelection() async {
    final availableProviders = providerList.where((provider) => provider.waitTime == null).toList();
    final selected = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProviderSelectionPage(providers: availableProviders),
      ),
    );

    if (selected != null) {
      setState(() {
        selectedProviders.add(selected);
      });
    }
  }
}


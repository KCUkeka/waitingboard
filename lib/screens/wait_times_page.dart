import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
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
  final Map<String, ProviderStatus> _statusMap = {};
  bool _isLoading = false;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _loadProvidersFromApi();
    _setupTabRefresh();
  }

  @override
  void dispose() {
    for (var controller in _waitTimeControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  // -------------------- Refresh logic -----------------------
  void _setupTabRefresh() {
    widget.tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (mounted && widget.tabController.index == 0) {
      _loadProvidersFromApi();
    }
  }

  // Manual refresh method
  Future<void> _manualRefresh() async {
    await _loadProvidersFromApi();
  }
  
  // Check if specialty supports Delay option
  bool _supportsDelayOption(String specialty) {
    return specialty == 'ANC' ||
           specialty == 'General' ||
           specialty == 'Infusion' ||
           specialty == 'Rheumatology';
  }
  
  // ------------------------------------------ Define functions ------------------------------------------------------
  Future<void> _loadProvidersFromApi() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _isRefreshing = true;
    });

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
                return providerData;
              } else {
                throw Exception(
                    'Unexpected data type: ${providerData.runtimeType}');
              }
            })
            .where((provider) => provider.locations
                .contains(widget.selectedLocation))
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

        _isLoading = false;
        _isRefreshing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isRefreshing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load providers: ${e.toString()}')));
    }
  }

  // ------------------------------------------ Rest of your existing functions (unchanged) ------------------------------------------------------
  
  String? _getWaitTimeText(String docId) {
    final status = _statusMap[docId] ?? ProviderStatus.time;
    switch (status) {
      case ProviderStatus.onTime:
        return 'On Time';
      case ProviderStatus.delayed:
        return 'Delayed';
      case ProviderStatus.time:
        final text = _waitTimeControllers[docId]?.text ?? '';
        if (text.isEmpty || int.tryParse(text) == null || int.parse(text) < 0)
          return null;
        return text;
    }
  }

  void _initializeControllers() {
    for (var provider in selectedProviders) {
      final docId = provider.docId;
      final waitTime = provider.waitTime?.toLowerCase() ?? '';

      _waitTimeControllers[docId] = TextEditingController(
        text: waitTime != 'on time' && waitTime != 'delayed'
            ? provider.waitTime
            : '',
      );

      if (waitTime == 'on time') {
        _statusMap[docId] = ProviderStatus.onTime;
      } else if (waitTime == 'delayed') {
        _statusMap[docId] = ProviderStatus.delayed;
      } else {
        _statusMap[docId] = ProviderStatus.time;
      }
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
          final value = _getWaitTimeText(provider.docId);
          if (value != null) {
            await ApiService.updateProvider(provider.docId, {
              'waitTime': value,
              'current_location': widget.selectedLocation,
            });
          }
        }

        await _loadProvidersFromApi();
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Wait times saved successfully')));
      } catch (e) {
        print('Error saving wait times: $e');
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save wait times: $e')));
      }
    }
  }

  Future<void> _updateWaitTime(
      ProviderInfo provider, String? newWaitTime) async {
    if (newWaitTime == null || newWaitTime.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid wait time')),
      );
      return;
    }

    try {
      final updateData = {
        'waitTime': newWaitTime,
        'current_location': widget.selectedLocation,
        'id': provider.docId,
      };

      await ApiService.updateProvider(provider.docId, updateData);

      setState(() {
        provider.waitTime = newWaitTime;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wait time updated successfully')),
      );
    } catch (e) {
      print('Error updating wait time: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update wait time: $e')),
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
          _statusMap.remove(provider.docId);
          provider.waitTime = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Wait time removed successfully')));
        await _loadProvidersFromApi();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to remove wait time: $e')));
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
          _statusMap.clear();
        });

        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('All wait times removed successfully')));
        await _loadProvidersFromApi();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete all wait times: $e')));
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
          selectedLocation: widget.selectedLocation,
        ),
      ),
    );

    if (selected != null && selected.isNotEmpty) {
      setState(() {
        selectedProviders.addAll(selected);
        for (var provider in selected) {
          final docId = provider.docId;
          _waitTimeControllers[docId] = TextEditingController();
          _statusMap[docId] = ProviderStatus.time;
        }
      });
    }
  }

  // ------------------------------------------ Build Method ------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Align(
          alignment: Alignment.center,
          child: Text('${widget.selectedLocation} Wait Times',
              style: TextStyle(fontSize: 20)),
        ),
        actions: [
          // Refresh button
          IconButton(
            icon: _isRefreshing 
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(Icons.refresh),
            onPressed: _isRefreshing ? null : _manualRefresh,
            tooltip: 'Refresh',
          ),
          IconButton(
              icon: Icon(CupertinoIcons.add), onPressed: openProviderSelection),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _buildContent(),
      floatingActionButton: Stack(
        children: [
          Positioned(
            bottom: 16,
            left: MediaQuery.of(context).size.width / 2 - 60,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton(
                  heroTag: 'deleteBtn',
                  onPressed: deleteAllWaitTimes,
                  tooltip: 'Delete All Wait Times',
                  child: Icon(Icons.delete_forever),
                ),
                SizedBox(width: 16),
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

  Widget _buildContent() {
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: Column(
        children: [
          if (currentlocationProviders.isNotEmpty)
            Expanded(
              child: ListView.builder(
                itemCount: currentlocationProviders.length,
                itemBuilder: (context, index) {
                  final provider = currentlocationProviders[index];
                  final docId = provider.docId;
                  final status = _statusMap[docId] ?? ProviderStatus.time;
                  final hasDelayOption = _supportsDelayOption(provider.specialty);

                  return Column(
                    children: [
                      ListTile(
                        title: Text(
                            provider.displayName.split('|').first.trim()),
                        subtitle: Text(provider.specialty),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Toggle buttons - different options based on specialty
                            if (hasDelayOption) ...[
                              // Three options: Time, On Time, Delay
                              ToggleButtons(
                                isSelected: [
                                  status == ProviderStatus.time,
                                  status == ProviderStatus.onTime,
                                  status == ProviderStatus.delayed,
                                ],
                                onPressed: (i) {
                                  final selected = ProviderStatus.values[i];
                                  setState(() {
                                    _statusMap[docId] = selected;
                                    if (selected != ProviderStatus.time) {
                                      _waitTimeControllers[docId]?.clear();
                                    }
                                  });
                                },
                                borderRadius: BorderRadius.circular(8),
                                constraints: BoxConstraints(
                                    minHeight: 36, minWidth: 60),
                                children: [
                                  Text("Time"),
                                  Text("On Time"),
                                  Text("Delay")
                                ],
                              ),
                            ] else ...[
                              // Two options: Time, On Time (no Delay)
                              ToggleButtons(
                                isSelected: [
                                  status == ProviderStatus.time,
                                  status == ProviderStatus.onTime,
                                ],
                                onPressed: (i) {
                                  final selected = i == 0 
                                      ? ProviderStatus.time 
                                      : ProviderStatus.onTime;
                                  setState(() {
                                    _statusMap[docId] = selected;
                                    if (selected != ProviderStatus.time) {
                                      _waitTimeControllers[docId]?.clear();
                                    }
                                  });
                                },
                                borderRadius: BorderRadius.circular(8),
                                constraints: BoxConstraints(
                                    minHeight: 36, minWidth: 60),
                                children: [
                                  Text("Time"),
                                  Text("On Time"),
                                ],
                              ),
                            ],
                            SizedBox(width: 6),
                            // Text input for time (only shown when Time is selected)
                            if (status == ProviderStatus.time)
                              SizedBox(
                                width: 50,
                                height: 36,
                                child: TextField(
                                  controller: _waitTimeControllers[docId],
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly
                                  ],
                                  textAlign: TextAlign.center,
                                  onChanged: (_) => setState(() {}),
                                  decoration: InputDecoration(
                                    hintText: 'Min',
                                    contentPadding:
                                        EdgeInsets.symmetric(vertical: 8),
                                    isDense: true,
                                    border: OutlineInputBorder(),
                                    errorText: (_waitTimeControllers[docId]
                                                    ?.text
                                                    .isEmpty ??
                                                true) ||
                                            int.tryParse(_waitTimeControllers[
                                                            docId]
                                                        ?.text ??
                                                    '') !=
                                                null
                                        ? null
                                        : 'Invalid',
                                  ),
                                ),
                              ),
                            IconButton(
                              icon: Icon(Icons.update, color: Colors.blue),
                              onPressed: () => _updateWaitTime(
                                  provider, _getWaitTimeText(docId)),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () => removeProvider(provider),
                            ),
                          ],
                        ),
                      ),
                      Divider(),
                    ],
                  );
                },
              ),
            )
          else
            Container(
              alignment: Alignment.center,
              child: Text(
                'No active times in ${widget.selectedLocation}',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ),
        ],
      ),
    );
  }
}
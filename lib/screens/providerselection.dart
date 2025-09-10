import 'package:flutter/material.dart';
import 'package:waitingboard/model/provider_info.dart';
import 'package:waitingboard/services/api_service.dart';

enum ProviderStatus { time, onTime, delayed }

class ProviderSelectionPage extends StatefulWidget {
  final List<ProviderInfo> providers;
  final String selectedLocation;

  ProviderSelectionPage({
    required this.providers,
    required this.selectedLocation,
  });

  @override
  _ProviderSelectionPageState createState() => _ProviderSelectionPageState();
}

class _ProviderSelectionPageState extends State<ProviderSelectionPage> {
  final Map<String, TextEditingController> _waitTimeControllers = {};
  final Map<String, ProviderStatus> _statusMap = {};

  @override
  void dispose() {
    _waitTimeControllers.forEach((_, c) => c.dispose());
    super.dispose();
  }

  Future<bool?> _showConfirmationDialog(
      BuildContext context, String title, String content) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Confirm')),
        ],
      ),
    );
  }

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

  Future<void> _updateWaitTime(ProviderInfo provider) async {
    final waitTime = _getWaitTimeText(provider.docId);

    if (waitTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a valid wait time')),
      );
      return;
    }

    try {
      await ApiService.updateProvider(provider.docId, {
        'wait_time': waitTime,
        'current_location': widget.selectedLocation,
      });
      setState(() {
        provider.waitTime = waitTime;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Wait time updated for ${provider.displayName}')),
      );
      Navigator.pop(context); // Go back to wait_times_page
    } catch (e) {
      print('Update error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update: $e')),
      );
    }
  }

  Future<void> _saveAllWaitTimes() async {
    bool? confirmed = await _showConfirmationDialog(
      context,
      'Confirm Save',
      'Are you sure you want to update all wait times?',
    );
    if (confirmed != true) return;

    bool errorOccurred = false;

    // Only update providers with a valid wait time
    final validProviders = widget.providers.where((provider) {
      final waitTime = _getWaitTimeText(provider.docId);
      return waitTime != null && waitTime.isNotEmpty;
    }).toList();

    for (var provider in validProviders) {
      final waitTime = _getWaitTimeText(provider.docId);

      // Optional: print debug info
      print('Saving ${provider.displayName} with waitTime: $waitTime');

      try {
        await ApiService.updateProvider(provider.docId, {
          'wait_time': waitTime,
          'current_location': widget.selectedLocation,
        });
      } catch (e) {
        errorOccurred = true;
        print('Error saving ${provider.displayName}: $e');
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(errorOccurred
            ? 'Some wait times failed to save.'
            : 'All wait times saved.'),
      ),
    );
    Navigator.pop(context); // Return to previous screen
  }

  bool _shouldShowTimeControls(String specialty) {
    final lower = specialty.toLowerCase();
    return lower == 'anc' ||
        lower == 'general' ||
        lower == 'infusion' ||
        lower == 'rheumatology';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Provider'),
        actions: [
          IconButton(
            onPressed: _saveAllWaitTimes,
            icon: Icon(Icons.check),
            tooltip: 'Save All Wait Times',
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: widget.providers.length,
        itemBuilder: (context, index) {
          final provider = widget.providers[index];
          print('Provider: ${provider.displayName}, ${provider.specialty}');
          final docId = provider.docId;
          _waitTimeControllers.putIfAbsent(
              docId, () => TextEditingController());
          _statusMap.putIfAbsent(docId, () => ProviderStatus.time);

          final status = _statusMap[docId]!;
          final showControls = _shouldShowTimeControls(provider.specialty);

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            child: Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Display Name + Specialty
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            provider.displayName,
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            provider.specialty,
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 12),
                          ),
                        ],
                      ),
                    ),

                    if (showControls) ...[
                      // Toggle Buttons (ANC or General only)
                      Expanded(
                        flex: 4,
                        child: ToggleButtons(
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
                          constraints:
                              BoxConstraints(minHeight: 36, minWidth: 60),
                          children: [
                            Text("Time"),
                            Text("On Time"),
                            Text("Delay"),
                          ],
                        ),
                      ),
                      SizedBox(width: 6),
                      if (status == ProviderStatus.time)
                        SizedBox(
                          width: 50,
                          height: 36,
                          child: TextField(
                            controller: _waitTimeControllers[docId],
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            decoration: InputDecoration(
                              hintText: 'Min',
                              contentPadding: EdgeInsets.symmetric(vertical: 8),
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                    ] else ...[
                      // Default time input for other providers
                      SizedBox(width: 6),
                      SizedBox(
                        width: 50,
                        height: 36,
                        child: TextField(
                          controller: _waitTimeControllers[docId],
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                            hintText: 'Min',
                            contentPadding: EdgeInsets.symmetric(vertical: 8),
                            isDense: true,
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],

                    // Update Button
                    IconButton(
                      icon: Icon(Icons.update, color: Colors.blue),
                      onPressed: () => _updateWaitTime(provider),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

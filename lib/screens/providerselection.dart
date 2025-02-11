import 'package:flutter/material.dart';
import 'package:waitingboard/model/provider_info.dart';
import 'package:waitingboard/services/api_service.dart';

class ProviderSelectionPage extends StatefulWidget {
  final List<ProviderInfo> providers;
  final String selectedLocation;

  ProviderSelectionPage({required this.providers, required this.selectedLocation});

  @override
  _ProviderSelectionPageState createState() => _ProviderSelectionPageState();
}

class _ProviderSelectionPageState extends State<ProviderSelectionPage> {
  // Map to store a TextEditingController for each provider's wait time field.
  final Map<String, TextEditingController> _waitTimeControllers = {};

  @override
  void dispose() {
    // Dispose all controllers to prevent memory leaks.
    _waitTimeControllers.forEach((key, controller) => controller.dispose());
    super.dispose();
  }

  /// This method shows a confirmation dialog and returns a boolean.
  Future<bool?> _showConfirmationDialog(
      BuildContext context, String title, String content) async {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: const Text('Confirm'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );
  }

  /// Saves all wait times for the providers.
  Future<void> saveAllWaitTimes() async {
    // Show confirmation dialog.
    bool? shouldSave = await _showConfirmationDialog(
      context,
      'Confirm Update',
      'Are you sure you want to update all wait times?',
    );

    if (shouldSave == true) {
      try {
        for (var provider in widget.providers) {
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Wait times saved successfully')),
        );
        setState(() {}); // Refresh the UI after saving.
      } catch (e) {
        print('Error saving wait times: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save wait times: $e')),
        );
      }
    }
  }

  /// Updates the wait time for a specific provider.
  Future<void> _updateWaitTime(ProviderInfo provider, String newWaitTime) async {
    int? updatedWaitTime = int.tryParse(newWaitTime);
    if (updatedWaitTime != null) {
      try {
        // Prepare the update data.
        Map<String, dynamic> updateData = {
          'waitTime': updatedWaitTime,
          'currentLocation': widget.selectedLocation,
          'id': provider.docId,
        };

        await ApiService.updateProvider(provider.docId, updateData);

        setState(() {
          provider.waitTime = updatedWaitTime;
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
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid wait time')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Provider'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: saveAllWaitTimes,
        tooltip: 'Save All Wait Times',
        child: Icon(Icons.check),
      ),
      body: ListView.builder(
        itemCount: widget.providers.length,
        itemBuilder: (context, index) {
          final provider = widget.providers[index];

          // Ensure a TextEditingController exists for each provider.
          if (!_waitTimeControllers.containsKey(provider.docId)) {
            _waitTimeControllers[provider.docId] = TextEditingController();
          }
          final controller = _waitTimeControllers[provider.docId]!;

          return Column(
            children: [
              ListTile(
                // The provider name is in the title.
                title: Text(provider.displayName),
                subtitle: Text(provider.specialty),
                // Trailing is a Row containing the time input and the update button.
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 80,
                      child: TextField(
                        controller: controller,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.right,
                        decoration: InputDecoration(
                          hintText: 'Time',
                          contentPadding: EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.update, color: Colors.blue),
                      onPressed: () async {
                        await _updateWaitTime(provider, controller.text);
                        setState(() {}); // Refresh the UI after update.
                      },
                    ),
                  ],
                ),
              ),
              Divider(),
            ],
          );
        },
      ),
    );
  }
}

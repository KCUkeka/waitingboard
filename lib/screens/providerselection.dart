import 'package:flutter/material.dart';
import 'package:waitingboard/model/provider_info.dart';

class ProviderSelectionPage extends StatefulWidget {
  final List<ProviderInfo> providers;

  ProviderSelectionPage({required this.providers});

  @override
  _ProviderSelectionPageState createState() => _ProviderSelectionPageState();
}

class _ProviderSelectionPageState extends State<ProviderSelectionPage> {
  final Set<ProviderInfo> _selectedProviders = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Provider'),
        actions: [
          IconButton(
            icon: Icon(Icons.check),
            onPressed: () {
              Navigator.pop(context, _selectedProviders.toList());
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: widget.providers.length,
        itemBuilder: (context, index) {
          final provider = widget.providers[index];
          return CheckboxListTile(
            title: Text(provider.displayName),
            subtitle: Text(provider.specialty),
            value: _selectedProviders.contains(provider),
            onChanged: (bool? selected) {
              setState(() {
                if (selected == true) {
                  _selectedProviders.add(provider);
                } else {
                  _selectedProviders.remove(provider);
                }
              });
            },
          );
        },
      ),
    );
  }
}
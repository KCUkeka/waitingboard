import 'package:flutter/material.dart';
import 'package:waitingboard/model/provider_info.dart';

class ProviderSelectionPage extends StatelessWidget {
  final List<ProviderInfo> providers;

  ProviderSelectionPage({required this.providers});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Provider'),
      ),
      body: ListView.builder(
        itemCount: providers.length,
        itemBuilder: (context, index) {
          final provider = providers[index];
          return ListTile(
            title: Text(provider.displayName),
            subtitle: Text(provider.specialty),
            onTap: () {
              Navigator.pop(context, provider); // Return the selected provider
            },
          );
        },
      ),
    );
  }
}

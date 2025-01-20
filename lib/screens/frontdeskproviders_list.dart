import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:waitingboard/model/provider_info.dart';
import 'package:waitingboard/services/api_service.dart'; // Import the API service

class FrontdeskprovidersList extends StatefulWidget {
  @override
  _FrontdeskProviderListPageState createState() =>
      _FrontdeskProviderListPageState();
}

class _FrontdeskProviderListPageState extends State<FrontdeskprovidersList> {
  String? _selectedLocation;
  late Future<List<ProviderInfo>> _providerFuture;

  @override
  void initState() {
    super.initState();
    _loadSelectedLocation();
  }

  // Load the selected location from SharedPreferences
  Future<void> _loadSelectedLocation() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedLocation = prefs.getString('selectedLocation');
      // Trigger the API call once the location is loaded
      if (_selectedLocation != null) {
        _providerFuture = ApiService.fetchProvidersByLocation(_selectedLocation!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Container(
          alignment: Alignment.center,
          child: const Text('Providers List'),
        ),
      ),
      body: _selectedLocation == null
          ? Center(child: CircularProgressIndicator())
          : FutureBuilder<List<ProviderInfo>>(
              future: _providerFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('No providers available for this location.'));
                }

                final providers = snapshot.data!;

                return ListView.builder(
                  itemCount: providers.length,
                  itemBuilder: (context, index) {
                    final provider = providers[index];

                    return ListTile(
                      title: Text('${provider.firstName} ${provider.lastName}'),
                      subtitle: Text(
                        '${provider.specialty ?? "N/A"} - ${provider.title ?? "N/A"}',
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}



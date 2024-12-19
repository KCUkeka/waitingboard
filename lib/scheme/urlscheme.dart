import 'package:flutter/material.dart';
import 'package:waitingboard/screens/dashboard_page.dart';
import 'package:waitingboard/screens/homepage/clinic_home_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My App',
      initialRoute: '/',
      onGenerateRoute: (settings) {
        if (settings.name == '/dashboard') {
          // Extract arguments passed to the route
          final args = settings.arguments as Map<String, dynamic>?;
          final selectedLocation = args?['selectedLocation'] ?? 'Default Location';

          return MaterialPageRoute(
            builder: (context) => DashboardPage(selectedLocation: selectedLocation),
          );
        }
        // Add other dynamic routes here if needed
        return null; // Let the framework handle unknown routes
      },
      routes: {
        '/': (context) => FutureBuilder<String>(
              future: _getSelectedLocation(), // Fetch selected location asynchronously
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator()); // Loading while fetching location
                } else if (snapshot.hasData) {
                  // If selectedLocation is fetched successfully
                  return ClinicHomePage(selectedLocation: snapshot.data!);
                } else {
                  // Handle case where location is not available
                  return Center(child: Text('No location found!'));
                }
              },
            ),
      },
    );
  }

  // Helper method to get selected location from SharedPreferences or other source
  Future<String> _getSelectedLocation() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('selectedLocation') ?? 'Default Location'; // Default fallback
  }
}

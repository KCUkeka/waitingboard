import 'package:flutter/material.dart';
import 'package:waitingboard/screens/homepage/clinic_home_page.dart';
import 'package:waitingboard/screens/dashboard_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My App',
      initialRoute: '/',
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
        '/dashboard': (context) => DashboardPage(), // Your DashboardPage
      },
    );
  }

  // Helper method to get selected location from SharedPreferences or other source
  Future<String> _getSelectedLocation() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('selectedLocation') ?? 'Default Location'; // Default fallback
  }
}

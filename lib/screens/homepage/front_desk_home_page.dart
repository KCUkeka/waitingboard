import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:waitingboard/screens/dashboard_page.dart';
import 'package:waitingboard/screens/frontdeskproviders_list.dart';
import 'package:waitingboard/services/api_service.dart'; // Flask API service
import '../login_page.dart'; // Import the LoginPage

class FrontHomePage extends StatefulWidget {
  final String selectedLocation; // Add selectedLocation as a parameter

  FrontHomePage({required this.selectedLocation}); // Require selectedLocation

  @override
  _FrontHomePageState createState() => _FrontHomePageState();
}

class _FrontHomePageState extends State<FrontHomePage> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus(); // Check login status when the home page is initialized
  }

  // Check if the user is logged in when the home page is loaded
  Future<void> _checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool? isLoggedIn = prefs.getBool('isLoggedIn');

    if (isLoggedIn == null || !isLoggedIn) {
      // If not logged in, navigate to the login page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    }
  }

  // Log out functionality
  Future<void> _logout() async {
  try {
    // Sign out from Supabase
    await ApiService.logout();
    print('Logout successful.');

    // Clear local session data
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    // Navigate back to the login page
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  } catch (e) {
    print('Error during logout: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to logout: $e')),
    );
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Container(
          alignment: Alignment.center,
          child: Column(
            children: [
              Text('Wait Time Dashboard'),
              Text(
                'Location: ${widget.selectedLocation}', // Display the selected location in the AppBar
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'Providers List') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => FrontdeskprovidersList()),
                  );
                } else if (value == 'Logout') {
                  _logout(); // Call the logout function
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'Providers List',
                  child: Text('Providers List'),
                ),
                PopupMenuItem(
                  value: 'Logout',
                  child: Text('Logout'),
                ),
              ],
              child: Icon(
                CupertinoIcons.person_crop_circle_fill_badge_plus,
                size: 40,
              ),
            ),
          ),
        ],
      ),
      body: DashboardPage(
        selectedLocation: widget.selectedLocation, // Pass the location
      ),
    );
  }
}

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:waitingboard/screens/dashboard_page.dart';
import 'package:waitingboard/screens/frontdeskproviders_list.dart';
import 'package:waitingboard/services/api_service.dart';
import '../login_page.dart';

class FrontHomePage extends StatefulWidget {
  final String selectedLocation; // Add selectedLocation as a parameter

  FrontHomePage({required this.selectedLocation}); // Require selectedLocation

  @override
  _FrontHomePageState createState() => _FrontHomePageState();
}

class _FrontHomePageState extends State<FrontHomePage> {
  String? _selectedLocation;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
    _loadSelectedLocation();
  }

  Future<void> _loadSelectedLocation() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedLocation = prefs.getString('selectedLocation');
    });
    
    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No location found, please login again')),
      );
      _logout();
    }
  }

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
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? loginId = prefs.getString('loginId');

    if (loginId != null) {
      try {
        // Call the Flask API to log out
        await ApiService.logout(loginId);
        print('Logout successful.');
      } catch (e) {
        print('Error logging out: $e');
      }
    } else {
      print('Login ID not found in SharedPreferences.');
    }

    // Clear login state but keep saved credentials
  await prefs.setBool('isLoggedIn', false);

    // Navigate back to the login page
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedLocation == null) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Container(
          alignment: Alignment.center,
          child: Column(
            children: [
              Text('Wait Time Dashboard'),
              Text(
                'Location: $_selectedLocation',
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
        selectedLocation: _selectedLocation!,
      ),
    );
  }
}
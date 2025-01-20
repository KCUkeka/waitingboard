import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/cupertino.dart';
import 'package:waitingboard/screens/dashboard_page.dart';
import 'package:waitingboard/screens/providers_list.dart';
import 'package:waitingboard/services/api_service.dart'; //Flask API service
import '../login_page.dart';
import '../wait_times_page.dart';

class ClinicHomePage extends StatefulWidget {
  final String selectedLocation; // Add selectedLocation as a parameter

  ClinicHomePage({required this.selectedLocation}); // Require selectedLocation

  @override
  _ClinicHomePageState createState() => _ClinicHomePageState();
}

class _ClinicHomePageState extends State<ClinicHomePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

@override
void initState() {
  super.initState();
  _checkLoginStatus(); // Check login status when the home page is initialized
  _tabController = TabController(length: 2, vsync: this); // Two tabs

  _saveSelectedLocation(); // Save the selected location to SharedPreferences
}

// Save the selected location to SharedPreferences
Future<void> _saveSelectedLocation() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setString('selectedLocation', widget.selectedLocation);
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
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? loginId = prefs.getString('loginId');

    if (loginId != null) {
      try {
        // API call to update the logout timestamp
        await ApiService.logout(loginId);
        print('Logout timestamp updated successfully.');
      } catch (e) {
        print('Error updating logout timestamp: $e');
      }
    } else {
      print('Login ID not found in SharedPreferences.');
    }

    // Clear session data
    await prefs.clear();

    // Navigate back to the login page
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Container(
          alignment: Alignment.center,
          child: Column(
            children: [
              const Text('Wait Time Dashboard'),
              Text(
                'Location: ${widget.selectedLocation}', // Display selected location
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Wait Times'),
            Tab(text: 'Board'),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'Providers List') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ProviderListPage()),
                  );
                } else if (value == 'Logout') {
                  _logout(); // Call the logout function
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                    value: 'Providers List', child: Text('Providers List')),
                PopupMenuItem(value: 'Logout', child: Text('Logout')),
              ],
              child: Icon(
                CupertinoIcons.person_crop_circle_fill_badge_plus,
                size: 40,
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: TabBarView(
          controller: _tabController,
          children: [
            WaitTimesPage(
              tabController: _tabController,
              selectedLocation: widget.selectedLocation,
            ),
            DashboardPage(
              selectedLocation: widget.selectedLocation,
            ),
          ],
        ),
      ),
    );
  }
}

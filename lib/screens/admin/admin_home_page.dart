import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/cupertino.dart';

import 'package:waitingboard/services/api_service.dart'; // Import ApiService
import '../login_page.dart'; // Import the LoginPage
import '../wait_times_page.dart';
import 'add_provider_page.dart';
import 'admin_dashboard_page.dart'; // Import DashboardPage
import 'edit_providers_list.dart'; // Import EditProvidersList

class AdminHomePage extends StatefulWidget {
  final String selectedLocation; // Add selectedLocation as a parameter

  AdminHomePage({required this.selectedLocation}); // Require selectedLocation

  @override
  _AdminHomePageState createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
    _tabController = TabController(length: 2, vsync: this); // Two tabs
  }

  // Check login status
  Future<void> _checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool? isLoggedIn = prefs.getBool('isLoggedIn');

    if (isLoggedIn == null || !isLoggedIn) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    }
  }

  // Logout user
  Future<void> _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? loginId = prefs.getString('loginId');

    if (loginId != null) {
      try {
        // Call the logout API
        await ApiService.logout(loginId);
      } catch (e) {
        print('Error during logout: $e');
      }
    }

    // Clear local preferences
    await prefs.clear();
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
          child: Text('Wait Time Dashboard - ${widget.selectedLocation}'), // Show location in the title
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
                if (value == 'Add Provider') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AddProviderPage()),
                  );
                } else if (value == 'Providers List') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => EditProvidersList()),
                  );
                } else if (value == 'Logout') {
                  _logout();
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                    value: 'Add Provider', child: Text('Add Provider')),
                PopupMenuItem(
                    value: 'Providers List', child: Text('Providers List')),
                PopupMenuItem(
                    value: 'Logout',
                    child: Text('Logout')),
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
              selectedLocation: widget.selectedLocation, // Pass selectedLocation here
            ),
            AdminDashboardPage(
              selectedLocation: widget.selectedLocation, // Pass location to DashboardPage
            ),
          ],
        ),
      ),
    );
  }
}

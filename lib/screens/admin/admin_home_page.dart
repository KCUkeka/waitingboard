import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:waitingboard/screens/admin/edit_providers_list.dart';
import '../login_page.dart'; // Import the LoginPage
import '../wait_times_page.dart';
import 'add_provider_page.dart';
import '../dashboard_page.dart'; // Import DashboardPage

class AdminHomePage extends StatefulWidget {
  final String selectedLocation; // Add selectedLocation as a parameter

  AdminHomePage({required this.selectedLocation}); // Require selectedLocation

  @override
  _AdminHomePageState createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
    _tabController = TabController(length: 2, vsync: this); // Two tabs
  }

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

  Future<void> _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? loginId = prefs.getString('loginId');

    if (loginId != null) {
      try {
        DocumentSnapshot snapshot =
            await _firestore.collection('logins').doc(loginId).get();

        if (snapshot.exists) {
          await _firestore.collection('logins').doc(loginId).update({
            'logout_timestamp': Timestamp.now(),
          });
        }
      } catch (e) {
        print('Error updating logout timestamp: $e');
      }
    }

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
        selectedLocation: widget.selectedLocation,  // Pass selectedLocation here
        ),
            DashboardPage(
              selectedLocation: widget.selectedLocation, // Pass location to DashboardPage
            ),
          ],
        ),
      ),
    );
  }
}

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
  @override
  _AdminHomePageState createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Firestore instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus(); // Check login status when the home page is initialized
    _tabController = TabController(length: 2, vsync: this); // Two tabs
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
      // Fetch the document to check if it exists
      DocumentSnapshot snapshot =
          await _firestore.collection('logins').doc(loginId).get();

      if (snapshot.exists) {
        // If the document exists, update the logout timestamp
        await _firestore.collection('logins').doc(loginId).update({
          'logout_timestamp': Timestamp.now(),
        });
        print('Logout timestamp updated successfully.');
      } else {
        print('Document with loginId does not exist.');
      }
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
          child: const Text('Wait Time Dashboard'),
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
                  _logout(); // Call the logout function
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                    value: 'Add Provider', child: Text('Add Provider')),
                PopupMenuItem(
                    value: 'Providers List', child: Text('Providers List')),
                PopupMenuItem(
                    value: 'Logout',
                    child: Text('Logout')), // Added logout option
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
            WaitTimesPage(tabController: _tabController),
            DashboardPage(), // Replace placeholder with DashboardPage
          ],
        ),
      ),
    );
  }
}

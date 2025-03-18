import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:waitingboard/screens/admin/admin_home_page.dart';
import 'package:waitingboard/screens/dashboard_page.dart';
import 'package:waitingboard/screens/fullscreendashboard.dart';
import 'package:waitingboard/screens/homepage/front_desk_home_page.dart';
import 'package:waitingboard/screens/login_page.dart';
import 'package:waitingboard/services/api_service.dart';
import 'screens/homepage/clinic_home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(WaitingApp());
}

class WaitingApp extends StatefulWidget {
  @override
  _WaitingAppState createState() => _WaitingAppState();
}

class _WaitingAppState extends State<WaitingApp> {
  String someLocation = 'defaultLocation';

  @override
  void initState() {
    super.initState();
    _fetchUsersData();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Wait Times',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => FutureBuilder<bool>(
              future: _checkLoginStatus(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasData && snapshot.data == true) {
                  return _getHomePage();
                } else {
                  return LoginPage();
                }
              },
            ),
        '/dashboard': (context) =>
            DashboardPage(selectedLocation: someLocation), 
        '/fullscreendashboard': (context) =>
            FullScreenDashboardPage(selectedLocation: someLocation), 
      },
    );
  }

  // Check login status using SharedPreferences
  Future<bool> _checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isLoggedIn') ?? false;
  }

  // Get the home page based on role
  Widget _getHomePage() {
    return FutureBuilder<String>(
      future: _getUserRole(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        final role = snapshot.data ?? '';
        switch (role.toLowerCase()) {
          case 'admin':
            return AdminHomePage(selectedLocation: someLocation);
          case 'clinic':
            return ClinicHomePage(selectedLocation: someLocation);
          case 'front desk':
            return FrontHomePage(selectedLocation: someLocation);
          default:
            return LoginPage(); // Fallback to login for unknown roles
        }
      },
    );
  }

  // Get user role from SharedPreferences or MySQL
  Future<String> _getUserRole() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('userRole') ?? '';
  }

  Future<void> _fetchUsersData() async {
    try {
      // Fetch users data from the API
      List<dynamic> users = await ApiService.fetchUsers();
      for (var user in users) {
        print('Username: ${user['username']}}');
      }
    } catch (e) {
      print('Error fetching users: $e');
    }
  }
}

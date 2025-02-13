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

class WaitingApp extends StatelessWidget {

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
        '/dashboard': (context) => DashboardPage(
              selectedLocation: 'Default Location',
            ),
        '/fullscreendashboard': (context) {
          return FutureBuilder<String>(
            future: _getSelectedLocation(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              } else if (snapshot.hasData) {
                String selectedLocation = snapshot.data!;
                return FullScreenDashboardPage(
                    selectedLocation: selectedLocation);
              } else {
                return Center(child: Text('No location found!'));
              }
            },
          );
        },
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
        } else if (snapshot.hasData) {
          String role = snapshot.data!;
          if (role == 'admin') {
            return AdminHomePage(selectedLocation: "Default Location");
          } else if (role == 'Clinic') {
            return ClinicHomePage(selectedLocation: "Default Location");
          } else if (role == 'Front desk') {
            return FrontHomePage(selectedLocation: "Default Location");
          } else {
            return ClinicHomePage(selectedLocation: "Default Location");
          }
        } else {
          return ClinicHomePage(selectedLocation: "Default Location");
        }
      },
    );
  }

  // Get user role from SharedPreferences or MySQL
  Future<String> _getUserRole() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('userRole') ?? '';
  }

  // Get selected location from SharedPreferences
  Future<String> _getSelectedLocation() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('selectedLocation') ?? 'Default Location';
  }

  // Fetch data from MySQL
Future<void> _fetchUsersData() async {
  try {
    // Fetch users data from the API
    List<dynamic> users = await ApiService.fetchUsers();
    // Print user data (or use it in the UI)
    for (var user in users) {
      print('Username: ${user['username']}}');
    }
  } catch (e) {
    print('Error fetching users: $e');
  }
}

}

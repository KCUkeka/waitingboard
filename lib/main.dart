import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:waitingboard/screens/admin/admin_home_page.dart';
import 'package:waitingboard/screens/fullscreendashboard.dart';
import 'package:waitingboard/screens/homepage/front_desk_home_page.dart';
import 'package:waitingboard/screens/login_page.dart';
import 'screens/homepage/clinic_home_page.dart';
import 'screens/dashboard_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    await Firebase.initializeApp(
        options: const FirebaseOptions(
            apiKey: "AIzaSyCkZcw4UIF7Wf_8ynRjdQNzAVFgxCmvf6g",
            authDomain: "orthowaittimes.firebaseapp.com",
            projectId: "orthowaittimes",
            storageBucket: "orthowaittimes.appspot.com",
            messagingSenderId: "935944261487",
            appId: "1:935944261487:web:5e02da4570934a26fa629a"));
  } else {
    await Firebase.initializeApp();
  }

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
                  return Center(
                      child:
                          CircularProgressIndicator()); // Loading indicator while checking
                } else if (snapshot.hasData && snapshot.data == true) {
                  return _getHomePage();
                } else {
                  return LoginPage();
                }
              },
            ),
        '/dashboard': (context) => DashboardPage(
              selectedLocation: 'Default Location', // Pass your location here
            ),
        '/fullscreendashboard': (context) {
          return FutureBuilder<String>(
            future:
                _getSelectedLocation(), // Get selected location from SharedPreferences
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              } else if (snapshot.hasData) {
                String selectedLocation = snapshot.data!;
                return FullScreenDashboardPage(
                    selectedLocation:
                        selectedLocation); // Pass selected location
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
          return Center(
              child:
                  CircularProgressIndicator()); // Loading indicator while fetching role
        } else if (snapshot.hasData) {
          // Navigate to appropriate home page based on role
          String role = snapshot.data!;
          if (role == 'admin') {
            // Fetch selected location for admin
            return FutureBuilder<String>(
              future:
                  _getSelectedLocation(), // Assuming this function fetches location
              builder: (context, locationSnapshot) {
                if (locationSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (locationSnapshot.hasData) {
                  return AdminHomePage(
                      selectedLocation: locationSnapshot.data!);
                } else {
                  return AdminHomePage(
                      selectedLocation:
                          "Default Location"); // Fallback if no location is found
                }
              },
            );
          } else if (role == 'Clinic') {
            return FutureBuilder<String>(
              future: _getSelectedLocation(),
              builder: (context, locationSnapshot) {
                if (locationSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (locationSnapshot.hasData) {
                  return ClinicHomePage(
                      selectedLocation: locationSnapshot.data!);
                } else {
                  return Center(child: Text("No location found!"));
                }
              },
            );
          } else if (role == 'Front desk') {
            return FutureBuilder<String>(
              future: _getSelectedLocation(),
              builder: (context, locationSnapshot) {
                if (locationSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (locationSnapshot.hasData) {
                  return FrontHomePage(
                      selectedLocation: locationSnapshot.data!);
                } else {
                  return Center(child: Text("No location found!"));
                }
              },
            );
          } else {
            return ClinicHomePage(selectedLocation: "Default Location");
          }
        } else {
          return ClinicHomePage(selectedLocation: "Default Location");
        }
      },
    );
  }

  // Get user role from SharedPreferences or Firestore
  Future<String> _getUserRole() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('userRole') ??
        ''; // Replace with role fetched from Firestore
  }

  // Get selected location from SharedPreferences
  Future<String> _getSelectedLocation() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('selectedLocation') ?? 'Default Location';
  }
}

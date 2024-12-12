import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:waitingboard/screens/admin/admin_home_page.dart';
import 'package:waitingboard/screens/fullscreendashboard.dart';
import 'package:waitingboard/screens/front_desk_home_page.dart';
import 'package:waitingboard/screens/login_page.dart';
import 'screens/clinic_home_page.dart';
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
              return CircularProgressIndicator(); // Loading indicator while checking
            } else if (snapshot.hasData && snapshot.data == true) {
              // User is logged in, navigate to appropriate page
              return _getHomePage();
            } else {
              // User is not logged in, show the LoginPage
              return LoginPage();
            }
          },
        ),
        '/home': (context) => ClinicHomePage(),
        '/dashboard': (context) => DashboardPage(),
        '/fullscreendashboard': (context) => FullScreenDashboardPage(),
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
          return CircularProgressIndicator(); // Loading indicator while fetching role
        } else if (snapshot.hasData) {
          // Navigate to appropriate home page based on role
          String role = snapshot.data!;
          if (role == 'admin') {
            return AdminHomePage();
          } else if (role == 'Clinic') {
            return ClinicHomePage();
          } else if (role == 'Front desk') {
            return FrontHomePage();
          } else {
            return ClinicHomePage(); // Default fallback
          }
        } else {
          return ClinicHomePage(); // Default fallback if no role is found
        }
      },
    );
  }

  // Get user role from SharedPreferences or Firestore
  Future<String> _getUserRole() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    // You can fetch the role from SharedPreferences or from Firestore
    return prefs.getString('userRole') ?? ''; // Replace with role fetched from Firestore
  }
}
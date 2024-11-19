import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:waitingboard/screens/fullscreendashboard.dart';
import 'package:waitingboard/screens/login_page.dart';
import 'screens/landing_page.dart';
import 'screens/home_page.dart';
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
        '/': (context) => HomePage(), 
        // to start at landing page, use the LandingPage() and LoginPage() method for login page
        '/home': (context) => HomePage(),
        '/dashboard': (context) => DashboardPage(),
        '/fullscreendashboard': (context) => FullScreenDashboardPage(),
      },
    );
  }
}

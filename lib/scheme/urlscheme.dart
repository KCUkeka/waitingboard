import 'package:flutter/material.dart';
// import 'package:url_launcher/url_launcher.dart';
import 'package:waitingboard/screens/dashboard_page.dart';
import 'package:waitingboard/screens/home_page.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My App',
      initialRoute: '/',
      routes: {
        '/': (context) => HomePage(),
        '/dashboard': (context) => DashboardPage(), // Your DashboardPage
      },
    );
  }
}

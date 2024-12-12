import 'package:flutter/material.dart';
import 'package:waitingboard/screens/clinic_home_page.dart';
import 'package:waitingboard/screens/dashboard_page.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My App',
      initialRoute: '/',
      routes: {
        '/': (context) => ClinicHomePage(),
        '/dashboard': (context) => DashboardPage(), // Your DashboardPage
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:waitingboard/screens/homepage/clinic_home_page.dart';
import 'package:waitingboard/services/api_service.dart';
import 'signup_page.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _passwordController = TextEditingController();

  String? _selectedUsername;
  String? _selectedLocation;

  List<Map<String, String>> _users = []; // Store user objects with username and hashed password
  List<String> _locations = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      var users = await ApiService.fetchUsers();
      var locations = await ApiService.fetchLocations();

      setState(() {
        _users = users.map((user) {
          return {
            'username': user['username'] as String,
            'password': user['password'] as String,
          };
        }).toList();
        _locations = locations.map((location) => location['name'] as String).toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load data: $e")),
      );
    }
  }

  String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<void> _login() async {
    final username = _selectedUsername;
    final enteredPassword = _passwordController.text.trim();

    if (username == null || _selectedLocation == null || enteredPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please complete all fields.")),
      );
      return;
    }

    try {
      // Find the selected user's hashed password
      final user = _users.firstWhere((user) => user['username'] == username, orElse: () => {});
      if (user.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Invalid username.")),
        );
        return;
      }

      final hashedPassword = user['password'];

      // Hash the entered password and compare with the stored hashed password
      if (hashPassword(enteredPassword) != hashedPassword) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Invalid password.")),
        );
        return;
      }

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('selectedLocation', _selectedLocation!);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ClinicHomePage(selectedLocation: _selectedLocation!),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Login failed: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(child: Text('Orthoillinois Wait Times Login')),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            DropdownButtonFormField<String>(
              value: _selectedUsername,
              items: _users.map((user) {
                return DropdownMenuItem(
                  value: user['username'],
                  child: Text(user['username']!),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedUsername = value;
                });
              },
              decoration: InputDecoration(labelText: 'Username'),
            ),
            DropdownButtonFormField<String>(
              value: _selectedLocation,
              items: _locations.map((location) {
                return DropdownMenuItem(
                  value: location,
                  child: Text(location),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedLocation = value;
                });
              },
              decoration: InputDecoration(labelText: 'Location'),
            ),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(labelText: 'Password'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _login,
              child: Text('Login'),
            ),
            SizedBox(height: 10),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CreateAccountPage()),
                );
              },
              child: Text('Create Account'),
            ),
          ],
        ),
      ),
    );
  }
}

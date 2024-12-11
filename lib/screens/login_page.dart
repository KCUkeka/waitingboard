import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart'; // FirebaseAuth import
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore import
import 'signup_page.dart'; // Import signup page
import 'home_page.dart'; // Home page to navigate after login

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _passwordController = TextEditingController();

  // FirebaseAuth instance
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Dropdown values
  String? _selectedUsername;
  String? _selectedLocation;

  // Usernames fetched from Firestore
  List<String> _usernames = [];
  List<String> _locations = [];

  @override
  void initState() {
    super.initState();
    _fetchUsernamesAndLocations();
  }

  Future<void> _fetchUsernamesAndLocations() async {
    try {
      // Fetch usernames from Firestore
      var usersSnapshot = await _firestore.collection('users').get();
      var locationsSnapshot = await _firestore.collection('locations').get();

      setState(() {
        _usernames = usersSnapshot.docs.map((doc) => doc['username'] as String).toList();
        _locations = locationsSnapshot.docs.map((doc) => doc['name'] as String).toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load data: $e")),
      );
    }
  }

  Future<void> _login() async {
    final password = _passwordController.text.trim();

    try {
      if (_selectedUsername == null || _selectedLocation == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please select a username and location.")),
        );
        return;
      }

      // Fetch user document from Firestore based on the selected username
      var userSnapshot = await _firestore
          .collection('users')
          .where('username', isEqualTo: _selectedUsername)
          .limit(1)
          .get();

      if (userSnapshot.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Username not found.")),
        );
        return;
      }

      var userDoc = userSnapshot.docs.first;
      String email = userDoc['email'];

      // Use FirebaseAuth to sign in
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Save login state and selected location to SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('selectedLocation', _selectedLocation!);

      // Navigate to Home Page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Login failed: ${e.toString()}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            DropdownButtonFormField<String>(
              value: _selectedUsername,
              items: _usernames.map((username) {
                return DropdownMenuItem(
                  value: username,
                  child: Text(username),
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

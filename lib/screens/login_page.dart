import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart'; // FirebaseAuth import
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore import
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
  String? _selectedLocation; // Updated from _selectedRole to _selectedLocation

  // Example data for usernames
  final List<String> _usernames = ['admin', 'clinic', 'frontdesk'];

  // Locations fetched from Firestore
  List<String> _locations = [];

  @override
  void initState() {
    super.initState();
    _fetchLocations(); // Fetch locations when the widget initializes
  }

  Future<void> _fetchLocations() async {
    try {
      var snapshot = await _firestore.collection('locations').get();
      setState(() {
        _locations = snapshot.docs.map((doc) => doc['name'] as String).toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load locations: $e")),
      );
    }
  }

Future<void> _login() async {
  final password = _passwordController.text;

  // Static admin login check
  if (_selectedUsername == 'admin' && password == 'admin') {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    
    // Set the login state and store loginId
    await prefs.setBool('isLoggedIn', true);

    String loginId = Timestamp.now().millisecondsSinceEpoch.toString();  // Generate a unique loginId based on timestamp

    // Create the login session in Firestore
    await _firestore.collection('logins').add({
      'username': _selectedUsername,
      'location': _selectedLocation,
      'login_timestamp': Timestamp.now(),
      'login_id': loginId,
      'logout_timestamp': null,
    });

    // Save the loginId for future reference (e.g., logout)
    await prefs.setString('loginId', loginId);

    // Navigate to the home page
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => HomePage()),
    );
    return;
  }

  // Static clinic login check
  if (_selectedUsername == 'clinic' && password == 'password') {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Set the login state and store loginId
    await prefs.setBool('isLoggedIn', true);

    String loginId = Timestamp.now().millisecondsSinceEpoch.toString();  // Generate a unique loginId based on timestamp

    // Create the login session in Firestore
    await _firestore.collection('logins').add({
      'username': _selectedUsername,
      'location': _selectedLocation,
      'login_timestamp': Timestamp.now(),
      'login_id': loginId,
      'logout_timestamp': null,
    });

    // Save the loginId for future reference (e.g., logout)
    await prefs.setString('loginId', loginId);

    // Navigate to the home page
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => HomePage()),
    );
    return;
  }

  // Static frontdesk login check
  if (_selectedUsername == 'frontdesk' && password == 'password') {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Set the login state and store loginId
    await prefs.setBool('isLoggedIn', true);

    String loginId = Timestamp.now().millisecondsSinceEpoch.toString();  // Generate a unique loginId based on timestamp

    // Create the login session in Firestore
    await _firestore.collection('logins').add({
      'username': _selectedUsername,
      'location': _selectedLocation,
      'login_timestamp': Timestamp.now(),
      'login_id': loginId,
      'logout_timestamp': null,
    });

    // Save the loginId for future reference (e.g., logout)
    await prefs.setString('loginId', loginId);

    // Navigate to the home page
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => HomePage()),
    );
    return;
  }

  // Firebase Firestore and Auth logic for other users (dynamic login)
  try {
    var userDoc = await _firestore
        .collection('users')
        .where('username', isEqualTo: _selectedUsername)
        .limit(1)
        .get();

    if (userDoc.docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Username not found")),
      );
      return;
    }

    String email = userDoc.docs.first['email'];
    UserCredential userCredential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => HomePage()),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Invalid username or password")),
    );
  }
}





  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
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
              onPressed: () {
                if (_selectedUsername != null && _selectedLocation != null) {
                  _login();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Please select a username and location.")),
                  );
                }
              },
              child: Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'package:waitingboard/screens/admin/admin_home_page.dart';
import 'dart:convert';
import 'package:waitingboard/screens/homepage/clinic_home_page.dart';
import 'package:waitingboard/screens/homepage/front_desk_home_page.dart';
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

  List<Map<String, dynamic>> _users =
      []; // Store user objects with username and hashed password
  List<String> _locations = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

//-------------------------------------------------------Fetch User/Location data----------------------------------------------

  Future<void> _fetchData() async {
    try {
      var users = await ApiService.fetchUsers();
      var locations = await ApiService.fetchLocations();

      setState(() {
        _users = users.map((user) {
          return {
            'username': user['username']?.toString() ?? '',
            'password': user['password']?.toString() ?? '',
            'role': user['role']?.toString() ?? '',
            'admin': user['admin'],
          };
        }).toList();

        

        _locations = locations
            .map((location) {
              return location.toString(); // Fallback to empty string
            })
            .where((name) => name.isNotEmpty)
            .toList(); // Filter out empty names
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load data: $e")),
      );
    }
  }

  String hashPassword(String password) {
    final bytes = utf8.encode(password); // Encode the password in UTF-8
    final digest = sha256.convert(bytes); // Generate the hash
    // print('Hashed Password: $digest');  // Debug print
    return digest
        .toString(); // Return the hashed password as a hexadecimal string
  }

//-------------------------------------------------------Add new location----------------------------------------------

  Future<void> _addNewLocation() async {
    final TextEditingController locationNameController =
        TextEditingController();
    final TextEditingController usernameController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Add New Location"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Dropdown for username selection
              DropdownButtonFormField<String>(
                value: usernameController.text.isEmpty
                    ? null
                    : usernameController.text,
                items: _users.map((user) {
                  return DropdownMenuItem(
                    value: user['username']?.toString() ?? '',
                    child: Text(user['username']!),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    usernameController.text = value!;
                  });
                },
                decoration: InputDecoration(labelText: "Select Username"),
              ),
              SizedBox(height: 10),

              // Password input
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(labelText: "Password"),
              ),
              SizedBox(height: 10),

              // Location name input
              TextField(
                controller: locationNameController,
                decoration: InputDecoration(labelText: "Location Name"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                final locationName = locationNameController.text.trim();
                final username = usernameController.text.trim();
                final password = passwordController.text.trim();

                if (locationName.isEmpty ||
                    username.isEmpty ||
                    password.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("All fields are required.")),
                  );
                  return;
                }

                // Find the user by username
                final user = _users.firstWhere(
                  (user) => user['username'] == username,
                  orElse: () => {},
                );

                if (user.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Invalid username.")),
                  );
                  return;
                }                ; 

                // Check if the user is an admin
                final isAdmin =
                    user['admin'] == true || user['admin'] == 'true';
                if (!isAdmin) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Only admins can add locations.")),
                  );
                  return;
                }

                // Verify the password
                final hashedPassword = user['password'];
                if (hashPassword(password) != hashedPassword) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Invalid password.")),
                  );
                  return;
                }

                // Add the new location via API
                try {
                  await ApiService.addLocation(locationName);
                  await _fetchData(); // Refresh locations
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Location added successfully.")),
                  );
                  Navigator.of(context).pop(); // Close dialog
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Failed to add location: $e")),
                  );
                }
              },
              child: Text("Add"),
            ),
          ],
        );
      },
    );
  }

  //-------------------------------------------------------Login method----------------------------------------------

  Future<void> _login() async {
    final username = _selectedUsername;
    final enteredPassword = _passwordController.text.trim();

    if (username == null ||
        _selectedLocation == null ||
        enteredPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please complete all fields.")),
      );
      return;
    }

    try {
      final user = _users.firstWhere((user) => user['username'] == username,
          orElse: () => {});
      if (user.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Invalid username.")),
        );
        return;
      }

      final hashedPassword = user['password'];

      if (hashPassword(enteredPassword) != hashedPassword) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Invalid password.")),
        );
        return;
      }

      final loginSuccess = await ApiService.loginUser(
          username,
          hashPassword(enteredPassword), // Make sure password is hashed
          _selectedLocation!);
      if (!loginSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Failed to update login time and location.")),
        );
        return;
      }

      //----------------------------------------------------Save login info-------------------------------------------

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('selectedLocation', _selectedLocation!);

      // Rest of your navigation logic remains the same
      final isAdmin = user['admin'] == true || user['admin'] == 'true';
      if (isAdmin) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  AdminHomePage(selectedLocation: _selectedLocation!)),
        );
        return;
      }

      if (user['role'] == 'Front desk') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => FrontHomePage(selectedLocation: _selectedLocation!)),
        );
      } else if (user['role'] == 'Clinic') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  ClinicHomePage(selectedLocation: _selectedLocation!)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Role not recognized.")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Login failed: $e")),
      );
    }
  }

//-------------------------------------------------------Build page----------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Container(
          alignment: Alignment.center,
          child: Column(
            children: [
              Text('Orthoillinois'),
              Padding(
                padding: EdgeInsets.only(left: 20.0),
                child: Text('Wait Times Login'),
              ),
            ],
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Image.asset(
              'assets/images/waitboard.png',
              width: 200,
              height: 200,
            ),
            DropdownButtonFormField<String>(
              value: _selectedUsername,
              items: _users.map((user) {
                return DropdownMenuItem(
                  value: user['username'] as String,
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
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _addNewLocation,
              child: Text('New Location'),
            ),
          ],
        ),
      ),
    );
  }
}

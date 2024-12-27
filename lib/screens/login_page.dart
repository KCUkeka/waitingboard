import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:waitingboard/logic/models/mysql.dart';
import 'package:waitingboard/screens/homepage/clinic_home_page.dart';
import 'package:waitingboard/screens/homepage/front_desk_home_page.dart';
import 'package:waitingboard/screens/admin/admin_home_page.dart';
import 'signup_page.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _passwordController = TextEditingController();

  String? _selectedUsername;
  String? _selectedLocation;

  List<String> _usernames = [];
  List<String> _locations = [];

  final Mysql db = Mysql();

  @override
  void initState() {
    super.initState();
    _fetchUsernamesAndLocations();
  }

  Future<void> _fetchUsernamesAndLocations() async {
    try {
      var conn = await db.getConnection();
      var userResults = await conn.query('SELECT username FROM users');
      var locationResults = await conn.query('SELECT name FROM locations');

      setState(() {
        _usernames = userResults.map((row) => row['username'] as String).toList();
        _locations = locationResults.map((row) => row['name'] as String).toList();
      });

      await conn.close();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load data: $e")),
      );
    }
  }

  Future<void> _login() async {
    final password = _passwordController.text.trim();

    if (_selectedUsername == null || _selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a username and location.")),
      );
      return;
    }

    try {
      var conn = await db.getConnection();
      var results = await conn.query(
        'SELECT * FROM users WHERE username = ? AND password = ?',
        [_selectedUsername, password],
      );

      if (results.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Invalid username or password.")),
        );
        await conn.close();
        return;
      }

      var user = results.first;
      bool isAdmin = user['admin'] == 1;
      String role = user['role'];

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('selectedLocation', _selectedLocation!);
      await prefs.setString('userRole', role);

      await conn.close();

      // Navigate based on role
      if (isAdmin) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                AdminHomePage(selectedLocation: _selectedLocation!),
          ),
        );
      } else if (role == 'Clinic') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ClinicHomePage(selectedLocation: _selectedLocation!),
          ),
        );
      } else if (role == 'Front desk') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                FrontHomePage(selectedLocation: _selectedLocation!),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Unknown role")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Login failed: ${e.toString()}")),
      );
    }
  }

  Future<void> _showAddLocationDialog() async {
    String? selectedUser;
    bool isAdmin = false;
    final TextEditingController newLocationController =
        TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text("Add New Location"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedUser,
                    items: _usernames.map((username) {
                      return DropdownMenuItem(
                        value: username,
                        child: Text(username),
                      );
                    }).toList(),
                    onChanged: (value) async {
                      setState(() {
                        selectedUser = value;
                      });

                      if (value != null) {
                        try {
                          var conn = await db.getConnection();
                          var result = await conn.query(
                            'SELECT admin FROM users WHERE username = ?',
                            [value],
                          );

                          if (result.isNotEmpty) {
                            isAdmin = result.first['admin'] == 1;
                          } else {
                            isAdmin = false;
                          }
                          await conn.close();
                          setState(() {});
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Error: $e")),
                          );
                        }
                      }
                    },
                    decoration: InputDecoration(labelText: "Select User"),
                  ),
                  SizedBox(height: 20),
                  if (selectedUser != null)
                    isAdmin
                        ? TextField(
                            controller: newLocationController,
                            decoration: InputDecoration(
                              labelText: "Location Name",
                            ),
                          )
                        : Text(
                            "User is not an admin",
                            style: TextStyle(color: Colors.red),
                          ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close dialog
                  },
                  child: Text("Cancel"),
                ),
                if (isAdmin)
                  ElevatedButton(
                    onPressed: () async {
                      final newLocation = newLocationController.text.trim();

                      if (newLocation.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('Location name cannot be empty')),
                        );
                        return;
                      }

                      if (_locations.contains(newLocation)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('Location already exists')),
                        );
                        return;
                      }

                      try {
                        var conn = await db.getConnection();
                        await conn.query(
                          'INSERT INTO locations (name) VALUES (?)',
                          [newLocation],
                        );
                        await _fetchUsernamesAndLocations(); // Refresh locations
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('Location added successfully')),
                        );
                        await conn.close();
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('Failed to add location: $e')),
                        );
                      }

                      Navigator.of(context).pop(); // Close dialog
                    },
                    child: Text("Add"),
                  ),
              ],
            );
          },
        );
      },
    );
  }

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
            SizedBox(height: 20),
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
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _showAddLocationDialog,
              child: Text('Add Location'),
            ),
          ],
        ),
      ),
    );
  }
}

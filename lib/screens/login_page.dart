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
  Future<void> _requireAdminBeforeCreateAccount() async {
    final TextEditingController usernameController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();

    String? selectedAdminUsername;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text("Admin Authorization Required"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedAdminUsername,
                    items: _users
                        .where((user) =>
                            user['admin'] == true || user['admin'] == 'true')
                        .map<DropdownMenuItem<String>>(
                            (user) => DropdownMenuItem<String>(
                                  value: user['username'] as String,
                                  child: Text(user['username'] as String),
                                ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedAdminUsername = value;
                        usernameController.text = value!;
                      });
                    },
                    decoration: InputDecoration(labelText: "Admin Username"),
                  ),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: InputDecoration(labelText: "Admin Password"),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () {
                    final user = _users.firstWhere(
                      (u) => u['username'] == selectedAdminUsername,
                      orElse: () => {},
                    );

                    if (user.isEmpty ||
                        hashPassword(passwordController.text.trim()) !=
                            user['password']) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Invalid admin credentials.")),
                      );
                      return;
                    }

                    final isAdmin =
                        user['admin'] == true || user['admin'] == 'true';
                    if (!isAdmin) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text("Only admins can create accounts.")),
                      );
                      return;
                    }

                    Navigator.of(context).pop(); // Close the dialog
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => CreateAccountPage()),
                    );
                  },
                  child: Text("Continue"),
                ),
              ],
            );
          },
        );
      },
    );
  }

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

        // Debugging the mapped users and their passwords
        // for (var user in _users) {
        //   print('Username: ${user['username']}, Password: ${user['password']}');
        // }

        

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
                items: _users
                    .where((user) =>
                        user['admin'] == true || user['admin'] == 'true')
                    .map((user) {
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

                if (locationName.isEmpty || username.isEmpty || password.isEmpty) {
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
                }

              

                // Check if the user is an admin
                final isAdmin = user['admin'] == true || user['admin'] == 'true';
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

// --------------------------------------------------------Password Reset--------------------------------------------

  Future<void> _resetPassword() async {
    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController adminUsernameController =
        TextEditingController();
    final TextEditingController adminPasswordController =
        TextEditingController();

    String? selectedTargetUsername;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text("Reset User Password"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedTargetUsername,
                      items: _users.map((user) {
                        return DropdownMenuItem<String>(
                          value: user['username'],
                          child: Text(user['username']),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedTargetUsername = value;
                        });
                      },
                      decoration: InputDecoration(
                          labelText: "Select Username to Reset"),
                    ),
                    TextField(
                      controller: newPasswordController,
                      obscureText: true,
                      decoration: InputDecoration(labelText: "New Password"),
                    ),
                    Divider(height: 20),
                    DropdownButtonFormField<String>(
                      value: adminUsernameController.text.isNotEmpty
                          ? adminUsernameController.text
                          : null,
                      items: _users
                          .where((user) =>
                              user['admin'] == true || user['admin'] == 'true')
                          .map((user) {
                        final username = user['username']?.toString() ?? '';
                        return DropdownMenuItem<String>(
                          value: username,
                          child: Text(username),
                        );
                      }).toList(),
                      onChanged: (value) {
                        adminUsernameController.text = value!;
                      },
                      decoration:
                          InputDecoration(labelText: "Select Admin Username"),
                    ),
                    TextField(
                      controller: adminPasswordController,
                      obscureText: true,
                      decoration: InputDecoration(labelText: "Admin Password"),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final targetUsername = selectedTargetUsername?.trim();
                    final newPassword = newPasswordController.text.trim();
                    final adminUsername = adminUsernameController.text.trim();
                    final adminPassword = adminPasswordController.text.trim();

                    if ([
                      targetUsername,
                      newPassword,
                      adminUsername,
                      adminPassword
                    ].any((v) => v == null || v.isEmpty)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("All fields are required.")));
                      return;
                    }

                    final adminUser = _users.firstWhere(
                      (user) => user['username'] == adminUsername,
                      orElse: () => {},
                    );

                    if (adminUser.isEmpty ||
                        hashPassword(adminPassword) != adminUser['password']) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text("Invalid admin credentials.")));
                      return;
                    }

                    final isAdmin = adminUser['admin'] == true ||
                        adminUser['admin'] == 'true';
                    if (!isAdmin) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text("Only admins can reset passwords.")));
                      return;
                    }

                    try {
                      await ApiService.resetPassword(
                          targetUsername!, hashPassword(newPassword));
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text("Password reset successfully.")));
                      Navigator.of(context).pop();
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text("Failed to reset password: $e")));
                    }
                  },
                  child: Text("Reset"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  //-------------------------------------------------------Login method----------------------------------------------

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
      final user = _users.firstWhere((user) => user['username'] == username, orElse: () => {});
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
          const SnackBar(content: Text("Failed to update login time and location.")),
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
            builder: (context) => AdminHomePage(selectedLocation: _selectedLocation!),
          ),
        );
        return;
      }

      if (user['role'] == 'Front desk') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => FrontHomePage(selectedLocation: _selectedLocation!),
          ),
        );
      } else if (user['role'] == 'Clinic') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ClinicHomePage(selectedLocation: _selectedLocation!),
          ),
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
              'assets/icons/waitboard.png',
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
            Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: TextButton(
                onPressed: _resetPassword,
                child: Text('Reset Password'),
              ),
            ),
            SizedBox(height: 10),
            TextButton(
              onPressed: _requireAdminBeforeCreateAccount,
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

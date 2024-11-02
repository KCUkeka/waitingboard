import 'package:flutter/material.dart';

class LandingPage extends StatefulWidget {
  @override
  _LandingPageState createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  String? selectedRole;
  String? selectedLocation;

  final List<String> roles = ['Clinical', 'Front Desk'];
  final List<String> locations = ['Elgin', 'Algonquin', 'Riverside', 'Roxbury'];

  void onLogin() {
    if (selectedRole != null && selectedLocation != null) {
      // Pass selectedRole and selectedLocation to the next page or use Provider/State Management
      Navigator.pushNamed(context, '/dashboard', arguments: {
        'role': selectedRole,
        'location': selectedLocation,
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select both role and location")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Role and Location')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Select Your Role', style: TextStyle(fontSize: 20)),
            DropdownButton<String>(
              value: selectedRole,
              hint: const Text("Select Role"),
              items: roles.map((role) {
                return DropdownMenuItem(value: role, child: Text(role));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedRole = value;
                });
              },
            ),
            const SizedBox(height: 20),
            const Text('Select Your Location', style: TextStyle(fontSize: 20)),
            DropdownButton<String>(
              value: selectedLocation,
              hint: const Text("Select Location"),
              items: locations.map((location) {
                return DropdownMenuItem(value: location, child: Text(location));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedLocation = value;
                });
              },
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: onLogin,
              child: const Text("Continue"),
            ),
          ],
        ),
      ),
    );
  }
}

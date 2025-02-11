import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart';
import 'package:waitingboard/services/api_service.dart';

class CreateAccountPage extends StatefulWidget {
  @override
  _CreateAccountPageState createState() => _CreateAccountPageState();
}

class _CreateAccountPageState extends State<CreateAccountPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  String? _selectedRole; // Selected role (Front desk or Clinic)

  String hashPassword(String password) {
    // Hash the password using SHA-256
    final bytes = utf8.encode(password); // Convert password to bytes
    final digest = sha256.convert(bytes); // Perform hashing
    return digest.toString();
  }

  Future<void> _createAccount() async {
    try {
      final username = _usernameController.text.trim();
      final password = _passwordController.text.trim();

      if (username.isEmpty ||
          password.isEmpty ||
          _selectedRole == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("All fields are required.")),
        );
        return;
      }


      if (password.length < 5) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Password must be at least 5 characters.")),
        );
        return;
      }

      // Hash the password before sending it to the API

      final hashedPassword = hashPassword(password);

      // Include 'admin': 'false' in the API payload
      final userPayload = {
        'username': username,
        'password': hashedPassword,
        'role': _selectedRole,
        'admin': false,
      };
      // Call API to create the user
      try {
        await ApiService.createUser(
          username,
          hashedPassword,
          _selectedRole!, // Role is required
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Account created successfully!")),
        );
        Navigator.pop(context); // Navigate back to the previous page
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to create account: $e")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("An error occurred: ${e.toString()}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(child: Text('Create Account')),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: 'Username'),
            ),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
            DropdownButtonFormField<String>(
              value: _selectedRole,
              items: ['Front desk', 'Clinic'].map((role) {
                return DropdownMenuItem(
                  value: role,
                  child: Text(role),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedRole = value;
                });
              },
              decoration: const InputDecoration(labelText: 'Role'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _createAccount,
              child: const Text('Create Account'),
            ),
          ],
        ),
      ),
    );
  }
}

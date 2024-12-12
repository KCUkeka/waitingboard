import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CreateAccountPage extends StatefulWidget {
  @override
  _CreateAccountPageState createState() => _CreateAccountPageState();
}

class _CreateAccountPageState extends State<CreateAccountPage> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _selectedRole; // Selected role (Front desk or Clinic)

  Future<void> _createAccount() async {
    try {
      final username = _usernameController.text.trim();
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      if (username.isEmpty || email.isEmpty || password.isEmpty || _selectedRole == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("All fields are required.")),
        );
        return;
      }

      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w]{2,4}$').hasMatch(email)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please enter a valid email address.")),
        );
        return;
      }

      if (password.length < 5) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Password must be at least 5 characters.")),
        );
        return;
      }

      // Check if username already exists
      var usernameCheck = await _firestore
          .collection('users')
          .where('username', isEqualTo: username)
          .get();

      if (usernameCheck.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Username already exists. Please choose another.")),
        );
        return;
      }

      // Create a new user in Firebase Authentication
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Add user details to Firestore with uid as the document ID
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'username': username,
        'email': email,
        'role': _selectedRole, // Save selected role
        'admin': false, // Hidden field defaulted to false
        'created_at': Timestamp.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Account created successfully!")),
      );

      // Navigate back to the Login page
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'email-already-in-use':
          errorMessage = "This email is already registered.";
          break;
        case 'weak-password':
          errorMessage = "The password provided is too weak.";
          break;
        default:
          errorMessage = "Failed to create account: ${e.message}";
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("An error occurred: ${e.toString()}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Create Account')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(labelText: 'Username'),
            ),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(labelText: 'Password'),
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
              decoration: InputDecoration(labelText: 'Role'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _createAccount,
              child: Text('Create Account'),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:waitingboard/logic/models/mysql.dart';

class CreateAccountPage extends StatefulWidget {
  @override
  _CreateAccountPageState createState() => _CreateAccountPageState();
}

class _CreateAccountPageState extends State<CreateAccountPage> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final Mysql db = Mysql();

  String? _selectedRole; // Selected role (Front desk or Clinic)

  Future<void> _createAccount() async {
    try {
      final username = _usernameController.text.trim();
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      if (username.isEmpty ||
          email.isEmpty ||
          password.isEmpty ||
          _selectedRole == null) {
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
          const SnackBar(
              content: Text("Password must be at least 5 characters.")),
        );
        return;
      }

      var conn = await db.getConnection();

      // Check if the username already exists
      var usernameCheck = await conn.query(
        'SELECT id FROM users WHERE username = ?',
        [username],
      );

      if (usernameCheck.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Username already exists. Please choose another.")),
        );
        await conn.close();
        return;
      }

      // Check if the email already exists
      var emailCheck = await conn.query(
        'SELECT id FROM users WHERE email = ?',
        [email],
      );

      if (emailCheck.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("This email is already registered.")),
        );
        await conn.close();
        return;
      }

      // Insert new user into the database
      await conn.query(
        'INSERT INTO wait_users (username, email, password, role, admin, created_at) VALUES (?, ?, ?, ?, ?, NOW())',
        [
          username,
          email,
          password,
          _selectedRole,
          0
        ], // Admin defaults to 0 (false)
      );

      await conn.close();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Account created successfully!")),
      );

      // Navigate back to the Login page
      Navigator.pop(context);
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
        title: Container(
          alignment: Alignment.center,
          child: Text('Create Account'),
        ),
      ),
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

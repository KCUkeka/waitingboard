import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:5000'; // Change to IP address for device testing

  // Fetch all users
  static Future<List<dynamic>> fetchUsers() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/users'));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to fetch users. Status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching users: $e');
    }
  }

  // Fetch all locations
  static Future<List<dynamic>> fetchLocations() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/locations'));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to fetch locations. Status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching locations: $e');
    }
  }

  // Login user
  static Future<bool> loginUser(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );
      if (response.statusCode == 200) {
        return true;
      } else {
        print('Login failed. Response: ${response.body}');
        return false;
      }
    } catch (e) {
      throw Exception('Error logging in: $e');
    }
  }

  // Add a new location
static Future<void> addLocation(String locationName) async {
  try {
    final url = Uri.parse('$baseUrl/locations');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': locationName}),
    );

    print('Request URL: $url');
    print('Request Body: ${jsonEncode({'name': locationName})}');
    print('Response Status: ${response.statusCode}');
    print('Response Body: ${response.body}');

    if (response.statusCode != 201) {
      throw Exception('Failed to add location. Response: ${response.body}');
    }
  } catch (e) {
    print('Error in addLocation: $e');
    throw Exception('Error adding location: $e');
  }
}


  // Create a new user
  static Future<void> createUser(
      String username, String email, String password, String role) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'email': email,
          'password': password,
          'role': role,
          'admin': false, // Default admin to false
        }),
      );

      print('Request Body: ${jsonEncode({
        'username': username,
        'email': email,
        'password': password,
        'role': role,
        'admin': false,
      })}'); // Debug request body

      if (response.statusCode != 201) {
        throw Exception('Failed to create user: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error creating user: $e');
    }
  }

  // Fetch all database tables
  static Future<List<dynamic>> fetchTables() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/tables'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to fetch database tables. Status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching database tables: $e');
    }
  }
}

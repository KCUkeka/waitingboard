import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:waitingboard/model/provider_info.dart';

class ApiService {
  static const String baseUrl =
      'http://172.28.0.115:5000'; // Change to IP address for device testing, currently set to localhost ip port 500

// ---------------------------------------------------------Users ----------------------------------------------
  // Fetch all users
  static Future<List<dynamic>> fetchUsers() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/users'));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
            'Failed to fetch users. Status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching users: $e');
    }
  }

  // Login user
  static Future<bool> loginUser(
      String username, String password, String location) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(
            {'username': username, 'password': password, 'location': location}),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print('Login failed. Response: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Login error: $e'); // Debug print
      throw Exception('Error logging in: $e');
    }
  }

  // Create a new user
  static Future<void> createUser(
      String username, String password, String role) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
          'role': role,
          'admin': false, // Default admin to false
        }),
      );
      if (response.statusCode != 201) {
        throw Exception('Failed to create user: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error creating user: $e');
    }
  }

//-------------------------------------------------------Locations ----------------------------------------------
  // Fetch all locations
  static Future<List<String>> fetchLocations() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/locations'));
      if (response.statusCode == 200) {
        // Decode response as List<dynamic>
        List<dynamic> jsonResponse = json.decode(response.body);

        // Extract 'name' field from each object
        return jsonResponse
            .map((item) {
              if (item is Map<String, dynamic> && item.containsKey('name')) {
                return item['name'].toString(); // Ensure 'name' is a String
              }
              return ''; // Fallback if 'name' is not found
            })
            .where((name) => name.isNotEmpty)
            .toList();
      } else {
        throw Exception(
            'Failed to fetch locations. Status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching locations: $e');
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

      if (response.statusCode != 201) {
        throw Exception('Failed to add location. Response: ${response.body}');
      }
    } catch (e) {
      print('Error in addLocation: $e');
      throw Exception('Error adding location: $e');
    }
  }

//-------------------------------------------------------Providers ----------------------------------------------
  // Fetch all providers
  static Future<List<dynamic>> fetchProviders() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/providers'));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
            'Failed to fetch providers. Status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching providers: $e');
    }
  }

// Method to add a provider
  static Future<void> addProvider(
    String firstName,
    String lastName,
    String specialty,
    String title,
    String locations, // Accept a String here
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/providers'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'firstName': firstName,
          'lastName': lastName,
          'specialty': specialty,
          'title': title,
          'locations': locations, // Pass as a String
        }),
      );

      if (response.statusCode == 201) {
        print('Provider added successfully');
      } else {
        throw Exception('Failed to add provider: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to add provider: $e');
    }
  }

// Method to fetch providers based on selected location
  static Future<List<ProviderInfo>> fetchProvidersByLocation(
      String location) async {
    try {
      final response =
          await http.get(Uri.parse('$baseUrl/providers?location=$location'));

      if (response.statusCode == 200) {
        // Parse the response JSON
        List<dynamic> data = jsonDecode(response.body);

        return data.map<ProviderInfo>((providerJson) {
          String docId = providerJson['id']?.toString() ?? '';
          // Convert single locationName to a list
          List<String> locations = (providerJson['provider_locations'] ?? '')
              .toString()
              .split(',')
              .map((e) => e.trim())
              .toList();

          return ProviderInfo.fromWaitTimeApi(providerJson, docId, locations);
        }).toList();
      } else {
        throw Exception(
            'Failed to load providers for location: ${response.statusCode}');
      }
    } catch (e) {
      print("Error in fetchProvidersByLocation: $e");
      throw Exception('Error fetching providers: $e');
    }
  }

// Active providers
  static Future<List<ProviderInfo>> fetchActiveProviders() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/providers/active'));
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.map<ProviderInfo>((providerJson) {
          String docId = providerJson['id']?.toString() ?? '';
          List<String> locations = (providerJson['provider_locations'] ?? '')
              .toString()
              .split(',')
              .map((e) => e.trim())
              .toList();
          return ProviderInfo.fromDashboardApi(providerJson, docId, locations);
        }).toList();
      } else {
        throw Exception('Failed to load active providers');
      }
    } catch (e) {
      throw Exception('Error fetching active providers: $e');
    }
  }

//-------------------------------------------------------Update methods ----------------------------------------------
  // Update provider time
  static Future<void> updateProvider(
      String providerId, Map<String, dynamic> updateData) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/providers/$providerId/wait-time'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(updateData),
      );

      if (response.statusCode != 200) {
        throw Exception(
            'Failed to update provider. Status code: ${response.statusCode}, Body: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error updating provider: $e');
    }
  }

  // Method to update general provider details
  static Future<void> updateProviderDetails(
      String providerId, Map<String, dynamic> updateData) async {
    try {
      final response = await http.put(
        Uri.parse(
            '$baseUrl/providers/$providerId'), // Note: no '/wait-time' here
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(updateData),
      );
      if (response.statusCode != 200) {
        throw Exception(
            'Failed to update provider details. Status code: ${response.statusCode}, Body: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error updating provider details: $e');
    }
  }

  // Remove provider wait time
  static Future<void> removeProviderWaitTime(String providerId) async {
    try {
      final response = await http.put(
        // Note: using PUT, not a new endpoint
        Uri.parse(
            '$baseUrl/providers/$providerId/wait-time'), // Use existing endpoint
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(
            {'isRemoving': true, 'waitTime': null, 'currentLocation': null}),
      );

      if (response.statusCode != 200) {
        throw Exception(
            'Failed to remove wait time. Status code: ${response.statusCode}, Body: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error removing wait time: $e');
    }
  }

  // Method to delete a provider
  static Future<void> deleteProvider(dynamic providerId) async {
    try {
      final response = await http.patch(
        Uri.parse(
            '$baseUrl/providers/$providerId'), // Assuming this is the API endpoint
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception(
            'Failed to delete provider. Response: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error deleting provider: $e');
    }
  }

//-------------------------------------------------------Tables ----------------------------------------------
  // Fetch all database tables
  static Future<List<dynamic>> fetchTables() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/tables'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
            'Failed to fetch database tables. Status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching database tables: $e');
    }
  }

//-------------------------------------------------------Logout ----------------------------------------------
  // Define the logout method
  static Future<void> logout(String loginId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/logout'),
      body: json.encode({'loginId': loginId}),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      print("Logout successful");
    } else {
      throw Exception(
          'Failed to log out: ${response.statusCode} ${response.reasonPhrase}');
    }
  }
}

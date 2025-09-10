import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:waitingboard/model/provider_info.dart';

class ApiService {
  static final SupabaseClient supabase = Supabase.instance.client;

  // --------------------------------------------------------- Users ----------------------------------------------
  // Fetch all users
  static Future<List<dynamic>> fetchUsers() async {
    final response = await supabase.from('waitingboard_users').select();
    return response;
  }

  // Login user 
static Future<bool> loginUser(
  String username,
  String hashedPassword,
  String location,
) async {
  try {
    final response = await supabase
        .from('waitingboard_users')
        .select()
        .eq('username', username)
        .eq('password', hashedPassword)
        .maybeSingle();

    if (response == null) {
      return false; // invalid login
    }

    final updateResponse = await supabase
        .from('waitingboard_users')
        .update({
          'last_location': location,
          'last_logged_in': DateTime.now().toIso8601String(),
        })
        .eq('id', response['id'])
        .select();

    return updateResponse.isNotEmpty;
  } catch (e) {
    print('Login error: $e');
    return false;
  }
}


  // Create user (custom table, not Supabase Auth)
  static Future<void> createUser(
      String username, String password, String role) async {
    final response = await supabase.from('waitingboard_users').insert({
      'username': username,
      'password': password,
      'role': role,
      'admin': false,
    }).select();

    if (response.isEmpty) {
      throw Exception('Failed to create user');
    }
  }

  // Reset a user's password (admin authorized)
  static Future<void> resetPassword(
      String username, String newPassword) async {
    final response = await supabase
        .from('waitingboard_users')
        .update({'password': newPassword})
        .eq('username', username)
        .select();

    if (response.isEmpty) {
      throw Exception('Failed to reset password for $username');
    }
  }

  // --------------------------------------------------------- Locations ----------------------------------------------
  static Future<List<String>> fetchLocations() async {
    try {
      final response = await supabase.from('waitingboard_locations').select();
      return (response as List<dynamic>)
          .map((item) => (item['name'] ?? '').toString())
          .where((name) => name.isNotEmpty)
          .toList();
    } catch (e) {
      throw Exception('Error fetching locations: $e');
    }
  }

  static Future<void> addLocation(String locationName) async {
    final response = await supabase
        .from('waitingboard_locations')
        .insert({'name': locationName})
        .select();

    if (response.isEmpty) {
      throw Exception('Failed to add location');
    }
  }

  // --------------------------------------------------------- Providers ----------------------------------------------
  static Future<List<ProviderInfo>> fetchProviders() async {
    try {
      final response = await supabase.from('waitingboard_providers').select();
      return (response as List<dynamic>).map((providerJson) {
        String docId = providerJson['id']?.toString() ?? '';
        List<String> locations = (providerJson['provider_locations'] ?? '')
            .toString()
            .split(',')
            .map((e) => e.trim())
            .toList();
        return ProviderInfo.fromWaitTimeApi(providerJson, docId, locations);
      }).toList();
    } catch (e) {
      throw Exception('Error fetching providers: $e');
    }
  }

  static Future<void> addProvider(
    String firstName,
    String lastName,
    String specialty,
    String title,
    String locations,
  ) async {
    final response = await supabase.from('waitingboard_providers').insert({
      'first_name': firstName,
      'last_name': lastName,
      'specialty': specialty,
      'title': title,
      'provider_locations': locations,
    }).select();

    if (response.isEmpty) {
      throw Exception('Failed to add provider');
    }
  }

  static Future<List<ProviderInfo>> fetchProvidersByLocation(
      String location) async {
    try {
      final response = await supabase
          .from('waitingboard_providers')
          .select()
          .ilike('provider_locations', '%$location%');

      return (response as List<dynamic>).map((providerJson) {
        String docId = providerJson['id']?.toString() ?? '';
        List<String> locations = (providerJson['provider_locations'] ?? '')
            .toString()
            .split(',')
            .map((e) => e.trim())
            .toList();

        return ProviderInfo.fromWaitTimeApi(providerJson, docId, locations);
      }).toList();
    } catch (e) {
      throw Exception('Error fetching providers: $e');
    }
  }

  static Future<List<ProviderInfo>> fetchActiveProviders() async {
    try {
      final response = await supabase
          .from('waitingboard_providers')
          .select()
          .eq('active', true);

      return (response as List<dynamic>).map((providerJson) {
        String docId = providerJson['id']?.toString() ?? '';
        List<String> locations = (providerJson['provider_locations'] ?? '')
            .toString()
            .split(',')
            .map((e) => e.trim())
            .toList();

        return ProviderInfo.fromDashboardApi(providerJson, docId, locations);
      }).toList();
    } catch (e) {
      throw Exception('Error fetching active providers: $e');
    }
  }
  
// Update provider time
static Future<void> updateProvider(
    String providerId, Map<String, dynamic> updateData) async {
  // Always set last_changed to now
  updateData['last_changed'] = DateTime.now().toIso8601String();

  final response = await supabase
      .from('waitingboard_providers')
      .update(updateData)
      .eq('id', providerId)
      .select();

  if (response.isEmpty) {
    throw Exception('Failed to update provider $providerId');
  }
}


  static Future<void> updateProviderDetails(
      String providerId, Map<String, dynamic> updateData) async {
    final response = await supabase
        .from('waitingboard_providers')
        .update(updateData)
        .eq('id', providerId)
        .select();

    if (response.isEmpty) {
      throw Exception('Failed to update provider details for $providerId');
    }
  }

  static Future<void> removeProviderWaitTime(String providerId) async {
    final response = await supabase
        .from('waitingboard_providers')
        .update({'wait_time': null, 'current_location': null})
        .eq('id', providerId)
        .select();

    if (response.isEmpty) {
      throw Exception('Failed to remove wait time for provider $providerId');
    }
  }

  static Future<void> deleteProvider(String providerId) async {
    final response = await supabase
        .from('waitingboard_providers')
        .delete()
        .eq('id', providerId)
        .select();

    if (response.isEmpty) {
      throw Exception('Failed to delete provider $providerId');
    }
  }

  // --------------------------------------------------------- Tables ----------------------------------------------
  static Future<List<String>> fetchTables() async {
    try {
      final response = await supabase
          .from('information_schema.tables')
          .select('table_name')
          .eq('table_schema', 'public');

      return (response as List<dynamic>)
          .map((t) => t['table_name'] as String)
          .toList();
    } catch (e) {
      throw Exception('Error fetching database tables: $e');
    }
  }

  // --------------------------------------------------------- Logout ----------------------------------------------
  static Future<void> logout() async {
    try {
      await supabase.auth.signOut();
      print("Logout successful");
    } catch (e) {
      throw Exception('Failed to log out: $e');
    }
  }
}

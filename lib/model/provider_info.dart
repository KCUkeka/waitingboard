
class ProviderInfo {
  final String docId;
  final String firstName;
  final String lastName;
  final String specialty;
  final String title;
  final List<String> locations;
  int? waitTime;
  final DateTime? last_changed; 

  ProviderInfo({
    required this.docId,
    required this.firstName,
    required this.lastName,
    required this.specialty,
    required this.title,
    required this.locations,
    this.waitTime,
    this.last_changed, 
  });

  factory ProviderInfo.fromWaitTimeApi(
      Map<String, dynamic> json, String docId, List<String> locations) {
      print('fromApi received JSON: $json'); // Add this debug print
      print('last_changed value: ${json['last_changed']}'); // Debug specific field

    DateTime? lastChanged;
    if (json['last_changed'] != null) {
      try {
        lastChanged = DateTime.parse(json['last_changed']);
        print('Parsed last_changed: $lastChanged'); // Debug print
      } catch (e) {
        print('Error parsing last_changed: $e');
      }
    }

    final provider = ProviderInfo(  // Store in variable first
      docId: docId,
      firstName: json['firstName'] ?? '', // Changed from 'first_name'
      lastName: json['lastName'] ?? '', // Changed from 'last_name'
      specialty: json['specialty'] ?? '',
      title: json['title'] ?? '',
      locations: locations,
      waitTime: json['waitTime'], // Changed from 'wait_time'
      last_changed: lastChanged,  
    );
    print('Created provider with last_changed: ${provider.last_changed}'); // Debug result
    return provider;
  }

    factory ProviderInfo.fromDashboardApi(
      Map<String, dynamic> json, String docId, List<String> locations) {
      print('fromApi received JSON: $json'); // Add this debug print
      print('last_changed value: ${json['last_changed']}'); // Debug specific field

    DateTime? lastChanged;
    if (json['last_changed'] != null) {
      try {
        lastChanged = DateTime.parse(json['last_changed']);
        print('Parsed last_changed: $lastChanged'); // Debug print
      } catch (e) {
        print('Error parsing last_changed: $e');
      }
    }

    final provider = ProviderInfo(  // Store in variable first
      docId: docId,
      firstName: json['first_name'] ?? '', // Changed from 'first_name'
      lastName: json['last_name'] ?? '', // Changed from 'last_name'
      specialty: json['specialty'] ?? '',
      title: json['title'] ?? '',
      locations: locations,
      waitTime: json['wait_time'], // Changed from 'wait_time'
      last_changed: lastChanged,  
    );
    print('Created provider with last_changed: ${provider.last_changed}'); // Debug result
    return provider;
  }

  // Converts to API-friendly format
  Map<String, dynamic> toApi() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'specialty': specialty,
      'title': title,
      'waitTime': waitTime ?? 0,
      'lastChanged': last_changed,
      'locations': locations.isNotEmpty ? locations.first : null,
    };
  }

  // Getter for display names for wait times page
  String get displayName {
    return '$lastName, ${firstName.isNotEmpty ? firstName[0] : '?'} | $title';
  }

  // Getter for dashboard cards
  String get dashboardName {
    if (firstName.isEmpty || lastName.isEmpty) {
      return '$title';
    }
    return '$lastName, ${firstName[0]} | $title';
  }

  // Getter for formatted wait time
  String get formattedWaitTime {
    return waitTime != null ? '$waitTime' : 'Not Set';
  }

  @override
  String toString() {
    return 'ProviderInfo(docId: $docId, name: $firstName $lastName, specialty: $specialty, locations: $locations)';
  }
}

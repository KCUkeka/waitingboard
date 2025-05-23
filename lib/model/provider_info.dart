
class ProviderInfo {
  final String docId;
  final String firstName;
  final String lastName;
  final String specialty;
  final String title;
  final List<String> locations;
  final String current_location;
  int? waitTime;
  final DateTime? last_changed; 

  ProviderInfo({
    required this.docId,
    required this.firstName,
    required this.lastName,
    required this.specialty,
    required this.title,
    required this.locations,
    required this.current_location,
    this.waitTime,
    this.last_changed, 
  });

factory ProviderInfo.fromWaitTimeApi(
    Map<String, dynamic> json, String docId, List<String> locations) {
  DateTime? lastChanged;
  if (json['lastChanged'] != null) {
    try {
      lastChanged = DateTime.parse(json['lastChanged']);
    } catch (e) {
      print('Error parsing last_changed: $e');
    }
  }
  // Debug: Print current_location
  print("Mapping provider: ${json['firstName']} ${json['lastName']}, current_location: ${json['currentLocation']}");

  return ProviderInfo(
    docId: docId,
    firstName: json['firstName'] ?? '', 
    lastName: json['lastName'] ?? '', 
    specialty: json['specialty'] ?? '',
    title: json['title'] ?? '',
    locations: locations,
    current_location: json['currentLocation'] ?? '',
    waitTime: json['waitTime'], 
    last_changed: lastChanged,  
  );
}


    factory ProviderInfo.fromDashboardApi(
      Map<String, dynamic> json, String docId, List<String> locations) {
    DateTime? lastChanged;
    if (json['last_changed'] != null) {
      try {
        lastChanged = DateTime.parse(json['last_changed']);
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
      current_location: json['currentLocation'] ?? '',
      waitTime: json['wait_time'], // Changed from 'wait_time'
      last_changed: lastChanged,  
    );
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
      'current_location': current_location,
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
    return '$title $lastName, ${firstName[0]}';
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

class ProviderInfo {
  final String docId;
  final String firstName;
  final String lastName;
  final String specialty;
  final String title;
  final List<String> locations; // New field to store location name
  int? waitTime;
  
  @override
  String toString() {
    return 'ProviderInfo(name: $firstName $lastName, specialty: $specialty, locations: $locations)';
  }

  ProviderInfo({
    required this.docId,
    required this.firstName,
    required this.lastName,
    required this.specialty,
    required this.title,
    required this.locations,
    this.waitTime,
  });

  // Factory constructor to create a ProviderInfo instance from API data
  factory ProviderInfo.fromApi(Map<String, dynamic> json, String docId, List<String> locations) {
  return ProviderInfo(
        docId: docId,
        firstName: json['firstName'] ?? '',
        lastName: json['lastName'] ?? '',
        specialty: json['specialty'] ?? '',
        title: json['title'] ?? 'No ',
        locations:locations,
        waitTime: json['waitTime'],
      );
      
    } 

  // Converts to API-friendly format
  Map<String, dynamic> toApi() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'specialty': specialty,
      'title': title,
      'waitTime': waitTime ?? 0,
      'locations': locations.isNotEmpty ? locations.first : null,
    };
  }

  // Getter for display name
  String get displayName {
    return '$lastName, ${firstName.isNotEmpty ? firstName[0] : '?'} | $title';

  }
}

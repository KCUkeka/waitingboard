class ProviderInfo {
  final String docId;
  final String firstName;
  final String lastName;
  final String specialty;
  final String title;
  final List<String> locations; // New field to store location name
  int? waitTime;

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
  factory ProviderInfo.fromApi(Map<String, dynamic> json, String? docId) {
    try {
      return ProviderInfo(
        docId: docId ?? 'Unknown',
        firstName: json['firstName'] ?? '',
        lastName: json['lastName'] ?? '',
        specialty: json['specialty'] ?? 'N/A',
        title: json['title'] ?? 'N/A',
        locations: List<String>.from(json['locations'] ?? []), // Map location_name
        waitTime: json['waitTime'] as int?,
      );
    } catch (e) {
      print('Error mapping ProviderInfo: $e');
      print('Data received: $json');
      rethrow;
    }
  }

  // Converts to API-friendly format
  Map<String, dynamic> toApi() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'specialty': specialty,
      'title': title,
      'waitTime': waitTime ?? 0,
      'locations': locations, // Include location_name when sending data
    };
  }

  // Getter for display name
  String get displayName {
    return '$lastName, ${firstName.isNotEmpty ? firstName[0] : '?'} | $title (${locations.isNotEmpty ? locations : 'No Location'})';
  }
}

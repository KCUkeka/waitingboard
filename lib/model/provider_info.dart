class ProviderInfo {
  final String firstName;
  final String lastName;
  final String specialty;
  final String title;
  int? waitTime;
  final String docId;
  final List<String> locations;
  String? selectedLocation;

  ProviderInfo({
    required this.firstName,
    required this.lastName,
    required this.specialty,
    required this.title,
    this.waitTime,
    required this.docId,
    required this.locations,
    this.selectedLocation,
  });

  // Factory constructor
  factory ProviderInfo.fromApi(Map<String, dynamic> data, String docId) {
    return ProviderInfo(
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      specialty: data['specialty'] ?? '',
      title: data['title'] ?? '',
      waitTime: data['waitTime'] as int?,
      docId: docId,
      locations: List<String>.from(data['locations'] ?? []),
      selectedLocation: data['selectedLocation'] as String?,
    );
  }

  // Converts to API-friendly format
  Map<String, dynamic> toApi() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'specialty': specialty,
      'title': title,
      'waitTime': waitTime,
      'locations': locations,
      'selectedLocation': selectedLocation,
    };
  }

  // Getter for display name
  String get displayName {
    final locationInfo = selectedLocation != null ? ' ($selectedLocation)' : '';
    return '$lastName, ${firstName[0]}. | $title$locationInfo';
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

class ProviderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> updateWaitTime(String providerId, int newWaitTime) async {
    await _firestore.collection('providers').doc(providerId).update({
      'waitTime': newWaitTime,
      'lastChanged': FieldValue.serverTimestamp(), // Automatically sets the server time
    });
  }

  // Add other Firestore operations as needed, like fetching, adding, or deleting providers
}

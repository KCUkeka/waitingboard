import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/wait_time_model.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fetch wait times from Firestore
  Stream<List<WaitTime>> getWaitTimes() {
    return _firestore.collection('wait_times').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return WaitTime(
          provider: doc['provider'],
          specialty: doc['specialty'],
          title: doc['title'],
          waitTime: doc['wait_time'],
        );
      }).toList();
    });
  }

  // Method to update the wait time and add the lastChanged timestamp
  Future<void> updateWaitTime(String providerId, int newWaitTime) async {
    await _firestore.collection('wait_times').doc(providerId).update({
      'wait_time': newWaitTime,
      'lastChanged': FieldValue.serverTimestamp(), // Sets the last changed time
    });
  }

  // Add new wait time (example)
  Future<void> addWaitTime(String provider, String specialty, String title, String waitTime) async {
    await _firestore.collection('wait_times').add({
      'provider': provider,
      'specialty': specialty,
      'title': title,
      'wait_time': waitTime,
    });
  }

  // Store QR Code URL in Firestore
  Future<void> storeQRCodeUrl(String url) async {
    await _firestore.collection('qr_codes').add({'url': url});
  }
}

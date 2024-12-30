import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TripService {
  static Future<List<Map<String, dynamic>>> loadTrips() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('trips')
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        data['startDate'] = data['startDate'] != null
            ? (data['startDate'] as Timestamp).toDate()
            : null;
        data['endDate'] = data['endDate'] != null
            ? (data['endDate'] as Timestamp).toDate()
            : null;

        return data;
      }).toList();
    } catch (e) {
      throw Exception('Error loading trips: $e');
    }
  }

  static Future<void> addTrip(Map<String, dynamic> tripData) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('trips')
          .add({
        'title': tripData['title'],
        'startDate': tripData['startDate'] != null
            ? Timestamp.fromDate(tripData['startDate'])
            : null,
        'endDate': tripData['endDate'] != null
            ? Timestamp.fromDate(tripData['endDate'])
            : null,
      });
    } catch (e) {
      throw Exception('Error adding trip: $e');
    }
  }

  static Future<void> deleteTrip(Map<String, dynamic> trip) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('trips')
          .doc(trip['id'])
          .delete();
    } catch (e) {
      throw Exception('Error deleting trip: $e');
    }
  }

  static Future<void> logOut() async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      throw Exception('Error logging out: $e');
    }
  }
}

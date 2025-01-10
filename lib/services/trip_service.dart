import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Service class for managing trips
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

  static Future<void> inviteUserToTrip(String tripId, String email) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  try {
    // Reference the trip document
    final tripDocRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('trips')
        .doc(tripId);

    // Get the trip data
    final tripDoc = await tripDocRef.get();
    if (!tripDoc.exists) throw Exception("Trip not found");

    // Add the email to the owners list
    List<dynamic> owners = tripDoc.data()?['owners'] ?? [];
    if (!owners.contains(email)) {
      owners.add(email);
      await tripDocRef.update({'owners': owners});
    }
  } catch (e) {
    throw Exception('Error inviting user: $e');
  }
}


  static Future<String?> addTrip(Map<String, dynamic> tripData) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return null;

  try {
    final tripDoc = await FirebaseFirestore.instance
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
      'owners': [user.email], // Initialize owners with the creator's email
    });
    return tripDoc.id; // Return the document ID (tripId)
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

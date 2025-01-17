import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  static Future<void> toggleTripActive(String tripId, bool isActive) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final batch = FirebaseFirestore.instance.batch();
    final tripsRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('trips');

    if (isActive) {
      // First, deactivate all trips
      final allTrips = await tripsRef.get();
      for (var doc in allTrips.docs) {
        batch.update(doc.reference, {'isActive': false});
      }
    }

    // Then activate/deactivate the selected trip
    batch.update(tripsRef.doc(tripId), {'isActive': isActive});

    await batch.commit();
  }
}

final dateFoldersProvider = StateNotifierProvider.family<DateFoldersNotifier, List<DateFolder>, String>((ref, tripId) {
  return DateFoldersNotifier(tripId);
});

// Model class for date folders
class DateFolder {
  String id;
  String title;
  List<DateTime> dates;
  
  DateFolder({
    required this.id,
    required this.title,
    required this.dates,
  });
  
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'dates': dates.map((date) => date.toIso8601String()).toList(),
    };
  }
  
  factory DateFolder.fromMap(Map<String, dynamic> map) {
    return DateFolder(
      id: map['id'],
      title: map['title'],
      dates: (map['dates'] as List)
          .map((dateStr) => DateTime.parse(dateStr))
          .toList(),
    );
  }
}

class DateFoldersNotifier extends StateNotifier<List<DateFolder>> {
  final String tripId;
  
  DateFoldersNotifier(this.tripId) : super([]) {
    _loadFolders();
  }

  Future<void> _loadFolders() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('trips')
          .doc(tripId)
          .get();

      if (doc.exists && doc.data()?['folders'] != null) {
        final folders = (doc.data()?['folders'] as List)
            .map((folder) => DateFolder.fromMap(folder))
            .toList();
        state = folders;
      }
    } catch (e) {
      print('Error loading folders: $e');
    }
  }

  Future<void> _saveFolders() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('trips')
          .doc(tripId)
          .set({
        'folders': state.map((folder) => folder.toMap()).toList(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error saving folders: $e');
    }
  }

  void addFolder(String title) {
    final newFolder = DateFolder(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      dates: [],
    );
    state = [...state, newFolder];
    _saveFolders();
  }

  void removeFolder(String folderId) {
    state = state.where((folder) => folder.id != folderId).toList();
    _saveFolders();
  }

  void addDateToFolder(String folderId, DateTime date) {
    state = state.map((folder) {
      if (folder.id == folderId && !folder.dates.contains(date)) {
        return DateFolder(
          id: folder.id,
          title: folder.title,
          dates: [...folder.dates, date],
        );
      }
      return folder;
    }).toList();
    _saveFolders();
  }

  void removeDateFromFolder(String folderId, DateTime date) {
    state = state.map((folder) {
      if (folder.id == folderId) {
        return DateFolder(
          id: folder.id,
          title: folder.title,
          dates: folder.dates.where((d) => d != date).toList(),
        );
      }
      return folder;
    }).toList();
    _saveFolders();
  }

  void updateFolderTitle(String folderId, String newTitle) {
    state = state.map((folder) {
      if (folder.id == folderId) {
        return DateFolder(
          id: folder.id,
          title: newTitle,
          dates: folder.dates,
        );
      }
      return folder;
    }).toList();
    _saveFolders();
  }
}
import 'package:flutter/material.dart';
import 'package:trip_app/services/trip_service.dart';
import 'package:trip_app/widgets/trip_card.dart';
import 'package:trip_app/widgets/add_trip_modal.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TripListPage extends StatefulWidget {
  const TripListPage({super.key});

  @override
  State<TripListPage> createState() => _TripListPageState();
}

class _TripListPageState extends State<TripListPage> {
  List<Map<String, dynamic>> trips = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTrips();
  }

  Future<void> _inviteUser(String tripId) async {
    final emailController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Invite User'),
          content: TextField(
            controller: emailController,
            decoration: const InputDecoration(labelText: 'Enter user email'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final email = emailController.text.trim();
                if (email.isNotEmpty) {
                  await TripService.inviteUserToTrip(tripId, email);
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Invitation sent to $email')),
                  );
                }
              },
              child: const Text('Invite'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _loadTrips() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception("User is not authenticated.");
    }

    try {
      final tripsData = await FirebaseFirestore.instance
          .collectionGroup('trips')
          .where('owners', arrayContains: user.email)
          .get();

      setState(() {
        trips = tripsData.docs.map((doc) {
          final data = doc.data();
          // Convert Firestore timestamps to DateTime
          data['startDate'] = (data['startDate'] as Timestamp).toDate();
          data['endDate'] = (data['endDate'] as Timestamp).toDate();
          data['id'] = doc.id;
          return data;
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      throw Exception('Error loading trips: $e');
    }
  }



  Future<void> _addTrip(Map<String, dynamic> tripData) async {
  final tripId = await TripService.addTrip(tripData); // Get the tripId
  if (tripId != null) {
    setState(() {
      trips.add({...tripData, 'id': tripId}); // Add the trip with the id
    });
  }
}


  Future<void> _deleteTrip(Map<String, dynamic> trip) async {
    await TripService.deleteTrip(trip);
    setState(() {
      trips.remove(trip);
    });
  }

  Future<void> _logOut() async {
    await TripService.logOut();
    Navigator.of(context).pushReplacementNamed('/login'); // Navigate to login screen
  }

  Future<void> _openAddTripModal() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return AddTripModal();
      },
    );
    if (result != null) {
      await _addTrip(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip Planner', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: _logOut,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : trips.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  itemCount: trips.length,
                  padding: const EdgeInsets.all(8.0),
                  itemBuilder: (context, index) {
                    final trip = trips[index];
                    return TripCard(
                      trip: trip,
                      onDelete: () => _deleteTrip(trip),
                      onInvite: () => _inviteUser(trip['id']), // Pass the correct trip ID
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddTripModal,
        tooltip: 'Add a new trip',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.travel_explore,
            size: 100,
            color: Colors.blueAccent.withOpacity(0.6),
          ),
          const SizedBox(height: 20),
          Text(
            'Plan Your Next Adventure',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Colors.blueGrey,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Tap the + button below to add your first trip.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

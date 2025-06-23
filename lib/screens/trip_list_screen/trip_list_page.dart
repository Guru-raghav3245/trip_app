import 'package:flutter/material.dart';
import 'package:trip_app/services/trip_service.dart';
import 'package:trip_app/widgets/trip_card.dart';
import 'package:trip_app/widgets/add_trip_modal.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:trip_app/widgets/draggable_trip_overlay.dart';

class TripListPage extends StatefulWidget {
  const TripListPage({super.key});

  @override
  State<TripListPage> createState() => _TripListPageState();
}

// State class
class _TripListPageState extends State<TripListPage> {
  List<Map<String, dynamic>> trips = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTrips();
  }

  Future<void> _toggleTripActive(
      Map<String, dynamic> trip, bool isActive) async {
    try {
      await TripService.toggleTripActive(trip['id'], isActive);
      await _loadTrips(); // Reload all trips to get updated states
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating trip status: $e')),
      );
    }
  }

  Map<String, dynamic>? get activeTrip {
    return trips.cast<Map<String, dynamic>>().firstWhere(
          (trip) => trip['isActive'] == true,
          orElse: () => {},
        );
  }

  void _handleCollaboratorsUpdated(
      Map<String, dynamic> trip, List<String> updatedCollaborators) {
    setState(() {
      final index = trips.indexOf(trip);
      if (index != -1) {
        trips[index] = {
          ...trip,
          'owners': updatedCollaborators,
        };
      }
    });
  }

  // Invite user to trip
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

  // Load trips from firebase
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
          data['id'] = doc.id;
          // Convert Timestamp to DateTime for startDate and endDate
          data['startDate'] = data['startDate'] != null
              ? (data['startDate'] as Timestamp).toDate()
              : null;
          data['endDate'] = data['endDate'] != null
              ? (data['endDate'] as Timestamp).toDate()
              : null;
          return data;
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      if (e.toString().contains('failed-precondition')) {
        // Show a temporary message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'The required index is still building. Please try again later.'),
          ),
        );
      } else {
        throw Exception('Error loading trips: $e');
      }
    }
  }

  // Add a trip to firebase
  Future<void> _addTrip(Map<String, dynamic> tripData) async {
    final tripId = await TripService.addTrip(tripData); // Get the tripId
    if (tripId != null) {
      setState(() {
        trips.add({...tripData, 'id': tripId}); // Add the trip with the id
      });
    }
  }

  // Delete a trip from firebase
  Future<void> _deleteTrip(Map<String, dynamic> trip) async {
    await TripService.deleteTrip(trip);
    setState(() {
      trips.remove(trip);
    });
  }

  // Log out the user
  Future<void> _logOut() async {
    await TripService.logOut();
    Navigator.of(context)
        .pushReplacementNamed('/login'); // Navigate to login screen
  }

  // Open the add trip modal
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

  // Build the widget
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Text('Trip Planner',
                style: TextStyle(fontWeight: FontWeight.bold)),
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
                          onInvite: () => _inviteUser(trip['id']),
                          onToggleActive: (isActive) =>
                              _toggleTripActive(trip, isActive),
                          onCollaboratorsUpdated: (updatedCollaborators) =>
                              _handleCollaboratorsUpdated(
                                  trip, updatedCollaborators),
                        );
                      },
                    ),
          floatingActionButton: FloatingActionButton(
            onPressed: _openAddTripModal,
            tooltip: 'Add a new trip',
            child: const Icon(Icons.add),
          ),
        ),
        if (activeTrip?.isNotEmpty == true)
          DraggableTripOverlay(trip: activeTrip!),
      ],
    );
  }

  // Empty state widget
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
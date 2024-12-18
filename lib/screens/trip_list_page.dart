// ignore_for_file: use_build_context_synchronously

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'trip_details_page.dart';
import '../modals/add_trip_modal.dart';

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

  Future<void> _loadTrips() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('trips')
          .get();

      setState(() {
        trips = querySnapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;

          // Safely handle null values for startDate and endDate
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
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading trips: $e')),
      );
    }
  }

  Future<void> _addTrip(Map<String, dynamic> tripData) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Add to Firestore
      final docRef = await FirebaseFirestore.instance
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

      // Add ID to local trip data
      tripData['id'] = docRef.id;

      setState(() {
        trips.add(tripData);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding trip: $e')),
      );
    }
  }

  Future<void> _deleteTrip(Map<String, dynamic> trip) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Remove from Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('trips')
          .doc(trip['id'])
          .delete();

      setState(() {
        trips.remove(trip);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Trip "${trip['title']}" deleted',
            style: const TextStyle(color: Colors.white),
          ),
          action: SnackBarAction(
            label: 'Undo',
            textColor: Colors.yellow,
            onPressed: () => _addTrip(trip),
          ),
          backgroundColor: Colors.blueGrey,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting trip: $e')),
      );
    }
  }

  // Log out method
  Future<void> _logOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Logged out successfully!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error logging out: $e')),
      );
    }
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
          ? Center(child: CircularProgressIndicator())
          : trips.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  itemCount: trips.length,
                  padding: const EdgeInsets.all(8.0),
                  itemBuilder: (context, index) {
                    final trip = trips[index];
                    return _buildTripCard(trip);
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

  Widget _buildTripCard(Map<String, dynamic> trip) {
    return Card(
      elevation: 6,
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade200, Colors.blueAccent.shade700],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    trip['title'] ?? 'No Title', // Provide a fallback value
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Icon(Icons.flight_takeoff, color: Colors.white70, size: 24),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${trip['startDate'] != null ? DateFormat.yMMMd().format(trip['startDate']) : 'No start date'}'
                ' - '
                '${trip['endDate'] != null ? DateFormat.yMMMd().format(trip['endDate']) : 'No end date'}',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.info, size: 20),
                    label: const Text('View Details'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.blueAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => TripDetailsPage(trip: trip),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteTrip(trip),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

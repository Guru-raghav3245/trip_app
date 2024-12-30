import 'package:flutter/material.dart';
import 'package:trip_app/services/trip_service.dart';
import 'package:trip_app/widgets/trip_card.dart';
import 'package:trip_app/widgets/add_trip_modal.dart';

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
    final tripsData = await TripService.loadTrips();
    setState(() {
      trips = tripsData;
      _isLoading = false;
    });
  }

  Future<void> _addTrip(Map<String, dynamic> tripData) async {
    await TripService.addTrip(tripData);
    setState(() {
      trips.add(tripData);
    });
  }

  Future<void> _deleteTrip(Map<String, dynamic> trip) async {
    await TripService.deleteTrip(trip);
    setState(() {
      trips.remove(trip);
    });
  }

  Future<void> _logOut() async {
    await TripService.logOut();
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
          ? Center(child: CircularProgressIndicator())
          : trips.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  itemCount: trips.length,
                  padding: const EdgeInsets.all(8.0),
                  itemBuilder: (context, index) {
                    final trip = trips[index];
                    return TripCard(trip: trip, onDelete: () => _deleteTrip(trip));
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

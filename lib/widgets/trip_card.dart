import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:trip_app/screens/trip_details_page.dart';

class TripCard extends StatelessWidget {
  final Map<String, dynamic> trip;
  final VoidCallback onDelete;
  final VoidCallback onInvite; // New callback for inviting users

  const TripCard({
    super.key,
    required this.trip,
    required this.onDelete,
    required this.onInvite, // Pass this in constructor
  });

  @override
  Widget build(BuildContext context) {
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
                  const Icon(Icons.flight_takeoff,
                      color: Colors.white70, size: 24),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${trip['startDate'] != null && trip['startDate'] is DateTime ? DateFormat.yMMMd().format(trip['startDate'] as DateTime) : 'No start date'}'
                ' - '
                '${trip['endDate'] != null && trip['endDate'] is DateTime ? DateFormat.yMMMd().format(trip['endDate'] as DateTime) : 'No end date'}',
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
                    onPressed: onDelete,
                  ),
                  IconButton(
                    icon: const Icon(Icons.person_add,
                        color: Colors.green), // Invite icon
                    onPressed: onInvite, // Trigger the invite functionality
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

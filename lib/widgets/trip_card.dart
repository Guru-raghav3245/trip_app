import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:trip_app/screens/trip_details_screen/trip_details_page.dart';
import 'package:trip_app/screens/trip_list_screen/collaborators_dialog.dart';

class TripCard extends StatelessWidget {
  final Map<String, dynamic> trip;
  final VoidCallback onDelete;
  final VoidCallback onInvite;
  final Function(bool) onToggleActive;
  final Function(List<String>)? onCollaboratorsUpdated;

  const TripCard({
    super.key,
    required this.trip,
    required this.onDelete,
    required this.onInvite,
    required this.onToggleActive,
    this.onCollaboratorsUpdated,
  });

  void _showCollaboratorsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => ManageCollaboratorsDialog(
        tripId: trip['id'],
        collaborators: List<String>.from(trip['owners'] ?? []),
        onCollaboratorsUpdated: (updatedCollaborators) {
          onCollaboratorsUpdated?.call(updatedCollaborators);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isActive = trip['isActive'] ?? false;

    return Card(
      elevation: 6,
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isActive 
              ? [Colors.green.shade200, Colors.green.shade700]
              : [Colors.blue.shade200, Colors.blueAccent.shade700],
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
                  Expanded(
                    child: Text(
                      trip['title'] ?? 'No Title',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Switch(
                    value: isActive,
                    onChanged: onToggleActive,
                    activeColor: Colors.white,
                    activeTrackColor: Colors.green.shade300,
                  ),
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
                      foregroundColor: isActive ? Colors.green : Colors.blueAccent,
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
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.group, color: Colors.white),
                        onPressed: () => _showCollaboratorsDialog(context),
                      ),
                      IconButton(
                        icon: const Icon(Icons.person_add, color: Colors.white70),
                        onPressed: onInvite,
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: onDelete,
                      ),
                    ],
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
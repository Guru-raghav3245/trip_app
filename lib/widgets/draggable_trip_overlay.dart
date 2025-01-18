// draggable_trip_overlay.dart
import 'package:flutter/material.dart';
import 'package:trip_app/screens/trip_details_screen/trip_details_page.dart';

class DraggableTripOverlay extends StatefulWidget {
  final Map<String, dynamic> trip;

  const DraggableTripOverlay({
    super.key,
    required this.trip,
  });

  @override
  State<DraggableTripOverlay> createState() => _DraggableTripOverlayState();
}

class _DraggableTripOverlayState extends State<DraggableTripOverlay> {
  Offset position = const Offset(20, 100); // Initial position

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: position.dx,
      top: position.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            position = Offset(
              position.dx + details.delta.dx,
              position.dy + details.delta.dy,
            );
          });
        },
        child: Container(
          width: 120,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.8),
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => TripDetailsPage(trip: widget.trip),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(25),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.trip_origin,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.trip['title'] ?? 'Active Trip',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
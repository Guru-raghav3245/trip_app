// manage_collaborators_dialog.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ManageCollaboratorsDialog extends StatefulWidget {
  final String tripId;
  final List<String> collaborators;
  final Function(List<String>) onCollaboratorsUpdated;

  const ManageCollaboratorsDialog({
    Key? key,
    required this.tripId,
    required this.collaborators,
    required this.onCollaboratorsUpdated,
  }) : super(key: key);

  @override
  State<ManageCollaboratorsDialog> createState() => _ManageCollaboratorsDialogState();
}

class _ManageCollaboratorsDialogState extends State<ManageCollaboratorsDialog> {
  late List<String> _collaborators;
  final currentUserEmail = FirebaseAuth.instance.currentUser?.email;

  @override
  void initState() {
    super.initState();
    _collaborators = List.from(widget.collaborators);
  }

  Future<void> _removeCollaborator(String email) async {
    // Don't allow removing yourself
    if (email == currentUserEmail) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You cannot remove yourself from the trip")),
      );
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Update Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('trips')
          .doc(widget.tripId)
          .update({
        'owners': FieldValue.arrayRemove([email])
      });

      setState(() {
        _collaborators.remove(email);
      });

      widget.onCollaboratorsUpdated(_collaborators);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error removing collaborator: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Collaborators',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (_collaborators.isEmpty)
              const Text('No collaborators yet')
            else
              ListView.builder(
                shrinkWrap: true,
                itemCount: _collaborators.length,
                itemBuilder: (context, index) {
                  final email = _collaborators[index];
                  return ListTile(
                    leading: const Icon(Icons.person),
                    title: Text(email),
                    trailing: email == currentUserEmail
                        ? const Icon(Icons.star, color: Colors.amber)
                        : IconButton(
                            icon: const Icon(Icons.remove_circle, color: Colors.red),
                            onPressed: () => _removeCollaborator(email),
                          ),
                  );
                },
              ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// In trip_service.dart, add this method:
Future<void> removeCollaborator(String tripId, String email) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  try {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('trips')
        .doc(tripId)
        .update({
      'owners': FieldValue.arrayRemove([email])
    });
  } catch (e) {
    throw Exception('Error removing collaborator: $e');
  }
}
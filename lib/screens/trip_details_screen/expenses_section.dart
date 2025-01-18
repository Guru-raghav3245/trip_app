import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'full_image_viewer.dart';
import 'package:trip_app/services/riverpod_providers.dart';

class ExpensesSection extends ConsumerWidget {
  final DateTime date;
  final Map<DateTime, List<Map<String, dynamic>>> expenses;
  final Map<DateTime, String> notes;
  final String currency;
  final String tripId;
  final TextEditingController expenseNameController;
  final TextEditingController expenseAmountController;
  final TextEditingController noteController;

  const ExpensesSection({
    super.key,
    required this.date,
    required this.expenses,
    required this.notes,
    required this.currency,
    required this.tripId,
    required this.expenseNameController,
    required this.expenseAmountController,
    required this.noteController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imagePathsProvider = ref.watch(imagesProvider(tripId));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(color: Colors.grey[300]),

          // Expenses Section
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Expenses:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if ((expenses[date] ?? []).isEmpty)
                    const Text(
                      'No expenses added yet.',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ...((expenses[date] ?? []).map((expense) => ListTile(
                        leading:
                            const Icon(Icons.shopping_bag, color: Colors.indigo),
                        title: Text(
                          expense['name'],
                          style: const TextStyle(fontSize: 16),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$currency${expense['amount'].toStringAsFixed(2)}',
                              style: const TextStyle(
                                  fontSize: 14, color: Colors.red),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                ref
                                    .read(expensesProvider(tripId).notifier)
                                    .removeExpense(date, expense);
                              },
                            ),
                          ],
                        ),
                      ))),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Images Section
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Photos:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if ((imagePathsProvider[date] ?? []).isEmpty)
                    const Text(
                      'No photos added yet.',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  if ((imagePathsProvider[date] ?? []).isNotEmpty)
                    SizedBox(
                      height: 100,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: (imagePathsProvider[date] ?? [])
                            .map((imagePath) => Padding(
                                  padding: const EdgeInsets.all(4.0),
                                  child: Stack(
                                    children: [
                                      GestureDetector(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  FullScreenImageViewer(
                                                imagePath: imagePath,
                                              ),
                                            ),
                                          );
                                        },
                                        child: Hero(
                                          tag: imagePath,
                                          child: Container(
                                            width: 100,
                                            height: 100,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                  color: Colors.grey.shade300),
                                            ),
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              child: Image.file(
                                                File(imagePath),
                                                width: 100,
                                                height: 100,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        top: 5,
                                        right: 5,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.black.withOpacity(0.5),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: IconButton(
                                            icon: const Icon(Icons.delete,
                                                color: Colors.white, size: 20),
                                            onPressed: () {
                                              ref
                                                  .read(imagesProvider(tripId)
                                                      .notifier)
                                                  .removeImage(date, imagePath);
                                            },
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ))
                            .toList(),
                      ),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Notes Section
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Notes:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (notes[date] == null || notes[date]!.isEmpty)
                    const Text(
                      'No notes for this day.',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  if (notes[date] != null && notes[date]!.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        notes[date]!,
                        style: const TextStyle(
                            fontSize: 14, color: Colors.black87),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

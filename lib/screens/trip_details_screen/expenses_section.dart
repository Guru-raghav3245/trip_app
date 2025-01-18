import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'full_image_viewer.dart';
import 'package:image_picker/image_picker.dart';
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
    Key? key,
    required this.date,
    required this.expenses,
    required this.notes,
    required this.currency,
    required this.tripId,
    required this.expenseNameController,
    required this.expenseAmountController,
    required this.noteController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imagePathsProvider = ref.watch(imagesProvider(tripId));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(color: Colors.grey[300]),
          if ((expenses[date] ?? []).isNotEmpty)
            ...(expenses[date] ?? []).map((expense) => ListTile(
                  leading: const Icon(Icons.shopping_bag, color: Colors.indigo),
                  title: Text(
                    expense['name'],
                    style: const TextStyle(fontSize: 16),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$currency${expense['amount'].toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 14, color: Colors.red),
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
                )),
          const SizedBox(height: 8),

          // Add Expense Section
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: expenseNameController,
                      decoration: InputDecoration(
                        hintText: 'Expense Name',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: expenseAmountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'Amount',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle, color: Colors.green),
                    onPressed: () {
                      if (expenseNameController.text.isNotEmpty &&
                          double.tryParse(expenseAmountController.text) != null) {
                        final expense = {
                          'name': expenseNameController.text,
                          'amount': double.parse(expenseAmountController.text),
                        };

                        ref
                            .read(expensesProvider(tripId).notifier)
                            .addExpense(date, expense);

                        expenseNameController.clear();
                        expenseAmountController.clear();
                      }
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Images Section
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Photos:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.camera, color: Colors.indigo),
                    onPressed: () async {
                      final picker = ImagePicker();
                      final pickedFile = await picker.pickImage(source: ImageSource.camera);

                      if (pickedFile != null) {
                        ref.read(imagesProvider(tripId).notifier).addImage(
                              date,
                              pickedFile.path,
                            );
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.photo_library, color: Colors.indigo),
                    onPressed: () async {
                      final picker = ImagePicker();
                      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

                      if (pickedFile != null) {
                        ref.read(imagesProvider(tripId).notifier).addImage(
                              date,
                              pickedFile.path,
                            );
                      }
                    },
                  ),
                ],
              ),
              if ((imagePathsProvider[date] ?? []).isNotEmpty)
                SizedBox(
                  height: 100,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: (imagePathsProvider[date] ?? []).map((imagePath) {
                      return Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Stack(
                          children: [
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => FullScreenImageViewer(
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
                                    borderRadius: BorderRadius.circular(8),
                                    border:
                                        Border.all(color: Colors.grey.shade300),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
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
                                  color: Colors.black.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.white, size: 20),
                                  onPressed: () {
                                    ref
                                        .read(imagesProvider(tripId).notifier)
                                        .removeImage(date, imagePath);
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 8),

          // Notes Section
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Notes:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: noteController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Add a note for this day...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle, color: Colors.green),
                    onPressed: () {
                      if (noteController.text.isNotEmpty) {
                        final existingNotes = notes[date] ?? '';

                        final combinedNotes = existingNotes.isNotEmpty
                            ? '$existingNotes\n${noteController.text}'
                            : noteController.text;

                        ref.read(notesProvider(tripId).notifier).updateNote(
                              date,
                              combinedNotes,
                            );

                        noteController.clear();
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (notes[date] != null && notes[date]!.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    notes[date]!,
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

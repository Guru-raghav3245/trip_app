import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:trip_app/services/riverpod_providers.dart';

class AddTripContentScreen extends ConsumerStatefulWidget {
  final String tripId;
  final DateTime initialDate;
  final DateTime startDate;
  final DateTime endDate;
  
  const AddTripContentScreen({
    required this.tripId,
    required this.initialDate,
    required this.startDate,
    required this.endDate,
    super.key,
  });

  @override
  ConsumerState<AddTripContentScreen> createState() => _AddTripContentScreenState();
}

class _AddTripContentScreenState extends ConsumerState<AddTripContentScreen> {
  late DateTime selectedDate;
  final TextEditingController expenseNameController = TextEditingController();
  final TextEditingController expenseAmountController = TextEditingController();
  final TextEditingController noteController = TextEditingController();
  List<String> newImagePaths = [];

  @override
  void initState() {
    super.initState();
    selectedDate = widget.initialDate;
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: widget.startDate,  
      lastDate: widget.endDate,     
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  void _addExpense() {
    if (expenseNameController.text.isNotEmpty &&
        double.tryParse(expenseAmountController.text) != null) {
      final expense = {
        'name': expenseNameController.text,
        'amount': double.parse(expenseAmountController.text),
      };

      ref.read(expensesProvider(widget.tripId).notifier).addExpense(
        selectedDate,
        expense,
      );

      // Clear expense fields after adding
      expenseNameController.clear();
      expenseAmountController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Expense added successfully!')),
      );
    }
  }

  Future<void> _addImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        newImagePaths.add(pickedFile.path);
      });
      
      ref.read(imagesProvider(widget.tripId).notifier).addImage(
        selectedDate,
        pickedFile.path,
      );
    }
  }

  void _addNote() {
    if (noteController.text.isNotEmpty) {
      // Get existing notes for the date
      final existingNotes = ref.read(notesProvider(widget.tripId))[selectedDate] ?? '';
      
      // Combine existing notes with new note
      final combinedNotes = existingNotes.isNotEmpty
          ? '$existingNotes\n${noteController.text}'
          : noteController.text;

      ref.read(notesProvider(widget.tripId).notifier).updateNote(
        selectedDate,
        combinedNotes,
      );

      // Clear note field after adding
      noteController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Note added successfully!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = ref.watch(currencyProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Add Trip Content'),
        backgroundColor: Colors.indigoAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Selection
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Date: ${DateFormat('MMM d, y').format(selectedDate)}',
                      style: TextStyle(fontSize: 18),
                    ),
                    TextButton(
                      onPressed: () => _selectDate(context),
                      child: Text('Change Date'),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 20),

            // Expense Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add Expense',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    TextField(
                      controller: expenseNameController,
                      decoration: InputDecoration(
                        labelText: 'Expense Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 10),
                    TextField(
                      controller: expenseAmountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Amount ($currency)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: _addExpense,
                      child: Text('Add Expense'),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 20),

            // Images Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add Images',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _addImage(ImageSource.camera),
                          icon: Icon(Icons.camera_alt),
                          label: Text('Camera'),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => _addImage(ImageSource.gallery),
                          icon: Icon(Icons.photo_library),
                          label: Text('Gallery'),
                        ),
                      ],
                    ),
                    if (newImagePaths.isNotEmpty) ...[
                      SizedBox(height: 10),
                      Container(
                        height: 100,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: newImagePaths.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Image.file(
                                File(newImagePaths[index]),
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            SizedBox(height: 20),

            // Notes Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add Note',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    TextField(
                      controller: noteController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Enter your note...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: _addNote,
                      child: Text('Add Note'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
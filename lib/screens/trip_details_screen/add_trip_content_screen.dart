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
  ConsumerState<AddTripContentScreen> createState() =>
      _AddTripContentScreenState();
}

class _AddTripContentScreenState extends ConsumerState<AddTripContentScreen> {
  late DateTime selectedDate;
  final TextEditingController expenseNameController = TextEditingController();
  final TextEditingController expenseAmountController = TextEditingController();
  final TextEditingController noteController = TextEditingController();
  List<String> newImagePaths = [];

  // Track which sections are expanded
  Map<String, bool> expandedSections = {
    'date': true,
    'expense': false,
    'images': false,
    'notes': false,
  };

  @override
  void initState() {
    super.initState();
    selectedDate = widget.initialDate;
  }

  void _toggleSection(String section) {
    setState(() {
      expandedSections[section] = !(expandedSections[section] ?? false);
    });
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
      final existingNotes =
          ref.read(notesProvider(widget.tripId))[selectedDate] ?? '';

      final combinedNotes = existingNotes.isNotEmpty
          ? '$existingNotes\n${noteController.text}'
          : noteController.text;

      ref.read(notesProvider(widget.tripId).notifier).updateNote(
            selectedDate,
            combinedNotes,
          );

      noteController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Note added successfully!')),
      );
    }
  }

  Widget _buildAccordionCard({
    required String title,
    required String sectionKey,
    required Widget content,
    IconData? icon,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Column(
        children: [
          InkWell(
            onTap: () => _toggleSection(sectionKey),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      if (icon != null) ...[
                        Icon(icon, color: Colors.indigoAccent),
                        SizedBox(width: 8),
                      ],
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    expandedSections[sectionKey] ?? false
                        ? Icons.expand_less
                        : Icons.expand_more,
                    color: Colors.indigoAccent,
                  ),
                ],
              ),
            ),
          ),
          if (expandedSections[sectionKey] ?? false)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: content,
            ),
        ],
      ),
    );
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
        child: Column(
          children: [
            // Date Selection Card
            _buildAccordionCard(
              title: 'Select Date',
              sectionKey: 'date',
              icon: Icons.calendar_today,
              content: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat('MMM d, y').format(selectedDate),
                    style: TextStyle(fontSize: 16),
                  ),
                  TextButton.icon(
                    onPressed: () => _selectDate(context),
                    icon: Icon(Icons.edit_calendar),
                    label: Text('Change'),
                  ),
                ],
              ),
            ),

            // Expense Card
            _buildAccordionCard(
              title: 'Add Expense',
              sectionKey: 'expense',
              icon: Icons.attach_money,
              content: Column(
                children: [
                  TextField(
                    controller: expenseNameController,
                    decoration: InputDecoration(
                      labelText: 'Expense Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: expenseAmountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Amount ($currency)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _addExpense,
                    icon: Icon(Icons.add),
                    label: Text('Add Expense'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigoAccent,
                    ),
                  ),
                ],
              ),
            ),

            // Images Card
            _buildAccordionCard(
              title: 'Add Images',
              sectionKey: 'images',
              icon: Icons.photo_camera,
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _addImage(ImageSource.camera),
                        icon: Icon(Icons.camera_alt),
                        label: Text('Camera'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigoAccent,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _addImage(ImageSource.gallery),
                        icon: Icon(Icons.photo_library),
                        label: Text('Gallery'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigoAccent,
                        ),
                      ),
                    ],
                  ),
                  if (newImagePaths.isNotEmpty) ...[
                    SizedBox(height: 16),
                    Container(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: newImagePaths.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Stack(
                              children: [
                                Image.file(
                                  File(newImagePaths[index]),
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                ),
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: IconButton(
                                    icon: Icon(Icons.close, color: Colors.red),
                                    onPressed: () {
                                      setState(() {
                                        newImagePaths.removeAt(index);
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Notes Card
            _buildAccordionCard(
              title: 'Add Note',
              sectionKey: 'notes',
              icon: Icons.note_add,
              content: Column(
                children: [
                  TextField(
                    controller: noteController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Enter your note...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _addNote,
                    icon: Icon(Icons.save),
                    label: Text('Save Note'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigoAccent,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

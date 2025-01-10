import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:currency_picker/currency_picker.dart';
import 'package:trip_app/services/riverpod_providers.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'full_image_viewer.dart';


class TripDetailsPage extends ConsumerStatefulWidget {
  final Map<String, dynamic> trip;

  const TripDetailsPage({required this.trip, super.key});

  @override
  ConsumerState<TripDetailsPage> createState() => _TripDetailsPageState();
}

class _TripDetailsPageState extends ConsumerState<TripDetailsPage> {
  late List<DateTime> tripDates;
  Set<DateTime> expandedDates = {};

  final TextEditingController expenseNameController = TextEditingController();
  final TextEditingController expenseAmountController = TextEditingController();
  final TextEditingController noteController = TextEditingController();

  @override
  @override
  void initState() {
    super.initState();
    
    final startDate = widget.trip['startDate'] as DateTime? ?? DateTime.now();
    final endDate = widget.trip['endDate'] as DateTime? ?? DateTime.now();

    tripDates = List.generate(
      endDate.difference(startDate).inDays + 1,
      (i) => startDate.add(Duration(days: i)),
    );
    
  }


  double _calculateTotalExpenses(
      DateTime date, Map<DateTime, List<Map<String, dynamic>>> expenses) {
    return expenses[date]
            ?.fold(0.0, (sum, expense) => sum! + (expense['amount'] ?? 0.0)) ??
        0.0;
  }

  void _showCurrencySelector(String selectedCurrency) {
    showCurrencyPicker(
      context: context,
      showFlag: true,
      showCurrencyName: true,
      showCurrencyCode: true,
      onSelect: (Currency currency) {
        ref.read(currencyProvider.notifier).updateCurrency(currency.symbol);
      },
    );
  }

  void _addExpense(DateTime date, String tripId) {
    if (expenseNameController.text.isNotEmpty &&
        double.tryParse(expenseAmountController.text) != null) {
      final expense = {
        'name': expenseNameController.text,
        'amount': double.parse(expenseAmountController.text),
      };

      // Use the Riverpod provider to add expense
      ref.read(expensesProvider(tripId).notifier).addExpense(date, expense);

      // Clear input fields after adding expense
      expenseNameController.clear();
      expenseAmountController.clear();
    }
  }

  Future<void> _captureImage(DateTime date, String tripId) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      final imageFile = File(pickedFile.path);
      ref.read(imagesProvider(tripId).notifier).addImage(date, imageFile.path);
    }
  }

  Future<void> _selectFromGallery(DateTime date, String tripId) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final imageFile = File(pickedFile.path);
      ref.read(imagesProvider(tripId).notifier).addImage(date, imageFile.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use the trip ID to create trip-specific providers
    final tripId = widget.trip['id'];
    final expenses = ref.watch(expensesProvider(tripId));
    final notes = ref.watch(notesProvider(tripId));
    final currency = ref.watch(currencyProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.trip['title'] ?? 'Trip Details',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.indigoAccent,
        actions: [
          IconButton(
            icon: Icon(Icons.currency_exchange),
            onPressed: () => _showCurrencySelector(currency),
          ),
        ],
      ),
      body: Column(
        children: [
          // Header Section
          Card(
            margin: const EdgeInsets.all(16.0),
            color: Colors.indigo[50],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0),
            ),
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Trip Overview',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                 Text(
                    'Duration: ${DateFormat.yMMMd().format(widget.trip['startDate'])} - '
                    '${DateFormat.yMMMd().format(widget.trip['endDate'])}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),

          // Expenses List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              children: tripDates
                  .map((date) =>
                      _buildDateTile(date, expenses, notes, currency, tripId))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateTile(
      DateTime date,
      Map<DateTime, List<Map<String, dynamic>>> expenses,
      Map<DateTime, String> notes,
      String currency,
      String tripId) {
    bool isExpanded = expandedDates.contains(date);
    double totalExpenses = _calculateTotalExpenses(date, expenses);

    return Card(
      key: ValueKey(date),
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        children: [
          ListTile(
            title: Row(
              children: [
                const Icon(Icons.calendar_today,
                    size: 20, color: Colors.indigo),
                const SizedBox(width: 8),
                Text(
                  DateFormat.yMMMd().format(date),
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$currency${totalExpenses.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 16, color: Colors.green),
                ),
                IconButton(
                  icon: Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.blueAccent,
                  ),
                  onPressed: () {
                    setState(() {
                      if (isExpanded) {
                        expandedDates.remove(date);
                      } else {
                        expandedDates.add(date);
                      }
                    });
                  },
                ),
              ],
            ),
          ),
          if (isExpanded)
            _buildExpensesSection(date, expenses, notes, currency, tripId),
        ],
      ),
    );
  }

  Widget _buildExpensesSection(
      DateTime date,
      Map<DateTime, List<Map<String, dynamic>>> expenses,
      Map<DateTime, String> notes,
      String currency,
      String tripId) {
    final imagePathsProvider =
        ref.watch(imagesProvider(tripId)); // Add image paths provider

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
                    onPressed: () => _addExpense(date, tripId),
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
                    onPressed: () => _captureImage(date, tripId),
                  ),
                  IconButton(
                    icon: const Icon(Icons.photo_library, color: Colors.indigo),
                    onPressed: () => _selectFromGallery(date, tripId),
                  ),
                ],
              ),
              // In the _buildExpensesSection method of TripDetailsPage, update the Images Section:
// Replace the existing image display code with this:

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
              TextField(
                controller: noteController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Add a note for this day...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                onSubmitted: (value) {
                  // Update the note for the specific date in Riverpod state
                  ref
                      .read(notesProvider(tripId).notifier)
                      .updateNote(date, value);
                },
              ),
              const SizedBox(height: 8),
              if (notes[date] != null && notes[date]!.isNotEmpty)
                Text(
                  notes[date]!,
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

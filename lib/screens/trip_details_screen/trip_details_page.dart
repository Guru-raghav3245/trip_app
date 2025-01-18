import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:currency_picker/currency_picker.dart';
import 'package:trip_app/services/riverpod_providers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:trip_app/services/trip_service.dart';
import 'package:trip_app/screens/trip_details_screen/add_trip_content_screen.dart';
import 'expenses_section.dart';

// Trip Details Page.
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
  String? selectedFolderId;
  bool showingAllDates = true;

  @override
  void initState() {
    super.initState();

    final startDateTimestamp = widget.trip['startDate'];
    final endDateTimestamp = widget.trip['endDate'];

    final startDate = (startDateTimestamp is Timestamp)
        ? startDateTimestamp.toDate()
        : (startDateTimestamp as DateTime? ?? DateTime.now());
    final endDate = (endDateTimestamp is Timestamp)
        ? endDateTimestamp.toDate()
        : (endDateTimestamp as DateTime? ?? DateTime.now());

    tripDates = List.generate(
      endDate.difference(startDate).inDays + 1,
      (i) => startDate.add(Duration(days: i)),
    );
  }

  void _showCreateFolderDialog() {
    final TextEditingController titleController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Create New Folder'),
        content: TextField(
          controller: titleController,
          decoration: InputDecoration(
            hintText: 'Enter folder name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (titleController.text.isNotEmpty) {
                ref
                    .read(dateFoldersProvider(widget.trip['id']).notifier)
                    .addFolder(titleController.text);
                Navigator.pop(context);
              }
            },
            child: Text('Create'),
          ),
        ],
      ),
    );
  }

  // Calculate the total expenses for a specific date
  double _calculateTotalExpenses(
      DateTime date, Map<DateTime, List<Map<String, dynamic>>> expenses) {
    return expenses[date]
            ?.fold(0.0, (sum, expense) => sum! + (expense['amount'] ?? 0.0)) ??
        0.0;
  }

  // Show the currency selector
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

  List<DateTime> _getFilteredDates() {
    if (showingAllDates || selectedFolderId == null) {
      return tripDates;
    }

    final folders = ref.watch(dateFoldersProvider(widget.trip['id']));
    final selectedFolder = folders.firstWhere(
      (folder) => folder.id == selectedFolderId,
      orElse: () => DateFolder(id: '', title: '', dates: []),
    );

    return selectedFolder.dates;
  }

  void _toggleFolderSelection(String folderId) {
    setState(() {
      if (selectedFolderId == folderId) {
        // If clicking the same folder again, show all dates
        selectedFolderId = null;
        showingAllDates = true;
      } else {
        // If clicking a different folder, show only folder dates
        selectedFolderId = folderId;
        showingAllDates = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Use the trip ID to create trip-specific providers
    final tripId = widget.trip['id'];
    final expenses = ref.watch(expensesProvider(tripId));
    final notes = ref.watch(notesProvider(tripId));
    final currency = ref.watch(currencyProvider);
    final folders = ref.watch(dateFoldersProvider(tripId));

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
          IconButton(
            icon: Icon(Icons.create_new_folder),
            onPressed: _showCreateFolderDialog,
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
                    'Duration: ${DateFormat.yMMMd().format(widget.trip['startDate'].toDate())} - '
                    '${DateFormat.yMMMd().format(widget.trip['endDate'].toDate())}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (folders.isNotEmpty) _buildFoldersSection(folders, tripId),
                ],
              ),
            ),
          ),
          Expanded(
            child: Scrollbar(
              thumbVisibility: true, // Makes the scrollbar always visible
              thickness: 8.0, // Adjust the width of the scrollbar
              radius: Radius.circular(16.0), // Make the scrollbar rounded
              trackVisibility: true, // Show the scrollbar track
              interactive:
                  true, // Allows clicking on the scrollbar for interaction
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                children: _getFilteredDates().map((date) {
                  return Draggable<DateTime>(
                    data: date,
                    feedback: Material(
                      child: Container(
                        padding: EdgeInsets.all(8),
                        color: Colors.indigo.withOpacity(0.5),
                        child: Text(
                          DateFormat.yMMMd().format(date),
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                    child:
                        _buildDateTile(date, expenses, notes, currency, tripId),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final startDate = (widget.trip['startDate'] as Timestamp).toDate();
          final endDate = (widget.trip['endDate'] as Timestamp).toDate();

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddTripContentScreen(
                tripId: widget.trip['id'],
                initialDate: DateTime.now(),
                startDate: startDate, // Pass trip start date
                endDate: endDate,
              ),
            ),
          );
        },
        label: Text('Add Content'),
        icon: Icon(Icons.add),
        backgroundColor: Colors.indigoAccent,
      ),
    );
  }

  // Build a date tile
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
            ExpensesSection(
              date: date,
              expenses: expenses,
              notes: notes,
              currency: currency,
              tripId: tripId,
              expenseNameController: expenseNameController,
              expenseAmountController: expenseAmountController,
              noteController: noteController,
            ),
        ],
      ),
    );
  }

  Widget _buildFolderCard(DateFolder folder, String tripId) {
    final isSelected = selectedFolderId == folder.id;

    return DragTarget<DateTime>(
      onAccept: (date) {
        ref
            .read(dateFoldersProvider(tripId).notifier)
            .addDateToFolder(folder.id, date);
      },
      builder: (context, candidateData, rejectedData) {
        return GestureDetector(
          onTap: () => _toggleFolderSelection(folder.id),
          child: Card(
            margin: EdgeInsets.all(8),
            color: isSelected ? Colors.indigo[100] : null,
            child: Container(
              width: 200, // Increased width to accommodate dates
              padding: EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          folder.title,
                          style: TextStyle(fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, size: 20),
                        onPressed: () {
                          if (selectedFolderId == folder.id) {
                            setState(() {
                              selectedFolderId = null;
                              showingAllDates = true;
                            });
                          }
                          ref
                              .read(dateFoldersProvider(tripId).notifier)
                              .removeFolder(folder.id);
                        },
                      ),
                    ],
                  ),
                  Text('${folder.dates.length} dates'),
                  if (isSelected && folder.dates.isNotEmpty)
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        itemCount: folder.dates.length,
                        itemBuilder: (context, index) {
                          final date = folder.dates[index];
                          return ListTile(
                            dense: true,
                            title: Text(
                              DateFormat('MMM d, y').format(date),
                              style: TextStyle(fontSize: 12),
                            ),
                            trailing: IconButton(
                              icon: Icon(Icons.close, size: 16),
                              onPressed: () {
                                ref
                                    .read(dateFoldersProvider(tripId).notifier)
                                    .removeDateFromFolder(folder.id, date);
                              },
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

// Update the _buildFoldersSection to allow scrolling and show all folders:
  Widget _buildFoldersSection(List<DateFolder> folders, String tripId) {
    if (folders.isEmpty) return SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            'Folders',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(
          height: 200, // Increased height to show more content
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: folders.length,
            itemBuilder: (context, index) =>
                _buildFolderCard(folders[index], tripId),
          ),
        ),
      ],
    );
  }
}

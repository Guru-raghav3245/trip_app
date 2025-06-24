import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:currency_picker/currency_picker.dart';
import 'package:trip_app/services/riverpod_providers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:trip_app/screens/trip_details_screen/add_trip_content_screen.dart';
import 'expenses_section.dart';
import 'dart:math';

class TripDetailsPage extends ConsumerStatefulWidget {
  final Map<String, dynamic> trip;

  const TripDetailsPage({required this.trip, super.key});

  @override
  ConsumerState<TripDetailsPage> createState() => _TripDetailsPageState();
}

class _TripDetailsPageState extends ConsumerState<TripDetailsPage> {
  late List<DateTime> tripDates;
  Set<DateTime> expandedDates = {};
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _folderNameController = TextEditingController();
  final TextEditingController expenseNameController = TextEditingController();
  final TextEditingController expenseAmountController = TextEditingController();
  final TextEditingController noteController = TextEditingController();

  // Folder state
  final Map<String, List<DateTime>> _folders = {};
  DateTime? _draggedDate;
  String? _draggedFromFolder;

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

  @override
  void dispose() {
    _scrollController.dispose();
    _folderNameController.dispose();
    super.dispose();
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

  void _showCreateFolderDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Create New Folder'),
          content: TextField(
            controller: _folderNameController,
            decoration: const InputDecoration(hintText: 'Folder name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (_folderNameController.text.trim().isNotEmpty) {
                  setState(() {
                    _folders[_folderNameController.text.trim()] = [];
                    _folderNameController.clear();
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteFolderDialog(String folderName) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Folder'),
          content: Text('Are you sure you want to delete "$folderName"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _folders.remove(folderName);
                });
                Navigator.pop(context);
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _onDragStarted(DateTime date, String? fromFolder) {
    setState(() {
      _draggedDate = date;
      _draggedFromFolder = fromFolder;
    });
  }

  void _onDragEnded() {
    setState(() {
      _draggedDate = null;
      _draggedFromFolder = null;
    });
  }

  void _onFolderDropped(String folderName) {
    if (_draggedDate == null) return;

    setState(() {
      // Remove from previous location
      if (_draggedFromFolder != null) {
        _folders[_draggedFromFolder]?.remove(_draggedDate);
      } else {
        tripDates.remove(_draggedDate);
      }

      // Add to new folder
      _folders[folderName]?.add(_draggedDate!);
      _draggedDate = null;
      _draggedFromFolder = null;
    });
  }

  void _onUnfolderDropped() {
    if (_draggedDate == null || _draggedFromFolder == null) return;

    setState(() {
      _folders[_draggedFromFolder]?.remove(_draggedDate);
      tripDates.add(_draggedDate!);
      tripDates.sort();
      _draggedDate = null;
      _draggedFromFolder = null;
    });
  }

  Widget _buildFolderSection() {
    if (_folders.isEmpty) {
      return Container();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            'Folders',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        ..._folders.entries.map((entry) {
          final folderName = entry.key;
          final datesInFolder = entry.value;

          return DragTarget<DateTime>(
            onAccept: (date) => _onFolderDropped(folderName),
            builder: (context, candidateData, rejectedData) {
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.folder, color: Colors.amber),
                      title: Text(folderName),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('${datesInFolder.length} items'),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _showDeleteFolderDialog(folderName),
                          ),
                        ],
                      ),
                    ),
                    ...datesInFolder.map((date) => _buildDateTile(
                          date,
                          ref.watch(expensesProvider(widget.trip['id'])),
                          ref.watch(notesProvider(widget.trip['id'])),
                          ref.watch(currencyProvider),
                          widget.trip['id'],
                          inFolder: folderName,
                        )),
                  ],
                ),
              );
            },
          );
        }).toList(),
      ],
    );
  }

  Widget _buildDragHandle(BuildContext context, {String? inFolder}) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onLongPressStart: (details) {
        if (inFolder != null) {
          _onDragStarted(_draggedDate!, inFolder);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.drag_handle, size: 20),
      ),
    );
  }

  Widget _buildDateTile(
    DateTime date,
    Map<DateTime, List<Map<String, dynamic>>> expenses,
    Map<DateTime, String> notes,
    String currency,
    String tripId, {
    String? inFolder,
  }) {
    bool isExpanded = expandedDates.contains(date);
    double totalExpenses = _calculateTotalExpenses(date, expenses);

    return Draggable<DateTime>(
      data: date,
      feedback: Material(
        elevation: 4,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            DateFormat.yMMMd().format(date),
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ),
      childWhenDragging: Container(
        height: 60,
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      onDragStarted: () => _onDragStarted(date, inFolder),
      onDragEnd: (_) => _onDragEnded(),
      child: DragTarget<DateTime>(
        onAccept: (date) {
          if (inFolder != null) {
            _onFolderDropped(inFolder);
          }
        },
        builder: (context, candidateData, rejectedData) {
          return Card(
            key: ValueKey(date),
            elevation: 3,
            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            color: candidateData.isNotEmpty
                ? Colors.blue.withOpacity(0.1)
                : null,
            child: Column(
              children: [
                ListTile(
                  leading: _buildDragHandle(context, inFolder: inFolder),
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
                        style: const TextStyle(
                            fontSize: 16, color: Colors.green),
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
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.5,
                    ),
                    child: SingleChildScrollView(
                      child: ExpensesSection(
                        date: date,
                        expenses: expenses,
                        notes: notes,
                        currency: currency,
                        tripId: tripId,
                        expenseNameController: expenseNameController,
                        expenseAmountController: expenseAmountController,
                        noteController: noteController,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tripId = widget.trip['id'];
    final expenses = ref.watch(expensesProvider(tripId));
    final notes = ref.watch(notesProvider(tripId));
    final currency = ref.watch(currencyProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.trip['trip'] ?? 'Trip Details',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.indigoAccent,
        actions: [
          IconButton(
            icon: const Icon(Icons.currency_exchange),
            onPressed: () => _showCurrencySelector(currency),
          ),
          IconButton(
            icon: const Icon(Icons.create_new_folder),
            onPressed: _showCreateFolderDialog,
          ),
        ],
      ),
      body: Column(
        children: [
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
          Expanded(
            child: CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: _buildFolderSection(),
                ),
                SliverToBoxAdapter(
                  child: DragTarget<DateTime>(
                    onAccept: (date) => _onUnfolderDropped(),
                    builder: (context, candidateData, rejectedData) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Card(
                          color: candidateData.isNotEmpty
                              ? Colors.blue.withOpacity(0.1)
                              : null,
                          child: const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                Icon(Icons.folder_open, color: Colors.amber),
                                SizedBox(width: 8),
                                Text('Drop here to remove from folder'),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final date = tripDates[index];
                      return _buildDateTile(
                          date, expenses, notes, currency, tripId);
                    },
                    childCount: tripDates.length,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final startDate = widget.trip['startDate'];
          final endDate = widget.trip['endDate'];

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddTripContentScreen(
                tripId: widget.trip['id'],
                initialDate: DateTime.now(),
                startDate: startDate,
                endDate: endDate,
              ),
            ),
          );
        },
        label: const Text('Add Content'),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.indigoAccent,
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:currency_picker/currency_picker.dart';
import 'package:trip_app/services/riverpod_providers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:trip_app/services/trip_service.dart';
import 'package:trip_app/screens/trip_details_screen/add_trip_content_screen.dart';
import 'expenses_section.dart';

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

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _showCreateFolderDialog() {
    final TextEditingController titleController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Folder'),
        content: TextField(
          controller: titleController,
          decoration: const InputDecoration(
            hintText: 'Enter folder name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
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
            child: const Text('Create'),
          ),
        ],
      ),
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
        selectedFolderId = null;
        showingAllDates = true;
      } else {
        selectedFolderId = folderId;
        showingAllDates = false;
      }
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
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
                  if (folders.isNotEmpty)
                    _buildFoldersSection(folders, tripId),
                ],
              ),
            ),
          ),
          Expanded(
            child: CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final date = _getFilteredDates()[index];
                      return _buildDateTile(date, expenses, notes, currency, tripId);
                    },
                    childCount: _getFilteredDates().length,
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
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          ListTile(
            title: Row(
              children: [
                const Icon(Icons.calendar_today, size: 20, color: Colors.indigo),
                const SizedBox(width: 8),
                Text(
                  DateFormat.yMMMd().format(date),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.all(8),
            margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: isSelected 
                  ? Colors.indigo[100] 
                  : candidateData.isNotEmpty 
                      ? Colors.indigo[50] 
                      : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected 
                    ? Colors.indigoAccent 
                    : candidateData.isNotEmpty
                        ? Colors.indigo
                        : Colors.grey.shade300,
                width: isSelected || candidateData.isNotEmpty ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            width: 140,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        folder.title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.indigo.shade800,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent, size: 18),
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
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      '${folder.dates.length} ${folder.dates.length == 1 ? 'date' : 'dates'}',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFoldersSection(List<DateFolder> folders, String tripId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 8, bottom: 4),
          child: Text(
            'Folders',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo),
          ),
        ),
        SizedBox(
          height: 80,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: folders.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) => _buildFolderCard(folders[index], tripId),
          ),
        ),
      ],
    );
  }
}
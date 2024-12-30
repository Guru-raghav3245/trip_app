import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Provider to manage expenses with trip-specific support
final expensesProvider = StateNotifierProvider.family<ExpensesNotifier,
    Map<DateTime, List<Map<String, dynamic>>>, String>((ref, tripId) {
  return ExpensesNotifier(tripId);
});

/// Provider to manage notes with trip-specific support
final notesProvider =
    StateNotifierProvider.family<NotesNotifier, Map<DateTime, String>, String>(
        (ref, tripId) {
  return NotesNotifier(tripId);
});

/// Provider to manage the selected currency
final currencyProvider = StateNotifierProvider<CurrencyNotifier, String>((ref) {
  return CurrencyNotifier();
});

/// Expenses Notifier
class ExpensesNotifier
    extends StateNotifier<Map<DateTime, List<Map<String, dynamic>>>> {
  final String tripId;

  ExpensesNotifier(this.tripId) : super({}) {
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final expensesDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('trips')
        .doc(tripId)
        .get();

    if (expensesDoc.exists && expensesDoc.data()?['expenses'] != null) {
      final loadedExpenses =
          (expensesDoc.data()?['expenses'] as Map<String, dynamic>);
      state = loadedExpenses.map((key, value) => MapEntry(
          DateTime.tryParse(key) ?? DateTime.now(),
          List<Map<String, dynamic>>.from(value)));
    } else {
      state = {};
    }
  }

  void addExpense(DateTime date, Map<String, dynamic> expense) async {
    state = {
      ...state,
      date: [...(state[date] ?? []), expense],
    };
    await _saveExpensesToFirebase();
  }

  void removeExpense(DateTime date, Map<String, dynamic> expense) async {
    final updatedList = state[date]?.where((e) => e != expense).toList() ?? [];
    state = {
      ...state,
      date: updatedList,
    };
    await _saveExpensesToFirebase();
  }

  Future<void> _saveExpensesToFirebase() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Convert DateTime keys to string for Firebase storage
    final expensesMap = state
        .map((date, expenses) => MapEntry(date.toIso8601String(), expenses));

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('trips')
        .doc(tripId)
        .set({
      'expenses': expensesMap,
    }, SetOptions(merge: true));
  }
}

/// Notes Notifier
class NotesNotifier extends StateNotifier<Map<DateTime, String>> {
  final String tripId;

  NotesNotifier(this.tripId) : super({}) {
    _loadNotes();
  }

  void updateNote(DateTime date, String note) async {
    if (note.isNotEmpty) {
      state = {
        ...state,
        date: note,
      };
      await _saveNotesToFirebase();
    }
  }

  Future<void> _saveNotesToFirebase() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Convert DateTime keys to string for Firebase storage
    final notesMap =
        state.map((date, note) => MapEntry(date.toIso8601String(), note));

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('trips')
        .doc(tripId)
        .set({
      'notes': notesMap,
    }, SetOptions(merge: true));
  }

  Future<void> _loadNotes() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final notesDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('trips')
        .doc(tripId)
        .get();

    if (notesDoc.exists && notesDoc.data()?['notes'] != null) {
      final loadedNotes = (notesDoc.data()?['notes'] as Map<String, dynamic>);
      state = loadedNotes.map((key, value) =>
          MapEntry(DateTime.tryParse(key) ?? DateTime.now(), value.toString()));
    } else {
      state = {};
    }
  }
}

/// Currency Notifier
class CurrencyNotifier extends StateNotifier<String> {
  CurrencyNotifier() : super('\$'); // Default currency symbol

  void updateCurrency(String newCurrency) {
    state = newCurrency;
  }
}

final imagesProvider = StateNotifierProvider.family<ImagesNotifier, Map<DateTime, List<String>>, String>((ref, tripId) {
  return ImagesNotifier();
});

class ImagesNotifier extends StateNotifier<Map<DateTime, List<String>>> {
  ImagesNotifier() : super({});

  void addImage(DateTime date, String imagePath) {
    final images = state[date] ?? [];
    state = {...state, date: [...images, imagePath]};
  }

  void removeImage(DateTime date, String imagePath) {
    final images = state[date] ?? [];
    images.remove(imagePath);
    state = {...state, date: images};
  }
}

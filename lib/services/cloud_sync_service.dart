import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/budget_model.dart';
import '../models/category_model.dart';
import '../models/transaction_model.dart';

/// Exception thrown when cloud database operations fail
class CloudSyncException implements Exception {
  final String message;
  final String? code;

  const CloudSyncException(this.message, {this.code});

  @override
  String toString() => 'CloudSyncException: $message${code != null ? ' (code: $code)' : ''}';
}

/// Abstract contract for cloud database synchronization
abstract class ICloudSyncService {
  Future<List<TransactionModel>> fetchTransactions(String userId);
  Future<List<String>> fetchDeletedTransactionIds(String userId);
  Future<void> saveTransaction(String userId, TransactionModel transaction);
  Future<void> deleteTransaction(String userId, String transactionId);

  Future<List<CategoryModel>> fetchCustomCategories(String userId);
  Future<void> saveCustomCategory(String userId, CategoryModel category);
  Future<void> deleteCustomCategory(String userId, String categoryId);

  Future<BudgetModel?> fetchBudget(String userId);
  Future<void> saveBudget(String userId, BudgetModel budget);
}

/// Production Cloud Firestore implementation with per-user partitioning
/// and explicit error mapping for network, permission, and authentication failures.
class FirestoreSyncService implements ICloudSyncService {
  final FirebaseFirestore _firestore;

  FirestoreSyncService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _userTransactionsRef(String userId) {
    return _firestore.collection('users').doc(userId).collection('transactions');
  }

  CollectionReference<Map<String, dynamic>> _userCategoriesRef(String userId) {
    return _firestore.collection('users').doc(userId).collection('custom_categories');
  }

  DocumentReference<Map<String, dynamic>> _userBudgetRef(String userId) {
    return _firestore.collection('users').doc(userId).collection('budget').doc('current');
  }

  String _mapFirestoreErrorMessage(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return 'Access denied. You do not have permission to access these financial records.';
      case 'unavailable':
        return 'Cloud Firestore is currently unreachable. Records remain saved safely on your device.';
      case 'deadline-exceeded':
        return 'Connection timed out while syncing with cloud.';
      case 'unauthenticated':
        return 'Session expired. Please sign in again to sync records.';
      default:
        return e.message ?? 'Firestore error occurred (${e.code}).';
    }
  }

  @override
  Future<List<TransactionModel>> fetchTransactions(String userId) async {
    try {
      final snapshot = await _userTransactionsRef(userId).get();
      final List<TransactionModel> transactions = [];

      for (final doc in snapshot.docs) {
        final data = doc.data();
        if (data['isDeleted'] == true) continue;
        try {
          transactions.add(TransactionModel.fromJson(data));
        } catch (e) {
          // Skip corrupted or unparseable documents
        }
      }

      transactions.sort((a, b) => b.date.compareTo(a.date));
      return transactions;
    } on FirebaseException catch (e) {
      throw CloudSyncException(_mapFirestoreErrorMessage(e), code: e.code);
    } catch (e) {
      throw CloudSyncException(e.toString());
    }
  }

  @override
  Future<List<String>> fetchDeletedTransactionIds(String userId) async {
    try {
      final snapshot = await _userTransactionsRef(userId).get();
      final List<String> deletedIds = [];

      for (final doc in snapshot.docs) {
        final data = doc.data();
        if (data['isDeleted'] == true) {
          deletedIds.add(doc.id);
        }
      }

      return deletedIds;
    } on FirebaseException catch (e) {
      throw CloudSyncException(_mapFirestoreErrorMessage(e), code: e.code);
    } catch (e) {
      throw CloudSyncException(e.toString());
    }
  }

  @override
  Future<void> saveTransaction(String userId, TransactionModel transaction) async {
    try {
      // Idempotent write using stable transaction id as document ID, resetting isDeleted to false
      final toSave = transaction.copyWith(isDeleted: false);
      await _userTransactionsRef(userId).doc(toSave.id).set(
            toSave.toJson(),
            SetOptions(merge: true),
          );
    } on FirebaseException catch (e) {
      throw CloudSyncException(_mapFirestoreErrorMessage(e), code: e.code);
    } catch (e) {
      throw CloudSyncException(e.toString());
    }
  }

  @override
  Future<void> deleteTransaction(String userId, String transactionId) async {
    try {
      // Write cloud tombstone with isDeleted flag and UTC updatedAt so all devices honor the deletion
      await _userTransactionsRef(userId).doc(transactionId).set({
        'id': transactionId,
        'isDeleted': true,
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
      }, SetOptions(merge: true));
    } on FirebaseException catch (e) {
      throw CloudSyncException(_mapFirestoreErrorMessage(e), code: e.code);
    } catch (e) {
      throw CloudSyncException(e.toString());
    }
  }

  @override
  Future<List<CategoryModel>> fetchCustomCategories(String userId) async {
    try {
      final snapshot = await _userCategoriesRef(userId).get();
      return snapshot.docs
          .map((doc) => CategoryModel.fromJson(doc.data()))
          .toList();
    } on FirebaseException catch (e) {
      throw CloudSyncException(_mapFirestoreErrorMessage(e), code: e.code);
    } catch (e) {
      throw CloudSyncException(e.toString());
    }
  }

  @override
  Future<void> saveCustomCategory(String userId, CategoryModel category) async {
    try {
      // Idempotent write using category id as document ID
      await _userCategoriesRef(userId).doc(category.id).set(
            category.toJson(),
            SetOptions(merge: true),
          );
    } on FirebaseException catch (e) {
      throw CloudSyncException(_mapFirestoreErrorMessage(e), code: e.code);
    } catch (e) {
      throw CloudSyncException(e.toString());
    }
  }

  @override
  Future<void> deleteCustomCategory(String userId, String categoryId) async {
    try {
      await _userCategoriesRef(userId).doc(categoryId).delete();
    } on FirebaseException catch (e) {
      throw CloudSyncException(_mapFirestoreErrorMessage(e), code: e.code);
    } catch (e) {
      throw CloudSyncException(e.toString());
    }
  }

  @override
  Future<BudgetModel?> fetchBudget(String userId) async {
    try {
      final doc = await _userBudgetRef(userId).get();
      if (!doc.exists || doc.data() == null) return null;
      return BudgetModel.fromJson(doc.data()!);
    } on FirebaseException catch (e) {
      throw CloudSyncException(_mapFirestoreErrorMessage(e), code: e.code);
    } catch (e) {
      throw CloudSyncException(e.toString());
    }
  }

  @override
  Future<void> saveBudget(String userId, BudgetModel budget) async {
    try {
      await _userBudgetRef(userId).set(
            budget.toJson(),
            SetOptions(merge: true),
          );
    } on FirebaseException catch (e) {
      throw CloudSyncException(_mapFirestoreErrorMessage(e), code: e.code);
    } catch (e) {
      throw CloudSyncException(e.toString());
    }
  }
}

/// In-memory mock cloud sync service for offline operation and deterministic testing
class MockCloudSyncService implements ICloudSyncService {
  final Map<String, List<TransactionModel>> _userTransactions = {};
  final Map<String, Set<String>> _userDeletedTransactionIds = {};
  final Map<String, List<CategoryModel>> _userCategories = {};
  final Map<String, BudgetModel> _userBudgets = {};

  bool shouldFail = false;

  void _checkFailure() {
    if (shouldFail) {
      throw const CloudSyncException(
        'Simulated network/cloud connection failure',
        code: 'unavailable',
      );
    }
  }

  @override
  Future<List<TransactionModel>> fetchTransactions(String userId) async {
    _checkFailure();
    return List.from((_userTransactions[userId] ?? []).where((t) => !t.isDeleted));
  }

  @override
  Future<List<String>> fetchDeletedTransactionIds(String userId) async {
    _checkFailure();
    return (_userDeletedTransactionIds[userId] ?? {}).toList();
  }

  @override
  Future<void> saveTransaction(String userId, TransactionModel transaction) async {
    _checkFailure();
    _userDeletedTransactionIds[userId]?.remove(transaction.id);
    final list = _userTransactions.putIfAbsent(userId, () => []);
    final idx = list.indexWhere((t) => t.id == transaction.id);
    final restored = transaction.copyWith(isDeleted: false);
    if (idx != -1) {
      list[idx] = restored;
    } else {
      list.insert(0, restored);
    }
  }

  @override
  Future<void> deleteTransaction(String userId, String transactionId) async {
    _checkFailure();
    _userTransactions[userId]?.removeWhere((t) => t.id == transactionId);
    _userDeletedTransactionIds.putIfAbsent(userId, () => {}).add(transactionId);
  }

  @override
  Future<List<CategoryModel>> fetchCustomCategories(String userId) async {
    _checkFailure();
    return List.from(_userCategories[userId] ?? []);
  }

  @override
  Future<void> saveCustomCategory(String userId, CategoryModel category) async {
    _checkFailure();
    final list = _userCategories.putIfAbsent(userId, () => []);
    final idx = list.indexWhere((c) => c.id == category.id);
    if (idx != -1) {
      list[idx] = category;
    } else {
      list.add(category);
    }
  }

  @override
  Future<void> deleteCustomCategory(String userId, String categoryId) async {
    _checkFailure();
    _userCategories[userId]?.removeWhere((c) => c.id == categoryId);
  }

  @override
  Future<BudgetModel?> fetchBudget(String userId) async {
    _checkFailure();
    return _userBudgets[userId];
  }

  @override
  Future<void> saveBudget(String userId, BudgetModel budget) async {
    _checkFailure();
    _userBudgets[userId] = budget;
  }
}

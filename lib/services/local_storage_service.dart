import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/budget_model.dart';
import '../models/category_model.dart';
import '../models/transaction_model.dart';

/// Local Storage Service abstract contract for testability, DI, and user scoping
abstract class ILocalStorageService {
  Future<List<TransactionModel>> getTransactions({String? userId});
  Future<bool> saveTransactions(List<TransactionModel> transactions, {String? userId});
  Future<BudgetModel?> getBudget({String? userId});
  Future<bool> saveBudget(BudgetModel budget, {String? userId});
  Future<List<CategoryModel>> getCustomCategories({String? userId});
  Future<bool> saveCustomCategories(List<CategoryModel> categories, {String? userId});
  Future<bool> isFirstLaunch();
  Future<void> setFirstLaunchCompleted();
  Future<void> clearAll({String? userId});

  // Offline deletion tombstone management
  Future<List<String>> getDeletedTransactionIds({String? userId});
  Future<void> recordDeletedTransactionId(String id, {String? userId});
  Future<void> removeDeletedTransactionId(String id, {String? userId});
  Future<void> clearDeletedTransactionIds({String? userId});
}

/// Robust Local Storage implementation with user-scoped isolation and tombstone tracking
class LocalStorageService implements ILocalStorageService {
  static const String keyTransactions = 'spendly_transactions_v1';
  static const String keyBudget = 'spendly_budget_v1';
  static const String keyFirstLaunch = 'spendly_first_launch_v1';
  static const String keyCustomCategories = 'spendly_custom_categories_v1';
  static const String keyTombstones = 'spendly_tombstones_v1';

  SharedPreferences? _prefs;

  Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // Key resolvers for multi-user isolation
  String _txKey(String? userId) => (userId != null && userId.isNotEmpty && userId != 'anonymous')
      ? 'spendly_user_${userId}_transactions_v1'
      : keyTransactions;

  String _budgetKey(String? userId) => (userId != null && userId.isNotEmpty && userId != 'anonymous')
      ? 'spendly_user_${userId}_budget_v1'
      : keyBudget;

  String _catKey(String? userId) => (userId != null && userId.isNotEmpty && userId != 'anonymous')
      ? 'spendly_user_${userId}_categories_v1'
      : keyCustomCategories;

  String _tombstonesKey(String? userId) => (userId != null && userId.isNotEmpty && userId != 'anonymous')
      ? 'spendly_user_${userId}_tombstones_v1'
      : keyTombstones;

  @override
  Future<bool> isFirstLaunch() async {
    try {
      final prefs = await _getPrefs();
      return prefs.getBool(keyFirstLaunch) ?? true;
    } catch (e) {
      debugPrint('[LocalStorageService] Error reading isFirstLaunch: $e');
      return true;
    }
  }

  @override
  Future<void> setFirstLaunchCompleted() async {
    try {
      final prefs = await _getPrefs();
      await prefs.setBool(keyFirstLaunch, false);
    } catch (e) {
      debugPrint('[LocalStorageService] Error setting first launch completed: $e');
    }
  }

  @override
  Future<List<TransactionModel>> getTransactions({String? userId}) async {
    try {
      final prefs = await _getPrefs();
      final key = _txKey(userId);
      final jsonString = prefs.getString(key);
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }

      final decoded = jsonDecode(jsonString);
      if (decoded is! List) {
        debugPrint('[LocalStorageService] Corrupted payload: expected List but got ${decoded.runtimeType}');
        return [];
      }

      final List<TransactionModel> transactions = [];
      for (final item in decoded) {
        if (item is Map<String, dynamic>) {
          try {
            transactions.add(TransactionModel.fromMap(item));
          } catch (e) {
            debugPrint('[LocalStorageService] Skipped corrupted transaction item: $e');
          }
        } else if (item is Map) {
          try {
            transactions.add(TransactionModel.fromMap(Map<String, dynamic>.from(item)));
          } catch (e) {
            debugPrint('[LocalStorageService] Skipped invalid map transaction item: $e');
          }
        }
      }
      return transactions;
    } catch (e) {
      debugPrint('[LocalStorageService] Error decoding transactions: $e');
      return [];
    }
  }

  @override
  Future<bool> saveTransactions(List<TransactionModel> transactions, {String? userId}) async {
    try {
      final prefs = await _getPrefs();
      final key = _txKey(userId);
      final serializedList = transactions.map((t) => t.toMap()).toList();
      final jsonString = jsonEncode(serializedList);
      return await prefs.setString(key, jsonString);
    } catch (e) {
      debugPrint('[LocalStorageService] Error saving transactions: $e');
      return false;
    }
  }

  @override
  Future<BudgetModel?> getBudget({String? userId}) async {
    try {
      final prefs = await _getPrefs();
      final key = _budgetKey(userId);
      final jsonString = prefs.getString(key);
      if (jsonString == null || jsonString.isEmpty) {
        return null;
      }

      final decoded = jsonDecode(jsonString);
      if (decoded is Map<String, dynamic>) {
        return BudgetModel.fromMap(decoded);
      } else if (decoded is Map) {
        return BudgetModel.fromMap(Map<String, dynamic>.from(decoded));
      }
      return null;
    } catch (e) {
      debugPrint('[LocalStorageService] Error decoding budget: $e');
      return null;
    }
  }

  @override
  Future<bool> saveBudget(BudgetModel budget, {String? userId}) async {
    try {
      final prefs = await _getPrefs();
      final key = _budgetKey(userId);
      final jsonString = jsonEncode(budget.toMap());
      return await prefs.setString(key, jsonString);
    } catch (e) {
      debugPrint('[LocalStorageService] Error saving budget: $e');
      return false;
    }
  }

  @override
  Future<List<CategoryModel>> getCustomCategories({String? userId}) async {
    try {
      final prefs = await _getPrefs();
      final key = _catKey(userId);
      final jsonString = prefs.getString(key);
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }

      final decoded = jsonDecode(jsonString);
      if (decoded is! List) {
        return [];
      }

      final List<CategoryModel> categories = [];
      for (final item in decoded) {
        if (item is Map<String, dynamic>) {
          try {
            categories.add(CategoryModel.fromMap(item));
          } catch (e) {
            debugPrint('[LocalStorageService] Skipped corrupted category item: $e');
          }
        } else if (item is Map) {
          try {
            categories.add(CategoryModel.fromMap(Map<String, dynamic>.from(item)));
          } catch (e) {
            debugPrint('[LocalStorageService] Skipped invalid map category item: $e');
          }
        }
      }
      return categories;
    } catch (e) {
      debugPrint('[LocalStorageService] Error decoding custom categories: $e');
      return [];
    }
  }

  @override
  Future<bool> saveCustomCategories(List<CategoryModel> categories, {String? userId}) async {
    try {
      final prefs = await _getPrefs();
      final key = _catKey(userId);
      final serializedList = categories.map((c) => c.toMap()).toList();
      final jsonString = jsonEncode(serializedList);
      return await prefs.setString(key, jsonString);
    } catch (e) {
      debugPrint('[LocalStorageService] Error saving custom categories: $e');
      return false;
    }
  }

  // Tombstones for Offline Deletions
  @override
  Future<List<String>> getDeletedTransactionIds({String? userId}) async {
    try {
      final prefs = await _getPrefs();
      final key = _tombstonesKey(userId);
      return prefs.getStringList(key) ?? [];
    } catch (e) {
      debugPrint('[LocalStorageService] Error reading tombstones: $e');
      return [];
    }
  }

  @override
  Future<void> recordDeletedTransactionId(String id, {String? userId}) async {
    try {
      final prefs = await _getPrefs();
      final key = _tombstonesKey(userId);
      final list = prefs.getStringList(key) ?? [];
      if (!list.contains(id)) {
        list.add(id);
        await prefs.setStringList(key, list);
      }
    } catch (e) {
      debugPrint('[LocalStorageService] Error recording tombstone: $e');
    }
  }

  @override
  Future<void> removeDeletedTransactionId(String id, {String? userId}) async {
    try {
      final prefs = await _getPrefs();
      final key = _tombstonesKey(userId);
      final list = prefs.getStringList(key) ?? [];
      if (list.remove(id)) {
        await prefs.setStringList(key, list);
      }
    } catch (e) {
      debugPrint('[LocalStorageService] Error removing tombstone: $e');
    }
  }

  @override
  Future<void> clearDeletedTransactionIds({String? userId}) async {
    try {
      final prefs = await _getPrefs();
      final key = _tombstonesKey(userId);
      await prefs.remove(key);
    } catch (e) {
      debugPrint('[LocalStorageService] Error clearing tombstones: $e');
    }
  }

  @override
  Future<void> clearAll({String? userId}) async {
    try {
      final prefs = await _getPrefs();
      if (userId != null && userId.isNotEmpty && userId != 'anonymous') {
        await prefs.remove(_txKey(userId));
        await prefs.remove(_budgetKey(userId));
        await prefs.remove(_catKey(userId));
        await prefs.remove(_tombstonesKey(userId));
      } else {
        await prefs.remove(keyTransactions);
        await prefs.remove(keyBudget);
        await prefs.remove(keyCustomCategories);
        await prefs.remove(keyFirstLaunch);
        await prefs.remove(keyTombstones);
      }
    } catch (e) {
      debugPrint('[LocalStorageService] Error clearing local storage: $e');
    }
  }
}

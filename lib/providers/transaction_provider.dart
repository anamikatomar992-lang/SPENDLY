import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../config/firebase_config.dart';
import '../models/transaction_model.dart';
import '../models/budget_model.dart';
import '../models/category_model.dart';
import '../models/financial_summary_model.dart';
import '../models/financial_insight_model.dart';
import '../models/monthly_data_point.dart';
import '../models/sync_status.dart';
import '../services/smart_insights_service.dart';
import '../services/local_storage_service.dart';
import '../services/cloud_sync_service.dart';
import '../services/cloud_migration_service.dart';
import '../utils/sample_data.dart';

/// Supported timeframes for financial intelligence and analytics reporting
enum AnalyticsTimeframe {
  thisMonth,
  lastMonth,
  allTime,
  custom,
}

class TransactionProvider with ChangeNotifier {
  final ILocalStorageService _storageService;
  final ICloudSyncService _cloudSync;

  List<TransactionModel> _transactions = [];
  List<CategoryModel> _customCategories = [];
  BudgetModel _currentBudget = SampleData.getMonthlyBudget();
  bool _isLoading = false;
  String? _errorMessage;
  bool _isBalanceVisible = true;

  // Cloud Synchronization State
  String? _currentUserId;
  SyncStatus _syncStatus = SyncStatus.localOnly;
  String? _lastSyncError;
  bool _isSyncing = false;

  // Filter & Search State
  String _searchQuery = '';
  String _selectedTypeFilter = 'All'; // 'All', 'Expense', 'Income'
  String? _selectedCategoryId; // null = all
  TransactionSortOrder _selectedSortOrder = TransactionSortOrder.dateDescending;

  // Analytics Timeframe State
  AnalyticsTimeframe _selectedTimeframe = AnalyticsTimeframe.thisMonth;
  DateTimeRange? _customDateRange;
  int _trendPeriodMonths = 6; // 3, 6, or 12 months for multi-month trend charts

  // Undo Delete Buffer
  TransactionModel? _lastDeletedTransaction;
  int? _lastDeletedIndex;

  TransactionProvider({
    ILocalStorageService? storageService,
    ICloudSyncService? cloudSyncService,
  })  : _storageService = storageService ?? LocalStorageService(),
        _cloudSync = cloudSyncService ??
            (FirebaseConfig.isRealFirebaseActive
                ? FirestoreSyncService()
                : MockCloudSyncService()) {
    loadTransactions();
  }

  // Getters
  List<TransactionModel> get transactions => List.unmodifiable(_transactions);
  List<CategoryModel> get customCategories => List.unmodifiable(_customCategories);
  List<CategoryModel> get allCategories => [...CategoryModel.defaultCategories, ..._customCategories];

  BudgetModel get currentBudget => _currentBudget;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isBalanceVisible => _isBalanceVisible;

  String get searchQuery => _searchQuery;
  String get selectedTypeFilter => _selectedTypeFilter;
  String? get selectedCategoryId => _selectedCategoryId;
  TransactionSortOrder get selectedSortOrder => _selectedSortOrder;
  bool get canUndoDelete => _lastDeletedTransaction != null;

  AnalyticsTimeframe get selectedTimeframe => _selectedTimeframe;
  DateTimeRange? get customDateRange => _customDateRange;
  int get trendPeriodMonths => _trendPeriodMonths;
  SyncStatus get syncStatus => _syncStatus;
  String? get lastSyncError => _lastSyncError;
  String? get currentUserId => _currentUserId;
  bool get isMockActive => _cloudSync is MockCloudSyncService;
  String get syncStatusLabel => _syncStatus.getLabel(isMock: isMockActive);

  void toggleBalanceVisibility() {
    _isBalanceVisible = !_isBalanceVisible;
    notifyListeners();
  }

  void setTrendPeriod(int months) {
    if (_trendPeriodMonths != months && months > 0) {
      _trendPeriodMonths = months;
      notifyListeners();
    }
  }

  /// Sets the active authenticated user ID and triggers cloud migration/sync.
  /// When logging out (userId == null), resets to local state without erasing
  /// the logged-out user's local or cloud records.
  Future<void> setUserId(String? userId, {bool importDemoData = false}) async {
    _currentUserId = userId;
    if (userId == null) {
      _syncStatus = SyncStatus.localOnly;
      _lastSyncError = null;
      // Reload anonymous dataset upon logout so a guest never sees the previous user's data
      _transactions = await _storageService.getTransactions();
      _customCategories = await _storageService.getCustomCategories();
      final anonBudget = await _storageService.getBudget();
      if (anonBudget != null) _currentBudget = anonBudget;
      CategoryModel.customRegistry = _customCategories;
      notifyListeners();
    } else {
      await syncWithCloud(importDemoData: importDemoData);
    }
  }

  /// Executes idempotent synchronization between local storage and Cloud Firestore.
  /// Skips demo data unless [importDemoData] is explicitly consented by the user.
  Future<bool> syncWithCloud({bool importDemoData = false}) async {
    if (_currentUserId == null) {
      _syncStatus = SyncStatus.localOnly;
      _lastSyncError = null;
      notifyListeners();
      return false;
    }

    if (_isSyncing) {
      debugPrint('[TransactionProvider] Sync already in progress. Ignoring concurrent trigger.');
      return false;
    }

    _isSyncing = true;
    _syncStatus = SyncStatus.syncing;
    notifyListeners();

    try {
      final migration = CloudMigrationService(
        localStorage: _storageService,
        cloudSync: _cloudSync,
      );

      final result = await migration.migrateLocalToCloud(
        _currentUserId!,
        importDemoData: importDemoData,
      );

      if (result.isSuccess) {
        // Refresh in-memory state from the newly merged user-scoped dataset
        _transactions = await _storageService.getTransactions(userId: _currentUserId);
        _customCategories = await _storageService.getCustomCategories(userId: _currentUserId);
        final loadedBudget = await _storageService.getBudget(userId: _currentUserId);
        if (loadedBudget != null) {
          _currentBudget = loadedBudget;
        }
        CategoryModel.customRegistry = _customCategories;
        _syncStatus = SyncStatus.synced;
        _lastSyncError = null;
        notifyListeners();
        return true;
      } else {
        _syncStatus = SyncStatus.syncFailed;
        _lastSyncError = result.errorMessage ?? 'Synchronization failed. Changes preserved locally.';
        notifyListeners();
        return false;
      }
    } on CloudSyncException catch (e) {
      _syncStatus = SyncStatus.syncFailed;
      _lastSyncError = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _syncStatus = SyncStatus.syncFailed;
      _lastSyncError = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isSyncing = false;
    }
  }

  // Filter and Search Mutations
  void setSearchQuery(String query) {
    _searchQuery = query.trim();
    notifyListeners();
  }

  void setTypeFilter(String filter) {
    _selectedTypeFilter = filter;
    notifyListeners();
  }

  void setCategoryFilter(String? categoryId) {
    _selectedCategoryId = categoryId;
    notifyListeners();
  }

  void setSortOrder(TransactionSortOrder order) {
    _selectedSortOrder = order;
    notifyListeners();
  }

  void resetFilters() {
    _searchQuery = '';
    _selectedTypeFilter = 'All';
    _selectedCategoryId = null;
    _selectedSortOrder = TransactionSortOrder.dateDescending;
    notifyListeners();
  }

  // Analytics Timeframe Mutations
  void setTimeframe(AnalyticsTimeframe timeframe, [DateTimeRange? customRange]) {
    _selectedTimeframe = timeframe;
    if (timeframe == AnalyticsTimeframe.custom && customRange != null) {
      _customDateRange = customRange;
    }
    notifyListeners();
  }

  /// Loads transactions, custom categories, and budgets from local storage
  Future<void> loadTransactions() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final isFirst = await _storageService.isFirstLaunch();

      if (isFirst) {
        // First launch: initialize with realistic seed data
        _transactions = SampleData.getInitialTransactions();
        _currentBudget = SampleData.getMonthlyBudget();
        _customCategories = [];

        await _storageService.saveTransactions(_transactions, userId: _currentUserId);
        await _storageService.saveBudget(_currentBudget, userId: _currentUserId);
        await _storageService.saveCustomCategories(_customCategories, userId: _currentUserId);
        await _storageService.setFirstLaunchCompleted();
      } else {
        // Subsequent launches: read persisted user transactions from disk
        _transactions = await _storageService.getTransactions(userId: _currentUserId);
        _customCategories = await _storageService.getCustomCategories(userId: _currentUserId);

        final loadedBudget = await _storageService.getBudget(userId: _currentUserId);
        if (loadedBudget != null) {
          _currentBudget = loadedBudget;
        }
      }

      CategoryModel.customRegistry = _customCategories;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load financial records from local storage: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Category Helper
  CategoryModel getCategoryById(String id) {
    return CategoryModel.findById(id, allCategories);
  }

  int getTransactionCountForCategory(String categoryId) {
    return _transactions
        .where((t) => t.categoryId.toLowerCase() == categoryId.toLowerCase())
        .length;
  }

  // Custom Category CRUD
  Future<void> addCategory(CategoryModel category) async {
    _customCategories.add(category);
    CategoryModel.customRegistry = _customCategories;
    notifyListeners();
    await _storageService.saveCustomCategories(_customCategories, userId: _currentUserId);

    if (_currentUserId != null) {
      _syncStatus = SyncStatus.syncing;
      notifyListeners();
      try {
        await _cloudSync.saveCustomCategory(_currentUserId!, category);
        _syncStatus = SyncStatus.synced;
        _lastSyncError = null;
        notifyListeners();
      } on CloudSyncException catch (e) {
        _syncStatus = SyncStatus.syncFailed;
        _lastSyncError = e.message;
        notifyListeners();
      } catch (e) {
        _syncStatus = SyncStatus.syncFailed;
        _lastSyncError = 'Failed to sync category: $e';
        notifyListeners();
      }
    }
  }

  Future<void> updateCategory(CategoryModel updatedCategory) async {
    final idx = _customCategories.indexWhere((c) => c.id == updatedCategory.id);
    if (idx != -1) {
      _customCategories[idx] = updatedCategory;
      CategoryModel.customRegistry = _customCategories;
      notifyListeners();
      await _storageService.saveCustomCategories(_customCategories, userId: _currentUserId);

      if (_currentUserId != null) {
        _syncStatus = SyncStatus.syncing;
        notifyListeners();
        try {
          await _cloudSync.saveCustomCategory(_currentUserId!, updatedCategory);
          _syncStatus = SyncStatus.synced;
          _lastSyncError = null;
          notifyListeners();
        } on CloudSyncException catch (e) {
          _syncStatus = SyncStatus.syncFailed;
          _lastSyncError = e.message;
          notifyListeners();
        } catch (e) {
          _syncStatus = SyncStatus.syncFailed;
          _lastSyncError = 'Failed to sync category update: $e';
          notifyListeners();
        }
      }
    }
  }

  Future<bool> deleteCategory(String categoryId, {String? replacementCategoryId}) async {
    // Default categories cannot be deleted
    final isDefault = CategoryModel.defaultCategories.any((c) => c.id == categoryId);
    if (isDefault) return false;

    final inUseCount = getTransactionCountForCategory(categoryId);
    if (inUseCount > 0) {
      if (replacementCategoryId == null || replacementCategoryId.isEmpty) {
        // Cannot delete in-use category without a replacement
        return false;
      }

      // Reassign all associated transactions to the replacement category
      _transactions = _transactions.map((tx) {
        if (tx.categoryId.toLowerCase() == categoryId.toLowerCase()) {
          return tx.copyWith(
            categoryId: replacementCategoryId,
            updatedAt: DateTime.now().toUtc(),
          );
        }
        return tx;
      }).toList();

      await _storageService.saveTransactions(_transactions, userId: _currentUserId);
    }

    _customCategories.removeWhere((c) => c.id == categoryId);
    CategoryModel.customRegistry = _customCategories;
    notifyListeners();
    await _storageService.saveCustomCategories(_customCategories, userId: _currentUserId);

    if (_currentUserId != null) {
      _syncStatus = SyncStatus.syncing;
      notifyListeners();
      try {
        await _cloudSync.deleteCustomCategory(_currentUserId!, categoryId);
        _syncStatus = SyncStatus.synced;
        _lastSyncError = null;
        notifyListeners();
      } on CloudSyncException catch (e) {
        _syncStatus = SyncStatus.syncFailed;
        _lastSyncError = e.message;
        notifyListeners();
      } catch (e) {
        _syncStatus = SyncStatus.syncFailed;
        _lastSyncError = 'Failed to delete category: $e';
        notifyListeners();
      }
    }
    return true;
  }

  // Filtered & Sorted Transactions Engine
  List<TransactionModel> get filteredTransactions {
    final list = _transactions.where((tx) {
      // Type Filter
      if (_selectedTypeFilter == 'Expense' && !tx.isExpense) return false;
      if (_selectedTypeFilter == 'Income' && !tx.isIncome) return false;

      // Category Filter
      if (_selectedCategoryId != null &&
          tx.categoryId.toLowerCase() != _selectedCategoryId!.toLowerCase()) {
        return false;
      }

      // Search Query
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesTitle = tx.title.toLowerCase().contains(query);
        final matchesCategory = tx.category.name.toLowerCase().contains(query);
        final matchesNote = tx.note?.toLowerCase().contains(query) ?? false;
        final matchesAmount = tx.amount.toString().contains(query);
        if (!matchesTitle && !matchesCategory && !matchesNote && !matchesAmount) {
          return false;
        }
      }

      return true;
    }).toList();

    // Apply Sorting
    switch (_selectedSortOrder) {
      case TransactionSortOrder.dateDescending:
        list.sort((a, b) => b.date.compareTo(a.date));
        break;
      case TransactionSortOrder.dateAscending:
        list.sort((a, b) => a.date.compareTo(b.date));
        break;
      case TransactionSortOrder.amountDescending:
        list.sort((a, b) => b.amount.compareTo(a.amount));
        break;
      case TransactionSortOrder.amountAscending:
        list.sort((a, b) => a.amount.compareTo(b.amount));
        break;
    }

    return list;
  }

  // Transactions filtered by selected Analytics timeframe
  List<TransactionModel> get timeframeTransactions {
    final now = DateTime.now();

    switch (_selectedTimeframe) {
      case AnalyticsTimeframe.thisMonth:
        return _transactions.where((t) {
          return t.date.year == now.year && t.date.month == now.month;
        }).toList();

      case AnalyticsTimeframe.lastMonth:
        final prevMonth = now.month == 1 ? 12 : now.month - 1;
        final prevYear = now.month == 1 ? now.year - 1 : now.year;
        return _transactions.where((t) {
          return t.date.year == prevYear && t.date.month == prevMonth;
        }).toList();

      case AnalyticsTimeframe.allTime:
        return _transactions;

      case AnalyticsTimeframe.custom:
        if (_customDateRange == null) return _transactions;
        final start = DateTime(
          _customDateRange!.start.year,
          _customDateRange!.start.month,
          _customDateRange!.start.day,
        );
        final end = DateTime(
          _customDateRange!.end.year,
          _customDateRange!.end.month,
          _customDateRange!.end.day,
          23,
          59,
          59,
        );
        return _transactions.where((t) {
          return !t.date.isBefore(start) && !t.date.isAfter(end);
        }).toList();
    }
  }

  // Computed Financial Metrics (Global All-Time)
  double get totalIncome {
    return _transactions
        .where((t) => t.isIncome)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get totalExpense {
    return _transactions
        .where((t) => t.isExpense)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get totalBalance => totalIncome - totalExpense;

  // Monthly Metrics (Current Calendar Month & Year)
  List<TransactionModel> get currentMonthTransactions {
    final now = DateTime.now();
    return _transactions.where((t) {
      return t.date.year == now.year && t.date.month == now.month;
    }).toList();
  }

  double get monthlyIncome {
    return currentMonthTransactions
        .where((t) => t.isIncome)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get monthlyExpense {
    return currentMonthTransactions
        .where((t) => t.isExpense)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get monthlySavings => (monthlyIncome - monthlyExpense);

  double get monthlySavingsPercentage {
    if (monthlyIncome <= 0) return 0.0;
    if (monthlySavings <= 0) return 0.0;
    final pct = (monthlySavings / monthlyIncome) * 100.0;
    return pct.clamp(0.0, 100.0);
  }

  // Budget Metrics
  double get budgetLimit => _currentBudget.limitAmount;
  double get budgetConsumed => monthlyExpense;
  double get budgetRemaining => (budgetLimit - monthlyExpense).clamp(0.0, double.infinity);

  double get budgetProgressPercentage {
    if (budgetLimit <= 0) return 0.0;
    return (monthlyExpense / budgetLimit).clamp(0.0, 1.0);
  }

  bool get isBudgetNearLimit => budgetProgressPercentage >= 0.75 && budgetProgressPercentage < 1.0;
  bool get isBudgetExceeded => monthlyExpense > budgetLimit;

  // Sorted Recent Transactions (Top 5)
  List<TransactionModel> get recentTransactions {
    final sorted = List<TransactionModel>.from(_transactions);
    sorted.sort((a, b) => b.date.compareTo(a.date));
    return sorted;
  }

  // Category-wise expense breakdown for selected Analytics timeframe
  Map<CategoryModel, double> get categoryExpenseBreakdown {
    final Map<CategoryModel, double> breakdown = {};
    for (final tx in timeframeTransactions.where((t) => t.isExpense)) {
      final cat = getCategoryById(tx.categoryId);
      breakdown[cat] = (breakdown[cat] ?? 0.0) + tx.amount;
    }
    return breakdown;
  }

  // Financial Intelligence Summary Objects
  FinancialSummary get analyticsSummary {
    return FinancialSummary.fromTransactions(
      transactions: timeframeTransactions,
      allCategories: allCategories,
      dateRange: _selectedTimeframe == AnalyticsTimeframe.custom ? _customDateRange : null,
    );
  }

  FinancialSummary get monthlySummary {
    return FinancialSummary.fromTransactions(
      transactions: currentMonthTransactions,
      allCategories: allCategories,
    );
  }

  /// Multi-month chronological metrics for spending trend analysis and grouped bar charts
  List<MonthlyDataPoint> get historicalMonthlyData {
    final now = DateTime.now();
    final List<MonthlyDataPoint> points = [];

    for (int i = _trendPeriodMonths - 1; i >= 0; i--) {
      final monthDate = DateTime(now.year, now.month - i, 1);
      final y = monthDate.year;
      final m = monthDate.month;
      final label = DateFormat('MMM').format(monthDate);

      final monthTxs = _transactions.where((t) => t.date.year == y && t.date.month == m);
      final inc = monthTxs.where((t) => t.isIncome).fold(0.0, (sum, t) => sum + t.amount);
      final exp = monthTxs.where((t) => t.isExpense).fold(0.0, (sum, t) => sum + t.amount);

      points.add(MonthlyDataPoint(
        year: y,
        month: m,
        monthLabel: label,
        income: inc,
        expense: exp,
      ));
    }
    return points;
  }

  /// Current month vs previous month comparison
  MonthOverMonthComparison get monthOverMonthComparison {
    final now = DateTime.now();
    final prevMonthDate = DateTime(now.year, now.month - 1, 1);

    final currentTxs = _transactions.where((t) => t.date.year == now.year && t.date.month == now.month);
    final prevTxs = _transactions.where((t) => t.date.year == prevMonthDate.year && t.date.month == prevMonthDate.month);

    final currentPoint = MonthlyDataPoint(
      year: now.year,
      month: now.month,
      monthLabel: DateFormat('MMM').format(now),
      income: currentTxs.where((t) => t.isIncome).fold(0.0, (sum, t) => sum + t.amount),
      expense: currentTxs.where((t) => t.isExpense).fold(0.0, (sum, t) => sum + t.amount),
    );

    MonthlyDataPoint? prevPoint;
    if (prevTxs.isNotEmpty) {
      prevPoint = MonthlyDataPoint(
        year: prevMonthDate.year,
        month: prevMonthDate.month,
        monthLabel: DateFormat('MMM').format(prevMonthDate),
        income: prevTxs.where((t) => t.isIncome).fold(0.0, (sum, t) => sum + t.amount),
        expense: prevTxs.where((t) => t.isExpense).fold(0.0, (sum, t) => sum + t.amount),
      );
    }

    return MonthOverMonthComparison(
      currentMonth: currentPoint,
      previousMonth: prevPoint,
    );
  }

  /// Current month budget utilization and burn rate analytics
  BudgetUtilizationAnalytics get budgetUtilization {
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final daysPassed = now.day;

    return BudgetUtilizationAnalytics(
      budgetLimit: budgetLimit,
      budgetSpent: monthlyExpense,
      daysPassedInMonth: daysPassed,
      totalDaysInMonth: daysInMonth,
    );
  }

  /// Rule-based dynamic financial insights generated from actual user data
  List<FinancialInsight> get smartInsights {
    return SmartInsightsService.generateInsights(
      currentMonthSummary: monthlySummary,
      momComparison: monthOverMonthComparison,
      budgetUtilization: budgetUtilization,
    );
  }

  // CRUD Operations with Local Storage Sync, Tombstones & Cloud Propagation
  Future<void> addTransaction(TransactionModel transaction) async {
    final stamped = transaction.copyWith(updatedAt: DateTime.now().toUtc());
    _transactions.insert(0, stamped);
    notifyListeners();
    await _storageService.saveTransactions(_transactions, userId: _currentUserId);

    if (_currentUserId != null) {
      _syncStatus = SyncStatus.syncing;
      notifyListeners();
      try {
        await _cloudSync.saveTransaction(_currentUserId!, stamped);
        _syncStatus = SyncStatus.synced;
        _lastSyncError = null;
        notifyListeners();
      } on CloudSyncException catch (e) {
        _syncStatus = SyncStatus.syncFailed;
        _lastSyncError = e.message;
        notifyListeners();
      } catch (e) {
        _syncStatus = SyncStatus.syncFailed;
        _lastSyncError = 'Failed to sync transaction: $e';
        notifyListeners();
      }
    }
  }

  Future<void> updateTransaction(TransactionModel updatedTransaction) async {
    final index = _transactions.indexWhere((t) => t.id == updatedTransaction.id);
    if (index != -1) {
      final stamped = updatedTransaction.copyWith(updatedAt: DateTime.now().toUtc());
      _transactions[index] = stamped;
      notifyListeners();
      await _storageService.saveTransactions(_transactions, userId: _currentUserId);

      if (_currentUserId != null) {
        _syncStatus = SyncStatus.syncing;
        notifyListeners();
        try {
          await _cloudSync.saveTransaction(_currentUserId!, stamped);
          _syncStatus = SyncStatus.synced;
          _lastSyncError = null;
          notifyListeners();
        } on CloudSyncException catch (e) {
          _syncStatus = SyncStatus.syncFailed;
          _lastSyncError = e.message;
          notifyListeners();
        } catch (e) {
          _syncStatus = SyncStatus.syncFailed;
          _lastSyncError = 'Failed to sync update: $e';
          notifyListeners();
        }
      }
    }
  }

  Future<TransactionModel?> deleteTransaction(String id) async {
    final index = _transactions.indexWhere((t) => t.id == id);
    if (index != -1) {
      final deleted = _transactions.removeAt(index);
      _lastDeletedTransaction = deleted;
      _lastDeletedIndex = index;
      notifyListeners();
      await _storageService.saveTransactions(_transactions, userId: _currentUserId);

      // Record offline deletion tombstone persistently
      await _storageService.recordDeletedTransactionId(id, userId: _currentUserId);

      if (_currentUserId != null) {
        _syncStatus = SyncStatus.syncing;
        notifyListeners();
        try {
          await _cloudSync.deleteTransaction(_currentUserId!, id);
          _syncStatus = SyncStatus.synced;
          _lastSyncError = null;
          notifyListeners();
        } on CloudSyncException catch (e) {
          _syncStatus = SyncStatus.syncFailed;
          _lastSyncError = e.message;
          notifyListeners();
        } catch (e) {
          _syncStatus = SyncStatus.syncFailed;
          _lastSyncError = 'Failed to sync deletion: $e';
          notifyListeners();
        }
      }
      return deleted;
    }
    return null;
  }

  Future<bool> undoDelete() async {
    if (_lastDeletedTransaction != null) {
      final targetIndex = _lastDeletedIndex != null && _lastDeletedIndex! <= _transactions.length
          ? _lastDeletedIndex!
          : 0;
      final restored = _lastDeletedTransaction!.copyWith(
        updatedAt: DateTime.now().toUtc(),
        isDeleted: false,
      );
      _transactions.insert(targetIndex, restored);
      _lastDeletedTransaction = null;
      _lastDeletedIndex = null;
      notifyListeners();
      await _storageService.saveTransactions(_transactions, userId: _currentUserId);

      // Remove tombstone since transaction has been restored
      await _storageService.removeDeletedTransactionId(restored.id, userId: _currentUserId);

      if (_currentUserId != null) {
        _syncStatus = SyncStatus.syncing;
        notifyListeners();
        try {
          await _cloudSync.saveTransaction(_currentUserId!, restored);
          _syncStatus = SyncStatus.synced;
          _lastSyncError = null;
          notifyListeners();
        } on CloudSyncException catch (e) {
          _syncStatus = SyncStatus.syncFailed;
          _lastSyncError = e.message;
          notifyListeners();
        } catch (e) {
          _syncStatus = SyncStatus.syncFailed;
          _lastSyncError = 'Failed to sync restore: $e';
          notifyListeners();
        }
      }
      return true;
    }
    return false;
  }

  Future<void> updateBudgetLimit(double newLimit) async {
    final now = DateTime.now().toUtc();
    _currentBudget = _currentBudget.copyWith(
      limitAmount: newLimit,
      month: now.month,
      year: now.year,
    );
    notifyListeners();
    await _storageService.saveBudget(_currentBudget, userId: _currentUserId);

    if (_currentUserId != null) {
      _syncStatus = SyncStatus.syncing;
      notifyListeners();
      try {
        await _cloudSync.saveBudget(_currentUserId!, _currentBudget);
        _syncStatus = SyncStatus.synced;
        _lastSyncError = null;
        notifyListeners();
      } on CloudSyncException catch (e) {
        _syncStatus = SyncStatus.syncFailed;
        _lastSyncError = e.message;
        notifyListeners();
      } catch (e) {
        _syncStatus = SyncStatus.syncFailed;
        _lastSyncError = 'Failed to sync budget: $e';
        notifyListeners();
      }
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spendly/main.dart';
import 'package:spendly/models/category_model.dart';
import 'package:spendly/models/financial_summary_model.dart';
import 'package:spendly/models/transaction_model.dart';
import 'package:spendly/models/monthly_data_point.dart';
import 'package:spendly/models/budget_model.dart';
import 'package:spendly/models/sync_status.dart';
import 'package:spendly/providers/auth_provider.dart';
import 'package:spendly/providers/transaction_provider.dart';
import 'package:spendly/services/auth_service.dart';
import 'package:spendly/services/cloud_sync_service.dart';
import 'package:spendly/services/cloud_migration_service.dart';
import 'package:spendly/services/local_storage_service.dart';
import 'package:spendly/services/smart_insights_service.dart';
import 'package:spendly/config/firebase_config.dart';
import 'package:spendly/firebase_options.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Phase 2: LocalStorageService Unit Tests', () {
    test('Saves and retrieves transactions and detects first launch', () async {
      SharedPreferences.setMockInitialValues({});
      final service = LocalStorageService();

      expect(await service.isFirstLaunch(), isTrue);

      final testTx = [
        TransactionModel(
          id: 'test-1',
          title: 'Coffee and Pastry',
          amount: 6.50,
          date: DateTime(2026, 10, 1),
          categoryId: 'food',
          type: TransactionType.expense,
        ),
      ];

      await service.saveTransactions(testTx);
      await service.setFirstLaunchCompleted();

      expect(await service.isFirstLaunch(), isFalse);
      final loaded = await service.getTransactions();
      expect(loaded.length, 1);
      expect(loaded.first.title, 'Coffee and Pastry');
      expect(loaded.first.amount, 6.50);
    });

    test('Corrupted JSON payloads recover safely without crashing', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(LocalStorageService.keyTransactions, 'INVALID_CORRUPTED_JSON{{[');
      await prefs.setString(LocalStorageService.keyBudget, 'CORRUPTED_BUDGET_DATA');
      await prefs.setString(LocalStorageService.keyCustomCategories, 'CORRUPTED_CATEGORIES');

      final service = LocalStorageService();
      final transactions = await service.getTransactions();
      expect(transactions, isEmpty);

      final budget = await service.getBudget();
      expect(budget, isNull);

      final categories = await service.getCustomCategories();
      expect(categories, isEmpty);
    });

    test('Model validation rules function correctly', () {
      expect(TransactionModel.validateTitle(''), 'Please enter a transaction title');
      expect(TransactionModel.validateTitle('a' * 65), 'Title cannot exceed 60 characters');
      expect(TransactionModel.validateTitle('Valid Title'), isNull);

      expect(TransactionModel.validateAmount(''), 'Please enter an amount');
      expect(TransactionModel.validateAmount('abc'), 'Please enter a valid numeric amount');
      expect(TransactionModel.validateAmount('0'), 'Amount must be greater than zero');
      expect(TransactionModel.validateAmount('-5'), 'Amount must be greater than zero');
      expect(TransactionModel.validateAmount('250000000'), 'Amount exceeds maximum supported limit');
      expect(TransactionModel.validateAmount('12.50'), isNull);
    });
  });

  group('Phase 2: TransactionProvider Business Logic Tests', () {
    test('First launch seeds sample data and computes dashboard metrics', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = TransactionProvider();
      await provider.loadTransactions();

      expect(provider.transactions.length, 10);
      expect(provider.totalIncome, greaterThan(0));
      expect(provider.totalExpense, greaterThan(0));
      expect(provider.totalBalance, equals(provider.totalIncome - provider.totalExpense));
    });

    test('Add, Edit, and Delete with Undo persistence', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = TransactionProvider();
      await provider.loadTransactions();

      final initialCount = provider.transactions.length;

      // 1. Add
      final newTx = TransactionModel(
        id: 'new-999',
        title: 'Freelance Design Gig',
        amount: 350.0,
        date: DateTime.now(),
        categoryId: 'freelance',
        type: TransactionType.income,
      );
      await provider.addTransaction(newTx);
      expect(provider.transactions.length, initialCount + 1);
      expect(provider.transactions.any((tx) => tx.id == 'new-999'), isTrue);

      // 2. Edit
      final updatedTx = newTx.copyWith(title: 'Freelance Mobile UI', amount: 450.0);
      await provider.updateTransaction(updatedTx);
      final found = provider.transactions.firstWhere((tx) => tx.id == 'new-999');
      expect(found.title, 'Freelance Mobile UI');
      expect(found.amount, 450.0);

      // 3. Delete
      await provider.deleteTransaction('new-999');
      expect(provider.transactions.length, initialCount);
      expect(provider.canUndoDelete, isTrue);

      // 4. Undo Delete
      await provider.undoDelete();
      expect(provider.transactions.length, initialCount + 1);
      expect(provider.transactions.any((tx) => tx.id == 'new-999'), isTrue);
    });

    test('Search, Type filter, Category filter, and Sorting', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = TransactionProvider();
      await provider.loadTransactions();

      // Search filter
      provider.setSearchQuery('grocery');
      expect(provider.filteredTransactions.length, 1);
      expect(provider.filteredTransactions.first.title.toLowerCase(), contains('grocery'));

      // Reset & Type filter
      provider.resetFilters();
      provider.setTypeFilter('Income');
      for (final tx in provider.filteredTransactions) {
        expect(tx.isIncome, isTrue);
      }

      // Sort by Amount Descending
      provider.resetFilters();
      provider.setSortOrder(TransactionSortOrder.amountDescending);
      final sorted = provider.filteredTransactions;
      for (int i = 0; i < sorted.length - 1; i++) {
        expect(sorted[i].amount >= sorted[i + 1].amount, isTrue);
      }
    });
  });

  group('Phase 3: Custom Categories & Persistence Unit Tests', () {
    test('CategoryModel validation rules', () {
      expect(CategoryModel.validateName(''), 'Please enter a category name');
      expect(CategoryModel.validateName('a'), 'Name must be at least 2 characters');
      expect(CategoryModel.validateName('a' * 35), 'Name cannot exceed 30 characters');
      expect(
        CategoryModel.validateName('Food', CategoryModel.defaultCategories),
        'A category with this name already exists',
      );
      expect(
        CategoryModel.validateName('Food', CategoryModel.defaultCategories, 'food'),
        isNull, // Editing the same category preserves its name
      );
      expect(CategoryModel.validateName('Gym & Fitness'), isNull);
    });

    test('Custom category creation, editing, and persistence in LocalStorage', () async {
      SharedPreferences.setMockInitialValues({});
      final service = LocalStorageService();

      const customCat = CategoryModel(
        id: 'cat_coffee',
        name: 'Artisan Coffee',
        icon: Icons.local_cafe_rounded,
        color: Color(0xFFF97316),
        isDefault: false,
      );

      await service.saveCustomCategories([customCat]);
      final loaded = await service.getCustomCategories();

      expect(loaded.length, 1);
      expect(loaded.first.id, 'cat_coffee');
      expect(loaded.first.name, 'Artisan Coffee');
      expect(loaded.first.icon.codePoint, Icons.local_cafe_rounded.codePoint);
    });

    test('Custom category lifecycle in TransactionProvider', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = TransactionProvider();
      await provider.loadTransactions();

      const customCat = CategoryModel(
        id: 'cat_subscriptions',
        name: 'Streaming Subscriptions',
        icon: Icons.subscriptions_rounded,
        color: Color(0xFF6366F1),
        isDefault: false,
      );

      // 1. Add Category
      await provider.addCategory(customCat);
      expect(provider.customCategories.length, 1);
      expect(provider.allCategories.any((c) => c.id == 'cat_subscriptions'), isTrue);

      // 2. Edit Category
      final updatedCat = customCat.copyWith(name: 'SaaS & Subscriptions');
      await provider.updateCategory(updatedCat);
      expect(provider.getCategoryById('cat_subscriptions').name, 'SaaS & Subscriptions');

      // 3. Assign to transaction
      final tx = TransactionModel(
        id: 'tx_sub_1',
        title: 'Netflix Premium',
        amount: 19.99,
        date: DateTime.now(),
        categoryId: 'cat_subscriptions',
        type: TransactionType.expense,
      );
      await provider.addTransaction(tx);
      expect(provider.getTransactionCountForCategory('cat_subscriptions'), 1);

      // 4. Attempt deletion without replacement (should be rejected)
      final deleteWithoutReplacement = await provider.deleteCategory('cat_subscriptions');
      expect(deleteWithoutReplacement, isFalse);
      expect(provider.customCategories.length, 1);

      // 5. Delete with replacement category (should reassign transactions)
      final deleteWithReplacement = await provider.deleteCategory(
        'cat_subscriptions',
        replacementCategoryId: 'entertainment',
      );
      expect(deleteWithReplacement, isTrue);
      expect(provider.customCategories.length, 0);

      // Verify transaction was reassigned to entertainment
      final reassignedTx = provider.transactions.firstWhere((t) => t.id == 'tx_sub_1');
      expect(reassignedTx.categoryId, 'entertainment');
    });
  });

  group('Phase 3: Financial Intelligence & Summary Calculation Tests', () {
    test('Calculates accurate cash flow and handles empty datasets safely', () {
      final summary = FinancialSummary.fromTransactions(
        transactions: [],
        allCategories: CategoryModel.defaultCategories,
      );

      expect(summary.totalIncome, 0.0);
      expect(summary.totalExpense, 0.0);
      expect(summary.netBalance, 0.0);
      expect(summary.savingsRate, 0.0);
      expect(summary.isDeficit, isFalse);
      expect(summary.averageDailyExpense, 0.0);
      expect(summary.topExpenseCategory, isNull);
    });

    test('Handles zero income and negative balance (deficit spending) gracefully', () {
      final expenseTx = [
        TransactionModel(
          id: '1',
          title: 'Textbooks',
          amount: 150.0,
          date: DateTime(2026, 10, 1),
          categoryId: 'education',
          type: TransactionType.expense,
        ),
      ];

      final summary = FinancialSummary.fromTransactions(
        transactions: expenseTx,
        allCategories: CategoryModel.defaultCategories,
      );

      expect(summary.totalIncome, 0.0);
      expect(summary.totalExpense, 150.0);
      expect(summary.netBalance, -150.0);
      expect(summary.isDeficit, isTrue);
      expect(summary.savingsRate, 0.0); // Zero income yields safe 0.0% without NaN/crash
      expect(summary.topExpenseCategory?.id, 'education');
      expect(summary.topExpenseAmount, 150.0);
      expect(summary.topCategoryPercentage, 100.0);
    });

    test('Calculates correct savings rate when income exceeds expenses', () {
      final transactions = [
        TransactionModel(
          id: '1',
          title: 'Internship Stipend',
          amount: 2000.0,
          date: DateTime(2026, 10, 1),
          categoryId: 'salary',
          type: TransactionType.income,
        ),
        TransactionModel(
          id: '2',
          title: 'Groceries',
          amount: 500.0,
          date: DateTime(2026, 10, 5),
          categoryId: 'food',
          type: TransactionType.expense,
        ),
      ];

      final summary = FinancialSummary.fromTransactions(
        transactions: transactions,
        allCategories: CategoryModel.defaultCategories,
      );

      expect(summary.totalIncome, 2000.0);
      expect(summary.totalExpense, 500.0);
      expect(summary.netBalance, 1500.0);
      expect(summary.savingsRate, 75.0); // (1500 / 2000) * 100 = 75%
      expect(summary.isDeficit, isFalse);
    });
  });

  group('Phase 3: Full UI Integration & Navigation Tests', () {
    testWidgets('Complete multi-screen navigation, category management, and analytics verification', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});

      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const SpendlyApp());
      await tester.pumpAndSettle();

      // 1. Dashboard Tab Verification
      expect(find.text('Total Available Balance'), findsOneWidget);
      expect(find.text('Alex Morgan'), findsOneWidget);
      expect(find.text('Monthly Budget'), findsOneWidget);

      // 2. Switch to Analytics Tab & verify Timeframe Chips
      await tester.tap(find.text('Analytics'));
      await tester.pumpAndSettle();
      expect(find.text('Financial Analytics'), findsOneWidget);
      expect(find.text('Net Cash Flow'), findsOneWidget);
      expect(find.text('This Month'), findsOneWidget);
      expect(find.text('Last Month'), findsOneWidget);
      expect(find.text('All Time'), findsOneWidget);
      expect(find.text('Daily Avg'), findsOneWidget);
      expect(find.text('Top Category'), findsOneWidget);

      // Test timeframe chip selection
      await tester.tap(find.text('All Time'));
      await tester.pumpAndSettle();

      // 3. Switch to Profile Tab & open Category Management
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();
      expect(find.text('Expense Categories'), findsOneWidget);

      await tester.tap(find.text('Expense Categories'));
      await tester.pumpAndSettle();

      // Verify Manage Categories Screen opened
      expect(find.text('Manage Categories'), findsOneWidget);
      expect(find.text('Custom Categories (0)'), findsOneWidget);
      expect(find.text('Default System Categories (9)'), findsOneWidget);

      // 4. Open Category Creation Modal
      await tester.tap(find.text('New Category'));
      await tester.pumpAndSettle();
      expect(find.text('Create Custom Category'), findsOneWidget);
      expect(find.text('Preview'), findsOneWidget);
      expect(find.text('Choose Icon'), findsOneWidget);
      expect(find.text('Choose Color'), findsOneWidget);

      // Validate empty form submission
      await tester.ensureVisible(find.text('Create Category'));
      await tester.tap(find.text('Create Category'));
      await tester.pumpAndSettle();
      expect(find.text('Please enter a category name'), findsOneWidget);

      // Fill in category name and submit
      await tester.enterText(find.byType(TextFormField).first, 'Fitness & Gym');
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Create Category'));
      await tester.tap(find.text('Create Category'));
      await tester.pumpAndSettle();

      // Verify category was created and appears in list
      expect(find.text('Fitness & Gym'), findsOneWidget);
      expect(find.text('Custom Categories (1)'), findsOneWidget);

      // Pop back to Profile
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      // 5. Navigate to History Tab and verify new custom category is synced
      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();
      expect(find.text('Transaction History'), findsOneWidget);

      final stateProvider = tester.element(find.text('Transaction History')).read<TransactionProvider>();
      expect(stateProvider.customCategories.length, 1);
      expect(stateProvider.allCategories.any((c) => c.name == 'Fitness & Gym'), isTrue);
    });
  });

  group('Phase 4: Advanced Analytics & Smart Spending Intelligence Tests', () {
    test('MonthlyDataPoint and MonthOverMonthComparison calculations', () {
      const current = MonthlyDataPoint(
        year: 2026,
        month: 10,
        monthLabel: 'Oct',
        income: 3000.0,
        expense: 1200.0,
      );

      const previous = MonthlyDataPoint(
        year: 2026,
        month: 9,
        monthLabel: 'Sep',
        income: 2800.0,
        expense: 1000.0,
      );

      const mom = MonthOverMonthComparison(
        currentMonth: current,
        previousMonth: previous,
      );

      expect(mom.hasEnoughHistory, isTrue);
      expect(mom.expenseChangeAmount, 200.0); // 1200 - 1000
      expect(mom.expenseChangePercentage, 20.0); // (200 / 1000) * 100
      expect(mom.isSpendingIncreased, isTrue);
      expect(current.netSavings, 1800.0);
      expect(current.savingsRate, 60.0); // (1800 / 3000) * 100
      expect(current.isDeficit, isFalse);

      // Test zero-previous expense edge case
      const prevZero = MonthlyDataPoint(
        year: 2026,
        month: 9,
        monthLabel: 'Sep',
        income: 0.0,
        expense: 0.0,
      );
      const momZero = MonthOverMonthComparison(
        currentMonth: current,
        previousMonth: prevZero,
      );
      expect(momZero.expenseChangePercentage, 0.0); // Safe fallback without NaN
    });

    test('BudgetUtilizationAnalytics burn velocity and allowance calculations', () {
      const budgetAnalytics = BudgetUtilizationAnalytics(
        budgetLimit: 2000.0,
        budgetSpent: 1200.0,
        daysPassedInMonth: 15,
        totalDaysInMonth: 30,
      );

      expect(budgetAnalytics.utilizationPercentage, 60.0); // (1200 / 2000) * 100
      expect(budgetAnalytics.expectedUtilizationPercentage, 50.0); // (15 / 30) * 100
      expect(budgetAnalytics.isPacingAhead, isTrue); // 60% > 50% + 5%
      expect(budgetAnalytics.isExceeded, isFalse);
      expect(budgetAnalytics.currentDailyBurnRate, 80.0); // 1200 / 15
      expect(budgetAnalytics.safeDailyRemainingSpend, closeTo(53.33, 0.01)); // (2000 - 1200) / 15
    });

    test('SmartInsightsService generates accurate rule-based intelligence', () {
      // Setup mock transactions for a month where Groceries dominates (>35%) and spending increased (>8%)
      final currentTxs = [
        TransactionModel(
          id: '1',
          title: 'Salary',
          amount: 4000.0,
          date: DateTime(2026, 10, 1),
          categoryId: 'salary',
          type: TransactionType.income,
        ),
        TransactionModel(
          id: '2',
          title: 'Gourmet Supermarket',
          amount: 600.0,
          date: DateTime(2026, 10, 2),
          categoryId: 'food',
          type: TransactionType.expense,
        ),
        TransactionModel(
          id: '3',
          title: 'Book',
          amount: 50.0,
          date: DateTime(2026, 10, 3),
          categoryId: 'education',
          type: TransactionType.expense,
        ),
      ];

      final currentSummary = FinancialSummary.fromTransactions(
        transactions: currentTxs,
        allCategories: CategoryModel.defaultCategories,
      );

      const mom = MonthOverMonthComparison(
        currentMonth: MonthlyDataPoint(
          year: 2026,
          month: 10,
          monthLabel: 'Oct',
          income: 4000.0,
          expense: 650.0,
        ),
        previousMonth: MonthlyDataPoint(
          year: 2026,
          month: 9,
          monthLabel: 'Sep',
          income: 4000.0,
          expense: 500.0,
        ),
      );

      const budget = BudgetUtilizationAnalytics(
        budgetLimit: 1500.0,
        budgetSpent: 650.0,
        daysPassedInMonth: 10,
        totalDaysInMonth: 30,
      );

      final insights = SmartInsightsService.generateInsights(
        currentMonthSummary: currentSummary,
        momComparison: mom,
        budgetUtilization: budget,
      );

      expect(insights.isNotEmpty, isTrue);

      // Verify MoM spending increased insight
      expect(insights.any((i) => i.id == 'mom_spending_increase'), isTrue);

      // Verify category concentration insight (Food is 600/650 = 92.3% of total expense)
      expect(insights.any((i) => i.id.startsWith('category_concentration_')), isTrue);

      // Verify healthy savings rate insight (saving > 20%)
      expect(insights.any((i) => i.id == 'savings_rate_healthy'), isTrue);
    });

    testWidgets('AnalyticsScreen renders IncomeExpenseBarChart, MoM, BudgetVelocity, and SmartInsights',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});

      tester.view.physicalSize = const Size(1200, 2600);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const SpendlyApp());
      await tester.pumpAndSettle();

      // Navigate to Analytics
      await tester.tap(find.text('Analytics'));
      await tester.pumpAndSettle();

      // Verify Phase 4 widgets exist
      expect(find.text('Income vs Expense'), findsOneWidget);
      expect(find.text('Multi-month cash flow trends'), findsOneWidget);
      expect(find.text('3M'), findsOneWidget);
      expect(find.text('6M'), findsOneWidget);
      expect(find.text('1Y'), findsOneWidget);

      expect(find.text('Month-over-Month Pace'), findsOneWidget);
      expect(find.text('Budget Burn Velocity'), findsOneWidget);
      expect(find.text('Category Spending Distribution'), findsOneWidget);
      expect(find.text('Smart Financial Intelligence'), findsOneWidget);

      // Tap 3M period pill on the bar chart
      await tester.tap(find.text('3M'));
      await tester.pumpAndSettle();
    });
  });

  group('Phase 5: Firebase Authentication & Cloud Synchronization Tests', () {
    test('MockAuthService user registration, login, and validation rules', () async {
      final authService = MockAuthService();

      // 1. Register valid account
      final user = await authService.registerWithEmailPassword(
        email: 'intern@spendly.io',
        password: 'securePassword123',
        displayName: 'Dev Intern',
      );
      expect(user.email, 'intern@spendly.io');
      expect(user.displayName, 'Dev Intern');
      expect(user.uid, startsWith('mock_uid_'));

      // 2. Reject duplicate email
      expect(
        () => authService.registerWithEmailPassword(
          email: 'intern@spendly.io',
          password: 'anotherPassword',
          displayName: 'Duplicate User',
        ),
        throwsA(isA<AuthFailureException>()),
      );

      // 3. Reject short password (< 6 chars)
      expect(
        () => authService.registerWithEmailPassword(
          email: 'new@spendly.io',
          password: '123',
          displayName: 'Short Password',
        ),
        throwsA(isA<AuthFailureException>()),
      );

      // 4. Logout and sign back in
      await authService.signOut();
      expect(await authService.getCurrentUser(), isNull);

      final loggedIn = await authService.signInWithEmailPassword(
        email: 'intern@spendly.io',
        password: 'securePassword123',
      );
      expect(loggedIn.email, 'intern@spendly.io');

      // 5. Reject wrong password
      expect(
        () => authService.signInWithEmailPassword(
          email: 'intern@spendly.io',
          password: 'wrongPassword',
        ),
        throwsA(isA<AuthFailureException>()),
      );

      // 6. Password reset simulation
      await authService.sendPasswordResetEmail('intern@spendly.io');
    });

    test('AuthProvider state transitions and session listeners', () async {
      final mockAuth = MockAuthService();
      final provider = AuthProvider(authService: mockAuth);

      expect(provider.isAuthenticated, isFalse);
      expect(provider.status, AuthStatus.unauthenticated);

      // Login
      await mockAuth.registerWithEmailPassword(
        email: 'test@spendly.io',
        password: 'password123',
        displayName: 'Test User',
      );

      final success = await provider.login(
        email: 'test@spendly.io',
        password: 'password123',
      );

      expect(success, isTrue);
      expect(provider.isAuthenticated, isTrue);
      expect(provider.user?.email, 'test@spendly.io');

      // Logout
      await provider.logout();
      expect(provider.isAuthenticated, isFalse);
      expect(provider.user, isNull);
    });

    test('CloudMigrationService idempotency and zero data loss guarantee', () async {
      SharedPreferences.setMockInitialValues({});
      final localStorage = LocalStorageService();
      final cloudSync = MockCloudSyncService();

      // Seed local storage with a transaction and custom category
      final localTx = [
        TransactionModel(
          id: 'tx_local_1',
          title: 'Mechanical Keyboard',
          amount: 150.0,
          date: DateTime(2026, 10, 1),
          categoryId: 'shopping',
          type: TransactionType.expense,
        ),
      ];
      const localCat = [
        CategoryModel(
          id: 'cat_hardware',
          name: 'Hardware',
          icon: Icons.computer_rounded,
          color: Color(0xFF3B82F6),
          isDefault: false,
        ),
      ];
      const localBudget = BudgetModel(
        id: 'budget_1',
        limitAmount: 2500.0,
        month: 10,
        year: 2026,
      );

      await localStorage.saveTransactions(localTx);
      await localStorage.saveCustomCategories(localCat);
      await localStorage.saveBudget(localBudget);

      final migration = CloudMigrationService(
        localStorage: localStorage,
        cloudSync: cloudSync,
      );

      // First migration: should upload 1 transaction and 1 category
      final firstRun = await migration.migrateLocalToCloud('user_123');
      expect(firstRun.isSuccess, isTrue);
      expect(firstRun.transactionsMigrated, 1);
      expect(firstRun.categoriesMigrated, 1);
      expect(firstRun.budgetMigrated, isTrue);

      // Second migration: should detect identical IDs and migrate 0 duplicates (idempotent!)
      final secondRun = await migration.migrateLocalToCloud('user_123');
      expect(secondRun.isSuccess, isTrue);
      expect(secondRun.transactionsMigrated, 0);
      expect(secondRun.categoriesMigrated, 0);

      // Verify local data was preserved without deletion
      final preservedTxs = await localStorage.getTransactions();
      expect(preservedTxs.length, 1);
      expect(preservedTxs.first.id, 'tx_local_1');
    });

    test('TransactionProvider cloud sync status and offline failure handling', () async {
      SharedPreferences.setMockInitialValues({});
      final localStorage = LocalStorageService();
      final cloudSync = MockCloudSyncService();

      final provider = TransactionProvider(
        storageService: localStorage,
        cloudSyncService: cloudSync,
      );
      await provider.loadTransactions();

      expect(provider.syncStatus, SyncStatus.localOnly);

      // Link user ID and sync successfully
      await provider.setUserId('user_test_456');
      expect(provider.syncStatus, SyncStatus.synced);

      // Simulate offline / cloud network failure
      cloudSync.shouldFail = true;
      final newTx = TransactionModel(
        id: 'tx_offline_1',
        title: 'Offline Subway Ride',
        amount: 2.75,
        date: DateTime.now(),
        categoryId: 'transportation',
        type: TransactionType.expense,
      );

      // Local write should succeed, but cloud sync should flag syncFailed
      await provider.addTransaction(newTx);
      expect(provider.transactions.any((t) => t.id == 'tx_offline_1'), isTrue);
      expect(provider.syncStatus, SyncStatus.syncFailed);

      // Recover network and retry sync
      cloudSync.shouldFail = false;
      final retrySuccess = await provider.syncWithCloud();
      expect(retrySuccess, isTrue);
      expect(provider.syncStatus, SyncStatus.synced);
    });

    testWidgets('Full UI Integration: Profile sign-in and registration flow',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});

      tester.view.physicalSize = const Size(1200, 2600);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final mockAuth = MockAuthService();
      final authProvider = AuthProvider(authService: mockAuth);

      await tester.pumpWidget(
        SpendlyApp(authProvider: authProvider),
      );
      await tester.pumpAndSettle();

      // 1. Navigate to Profile
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();

      // Verify Profile Screen shows local status & sign in button
      expect(find.text('Local Only'), findsOneWidget);
      expect(find.text('Sign In to Enable Cloud Sync'), findsOneWidget);

      // 2. Open Login Screen
      await tester.tap(find.text('Sign In to Enable Cloud Sync'));
      await tester.pumpAndSettle();

      expect(find.text('Welcome Back'), findsOneWidget);
      expect(find.text('Create Account'), findsOneWidget);

      // 3. Navigate to Register Screen
      await tester.tap(find.text('Create Account'));
      await tester.pumpAndSettle();

      expect(find.text('Create an Account'), findsOneWidget);

      // 4. Fill in Registration Form
      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), 'Morgan Reed'); // Full Name
      await tester.enterText(textFields.at(1), 'morgan.reed@spendly.io'); // Email
      await tester.enterText(textFields.at(2), 'password123'); // Password
      await tester.enterText(textFields.at(3), 'password123'); // Confirm Password
      await tester.pumpAndSettle();

      // Submit Registration
      await tester.tap(find.widgetWithText(ElevatedButton, 'Create Account'));
      await tester.pumpAndSettle();

      // Pop Login Screen back to Profile
      if (find.byType(BackButton).evaluate().isNotEmpty) {
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
      }

      // 5. Verify Profile reflects newly registered user
      expect(find.text('Morgan Reed'), findsOneWidget);
      expect(find.text('morgan.reed@spendly.io'), findsOneWidget);
      expect(find.text('Sign Out'), findsOneWidget);

      // 6. Test Sign Out Dialog
      await tester.tap(find.text('Sign Out'));
      await tester.pumpAndSettle();

      expect(find.text('Are you sure you want to log out of Spendly? Local data will remain on this device.'), findsOneWidget);
      await tester.tap(find.text('Log Out').last);
      await tester.pumpAndSettle();

      // Verify signed out state
      expect(find.text('Sign In to Enable Cloud Sync'), findsOneWidget);
    });
  });

  group('Phase 5.1: Data Safety & Sync Reliability Tests', () {
    test('Multi-user isolation: User A records are strictly isolated from User B', () async {
      SharedPreferences.setMockInitialValues({});
      final localStorage = LocalStorageService();
      final cloudSync = MockCloudSyncService();

      final provider = TransactionProvider(
        storageService: localStorage,
        cloudSyncService: cloudSync,
      );

      // User A signs in and adds a transaction
      await provider.setUserId('user_alice');
      final aliceTx = TransactionModel(
        id: 'tx_alice_private_1',
        title: 'Alice Private Project Expense',
        amount: 320.0,
        date: DateTime.now(),
        categoryId: 'bills',
        type: TransactionType.expense,
      );
      await provider.addTransaction(aliceTx);
      expect(provider.transactions.any((t) => t.id == 'tx_alice_private_1'), isTrue);

      // Alice logs out
      await provider.setUserId(null);
      expect(provider.transactions.any((t) => t.id == 'tx_alice_private_1'), isFalse);

      // Bob signs in on the same device
      await provider.setUserId('user_bob');
      expect(provider.transactions.any((t) => t.id == 'tx_alice_private_1'), isFalse);

      final bobTx = TransactionModel(
        id: 'tx_bob_1',
        title: 'Bob Gaming Laptop',
        amount: 1400.0,
        date: DateTime.now(),
        categoryId: 'shopping',
        type: TransactionType.expense,
      );
      await provider.addTransaction(bobTx);
      expect(provider.transactions.any((t) => t.id == 'tx_bob_1'), isTrue);
      expect(provider.transactions.any((t) => t.id == 'tx_alice_private_1'), isFalse);

      // Verify Cloud Firestore collections are partitioned
      final aliceCloud = await cloudSync.fetchTransactions('user_alice');
      final bobCloud = await cloudSync.fetchTransactions('user_bob');
      expect(aliceCloud.any((t) => t.id == 'tx_alice_private_1'), isTrue);
      expect(aliceCloud.any((t) => t.id == 'tx_bob_1'), isFalse);
      expect(bobCloud.any((t) => t.id == 'tx_bob_1'), isTrue);
      expect(bobCloud.any((t) => t.id == 'tx_alice_private_1'), isFalse);

      // Alice logs back in: her private data is restored intact!
      await provider.setUserId('user_alice');
      expect(provider.transactions.any((t) => t.id == 'tx_alice_private_1'), isTrue);
      expect(provider.transactions.any((t) => t.id == 'tx_bob_1'), isFalse);
    });

    test('Offline deletion: Tombstones prevent deleted transactions from reappearing after sync', () async {
      SharedPreferences.setMockInitialValues({});
      final localStorage = LocalStorageService();
      final cloudSync = MockCloudSyncService();

      // Seed cloud with a transaction
      final initialTx = TransactionModel(
        id: 'tx_cloud_persistent_1',
        title: 'Online Subscription',
        amount: 14.99,
        date: DateTime.now(),
        categoryId: 'entertainment',
        type: TransactionType.expense,
      );
      await cloudSync.saveTransaction('user_tombstone', initialTx);

      final provider = TransactionProvider(
        storageService: localStorage,
        cloudSyncService: cloudSync,
      );
      await provider.setUserId('user_tombstone');
      expect(provider.transactions.any((t) => t.id == 'tx_cloud_persistent_1'), isTrue);

      // Simulate network disconnection
      cloudSync.shouldFail = true;

      // Delete while offline
      await provider.deleteTransaction('tx_cloud_persistent_1');
      expect(provider.transactions.any((t) => t.id == 'tx_cloud_persistent_1'), isFalse);
      expect(provider.syncStatus, SyncStatus.syncFailed);

      // Verify persistent tombstone was recorded
      final tombstones = await localStorage.getDeletedTransactionIds(userId: 'user_tombstone');
      expect(tombstones.contains('tx_cloud_persistent_1'), isTrue);

      // Network recovers
      cloudSync.shouldFail = false;

      // Run sync: tombstone should be pushed to cloud, deleting it remotely without re-inserting
      final syncSuccess = await provider.syncWithCloud();
      expect(syncSuccess, isTrue);

      // Verify transaction did NOT reappear!
      expect(provider.transactions.any((t) => t.id == 'tx_cloud_persistent_1'), isFalse);
      final remainingCloud = await cloudSync.fetchTransactions('user_tombstone');
      expect(remainingCloud.any((t) => t.id == 'tx_cloud_persistent_1'), isFalse);
    });

    test('Offline edits: Last-Write-Wins (LWW) conflict resolution preserves newer modifications', () async {
      SharedPreferences.setMockInitialValues({});
      final localStorage = LocalStorageService();
      final cloudSync = MockCloudSyncService();

      final oldTimestamp = DateTime(2026, 10, 1, 10, 0);
      final newerTimestamp = DateTime(2026, 10, 1, 14, 0);

      // Remote has an older transaction
      final remoteTx = TransactionModel(
        id: 'tx_conflict_1',
        title: 'Grocery (Original)',
        amount: 50.0,
        date: oldTimestamp,
        categoryId: 'food',
        type: TransactionType.expense,
        updatedAt: oldTimestamp,
      );
      await cloudSync.saveTransaction('user_conflict', remoteTx);

      // Local has a newer offline edit of that same transaction
      final localEditedTx = TransactionModel(
        id: 'tx_conflict_1',
        title: 'Grocery (Modified Offline)',
        amount: 75.0,
        date: oldTimestamp,
        categoryId: 'food',
        type: TransactionType.expense,
        updatedAt: newerTimestamp,
      );
      await localStorage.saveTransactions([localEditedTx], userId: 'user_conflict');

      final migration = CloudMigrationService(
        localStorage: localStorage,
        cloudSync: cloudSync,
      );

      final result = await migration.migrateLocalToCloud('user_conflict');
      expect(result.isSuccess, isTrue);

      // Local edit was newer, so it should win and update the cloud
      final cloudTxs = await cloudSync.fetchTransactions('user_conflict');
      expect(cloudTxs.length, 1);
      expect(cloudTxs.first.title, 'Grocery (Modified Offline)');
      expect(cloudTxs.first.amount, 75.0);
    });

    test('Demo data protection: Sample transactions are excluded from cloud unless consented', () async {
      SharedPreferences.setMockInitialValues({});
      final localStorage = LocalStorageService();
      final cloudSync = MockCloudSyncService();

      // Seed 1 real transaction and 1 demo transaction
      final realTx = TransactionModel(
        id: 'tx_real_1',
        title: 'Real Salary',
        amount: 2500.0,
        date: DateTime.now(),
        categoryId: 'salary',
        type: TransactionType.income,
        isSample: false,
      );
      final demoTx = TransactionModel(
        id: 'tx_demo_sample_1',
        title: 'Sample Coffee Demo',
        amount: 5.0,
        date: DateTime.now(),
        categoryId: 'food',
        type: TransactionType.expense,
        isSample: true,
      );

      await localStorage.saveTransactions([realTx, demoTx], userId: 'user_consent');

      final migration = CloudMigrationService(
        localStorage: localStorage,
        cloudSync: cloudSync,
      );

      // 1. Without consent (importDemoData = false): demo transaction is SKIPPED
      final runWithoutConsent = await migration.migrateLocalToCloud('user_consent', importDemoData: false);
      expect(runWithoutConsent.isSuccess, isTrue);

      final cloudWithoutConsent = await cloudSync.fetchTransactions('user_consent');
      expect(cloudWithoutConsent.any((t) => t.id == 'tx_real_1'), isTrue);
      expect(cloudWithoutConsent.any((t) => t.id == 'tx_demo_sample_1'), isFalse);

      // 2. With explicit consent (importDemoData = true): demo transaction is uploaded
      final runWithConsent = await migration.migrateLocalToCloud('user_consent', importDemoData: true);
      expect(runWithConsent.isSuccess, isTrue);

      final cloudWithConsent = await cloudSync.fetchTransactions('user_consent');
      expect(cloudWithConsent.any((t) => t.id == 'tx_demo_sample_1'), isTrue);
    });

    test('Truthful sync status: Distinguishes Mock Dev Sync from Live Firestore Sync', () {
      final mockSync = MockCloudSyncService();
      final provider = TransactionProvider(cloudSyncService: mockSync);

      expect(provider.isMockActive, isTrue);
      // When synced in mock mode, label reflects Mock Dev honestly
      expect(SyncStatus.synced.getLabel(isMock: true), 'Synced (Mock Dev)');
      expect(SyncStatus.synced.getLabel(isMock: false), 'Synced (Firestore)');
      expect(SyncStatus.localOnly.getLabel(isMock: true), 'Local Only');
      expect(SyncStatus.syncFailed.getLabel(isMock: true), 'Sync Failed');
    });
  });

  group('Phase 5.2: Real Firebase Integration & Error Handling Tests', () {
    test('DefaultFirebaseOptions configuration integrity for spendly-18e90', () {
      expect(DefaultFirebaseOptions.web.projectId, 'spendly-18e90');
      expect(DefaultFirebaseOptions.web.authDomain, 'spendly-18e90.firebaseapp.com');
      expect(DefaultFirebaseOptions.web.apiKey.isNotEmpty, isTrue);

      expect(DefaultFirebaseOptions.android.projectId, 'spendly-18e90');
      expect(DefaultFirebaseOptions.android.storageBucket, 'spendly-18e90.firebasestorage.app');
      expect(DefaultFirebaseOptions.android.apiKey.isNotEmpty, isTrue);
    });

    test('FirebaseConfig fallback and forceMockMode developer controls', () {
      // Test forceMockMode override
      FirebaseConfig.forceMockMode = true;
      expect(FirebaseConfig.isRealFirebaseActive, isFalse);

      FirebaseConfig.forceMockMode = false;
      // Default activeProjectId reflects spendly-18e90
      if (FirebaseConfig.isInitialized) {
        expect(FirebaseConfig.activeProjectId, 'spendly-18e90');
      }
    });

    test('CloudSyncException formatting and MockCloudSyncService failure mapping', () async {
      const ex = CloudSyncException('Permission denied by rules', code: 'permission-denied');
      expect(ex.message, 'Permission denied by rules');
      expect(ex.code, 'permission-denied');
      expect(ex.toString(), contains('code: permission-denied'));

      final mockSync = MockCloudSyncService();
      mockSync.shouldFail = true;

      expect(
        () => mockSync.fetchTransactions('user_err'),
        throwsA(isA<CloudSyncException>()),
      );
    });

    test('TransactionProvider handles CloudSyncException gracefully without local data corruption', () async {
      SharedPreferences.setMockInitialValues({});
      final localStorage = LocalStorageService();
      final cloudSync = MockCloudSyncService();

      final provider = TransactionProvider(
        storageService: localStorage,
        cloudSyncService: cloudSync,
      );

      await provider.loadTransactions();
      expect(provider.transactions.isNotEmpty, isTrue);
      // Authenticate with user
      await provider.setUserId('user_error_resilience');
      final userInitialCount = provider.transactions.length;

      // Induce cloud exception
      cloudSync.shouldFail = true;

      final addResult = TransactionModel(
        id: 'tx_fail_resilient',
        title: 'Cloud Failure Test',
        amount: 88.0,
        date: DateTime.now(),
        categoryId: 'bills',
        type: TransactionType.expense,
      );

      // Local write must succeed, cloud sync must flag syncFailed, no crash
      await provider.addTransaction(addResult);
      expect(provider.transactions.length, userInitialCount + 1);
      expect(provider.transactions.any((t) => t.id == 'tx_fail_resilient'), isTrue);
      expect(provider.syncStatus, SyncStatus.syncFailed);

      // Verify local disk storage has the record preserved
      final diskTxs = await localStorage.getTransactions(userId: 'user_error_resilience');
      expect(diskTxs.any((t) => t.id == 'tx_fail_resilient'), isTrue);
    });
  });

  group('Phase 6.1: Critical Data Integrity & Multi-Device Sync Tests', () {
    test('1. Fresh-session demo isolation: Seed demo data never enters user dataset without explicit consent', () async {
      SharedPreferences.setMockInitialValues({});
      final localStorage = LocalStorageService();
      final cloudSync = MockCloudSyncService();

      // Seed anonymous storage with a sample demo transaction and a user-created guest transaction
      final demoTx = TransactionModel(
        id: 'tx_seed_demo_01',
        title: 'Seed Demo Coffee',
        amount: 4.50,
        date: DateTime.now().toUtc(),
        categoryId: 'food',
        type: TransactionType.expense,
        isSample: true,
      );
      final guestRealTx = TransactionModel(
        id: 'tx_guest_real_01',
        title: 'Guest Real Taxi Ride',
        amount: 22.00,
        date: DateTime.now().toUtc(),
        categoryId: 'transportation',
        type: TransactionType.expense,
        isSample: false,
      );
      await localStorage.saveTransactions([demoTx, guestRealTx]);

      final migration = CloudMigrationService(
        localStorage: localStorage,
        cloudSync: cloudSync,
      );

      // User signs in on fresh session without importing demo data
      final result = await migration.migrateLocalToCloud('user_fresh_session', importDemoData: false);
      expect(result.isSuccess, isTrue);

      // Check user-scoped local storage: MUST contain guestRealTx, MUST NOT contain demoTx
      final userTxs = await localStorage.getTransactions(userId: 'user_fresh_session');
      expect(userTxs.any((t) => t.id == 'tx_guest_real_01'), isTrue);
      expect(userTxs.any((t) => t.id == 'tx_seed_demo_01'), isFalse);

      // Check cloud storage: only guestRealTx should be in cloud
      final cloudTxs = await cloudSync.fetchTransactions('user_fresh_session');
      expect(cloudTxs.any((t) => t.id == 'tx_guest_real_01'), isTrue);
      expect(cloudTxs.any((t) => t.id == 'tx_seed_demo_01'), isFalse);

      // Check anonymous storage: still retains demoTx and guestRealTx intact
      final anonTxs = await localStorage.getTransactions();
      expect(anonTxs.any((t) => t.id == 'tx_seed_demo_01'), isTrue);
    });

    test('2. Transaction deletion safety: Stale secondary device cannot resurrect deleted transaction', () async {
      SharedPreferences.setMockInitialValues({});
      final localStorageA = LocalStorageService();
      final cloudSync = MockCloudSyncService();

      final sharedTx = TransactionModel(
        id: 'tx_shared_multidevice',
        title: 'Team Dinner',
        amount: 150.0,
        date: DateTime.now().toUtc(),
        categoryId: 'food',
        type: TransactionType.expense,
      );

      // Seed both cloud and Device A
      await cloudSync.saveTransaction('user_multi', sharedTx);
      final providerA = TransactionProvider(
        storageService: localStorageA,
        cloudSyncService: cloudSync,
      );
      await providerA.setUserId('user_multi');
      expect(providerA.transactions.any((t) => t.id == 'tx_shared_multidevice'), isTrue);

      // Device A deletes the transaction
      await providerA.deleteTransaction('tx_shared_multidevice');
      expect(providerA.transactions.any((t) => t.id == 'tx_shared_multidevice'), isFalse);

      // Verify cloud tombstone was recorded
      final cloudDeleted = await cloudSync.fetchDeletedTransactionIds('user_multi');
      expect(cloudDeleted.contains('tx_shared_multidevice'), isTrue);

      // Device B comes online with a stale cached copy of tx_shared_multidevice
      final localStorageB = LocalStorageService();
      await localStorageB.saveTransactions([sharedTx], userId: 'user_multi');

      final providerB = TransactionProvider(
        storageService: localStorageB,
        cloudSyncService: cloudSync,
      );
      await providerB.setUserId('user_multi');

      // Crucial assertion: Device B must NOT have resurrected the transaction in cloud or locally!
      final remainingCloud = await cloudSync.fetchTransactions('user_multi');
      expect(remainingCloud.any((t) => t.id == 'tx_shared_multidevice'), isFalse);
      expect(providerB.transactions.any((t) => t.id == 'tx_shared_multidevice'), isFalse);

      final diskB = await localStorageB.getTransactions(userId: 'user_multi');
      expect(diskB.any((t) => t.id == 'tx_shared_multidevice'), isFalse);
    });

    test('3. UTC timestamp consistency: Normalizes timestamps to UTC and preserves cross-timezone LWW', () async {
      final nowUtc = DateTime.utc(2026, 10, 2, 12, 0, 0);
      final tx = TransactionModel(
        id: 'tx_utc_test',
        title: 'UTC Check',
        amount: 50.0,
        date: nowUtc,
        categoryId: 'shopping',
        type: TransactionType.expense,
        updatedAt: nowUtc,
      );

      final map = tx.toMap();
      expect(map['date'], contains('Z'));
      expect(map['updatedAt'], contains('Z'));

      // Deserialization check
      final parsed = TransactionModel.fromMap(map);
      expect(parsed.date.isUtc, isTrue);
      expect(parsed.updatedAt.isUtc, isTrue);

      // Backward compatibility with legacy non-Z timestamp strings
      final legacyMap = {
        'id': 'tx_legacy',
        'title': 'Legacy Tx',
        'amount': 25.0,
        'date': '2026-10-01T15:30:00.000',
        'categoryId': 'food',
        'type': 'expense',
        'updatedAt': '2026-10-01T15:30:00.000',
      };
      final legacyParsed = TransactionModel.fromMap(legacyMap);
      expect(legacyParsed.date.isUtc, isTrue);
      expect(legacyParsed.updatedAt.isUtc, isTrue);
    });

    test('4. Sync concurrency: Prevents simultaneous syncWithCloud executions from colliding', () async {
      SharedPreferences.setMockInitialValues({});
      final localStorage = LocalStorageService();
      final cloudSync = MockCloudSyncService();

      final provider = TransactionProvider(
        storageService: localStorage,
        cloudSyncService: cloudSync,
      );
      await provider.setUserId('user_concurrent');

      // Trigger two concurrent syncs
      final syncFuture1 = provider.syncWithCloud();
      final syncFuture2 = provider.syncWithCloud();

      final results = await Future.wait([syncFuture1, syncFuture2]);
      // One of the syncs must succeed, while the overlapping trigger is safely rejected without crash
      expect(results.contains(true), isTrue);
      expect(provider.syncStatus, SyncStatus.synced);
    });

    test('5. Sync error handling: Sets syncing state, populates lastSyncError on failure, and clears on success', () async {
      SharedPreferences.setMockInitialValues({});
      final localStorage = LocalStorageService();
      final cloudSync = MockCloudSyncService();

      final provider = TransactionProvider(
        storageService: localStorage,
        cloudSyncService: cloudSync,
      );
      await provider.setUserId('user_err_lifecycle');
      expect(provider.syncStatus, SyncStatus.synced);
      expect(provider.lastSyncError, isNull);

      // Induce cloud failure
      cloudSync.shouldFail = true;
      final failedTx = TransactionModel(
        id: 'tx_will_fail',
        title: 'Error Test',
        amount: 30.0,
        date: DateTime.now().toUtc(),
        categoryId: 'bills',
        type: TransactionType.expense,
      );

      await provider.addTransaction(failedTx);
      expect(provider.syncStatus, SyncStatus.syncFailed);
      expect(provider.lastSyncError, isNotNull);
      expect(provider.lastSyncError, contains('Simulated network/cloud connection failure'));

      // Network recovers
      cloudSync.shouldFail = false;
      final retrySuccess = await provider.syncWithCloud();
      expect(retrySuccess, isTrue);
      expect(provider.syncStatus, SyncStatus.synced);
      expect(provider.lastSyncError, isNull); // Stale error cleared
    });
  });
}

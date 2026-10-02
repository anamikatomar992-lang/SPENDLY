import 'package:flutter/foundation.dart';
import '../models/budget_model.dart';
import '../models/category_model.dart';
import '../models/transaction_model.dart';
import 'cloud_sync_service.dart';
import 'local_storage_service.dart';

/// Result summary of local-to-cloud data migration
class MigrationResult {
  final bool isSuccess;
  final int transactionsMigrated;
  final int categoriesMigrated;
  final bool budgetMigrated;
  final int tombstonesProcessed;
  final String? errorMessage;

  const MigrationResult({
    required this.isSuccess,
    this.transactionsMigrated = 0,
    this.categoriesMigrated = 0,
    this.budgetMigrated = false,
    this.tombstonesProcessed = 0,
    this.errorMessage,
  });
}

/// Zero-data-loss, idempotent migration engine from LocalStorage to Cloud Firestore
/// with Last-Write-Wins (LWW) conflict resolution, offline deletion tombstones,
/// and demo-data protection.
class CloudMigrationService {
  final ILocalStorageService _localStorage;
  final ICloudSyncService _cloudSync;

  const CloudMigrationService({
    required ILocalStorageService localStorage,
    required ICloudSyncService cloudSync,
  })  : _localStorage = localStorage,
        _cloudSync = cloudSync;

  /// Migrates local user data into Cloud Firestore.
  /// - Uses stable document IDs (`tx.id`, `category.id`) for idempotent operations.
  /// - Compares `updatedAt` to ensure newer local modifications are pushed (LWW).
  /// - Reconciles persistent offline deletion tombstones before merging.
  /// - Excludes demo/sample transactions unless [importDemoData] is explicitly true.
  /// - Never purges local data without successful cloud confirmation.
  Future<MigrationResult> migrateLocalToCloud(
    String userId, {
    bool importDemoData = false,
  }) async {
    try {
      debugPrint('[CloudMigration] Starting idempotent migration for user: $userId (importDemoData=$importDemoData)');

      // 1. Process offline deletion tombstones and fetch cloud tombstones
      // Check both anonymous tombstones (pre-login offline deletes) and user tombstones
      final anonTombstones = await _localStorage.getDeletedTransactionIds();
      final userTombstones = await _localStorage.getDeletedTransactionIds(userId: userId);
      final remoteDeletedIds = await _cloudSync.fetchDeletedTransactionIds(userId);
      final allTombstones = {...anonTombstones, ...userTombstones, ...remoteDeletedIds};

      int tombstonesCount = 0;
      // Push any local offline tombstones to cloud
      for (final tombstoneId in {...anonTombstones, ...userTombstones}) {
        try {
          await _cloudSync.deleteTransaction(userId, tombstoneId);
          tombstonesCount++;
        } catch (e) {
          debugPrint('[CloudMigration] Error pushing tombstone $tombstoneId: $e');
        }
      }

      // Ensure local user storage remembers all known tombstones (including remote)
      for (final tombstoneId in allTombstones) {
        await _localStorage.recordDeletedTransactionId(tombstoneId, userId: userId);
      }
      // Clear pre-login anonymous tombstones once reconciled
      for (final tombstoneId in anonTombstones) {
        await _localStorage.removeDeletedTransactionId(tombstoneId);
      }

      // 2. Read local state (check user-scoped first; if empty, inspect anonymous/pre-login state)
      List<TransactionModel> userLocalTransactions = await _localStorage.getTransactions(userId: userId);
      final bool isFreshUserSession = userLocalTransactions.isEmpty;
      final anonTransactions = await _localStorage.getTransactions();

      List<TransactionModel> localTransactions;
      if (isFreshUserSession) {
        // Fresh session for this user on this device:
        if (importDemoData) {
          localTransactions = List.from(anonTransactions);
        } else {
          // Demo Isolation: Only import user-created transactions, NEVER seed demo samples without consent
          localTransactions = anonTransactions.where((t) => !t.isSample).toList();
        }
      } else {
        // Existing user dataset on this device
        localTransactions = List.from(userLocalTransactions);
        if (importDemoData) {
          // User explicitly consented to import demo data into existing account: add anonymous demo samples
          final existingIds = localTransactions.map((t) => t.id).toSet();
          for (final anonTx in anonTransactions) {
            if (anonTx.isSample && !existingIds.contains(anonTx.id)) {
              localTransactions.add(anonTx);
            }
          }
        }
      }

      List<CategoryModel> localCategories = await _localStorage.getCustomCategories(userId: userId);
      BudgetModel? localBudget = await _localStorage.getBudget(userId: userId);

      if (localCategories.isEmpty) {
        final anonCategories = await _localStorage.getCustomCategories();
        if (anonCategories.isNotEmpty) {
          localCategories = anonCategories;
        }
      }

      localBudget ??= await _localStorage.getBudget();

      // 3. Fetch remote state to identify existing records and avoid duplicates
      final remoteTransactions = await _cloudSync.fetchTransactions(userId);
      final remoteCategories = await _cloudSync.fetchCustomCategories(userId);
      final remoteBudget = await _cloudSync.fetchBudget(userId);

      final remoteTxMap = {for (final t in remoteTransactions) t.id: t};
      final remoteCatMap = {for (final c in remoteCategories) c.id: c};

      int txCount = 0;
      int catCount = 0;
      bool budgetDone = false;

      // 4. Migrate transactions with Last-Write-Wins (LWW) conflict resolution
      final mergedTxMap = <String, TransactionModel>{};

      for (final localTx in localTransactions) {
        // Ignore any transaction that was deleted locally or remotely
        if (allTombstones.contains(localTx.id)) continue;

        // Skip sample/demo transactions from cloud upload and user storage unless explicitly consented
        if (localTx.isSample && !importDemoData) {
          debugPrint('[CloudMigration] Skipping demo transaction ${localTx.id} - no import consent');
          if (!isFreshUserSession) {
            // Existing user transactions preserve local state
            mergedTxMap[localTx.id] = localTx;
          }
          continue;
        }

        final remoteTx = remoteTxMap[localTx.id];
        if (remoteTx == null) {
          // New local transaction not yet on cloud: upload to Firestore
          await _cloudSync.saveTransaction(userId, localTx);
          mergedTxMap[localTx.id] = localTx;
          txCount++;
        } else {
          // Record exists on both local and cloud: compare UTC updatedAt
          if (localTx.updatedAt.isAfter(remoteTx.updatedAt)) {
            // Local edit is newer than remote: push local edit to cloud
            await _cloudSync.saveTransaction(userId, localTx);
            mergedTxMap[localTx.id] = localTx;
            txCount++;
          } else {
            // Remote version is newer or identical: remote wins
            mergedTxMap[localTx.id] = remoteTx;
          }
        }
      }

      // Add any remote transactions that weren't in local, excluding tombstones
      for (final remoteTx in remoteTransactions) {
        if (!allTombstones.contains(remoteTx.id) && !mergedTxMap.containsKey(remoteTx.id)) {
          mergedTxMap[remoteTx.id] = remoteTx;
        }
      }

      // 5. Migrate custom categories
      final mergedCatMap = <String, CategoryModel>{};
      for (final localCat in localCategories) {
        if (!remoteCatMap.containsKey(localCat.id)) {
          await _cloudSync.saveCustomCategory(userId, localCat);
          mergedCatMap[localCat.id] = localCat;
          catCount++;
        } else {
          mergedCatMap[localCat.id] = remoteCatMap[localCat.id]!;
        }
      }
      for (final remoteCat in remoteCategories) {
        mergedCatMap.putIfAbsent(remoteCat.id, () => remoteCat);
      }

      // 6. Migrate budget if remote has none
      if (remoteBudget == null && localBudget != null) {
        await _cloudSync.saveBudget(userId, localBudget);
        budgetDone = true;
      }

      // 7. Save reconciled merged dataset to user-scoped local storage
      final mergedTransactions = mergedTxMap.values.toList()
        ..sort((a, b) => b.date.compareTo(a.date));

      await _localStorage.saveTransactions(mergedTransactions, userId: userId);
      await _localStorage.saveCustomCategories(mergedCatMap.values.toList(), userId: userId);
      if (remoteBudget != null) {
        await _localStorage.saveBudget(remoteBudget, userId: userId);
      } else if (localBudget != null) {
        await _localStorage.saveBudget(localBudget, userId: userId);
      }

      debugPrint(
        '[CloudMigration] Migration successful: $txCount txs, $catCount categories, budget: $budgetDone, tombstones: $tombstonesCount',
      );

      return MigrationResult(
        isSuccess: true,
        transactionsMigrated: txCount,
        categoriesMigrated: catCount,
        budgetMigrated: budgetDone,
        tombstonesProcessed: tombstonesCount,
      );
    } catch (e) {
      debugPrint('[CloudMigration] Migration failed: $e');
      return MigrationResult(
        isSuccess: false,
        errorMessage: e.toString(),
      );
    }
  }
}

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Explicit synchronization statuses for cloud persistence
enum SyncStatus {
  localOnly,
  syncing,
  synced,
  syncFailed,
}

extension SyncStatusDetails on SyncStatus {
  /// Returns a truthful label distinguishing live Cloud Firestore from local in-memory Mock
  String getLabel({bool isMock = false}) {
    switch (this) {
      case SyncStatus.localOnly:
        return 'Local Only';
      case SyncStatus.syncing:
        return 'Syncing...';
      case SyncStatus.synced:
        return isMock ? 'Synced (Mock Dev)' : 'Synced (Firestore)';
      case SyncStatus.syncFailed:
        return 'Sync Failed';
    }
  }

  String get label => getLabel(isMock: false);

  IconData get icon {
    switch (this) {
      case SyncStatus.localOnly:
        return Icons.cloud_off_rounded;
      case SyncStatus.syncing:
        return Icons.sync_rounded;
      case SyncStatus.synced:
        return Icons.cloud_done_rounded;
      case SyncStatus.syncFailed:
        return Icons.cloud_sync_rounded;
    }
  }

  Color get color {
    switch (this) {
      case SyncStatus.localOnly:
        return AppColors.textTertiary;
      case SyncStatus.syncing:
        return AppColors.primaryNavy;
      case SyncStatus.synced:
        return AppColors.emeraldDark;
      case SyncStatus.syncFailed:
        return AppColors.expenseCoral;
    }
  }

  Color get backgroundColor {
    switch (this) {
      case SyncStatus.localOnly:
        return AppColors.surfaceMuted;
      case SyncStatus.syncing:
        return AppColors.primaryNavy.withValues(alpha: 0.1);
      case SyncStatus.synced:
        return AppColors.emeraldLight.withValues(alpha: 0.7);
      case SyncStatus.syncFailed:
        return AppColors.expenseCoral.withValues(alpha: 0.12);
    }
  }
}

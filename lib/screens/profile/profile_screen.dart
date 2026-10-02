import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/sync_status.dart';
import '../../providers/auth_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/custom_card.dart';
import '../auth/login_screen.dart';
import '../categories/manage_categories_screen.dart';
import '../../config/firebase_config.dart';

/// User Profile and preferences screen with Firebase Authentication & Cloud Sync
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _showLogoutDialog(BuildContext context, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text(
          'Are you sure you want to log out of Spendly? Local data will remain on this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await auth.logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.expenseCoral,
              foregroundColor: Colors.white,
            ),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }

  void _showDemoConsentDialog(BuildContext context, TransactionProvider txProvider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Import Demo Transactions?'),
        content: const Text(
          'Do you want to import Spendly\'s initial demo portfolio transactions into your cloud account? '
          'Your existing transactions and custom categories will remain completely safe.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await txProvider.syncWithCloud(importDemoData: true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryNavy,
              foregroundColor: Colors.white,
            ),
            child: const Text('Import Demo Data'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final txProvider = context.watch<TransactionProvider>();
    final user = authProvider.user;
    final isAuthenticated = authProvider.isAuthenticated;
    final syncStatus = txProvider.syncStatus;

    final displayName = user?.displayName.isNotEmpty == true
        ? user!.displayName
        : 'Alex Morgan';
    final email = user?.email.isNotEmpty == true
        ? user!.email
        : 'alex.morgan@university.edu';
    final initials = displayName
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();

    return Scaffold(
      backgroundColor: AppColors.backgroundCanvas,
      appBar: AppBar(
        title: const Text('Profile & Settings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // User Card
            CustomCard(
              padding: const EdgeInsets.all(20),
              backgroundColor: AppColors.surfaceWhite,
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: AppColors.primaryNavy,
                        child: Text(
                          initials.isNotEmpty ? initials : 'AM',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              email,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                // Sync Status Badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: syncStatus.backgroundColor,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        syncStatus.icon,
                                        size: 11,
                                        color: syncStatus.color,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        txProvider.syncStatusLabel,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: syncStatus.color,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.emeraldLight
                                        .withValues(alpha: 0.6),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'Free Student Plan',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.emeraldDark,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Divider(color: AppColors.borderSubtle, height: 1),
                  const SizedBox(height: 12),

                  // Auth Action Button
                  if (isAuthenticated) ...[
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => txProvider.syncWithCloud(),
                            icon: const Icon(Icons.sync_rounded, size: 16),
                            label: const Text('Sync Now'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primaryNavy,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _showLogoutDialog(context, authProvider),
                            icon: const Icon(Icons.logout_rounded, size: 16),
                            label: const Text('Sign Out'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.expenseCoral,
                              side: BorderSide(
                                color: AppColors.expenseCoral.withValues(alpha: 0.4),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    TextButton.icon(
                      onPressed: () => _showDemoConsentDialog(context, txProvider),
                      icon: const Icon(Icons.download_for_offline_outlined, size: 14),
                      label: const Text(
                        'Import Demo Transactions to Cloud...',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                    if (syncStatus == SyncStatus.syncFailed &&
                        txProvider.lastSyncError != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.expenseCoral.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color:
                                AppColors.expenseCoral.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              size: 16,
                              color: AppColors.expenseCoral,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                txProvider.lastSyncError!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.expenseCoral,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ]
                  else
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                          );
                        },
                        icon: const Icon(Icons.cloud_upload_outlined, size: 16),
                        label: const Text('Sign In to Enable Cloud Sync'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryNavy,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Settings Section
            CustomCard(
              padding: EdgeInsets.zero,
              backgroundColor: AppColors.surfaceWhite,
              child: Column(
                children: [
                  _SettingsTile(
                    icon: Icons.category_rounded,
                    title: 'Expense Categories',
                    subtitle: 'Create, edit & manage custom categories',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ManageCategoriesScreen(),
                        ),
                      );
                    },
                  ),
                  const Divider(color: AppColors.borderSubtle, height: 1),
                  _SettingsTile(
                    icon: Icons.cloud_sync_rounded,
                    title: 'Cloud Data Synchronization',
                    subtitle: isAuthenticated
                        ? (txProvider.isMockActive
                            ? 'In-Memory Mock Cloud (Dev Mode)'
                            : (syncStatus == SyncStatus.syncFailed &&
                                    txProvider.lastSyncError != null
                                ? 'Sync Failed: ${txProvider.lastSyncError}'
                                : 'Connected to Cloud Firestore (${FirebaseConfig.activeProjectId ?? "spendly-18e90"})'))
                        : 'Local storage active (Tap to sign in)',
                    onTap: () {
                      if (!isAuthenticated) {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                        );
                      } else {
                        txProvider.syncWithCloud();
                      }
                    },
                  ),
                  const Divider(color: AppColors.borderSubtle, height: 1),
                  _SettingsTile(
                    icon: Icons.security_rounded,
                    title: 'Security & Auth',
                    subtitle: isAuthenticated
                        ? (txProvider.isMockActive
                            ? 'Mock Authentication (Dev Mode)'
                            : 'Authenticated with Firebase (${FirebaseConfig.activeProjectId ?? "spendly-18e90"})')
                        : 'Sign in to protect records',
                    onTap: () {
                      if (!isAuthenticated) {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                        );
                      }
                    },
                  ),
                  const Divider(color: AppColors.borderSubtle, height: 1),
                  _SettingsTile(
                    icon: Icons.currency_exchange_rounded,
                    title: 'Currency Symbol',
                    subtitle: 'USD (\$) default',
                    onTap: () {},
                  ),
                  const Divider(color: AppColors.borderSubtle, height: 1),
                  _SettingsTile(
                    icon: Icons.info_outline_rounded,
                    title: 'About Spendly',
                    subtitle: 'v1.0.0 • Portfolio Edition',
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: AppColors.primaryNavy),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded,
            size: 14, color: AppColors.textTertiary),
      ),
    );
  }
}

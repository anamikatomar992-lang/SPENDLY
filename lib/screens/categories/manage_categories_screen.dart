import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/category_model.dart';
import '../../providers/transaction_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/custom_card.dart';
import 'widgets/category_form_dialog.dart';

/// Screen allowing users to view, create, edit, and safely delete custom categories
class ManageCategoriesScreen extends StatelessWidget {
  const ManageCategoriesScreen({super.key});

  void _showDeleteCategoryDialog(BuildContext context, CategoryModel category) {
    final provider = context.read<TransactionProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final count = provider.getTransactionCountForCategory(category.id);

    if (count == 0) {
      // Safe to delete immediately without reassignment
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Delete Category'),
          content: Text('Are you sure you want to delete "${category.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.expenseCoral),
              onPressed: () async {
                Navigator.of(ctx).pop();
                await provider.deleteCategory(category.id);
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Category "${category.name}" deleted.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: const Text('Delete'),
            ),
          ],
        ),
      );
    } else {
      // Category is in use: require replacement selection
      String? selectedReplacementId;
      final availableReplacements = provider.allCategories
          .where((c) => c.id.toLowerCase() != category.id.toLowerCase())
          .toList();

      if (availableReplacements.isNotEmpty) {
        selectedReplacementId = availableReplacements.first.id;
      }

      showDialog(
        context: context,
        builder: (ctx) {
          return StatefulBuilder(
            builder: (ctx, setState) {
              return AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                title: const Text('Reassign Transactions'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '"${category.name}" is currently used by $count transaction${count > 1 ? 's' : ''}.\n\nSelect a replacement category to safely reassign those transactions before deleting:',
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: selectedReplacementId,
                      decoration: const InputDecoration(
                        labelText: 'Replacement Category',
                      ),
                      items: availableReplacements.map((cat) {
                        return DropdownMenuItem<String>(
                          value: cat.id,
                          child: Row(
                            children: [
                              Icon(cat.icon, size: 18, color: cat.color),
                              const SizedBox(width: 8),
                              Text(cat.name),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() => selectedReplacementId = val);
                      },
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.expenseCoral),
                    onPressed: selectedReplacementId == null
                        ? null
                        : () async {
                            Navigator.of(ctx).pop();
                            await provider.deleteCategory(
                              category.id,
                              replacementCategoryId: selectedReplacementId,
                            );
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Category deleted. $count transaction${count > 1 ? 's' : ''} reassigned.',
                                ),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                    child: const Text('Reassign & Delete'),
                  ),
                ],
              );
            },
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransactionProvider>();
    final customCategories = provider.customCategories;
    const defaultCategories = CategoryModel.defaultCategories;

    return Scaffold(
      backgroundColor: AppColors.backgroundCanvas,
      appBar: AppBar(
        title: const Text('Manage Categories'),
        actions: [
          IconButton(
            onPressed: () => CategoryFormDialog.show(context),
            icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primaryNavy),
            tooltip: 'Add Custom Category',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => CategoryFormDialog.show(context),
        backgroundColor: AppColors.primaryNavy,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Category'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Custom Categories Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Custom Categories (${customCategories.length})',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                ),
                if (customCategories.isNotEmpty)
                  TextButton.icon(
                    onPressed: () => CategoryFormDialog.show(context),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add'),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      foregroundColor: AppColors.emeraldDark,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),

            // Custom Categories List / Empty State
            if (customCategories.isEmpty)
              CustomCard(
                padding: const EdgeInsets.all(24),
                backgroundColor: AppColors.surfaceWhite,
                child: Center(
                  child: Column(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: const BoxDecoration(
                          color: AppColors.surfaceMuted,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.category_outlined,
                          color: AppColors.textTertiary,
                          size: 26,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'No Custom Categories Yet',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Create personalized categories tailored to your spending habits.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: () => CategoryFormDialog.show(context),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Create First Category'),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: customCategories.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final cat = customCategories[index];
                  final txCount = provider.getTransactionCountForCategory(cat.id);

                  return CustomCard(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    backgroundColor: AppColors.surfaceWhite,
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: cat.color.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(cat.icon, color: cat.color, size: 20),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                cat.name,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$txCount transaction${txCount == 1 ? '' : 's'}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textTertiary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.textSecondary),
                          onPressed: () => CategoryFormDialog.show(context, categoryToEdit: cat),
                          tooltip: 'Edit Category',
                          visualDensity: VisualDensity.compact,
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.expenseCoral),
                          onPressed: () => _showDeleteCategoryDialog(context, cat),
                          tooltip: 'Delete Category',
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                  );
                },
              ),

            const SizedBox(height: 28),

            // System Categories Header
            Text(
              'Default System Categories (${defaultCategories.length})',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Standard built-in categories cannot be deleted to ensure baseline budget stability.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),

            // System Default Categories List
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: defaultCategories.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final cat = defaultCategories[index];
                final txCount = provider.getTransactionCountForCategory(cat.id);

                return CustomCard(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  backgroundColor: AppColors.surfaceWhite,
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: cat.color.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(cat.icon, color: cat.color, size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cat.name,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$txCount transaction${txCount == 1 ? '' : 's'}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceMuted,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'System',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 80), // spacing for FAB
          ],
        ),
      ),
    );
  }
}

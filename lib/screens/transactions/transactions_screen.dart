import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/transaction_model.dart';
import '../../providers/transaction_provider.dart';
import '../../theme/app_colors.dart';
import '../../utils/currency_formatter.dart';
import '../../utils/date_helpers.dart';
import '../../widgets/category_icon_badge.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/empty_state_view.dart';
import 'widgets/add_transaction_dialog.dart';

/// Transactions Screen with persistent search, category & type filters, sorting, and swipe-to-delete
class TransactionsScreen extends StatefulWidget {
  final VoidCallback onAddTransaction;

  const TransactionsScreen({
    super.key,
    required this.onAddTransaction,
  });

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final provider = context.read<TransactionProvider>();
    _searchController.text = provider.searchQuery;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onEditTransaction(TransactionModel transaction) {
    AddTransactionDialog.show(context, initialTransaction: transaction);
  }

  @override
  Widget build(BuildContext context) {
    final txProvider = context.watch<TransactionProvider>();
    final filtered = txProvider.filteredTransactions;
    final totalCount = txProvider.transactions.length;

    return Scaffold(
      backgroundColor: AppColors.backgroundCanvas,
      appBar: AppBar(
        title: const Text('Transaction History'),
        actions: [
          // Sorting Menu Button
          PopupMenuButton<TransactionSortOrder>(
            icon: const Icon(Icons.sort_rounded, color: AppColors.primaryNavy),
            tooltip: 'Sort Transactions',
            initialValue: txProvider.selectedSortOrder,
            onSelected: (order) => txProvider.setSortOrder(order),
            itemBuilder: (context) {
              return TransactionSortOrder.values.map((order) {
                return PopupMenuItem(
                  value: order,
                  child: Row(
                    children: [
                      Icon(
                        order == txProvider.selectedSortOrder
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_off_rounded,
                        size: 18,
                        color: order == txProvider.selectedSortOrder
                            ? AppColors.primaryNavy
                            : AppColors.textTertiary,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        order.label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: order == txProvider.selectedSortOrder
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList();
            },
          ),
          IconButton(
            onPressed: widget.onAddTransaction,
            icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primaryNavy),
            tooltip: 'Add Transaction',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar & Filter Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Column(
              children: [
                // Search Input
                TextField(
                  controller: _searchController,
                  onChanged: (val) => txProvider.setSearchQuery(val),
                  decoration: InputDecoration(
                    hintText: 'Search title, category, payment method...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.textSecondary),
                    suffixIcon: txProvider.searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              txProvider.setSearchQuery('');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.surfaceWhite,
                  ),
                ),
                const SizedBox(height: 12),

                // Type Filters (All, Expense, Income)
                Row(
                  children: [
                    _FilterChip(
                      label: 'All ($totalCount)',
                      isSelected: txProvider.selectedTypeFilter == 'All',
                      onTap: () => txProvider.setTypeFilter('All'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Expenses',
                      isSelected: txProvider.selectedTypeFilter == 'Expense',
                      onTap: () => txProvider.setTypeFilter('Expense'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Income',
                      isSelected: txProvider.selectedTypeFilter == 'Income',
                      onTap: () => txProvider.setTypeFilter('Income'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Category Filter Pills
                SizedBox(
                  height: 34,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _CategoryFilterPill(
                        label: 'All Categories',
                        isSelected: txProvider.selectedCategoryId == null,
                        onTap: () => txProvider.setCategoryFilter(null),
                      ),
                      ...txProvider.allCategories.map((cat) {
                        return Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: _CategoryFilterPill(
                            label: cat.name,
                            icon: cat.icon,
                            iconColor: cat.color,
                            isSelected: txProvider.selectedCategoryId == cat.id,
                            onTap: () => txProvider.setCategoryFilter(
                              txProvider.selectedCategoryId == cat.id ? null : cat.id,
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // Active filter indicator / count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Showing ${filtered.length} of $totalCount items',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textTertiary,
                        fontWeight: FontWeight.w500,
                      ),
                ),
                if (txProvider.searchQuery.isNotEmpty ||
                    txProvider.selectedTypeFilter != 'All' ||
                    txProvider.selectedCategoryId != null)
                  GestureDetector(
                    onTap: () {
                      _searchController.clear();
                      txProvider.resetFilters();
                    },
                    child: const Text(
                      'Clear Filters',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryNavy,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),

          // Transaction list with Swipe to Delete and Tap to Edit
          Expanded(
            child: filtered.isEmpty
                ? EmptyStateView(
                    icon: Icons.search_off_rounded,
                    title: 'No matching transactions',
                    description: (txProvider.searchQuery.isNotEmpty ||
                            txProvider.selectedTypeFilter != 'All' ||
                            txProvider.selectedCategoryId != null)
                        ? 'Try loosening your search query or reset active filters.'
                        : 'Tap "+ Add" to log your first income or expense transaction.',
                    actionLabel: (txProvider.searchQuery.isNotEmpty ||
                            txProvider.selectedTypeFilter != 'All' ||
                            txProvider.selectedCategoryId != null)
                        ? 'Reset All Filters'
                        : 'Add Transaction',
                    onActionPressed: (txProvider.searchQuery.isNotEmpty ||
                            txProvider.selectedTypeFilter != 'All' ||
                            txProvider.selectedCategoryId != null)
                        ? () {
                            _searchController.clear();
                            txProvider.resetFilters();
                          }
                        : widget.onAddTransaction,
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    itemCount: filtered.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final tx = filtered[index];
                      return Dismissible(
                        key: ValueKey(tx.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          decoration: BoxDecoration(
                            color: AppColors.expenseCoral,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.delete_sweep_rounded, color: Colors.white, size: 24),
                              SizedBox(width: 8),
                              Text(
                                'Delete',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        onDismissed: (direction) async {
                          final deletedTitle = tx.title;
                          final deleted = await txProvider.deleteTransaction(tx.id);
                          if (context.mounted && deleted != null) {
                            ScaffoldMessenger.of(context).clearSnackBars();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Deleted "$deletedTitle"'),
                                duration: const Duration(seconds: 5),
                                behavior: SnackBarBehavior.floating,
                                action: SnackBarAction(
                                  label: 'UNDO',
                                  textColor: AppColors.emeraldGreen,
                                  onPressed: () {
                                    txProvider.undoDelete();
                                  },
                                ),
                              ),
                            );
                          }
                        },
                        child: CustomCard(
                          padding: const EdgeInsets.all(14),
                          backgroundColor: AppColors.surfaceWhite,
                          onTap: () => _onEditTransaction(tx),
                          child: Row(
                            children: [
                              CategoryIconBadge(category: tx.category),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      tx.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${DateHelpers.formatRelative(tx.date)} • ${tx.paymentMethod.label}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textTertiary,
                                      ),
                                    ),
                                    if (tx.note != null && tx.note!.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        tx.note!,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontStyle: FontStyle.italic,
                                          color: AppColors.textSecondary.withValues(alpha: 0.8),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    CurrencyFormatter.formatSigned(
                                      tx.amount,
                                      isExpense: tx.isExpense,
                                    ),
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: tx.isExpense
                                          ? AppColors.expenseCoral
                                          : AppColors.emeraldDark,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    tx.category.name,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textTertiary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryNavy : AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primaryNavy : AppColors.borderLight,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _CategoryFilterPill extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? iconColor;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryFilterPill({
    required this.label,
    this.icon,
    this.iconColor,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryNavy : AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primaryNavy : AppColors.borderLight,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: isSelected ? Colors.white : (iconColor ?? AppColors.textSecondary)),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

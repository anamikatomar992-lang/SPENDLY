import 'package:flutter/material.dart';
import '../../../models/transaction_model.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/currency_formatter.dart';
import '../../../utils/date_helpers.dart';
import '../../../widgets/category_icon_badge.dart';
import '../../../widgets/custom_card.dart';

/// Recent transactions list with category icon, payment badge, and signed amounts
class RecentTransactionsSection extends StatelessWidget {
  final List<TransactionModel> transactions;
  final VoidCallback onSeeAll;
  final Function(TransactionModel transaction)? onTransactionTap;

  const RecentTransactionsSection({
    super.key,
    required this.transactions,
    required this.onSeeAll,
    this.onTransactionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Recent Transactions',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
              ),
            ),
            TextButton(
              onPressed: onSeeAll,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primaryNavy,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Row(
                children: [
                  Text(
                    'See All',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryNavy,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward_ios_rounded, size: 12),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (transactions.isEmpty)
          const CustomCard(
            padding: EdgeInsets.symmetric(vertical: 32, horizontal: 16),
            backgroundColor: AppColors.surfaceWhite,
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.receipt_long_outlined, size: 40, color: AppColors.textTertiary),
                  SizedBox(height: 8),
                  Text(
                    'No transactions yet',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          CustomCard(
            padding: EdgeInsets.zero,
            backgroundColor: AppColors.surfaceWhite,
            child: ListView.separated(
              itemCount: transactions.take(5).length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              separatorBuilder: (context, index) => const Divider(
                height: 1,
                indent: 68,
                endIndent: 16,
                color: AppColors.borderSubtle,
              ),
              itemBuilder: (context, index) {
                final tx = transactions[index];
                final isExpense = tx.isExpense;

                return InkWell(
                  onTap: () => onTransactionTap?.call(tx),
                  borderRadius: BorderRadius.vertical(
                    top: index == 0 ? const Radius.circular(20) : Radius.zero,
                    bottom: index == transactions.take(5).length - 1
                        ? const Radius.circular(20)
                        : Radius.zero,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        CategoryIconBadge(
                          category: tx.category,
                          size: 44,
                          iconSize: 22,
                        ),
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
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      '${DateHelpers.formatRelative(tx.date)} • ${tx.paymentMethod.label}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textTertiary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
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
                                isExpense: isExpense,
                              ),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: isExpense
                                    ? AppColors.expenseCoral
                                    : AppColors.emeraldDark,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              tx.category.name,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
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
    );
  }
}

import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/currency_formatter.dart';

/// Hero Balance Card with deep navy gradient, eye privacy toggle, and savings indicator
class BalanceCard extends StatelessWidget {
  final double totalBalance;
  final double monthlySavings;
  final double savingsPercentage;
  final bool isVisible;
  final VoidCallback onToggleVisibility;

  const BalanceCard({
    super.key,
    required this.totalBalance,
    required this.monthlySavings,
    required this.savingsPercentage,
    required this.isVisible,
    required this.onToggleVisibility,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0F172A), // Deep Navy
            Color(0xFF1E293B), // Medium Navy Slate
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppColors.heroCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_rounded,
                      size: 16,
                      color: AppColors.emeraldGreen,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Total Available Balance',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.75),
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: onToggleVisibility,
                icon: Icon(
                  isVisible ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                  color: Colors.white.withValues(alpha: 0.7),
                  size: 20,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: isVisible ? 'Hide Balance' : 'Show Balance',
              ),
            ],
          ),
          const SizedBox(height: 14),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            crossFadeState:
                isVisible ? CrossFadeState.showFirst : CrossFadeState.showSecond,
            firstChild: Text(
              CurrencyFormatter.format(totalBalance),
              style: const TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
            secondChild: const Text(
              '••••••••',
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 2.0,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.trending_up_rounded,
                  size: 16,
                  color: AppColors.emeraldGreen,
                ),
                const SizedBox(width: 6),
                Text(
                  'This Month: ',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w400,
                  ),
                ),
                Text(
                  isVisible
                      ? '${CurrencyFormatter.formatSigned(monthlySavings)} (${savingsPercentage.toStringAsFixed(1)}% saved)'
                      : 'Saved ••••',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.emeraldGreen,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

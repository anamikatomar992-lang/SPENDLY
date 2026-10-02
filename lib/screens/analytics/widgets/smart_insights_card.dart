import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/financial_insight_model.dart';
import '../../../providers/transaction_provider.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/custom_card.dart';

/// Personalized Rule-Based Financial Intelligence & Insights Section
class SmartInsightsCard extends StatelessWidget {
  const SmartInsightsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final txProvider = context.watch<TransactionProvider>();
    final insights = txProvider.smartInsights;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primaryNavy.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                size: 16,
                color: AppColors.primaryNavy,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Smart Financial Intelligence',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
            ),
            const Spacer(),
            Text(
              '${insights.length} active',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: insights.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final insight = insights[index];
            return _InsightTile(insight: insight);
          },
        ),
      ],
    );
  }
}

class _InsightTile extends StatelessWidget {
  final FinancialInsight insight;

  const _InsightTile({required this.insight});

  Color _getBorderColor() {
    switch (insight.type) {
      case InsightType.achievement:
        return AppColors.emeraldDark.withValues(alpha: 0.2);
      case InsightType.warning:
        return AppColors.warningAmber.withValues(alpha: 0.3);
      case InsightType.alert:
        return AppColors.expenseCoral.withValues(alpha: 0.3);
      case InsightType.info:
        return AppColors.borderLight;
    }
  }

  Color _getBadgeBackgroundColor() {
    switch (insight.type) {
      case InsightType.achievement:
        return AppColors.emeraldLight.withValues(alpha: 0.7);
      case InsightType.warning:
        return AppColors.warningAmber.withValues(alpha: 0.14);
      case InsightType.alert:
        return AppColors.expenseCoral.withValues(alpha: 0.14);
      case InsightType.info:
        return AppColors.surfaceMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      padding: const EdgeInsets.all(16),
      backgroundColor: AppColors.surfaceWhite,
      border: Border.all(color: _getBorderColor(), width: 1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: insight.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              insight.icon,
              size: 20,
              color: insight.color,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        insight.title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (insight.badgeText != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: _getBadgeBackgroundColor(),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          insight.badgeText!,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: insight.color,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  insight.message,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.4,
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

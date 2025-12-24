import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';

/// Revenue bar chart widget for dashboard
class RevenueChart extends StatelessWidget {
  final Map<String, double> monthlyData;

  const RevenueChart({super.key, required this.monthlyData});

  @override
  Widget build(BuildContext context) {
    if (monthlyData.isEmpty) {
      return Container(
        height: 200,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.getSurface(context),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.getBorder(context)),
        ),
        child: Center(
          child: Text(
            'No revenue data yet',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.getTextSecondary(context),
            ),
          ),
        ),
      );
    }

    final entries = monthlyData.entries.toList();
    final maxValue = monthlyData.values.reduce((a, b) => a > b ? a : b);

    return Container(
      height: 220,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.getSurface(context),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.getBorder(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Monthly Revenue',
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.getTextPrimary(context),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxValue * 1.2,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '\$${rod.toY.toStringAsFixed(0)}',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() < entries.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              entries[value.toInt()].key,
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.getTextSecondary(context),
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                      reservedSize: 30,
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: false),
                barGroups: entries.asMap().entries.map((entry) {
                  return BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: entry.value.value,
                        color: AppColors.primary,
                        width: 20,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Payment status pie chart
class PaymentStatusChart extends StatelessWidget {
  final int paidCount;
  final int unpaidCount;
  final int partialCount;
  final int overdueCount;

  const PaymentStatusChart({
    super.key,
    required this.paidCount,
    required this.unpaidCount,
    required this.partialCount,
    required this.overdueCount,
  });

  @override
  Widget build(BuildContext context) {
    final total = paidCount + unpaidCount + partialCount + overdueCount;

    if (total == 0) {
      return Container(
        height: 180,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.getSurface(context),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.getBorder(context)),
        ),
        child: Center(
          child: Text(
            'No invoices yet',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.getTextSecondary(context),
            ),
          ),
        ),
      );
    }

    return Container(
      height: 180,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.getSurface(context),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.getBorder(context)),
      ),
      child: Row(
        children: [
          Expanded(
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 30,
                sections: [
                  if (paidCount > 0)
                    PieChartSectionData(
                      color: AppColors.paid,
                      value: paidCount.toDouble(),
                      title: '',
                      radius: 25,
                    ),
                  if (unpaidCount > 0)
                    PieChartSectionData(
                      color: AppColors.unpaid,
                      value: unpaidCount.toDouble(),
                      title: '',
                      radius: 25,
                    ),
                  if (partialCount > 0)
                    PieChartSectionData(
                      color: AppColors.partial,
                      value: partialCount.toDouble(),
                      title: '',
                      radius: 25,
                    ),
                  if (overdueCount > 0)
                    PieChartSectionData(
                      color: AppColors.overdue,
                      value: overdueCount.toDouble(),
                      title: '',
                      radius: 25,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLegendItem(context, 'Paid', paidCount, AppColors.paid),
              const SizedBox(height: 6),
              _buildLegendItem(
                context,
                'Unpaid',
                unpaidCount,
                AppColors.unpaid,
              ),
              const SizedBox(height: 6),
              _buildLegendItem(
                context,
                'Partial',
                partialCount,
                AppColors.partial,
              ),
              const SizedBox(height: 6),
              _buildLegendItem(
                context,
                'Overdue',
                overdueCount,
                AppColors.overdue,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(
    BuildContext context,
    String label,
    int count,
    Color color,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          '$label ($count)',
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.getTextSecondary(context),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';
import '../models/estimate.dart';
import 'estimate_form_screen.dart';

/// Estimates list screen
class EstimatesScreen extends StatelessWidget {
  const EstimatesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(title: const Text('Estimates')),
          body: appState.estimates.isEmpty
              ? EmptyState(
                  icon: Icons.description,
                  title: 'No estimates yet',
                  subtitle: 'Create estimates to send quotes to clients',
                  buttonLabel: 'Create Estimate',
                  onButtonPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const EstimateFormScreen(),
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: appState.estimates.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final estimate = appState.estimates[index];
                    return _EstimateCard(estimate: estimate);
                  },
                ),
          floatingActionButton: FloatingActionButton.extended(
            heroTag: 'estimates_fab',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EstimateFormScreen()),
            ),
            icon: const Icon(Icons.add),
            label: const Text('New Estimate'),
          ),
        );
      },
    );
  }
}

class _EstimateCard extends StatelessWidget {
  final Estimate estimate;
  const _EstimateCard({required this.estimate});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(estimate.estimateNumber, style: AppTypography.titleMedium),
              StatusBadge(
                label: estimate.status.name.toUpperCase(),
                color: AppColors.accent.withOpacity(0.15),
                textColor: AppColors.accent,
                isSmall: true,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            estimate.clientName ?? 'Unknown',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Valid until ${estimate.validUntil.day}/${estimate.validUntil.month}',
                style: AppTypography.bodySmall,
              ),
              Text(
                '\$${estimate.total.toStringAsFixed(2)}',
                style: AppTypography.titleMedium,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

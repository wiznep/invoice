import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';
import 'invoice_form_screen.dart';
import 'estimate_form_screen.dart';
import 'invoice_detail_screen.dart';

/// Dashboard screen - main overview of the app
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '\$');

    return Consumer<AppState>(
      builder: (context, appState, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Dashboard'),
            actions: [
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => _showQuickActions(context),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary cards
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: AppSpacing.sm,
                  crossAxisSpacing: AppSpacing.sm,
                  childAspectRatio: 1.3,
                  children: [
                    StatCard(
                      title: 'Total Revenue',
                      value: currencyFormat.format(appState.totalRevenue),
                      icon: Icons.trending_up,
                      iconColor: AppColors.success,
                    ),
                    StatCard(
                      title: 'Outstanding',
                      value: currencyFormat.format(appState.totalOutstanding),
                      icon: Icons.payment,
                      iconColor: AppColors.warning,
                    ),
                    StatCard(
                      title: 'Invoices',
                      value: appState.invoices.length.toString(),
                      icon: Icons.receipt_long,
                      iconColor: AppColors.primary,
                    ),
                    StatCard(
                      title: 'Clients',
                      value: appState.clients.length.toString(),
                      icon: Icons.people,
                      iconColor: AppColors.accent,
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.md),

                // Payment status chart
                PaymentStatusChart(
                  paidCount: appState.paidInvoices.length,
                  unpaidCount: appState.unpaidInvoices.length,
                  partialCount: appState.partialInvoices.length,
                  overdueCount: appState.overdueInvoices.length,
                ),

                const SizedBox(height: AppSpacing.lg),

                // Quick actions
                Text(
                  'Quick Actions',
                  style: AppTypography.titleMedium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: _QuickActionButton(
                        icon: Icons.add_circle,
                        label: 'New Invoice',
                        color: AppColors.primary,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const InvoiceFormScreen(),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _QuickActionButton(
                        icon: Icons.description,
                        label: 'New Estimate',
                        color: AppColors.accent,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const EstimateFormScreen(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.lg),

                // Recent invoices / overdue
                if (appState.overdueInvoices.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Overdue',
                        style: AppTypography.titleMedium.copyWith(
                          color: AppColors.overdue,
                        ),
                      ),
                      Text(
                        '${appState.overdueInvoices.length} invoice(s)',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ...appState.overdueInvoices
                      .take(3)
                      .map(
                        (invoice) => Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: InvoiceCard(
                            invoice: invoice,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    InvoiceDetailScreen(invoiceId: invoice.id),
                              ),
                            ),
                          ),
                        ),
                      ),
                  const SizedBox(height: AppSpacing.md),
                ],

                // Recent invoices
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Invoices',
                      style: AppTypography.titleMedium.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                if (appState.invoices.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.receipt_long,
                          size: 48,
                          color: AppColors.textTertiary,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'No invoices yet',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        ElevatedButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const InvoiceFormScreen(),
                            ),
                          ),
                          child: const Text('Create Invoice'),
                        ),
                      ],
                    ),
                  )
                else
                  ...appState.invoices
                      .take(5)
                      .map(
                        (invoice) => Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: InvoiceCard(
                            invoice: invoice,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    InvoiceDetailScreen(invoiceId: invoice.id),
                              ),
                            ),
                          ),
                        ),
                      ),

                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showQuickActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(Icons.add_circle, color: AppColors.primary),
                ),
                title: const Text('New Invoice'),
                subtitle: const Text('Create a new invoice'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const InvoiceFormScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(Icons.description, color: AppColors.accent),
                ),
                title: const Text('New Estimate'),
                subtitle: const Text('Create a new estimate'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const EstimateFormScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Text(label, style: AppTypography.labelLarge.copyWith(color: color)),
          ],
        ),
      ),
    );
  }
}

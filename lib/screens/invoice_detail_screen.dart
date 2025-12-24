import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../widgets/widgets.dart';
import '../services/pdf_service.dart';

/// Invoice detail screen
class InvoiceDetailScreen extends StatelessWidget {
  final String invoiceId;

  const InvoiceDetailScreen({super.key, required this.invoiceId});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    final dateFormat = DateFormat('MMM d, yyyy');

    return Consumer<AppState>(
      builder: (context, appState, child) {
        final invoice = appState.getInvoiceById(invoiceId);

        if (invoice == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Invoice')),
            body: const Center(child: Text('Invoice not found')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(invoice.invoiceNumber),
            actions: [
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: () => _shareInvoice(context, invoice),
              ),
              PopupMenuButton<String>(
                onSelected: (value) =>
                    _handleMenuAction(context, value, invoice, appState),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'print',
                    child: Text('Print / Preview'),
                  ),
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  const PopupMenuItem(
                    value: 'duplicate',
                    child: Text('Duplicate'),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text(
                      'Delete',
                      style: TextStyle(color: AppColors.error),
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Status & Amount Card
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total Amount',
                            style: AppTypography.bodyMedium.copyWith(
                              color: Colors.white70,
                            ),
                          ),
                          if (invoice.isOverdue)
                            StatusBadge.overdue()
                          else
                            StatusBadge.fromPaymentStatus(invoice.status),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        currencyFormat.format(invoice.total),
                        style: AppTypography.displayLarge.copyWith(
                          color: Colors.white,
                        ),
                      ),
                      if (invoice.status != PaymentStatus.paid) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Balance due: ${currencyFormat.format(invoice.balanceDue)}',
                          style: AppTypography.bodyMedium.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // Client section
                _buildSection(
                  context,
                  title: 'Client',
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Center(
                          child: Text(
                            invoice.clientName?[0].toUpperCase() ?? '?',
                            style: AppTypography.titleLarge.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              invoice.clientName ?? 'Unknown Client',
                              style: AppTypography.titleMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.md),

                // Dates section
                _buildSection(
                  context,
                  title: 'Dates',
                  child: Column(
                    children: [
                      _buildInfoRow(
                        'Issue Date',
                        dateFormat.format(invoice.issueDate),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _buildInfoRow(
                        'Due Date',
                        dateFormat.format(invoice.dueDate),
                        valueColor: invoice.isOverdue ? AppColors.error : null,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.md),

                // Items section
                _buildSection(
                  context,
                  title: 'Items',
                  child: Column(
                    children: invoice.items.map((item) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    style: AppTypography.titleMedium,
                                  ),
                                  Text(
                                    '${item.quantity} × ${currencyFormat.format(item.price)}',
                                    style: AppTypography.bodySmall.copyWith(
                                      color: AppColors.getTextSecondary(
                                        context,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              currencyFormat.format(item.total),
                              style: AppTypography.titleMedium,
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: AppSpacing.md),

                // Summary section
                _buildSection(
                  context,
                  title: 'Summary',
                  child: Column(
                    children: [
                      _buildInfoRow(
                        'Subtotal',
                        currencyFormat.format(invoice.subtotal),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _buildInfoRow(
                        'Tax',
                        currencyFormat.format(invoice.taxAmount),
                      ),
                      const Divider(height: AppSpacing.lg),
                      _buildInfoRow(
                        'Total',
                        currencyFormat.format(invoice.total),
                        isBold: true,
                      ),
                      if (invoice.paidAmount > 0) ...[
                        const SizedBox(height: AppSpacing.sm),
                        _buildInfoRow(
                          'Paid',
                          '- ${currencyFormat.format(invoice.paidAmount)}',
                          valueColor: AppColors.success,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _buildInfoRow(
                          'Balance Due',
                          currencyFormat.format(invoice.balanceDue),
                          isBold: true,
                          valueColor: AppColors.primary,
                        ),
                      ],
                    ],
                  ),
                ),

                if (invoice.notes != null && invoice.notes!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  _buildSection(
                    context,
                    title: 'Notes',
                    child: Text(
                      invoice.notes!,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.getTextSecondary(context),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: AppSpacing.xl),

                // Action buttons
                if (invoice.status != PaymentStatus.paid)
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () =>
                          _recordPayment(context, invoice, appState),
                      child: const Text('Record Payment'),
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

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required Widget child,
  }) {
    return Container(
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
            title,
            style: AppTypography.labelLarge.copyWith(
              color: AppColors.getTextSecondary(context),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    bool isBold = false,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: (isBold ? AppTypography.titleMedium : AppTypography.bodyMedium)
              .copyWith(color: valueColor),
        ),
      ],
    );
  }

  InvoiceTemplate _getTemplateFromSettings(String templateName) {
    switch (templateName) {
      case 'modern':
        return InvoiceTemplate.modern;
      case 'minimal':
        return InvoiceTemplate.minimal;
      default:
        return InvoiceTemplate.classic;
    }
  }

  void _shareInvoice(BuildContext context, Invoice invoice) async {
    try {
      final appState = context.read<AppState>();
      final template = _getTemplateFromSettings(
        appState.settings.invoiceTemplate,
      );
      await PdfService().shareInvoice(
        invoice,
        settings: appState.settings,
        template: template,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error generating PDF: $e')));
      }
    }
  }

  void _handleMenuAction(
    BuildContext context,
    String action,
    Invoice invoice,
    AppState appState,
  ) {
    switch (action) {
      case 'print':
        final template = _getTemplateFromSettings(
          appState.settings.invoiceTemplate,
        );
        PdfService().printInvoice(
          invoice,
          settings: appState.settings,
          template: template,
        );
        break;
      case 'edit':
        // Navigate to edit screen
        break;
      case 'duplicate':
        // Duplicate invoice
        break;
      case 'delete':
        _deleteInvoice(context, invoice);
        break;
    }
  }

  Future<void> _deleteInvoice(BuildContext context, Invoice invoice) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Invoice'),
        content: Text(
          'Are you sure you want to delete ${invoice.invoiceNumber}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await context.read<AppState>().deleteInvoice(invoice.id);
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Invoice deleted')));
      }
    }
  }

  void _recordPayment(
    BuildContext context,
    Invoice invoice,
    AppState appState,
  ) {
    final amountController = TextEditingController(
      text: invoice.balanceDue.toStringAsFixed(2),
    );
    String? selectedMethod;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.getSurface(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Record Payment', style: AppTypography.titleLarge),
                  const SizedBox(height: AppSpacing.lg),

                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Amount',
                      prefixText: '\$ ',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  DropdownButtonFormField<String>(
                    value: selectedMethod,
                    decoration: const InputDecoration(
                      labelText: 'Payment Method',
                    ),
                    items: ['Cash', 'Bank Transfer', 'Card', 'Check', 'Other']
                        .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                        .toList(),
                    onChanged: (v) => setModalState(() => selectedMethod = v),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  ElevatedButton(
                    onPressed: () async {
                      final amount =
                          double.tryParse(amountController.text) ?? 0;
                      if (amount > 0) {
                        await appState.recordPayment(
                          invoiceId: invoice.id,
                          amount: amount,
                          method: selectedMethod,
                        );
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Payment recorded')),
                          );
                        }
                      }
                    },
                    child: const Text('Record Payment'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

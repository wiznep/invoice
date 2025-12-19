import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';
import '../models/invoice.dart';
import 'invoice_form_screen.dart';
import 'invoice_detail_screen.dart';

/// Invoices list screen
class InvoicesScreen extends StatefulWidget {
  const InvoicesScreen({super.key});

  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Invoices'),
            bottom: TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              tabs: [
                Tab(text: 'All (${appState.invoices.length})'),
                Tab(text: 'Unpaid (${appState.unpaidInvoices.length})'),
                Tab(text: 'Partial (${appState.partialInvoices.length})'),
                Tab(text: 'Paid (${appState.paidInvoices.length})'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _InvoiceList(invoices: appState.invoices),
              _InvoiceList(invoices: appState.unpaidInvoices),
              _InvoiceList(invoices: appState.partialInvoices),
              _InvoiceList(invoices: appState.paidInvoices),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            heroTag: 'invoices_fab',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const InvoiceFormScreen()),
            ),
            icon: const Icon(Icons.add),
            label: const Text('New Invoice'),
          ),
        );
      },
    );
  }
}

class _InvoiceList extends StatelessWidget {
  final List<Invoice> invoices;

  const _InvoiceList({required this.invoices});

  @override
  Widget build(BuildContext context) {
    if (invoices.isEmpty) {
      return EmptyState(
        icon: Icons.receipt_long,
        title: 'No invoices',
        subtitle: 'Create your first invoice to get started',
        buttonLabel: 'Create Invoice',
        onButtonPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const InvoiceFormScreen()),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: invoices.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final invoice = invoices[index];
        return InvoiceCard(
          invoice: invoice,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => InvoiceDetailScreen(invoiceId: invoice.id),
            ),
          ),
        );
      },
    );
  }
}

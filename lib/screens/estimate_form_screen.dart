import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';

/// Estimate creation form
class EstimateFormScreen extends StatefulWidget {
  final Estimate? estimate;
  const EstimateFormScreen({super.key, this.estimate});

  @override
  State<EstimateFormScreen> createState() => _EstimateFormScreenState();
}

class _EstimateFormScreenState extends State<EstimateFormScreen> {
  Client? _selectedClient;
  List<InvoiceItem> _items = [];
  DateTime _validUntil = DateTime.now().add(const Duration(days: 30));
  final _notesController = TextEditingController();
  bool _isLoading = false;

  double get total => _items.fold(0, (s, i) => s + i.total);

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '\$');

    return Scaffold(
      
      appBar: AppBar(title: const Text('New Estimate')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          _buildClientSelector(),
          const SizedBox(height: AppSpacing.lg),
          _buildItemsSection(currencyFormat),
          const SizedBox(height: AppSpacing.lg),
          _buildDatePicker(),
          const SizedBox(height: AppSpacing.lg),
          TextFormField(
            controller: _notesController,
            maxLines: 3,
            decoration: const InputDecoration(hintText: 'Notes'),
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildSummary(currencyFormat),
          const SizedBox(height: AppSpacing.xl),
          ElevatedButton(
            onPressed: _canSave ? _saveEstimate : null,
            child: _isLoading
                ? const CircularProgressIndicator()
                : const Text('Create Estimate'),
          ),
        ],
      ),
    );
  }

  bool get _canSave => _selectedClient != null && _items.isNotEmpty;

  Widget _buildClientSelector() {
    return GestureDetector(
      onTap: _showClientPicker,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.getSurfaceVariant(context),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          children: [
            Icon(Icons.person, color: AppColors.accent),
            const SizedBox(width: AppSpacing.md),
            Text(_selectedClient?.name ?? 'Select Client'),
            const Spacer(),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsSection(NumberFormat fmt) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Items', style: AppTypography.labelLarge),
            TextButton.icon(
              onPressed: _showAddItemDialog,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add'),
            ),
          ],
        ),
        if (_items.isEmpty)
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.getSurfaceVariant(context),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: const Center(child: Text('No items added')),
          )
        else
          ...List.generate(_items.length, (i) {
            final item = _items[i];
            return ListTile(
              title: Text(item.name),
              subtitle: Text('${item.quantity} × ${fmt.format(item.price)}'),
              trailing: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() => _items.removeAt(i)),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildDatePicker() {
    return GestureDetector(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _validUntil,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (date != null) setState(() => _validUntil = date);
      },
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.getSurfaceVariant(context),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          children: [
            Text('Valid Until: ${DateFormat('MMM d').format(_validUntil)}'),
            const Spacer(),
            const Icon(Icons.calendar_today, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary(NumberFormat fmt) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.getSurface(context),
        border: Border.all(color: AppColors.getBorder(context)),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Total', style: AppTypography.titleMedium),
          Text(fmt.format(total), style: AppTypography.headlineMedium),
        ],
      ),
    );
  }

  void _showClientPicker() {
    final clients = context.read<AppState>().clients;
    showModalBottomSheet(
      context: context,
      builder: (_) => ListView.builder(
        itemCount: clients.length,
        itemBuilder: (_, i) => ListTile(
          title: Text(clients[i].name),
          onTap: () {
            setState(() => _selectedClient = clients[i]);
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  void _showAddItemDialog() {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final qtyCtrl = TextEditingController(text: '1');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: priceCtrl,
              decoration: const InputDecoration(labelText: 'Price'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: qtyCtrl,
              decoration: const InputDecoration(labelText: 'Qty'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                if (nameCtrl.text.isNotEmpty) {
                  final item = InvoiceItem(
                    id: DateTime.now().toString(),
                    itemId: '',
                    name: nameCtrl.text,
                    price: double.tryParse(priceCtrl.text) ?? 0,
                    quantity: double.tryParse(qtyCtrl.text) ?? 1,
                  );
                  setState(() => _items.add(item));
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _saveEstimate() async {
    setState(() => _isLoading = true);
    try {
      await context.read<AppState>().createEstimate(
        clientId: _selectedClient!.id,
        items: _items,
        validUntil: _validUntil,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';

/// Invoice creation/editing form screen
class InvoiceFormScreen extends StatefulWidget {
  final Invoice? invoice;

  const InvoiceFormScreen({super.key, this.invoice});

  @override
  State<InvoiceFormScreen> createState() => _InvoiceFormScreenState();
}

class _InvoiceFormScreenState extends State<InvoiceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  Client? _selectedClient;
  List<InvoiceItem> _items = [];
  DateTime _dueDate = DateTime.now().add(const Duration(days: 30));
  final TextEditingController _notesController = TextEditingController();
  bool _isLoading = false;

  bool get isEditing => widget.invoice != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      final appState = context.read<AppState>();
      _selectedClient = appState.getClientById(widget.invoice!.clientId);
      _items = List.from(widget.invoice!.items);
      _dueDate = widget.invoice!.dueDate;
      _notesController.text = widget.invoice!.notes ?? '';
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  double get subtotal => _items.fold(0, (sum, item) => sum + item.subtotal);
  double get taxAmount => _items.fold(0, (sum, item) => sum + item.taxAmount);
  double get total => subtotal + taxAmount;

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    final dateFormat = DateFormat('MMM d, yyyy');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(isEditing ? 'Edit Invoice' : 'New Invoice')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            // Client selection
            _buildSectionTitle('Client'),
            const SizedBox(height: AppSpacing.sm),
            _buildClientSelector(),

            const SizedBox(height: AppSpacing.lg),

            // Items section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSectionTitle('Items'),
                TextButton.icon(
                  onPressed: () => _showAddItemDialog(),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Item'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            _buildItemsList(),

            const SizedBox(height: AppSpacing.lg),

            // Due date
            _buildSectionTitle('Due Date'),
            const SizedBox(height: AppSpacing.sm),
            GestureDetector(
              onTap: _selectDueDate,
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      dateFormat.format(_dueDate),
                      style: AppTypography.bodyLarge,
                    ),
                    const Icon(Icons.calendar_today, size: 20),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Notes
            _buildSectionTitle('Notes'),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Additional notes for the invoice',
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Summary
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _buildSummaryRow('Subtotal', currencyFormat.format(subtotal)),
                  const SizedBox(height: AppSpacing.sm),
                  _buildSummaryRow('Tax', currencyFormat.format(taxAmount)),
                  const Divider(height: AppSpacing.lg),
                  _buildSummaryRow(
                    'Total',
                    currencyFormat.format(total),
                    isTotal: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _canSave ? (_isLoading ? null : _saveInvoice) : null,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(isEditing ? 'Update Invoice' : 'Create Invoice'),
              ),
            ),

            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  bool get _canSave => _selectedClient != null && _items.isNotEmpty;

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTypography.labelLarge.copyWith(color: AppColors.textPrimary),
    );
  }

  Widget _buildClientSelector() {
    final appState = context.watch<AppState>();

    return GestureDetector(
      onTap: () => _showClientPicker(),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: _selectedClient == null
              ? Border.all(color: AppColors.error.withOpacity(0.5))
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(
                _selectedClient != null ? Icons.person : Icons.person_add,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _selectedClient != null
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedClient!.name,
                          style: AppTypography.titleMedium,
                        ),
                        if (_selectedClient!.email != null)
                          Text(
                            _selectedClient!.email!,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                      ],
                    )
                  : Text(
                      appState.clients.isEmpty
                          ? 'Add a client first'
                          : 'Select a client',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsList() {
    if (_items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.shopping_cart_outlined,
                size: 32,
                color: AppColors.textTertiary,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'No items added',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final currencyFormat = NumberFormat.currency(symbol: '\$');

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: _items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return Column(
            children: [
              ListTile(
                title: Text(item.name),
                subtitle: Text(
                  '${item.quantity} × ${currencyFormat.format(item.price)}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      currencyFormat.format(item.total),
                      style: AppTypography.titleMedium,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => _removeItem(index),
                      color: AppColors.error,
                    ),
                  ],
                ),
              ),
              if (index < _items.length - 1) const Divider(height: 1),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isTotal
              ? AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w600)
              : AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
        ),
        Text(
          value,
          style: isTotal
              ? AppTypography.headlineMedium.copyWith(color: AppColors.primary)
              : AppTypography.bodyMedium,
        ),
      ],
    );
  }

  void _showClientPicker() {
    final appState = context.read<AppState>();

    if (appState.clients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a client first')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Text('Select Client', style: AppTypography.titleLarge),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: appState.clients.length,
                itemBuilder: (context, index) {
                  final client = appState.clients[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      child: Text(
                        client.name[0].toUpperCase(),
                        style: TextStyle(color: AppColors.primary),
                      ),
                    ),
                    title: Text(client.name),
                    subtitle: client.email != null ? Text(client.email!) : null,
                    selected: _selectedClient?.id == client.id,
                    onTap: () {
                      setState(() => _selectedClient = client);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddItemDialog() {
    final appState = context.read<AppState>();
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final quantityController = TextEditingController(text: '1');
    Item? selectedItem;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
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
                  Text('Add Item', style: AppTypography.titleLarge),
                  const SizedBox(height: AppSpacing.lg),

                  // Quick select from saved items
                  if (appState.items.isNotEmpty) ...[
                    Text('Quick Select', style: AppTypography.labelLarge),
                    const SizedBox(height: AppSpacing.sm),
                    SizedBox(
                      height: 40,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: appState.items.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final item = appState.items[index];
                          final isSelected = selectedItem?.id == item.id;
                          return ChoiceChip(
                            label: Text(item.name),
                            selected: isSelected,
                            onSelected: (selected) {
                              setModalState(() {
                                if (selected) {
                                  selectedItem = item;
                                  nameController.text = item.name;
                                  priceController.text = item.price.toString();
                                } else {
                                  selectedItem = null;
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],

                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Item Name'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: priceController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Price',
                            prefixText: '\$ ',
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: TextField(
                          controller: quantityController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Qty'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  ElevatedButton(
                    onPressed: () {
                      final name = nameController.text.trim();
                      final price = double.tryParse(priceController.text) ?? 0;
                      final quantity =
                          double.tryParse(quantityController.text) ?? 1;

                      if (name.isNotEmpty && price > 0) {
                        final newItem = InvoiceItem(
                          id: context.read<AppState>().generateItemId(),
                          itemId: selectedItem?.id ?? '',
                          name: name,
                          description: selectedItem?.description,
                          price: price,
                          quantity: quantity,
                          taxRate: selectedItem?.taxRate ?? 0,
                        );
                        setState(() => _items.add(newItem));
                        Navigator.pop(context);
                      }
                    },
                    child: const Text('Add Item'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _removeItem(int index) {
    setState(() => _items.removeAt(index));
  }

  Future<void> _selectDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  Future<void> _saveInvoice() async {
    if (!_canSave) return;

    setState(() => _isLoading = true);

    try {
      final appState = context.read<AppState>();

      if (isEditing) {
        final updated = widget.invoice!.copyWith(
          clientId: _selectedClient!.id,
          clientName: _selectedClient!.name,
          items: _items,
          dueDate: _dueDate,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
        );
        await appState.updateInvoice(updated);
      } else {
        await appState.createInvoice(
          clientId: _selectedClient!.id,
          items: _items,
          dueDate: _dueDate,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
        );
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditing ? 'Invoice updated' : 'Invoice created'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

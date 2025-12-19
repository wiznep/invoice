import 'item.dart';

/// Payment status for invoices
enum PaymentStatus { unpaid, partial, paid }

/// Line item in an invoice (references an Item with quantity)
class InvoiceItem {
  final String id;
  final String itemId;
  final String name;
  final String? description;
  final double price;
  final double quantity;
  final double taxRate;

  InvoiceItem({
    required this.id,
    required this.itemId,
    required this.name,
    this.description,
    required this.price,
    required this.quantity,
    this.taxRate = 0.0,
  });

  double get subtotal => price * quantity;
  double get taxAmount => subtotal * (taxRate / 100);
  double get total => subtotal + taxAmount;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'itemId': itemId,
      'name': name,
      'description': description,
      'price': price,
      'quantity': quantity,
      'taxRate': taxRate,
    };
  }

  factory InvoiceItem.fromMap(Map<String, dynamic> map) {
    return InvoiceItem(
      id: map['id'] as String,
      itemId: map['itemId'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      price: (map['price'] as num).toDouble(),
      quantity: (map['quantity'] as num).toDouble(),
      taxRate: (map['taxRate'] as num?)?.toDouble() ?? 0.0,
    );
  }

  factory InvoiceItem.fromItem(
    Item item, {
    required String id,
    double quantity = 1,
  }) {
    return InvoiceItem(
      id: id,
      itemId: item.id,
      name: item.name,
      description: item.description,
      price: item.price,
      quantity: quantity,
      taxRate: item.taxRate,
    );
  }

  InvoiceItem copyWith({
    String? id,
    String? itemId,
    String? name,
    String? description,
    double? price,
    double? quantity,
    double? taxRate,
  }) {
    return InvoiceItem(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      taxRate: taxRate ?? this.taxRate,
    );
  }
}

/// Invoice model
class Invoice {
  final String id;
  final String invoiceNumber;
  final String clientId;
  final String? clientName; // Denormalized for display
  final List<InvoiceItem> items;
  final PaymentStatus status;
  final DateTime issueDate;
  final DateTime dueDate;
  final String? notes;
  final double paidAmount;
  final DateTime createdAt;

  Invoice({
    required this.id,
    required this.invoiceNumber,
    required this.clientId,
    this.clientName,
    required this.items,
    this.status = PaymentStatus.unpaid,
    required this.issueDate,
    required this.dueDate,
    this.notes,
    this.paidAmount = 0.0,
    required this.createdAt,
  });

  double get subtotal => items.fold(0, (sum, item) => sum + item.subtotal);
  double get taxAmount => items.fold(0, (sum, item) => sum + item.taxAmount);
  double get total => subtotal + taxAmount;
  double get balanceDue => total - paidAmount;
  bool get isOverdue =>
      status != PaymentStatus.paid && DateTime.now().isAfter(dueDate);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoiceNumber': invoiceNumber,
      'clientId': clientId,
      'clientName': clientName,
      'status': status.name,
      'issueDate': issueDate.toIso8601String(),
      'dueDate': dueDate.toIso8601String(),
      'notes': notes,
      'paidAmount': paidAmount,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Invoice.fromMap(Map<String, dynamic> map, List<InvoiceItem> items) {
    return Invoice(
      id: map['id'] as String,
      invoiceNumber: map['invoiceNumber'] as String,
      clientId: map['clientId'] as String,
      clientName: map['clientName'] as String?,
      items: items,
      status: PaymentStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => PaymentStatus.unpaid,
      ),
      issueDate: DateTime.parse(map['issueDate'] as String),
      dueDate: DateTime.parse(map['dueDate'] as String),
      notes: map['notes'] as String?,
      paidAmount: (map['paidAmount'] as num?)?.toDouble() ?? 0.0,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  Invoice copyWith({
    String? id,
    String? invoiceNumber,
    String? clientId,
    String? clientName,
    List<InvoiceItem>? items,
    PaymentStatus? status,
    DateTime? issueDate,
    DateTime? dueDate,
    String? notes,
    double? paidAmount,
    DateTime? createdAt,
  }) {
    return Invoice(
      id: id ?? this.id,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      items: items ?? this.items,
      status: status ?? this.status,
      issueDate: issueDate ?? this.issueDate,
      dueDate: dueDate ?? this.dueDate,
      notes: notes ?? this.notes,
      paidAmount: paidAmount ?? this.paidAmount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() =>
      'Invoice(id: $id, number: $invoiceNumber, total: $total, status: $status)';
}

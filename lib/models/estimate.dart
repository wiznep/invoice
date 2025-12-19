import 'invoice.dart';

/// Estimate status
enum EstimateStatus {
  draft,
  sent,
  accepted,
  declined,
  expired,
  converted, // Converted to invoice
}

/// Estimate model (similar to Invoice but for quotes)
class Estimate {
  final String id;
  final String estimateNumber;
  final String clientId;
  final String? clientName;
  final List<InvoiceItem> items; // Reusing InvoiceItem structure
  final EstimateStatus status;
  final DateTime issueDate;
  final DateTime validUntil;
  final String? notes;
  final String? convertedInvoiceId;
  final DateTime createdAt;

  Estimate({
    required this.id,
    required this.estimateNumber,
    required this.clientId,
    this.clientName,
    required this.items,
    this.status = EstimateStatus.draft,
    required this.issueDate,
    required this.validUntil,
    this.notes,
    this.convertedInvoiceId,
    required this.createdAt,
  });

  double get subtotal => items.fold(0, (sum, item) => sum + item.subtotal);
  double get taxAmount => items.fold(0, (sum, item) => sum + item.taxAmount);
  double get total => subtotal + taxAmount;
  bool get isExpired =>
      status != EstimateStatus.accepted &&
      status != EstimateStatus.converted &&
      DateTime.now().isAfter(validUntil);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'estimateNumber': estimateNumber,
      'clientId': clientId,
      'clientName': clientName,
      'status': status.name,
      'issueDate': issueDate.toIso8601String(),
      'validUntil': validUntil.toIso8601String(),
      'notes': notes,
      'convertedInvoiceId': convertedInvoiceId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Estimate.fromMap(Map<String, dynamic> map, List<InvoiceItem> items) {
    return Estimate(
      id: map['id'] as String,
      estimateNumber: map['estimateNumber'] as String,
      clientId: map['clientId'] as String,
      clientName: map['clientName'] as String?,
      items: items,
      status: EstimateStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => EstimateStatus.draft,
      ),
      issueDate: DateTime.parse(map['issueDate'] as String),
      validUntil: DateTime.parse(map['validUntil'] as String),
      notes: map['notes'] as String?,
      convertedInvoiceId: map['convertedInvoiceId'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  Estimate copyWith({
    String? id,
    String? estimateNumber,
    String? clientId,
    String? clientName,
    List<InvoiceItem>? items,
    EstimateStatus? status,
    DateTime? issueDate,
    DateTime? validUntil,
    String? notes,
    String? convertedInvoiceId,
    DateTime? createdAt,
  }) {
    return Estimate(
      id: id ?? this.id,
      estimateNumber: estimateNumber ?? this.estimateNumber,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      items: items ?? this.items,
      status: status ?? this.status,
      issueDate: issueDate ?? this.issueDate,
      validUntil: validUntil ?? this.validUntil,
      notes: notes ?? this.notes,
      convertedInvoiceId: convertedInvoiceId ?? this.convertedInvoiceId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Convert this estimate to an invoice
  Invoice toInvoice({
    required String invoiceId,
    required String invoiceNumber,
    required DateTime dueDate,
  }) {
    return Invoice(
      id: invoiceId,
      invoiceNumber: invoiceNumber,
      clientId: clientId,
      clientName: clientName,
      items: items,
      status: PaymentStatus.unpaid,
      issueDate: DateTime.now(),
      dueDate: dueDate,
      notes: notes,
      createdAt: DateTime.now(),
    );
  }

  @override
  String toString() =>
      'Estimate(id: $id, number: $estimateNumber, total: $total, status: $status)';
}

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../services/database_service.dart';

/// Central app state management using ChangeNotifier
class AppState extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  final Uuid _uuid = const Uuid();

  List<Client> _clients = [];
  List<Item> _items = [];
  List<Invoice> _invoices = [];
  List<Estimate> _estimates = [];
  BusinessSettings _settings = BusinessSettings();
  bool _isLoading = true;

  // Getters
  List<Client> get clients => _clients;
  List<Item> get items => _items;
  List<Invoice> get invoices => _invoices;
  List<Estimate> get estimates => _estimates;
  BusinessSettings get settings => _settings;
  bool get isLoading => _isLoading;

  // Filtered lists
  List<Invoice> get unpaidInvoices =>
      _invoices.where((i) => i.status == PaymentStatus.unpaid).toList();
  List<Invoice> get paidInvoices =>
      _invoices.where((i) => i.status == PaymentStatus.paid).toList();
  List<Invoice> get partialInvoices =>
      _invoices.where((i) => i.status == PaymentStatus.partial).toList();
  List<Invoice> get overdueInvoices =>
      _invoices.where((i) => i.isOverdue).toList();

  // Summary data
  double get totalRevenue =>
      _invoices.fold(0, (sum, inv) => sum + inv.paidAmount);
  double get totalOutstanding =>
      _invoices.fold(0, (sum, inv) => sum + inv.balanceDue);
  double get totalInvoiced => _invoices.fold(0, (sum, inv) => sum + inv.total);

  /// Initialize app state by loading data from database
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      _clients = await _db.getAllClients();
      _items = await _db.getAllItems();
      _invoices = await _db.getAllInvoices();
      _estimates = await _db.getAllEstimates();
      _settings = await _db.getBusinessSettings();
    } catch (e) {
      debugPrint('Error initializing app state: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // ========== CLIENT OPERATIONS ==========

  Future<void> addClient(Client client) async {
    final newClient = Client(
      id: _uuid.v4(),
      name: client.name,
      email: client.email,
      phone: client.phone,
      address: client.address,
      notes: client.notes,
      createdAt: DateTime.now(),
    );
    await _db.insertClient(newClient);
    _clients.insert(0, newClient);
    _clients.sort((a, b) => a.name.compareTo(b.name));
    notifyListeners();
  }

  Future<void> updateClient(Client client) async {
    await _db.updateClient(client);
    final index = _clients.indexWhere((c) => c.id == client.id);
    if (index != -1) {
      _clients[index] = client;
      _clients.sort((a, b) => a.name.compareTo(b.name));
      notifyListeners();
    }
  }

  Future<void> deleteClient(String id) async {
    await _db.deleteClient(id);
    _clients.removeWhere((c) => c.id == id);
    notifyListeners();
  }

  Client? getClientById(String id) {
    try {
      return _clients.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }

  // ========== ITEM OPERATIONS ==========

  Future<void> addItem(Item item) async {
    final newItem = Item(
      id: _uuid.v4(),
      name: item.name,
      description: item.description,
      price: item.price,
      unit: item.unit,
      taxRate: item.taxRate,
      createdAt: DateTime.now(),
    );
    await _db.insertItem(newItem);
    _items.insert(0, newItem);
    _items.sort((a, b) => a.name.compareTo(b.name));
    notifyListeners();
  }

  Future<void> updateItem(Item item) async {
    await _db.updateItem(item);
    final index = _items.indexWhere((i) => i.id == item.id);
    if (index != -1) {
      _items[index] = item;
      _items.sort((a, b) => a.name.compareTo(b.name));
      notifyListeners();
    }
  }

  Future<void> deleteItem(String id) async {
    await _db.deleteItem(id);
    _items.removeWhere((i) => i.id == id);
    notifyListeners();
  }

  // ========== INVOICE OPERATIONS ==========

  Future<Invoice> createInvoice({
    required String clientId,
    required List<InvoiceItem> items,
    required DateTime dueDate,
    String? notes,
  }) async {
    final client = getClientById(clientId);
    final invoiceNumber = _settings.nextInvoiceNumberFormatted;

    final invoice = Invoice(
      id: _uuid.v4(),
      invoiceNumber: invoiceNumber,
      clientId: clientId,
      clientName: client?.name,
      items: items.map((item) => item.copyWith(id: _uuid.v4())).toList(),
      status: PaymentStatus.unpaid,
      issueDate: DateTime.now(),
      dueDate: dueDate,
      notes: notes,
      createdAt: DateTime.now(),
    );

    await _db.insertInvoice(invoice);
    _invoices.insert(0, invoice);

    // Increment invoice number
    _settings = _settings.copyWith(
      nextInvoiceNumber: _settings.nextInvoiceNumber + 1,
    );
    await _db.saveBusinessSettings(_settings);

    notifyListeners();
    return invoice;
  }

  Future<void> updateInvoice(Invoice invoice) async {
    await _db.updateInvoice(invoice);
    final index = _invoices.indexWhere((i) => i.id == invoice.id);
    if (index != -1) {
      _invoices[index] = invoice;
      notifyListeners();
    }
  }

  Future<void> deleteInvoice(String id) async {
    await _db.deleteInvoice(id);
    _invoices.removeWhere((i) => i.id == id);
    notifyListeners();
  }

  Future<void> recordPayment({
    required String invoiceId,
    required double amount,
    String? method,
    String? notes,
  }) async {
    final invoice = _invoices.firstWhere((i) => i.id == invoiceId);
    final newPaidAmount = invoice.paidAmount + amount;

    PaymentStatus newStatus;
    if (newPaidAmount >= invoice.total) {
      newStatus = PaymentStatus.paid;
    } else if (newPaidAmount > 0) {
      newStatus = PaymentStatus.partial;
    } else {
      newStatus = PaymentStatus.unpaid;
    }

    final payment = Payment(
      id: _uuid.v4(),
      invoiceId: invoiceId,
      amount: amount,
      date: DateTime.now(),
      method: method,
      notes: notes,
      createdAt: DateTime.now(),
    );
    await _db.insertPayment(payment);

    final updatedInvoice = invoice.copyWith(
      paidAmount: newPaidAmount,
      status: newStatus,
    );
    await updateInvoice(updatedInvoice);
  }

  Invoice? getInvoiceById(String id) {
    try {
      return _invoices.firstWhere((i) => i.id == id);
    } catch (e) {
      return null;
    }
  }

  // ========== ESTIMATE OPERATIONS ==========

  Future<Estimate> createEstimate({
    required String clientId,
    required List<InvoiceItem> items,
    required DateTime validUntil,
    String? notes,
  }) async {
    final client = getClientById(clientId);
    final estimateNumber = _settings.nextEstimateNumberFormatted;

    final estimate = Estimate(
      id: _uuid.v4(),
      estimateNumber: estimateNumber,
      clientId: clientId,
      clientName: client?.name,
      items: items.map((item) => item.copyWith(id: _uuid.v4())).toList(),
      status: EstimateStatus.draft,
      issueDate: DateTime.now(),
      validUntil: validUntil,
      notes: notes,
      createdAt: DateTime.now(),
    );

    await _db.insertEstimate(estimate);
    _estimates.insert(0, estimate);

    // Increment estimate number
    _settings = _settings.copyWith(
      nextEstimateNumber: _settings.nextEstimateNumber + 1,
    );
    await _db.saveBusinessSettings(_settings);

    notifyListeners();
    return estimate;
  }

  Future<void> updateEstimate(Estimate estimate) async {
    await _db.updateEstimate(estimate);
    final index = _estimates.indexWhere((e) => e.id == estimate.id);
    if (index != -1) {
      _estimates[index] = estimate;
      notifyListeners();
    }
  }

  Future<void> deleteEstimate(String id) async {
    await _db.deleteEstimate(id);
    _estimates.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  Future<Invoice> convertEstimateToInvoice(String estimateId) async {
    final estimate = _estimates.firstWhere((e) => e.id == estimateId);

    final dueDate = DateTime.now().add(
      Duration(days: _settings.defaultDueDays),
    );
    final invoice = await createInvoice(
      clientId: estimate.clientId,
      items: estimate.items,
      dueDate: dueDate,
      notes: estimate.notes,
    );

    final updatedEstimate = estimate.copyWith(
      status: EstimateStatus.converted,
      convertedInvoiceId: invoice.id,
    );
    await updateEstimate(updatedEstimate);

    return invoice;
  }

  Estimate? getEstimateById(String id) {
    try {
      return _estimates.firstWhere((e) => e.id == id);
    } catch (e) {
      return null;
    }
  }

  // ========== SETTINGS OPERATIONS ==========

  Future<void> updateSettings(BusinessSettings newSettings) async {
    await _db.saveBusinessSettings(newSettings);
    _settings = newSettings;
    notifyListeners();
  }

  // ========== HELPER METHODS ==========

  String generateItemId() => _uuid.v4();
}

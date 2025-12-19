import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';

/// PDF generation service for invoices and estimates
class PdfService {
  static final PdfService _instance = PdfService._internal();
  factory PdfService() => _instance;
  PdfService._internal();

  final _currencyFormat = NumberFormat.currency(symbol: '\$');
  final _dateFormat = DateFormat('MMM d, yyyy');

  /// Generate PDF for an invoice
  Future<Uint8List> generateInvoicePdf({
    required Invoice invoice,
    BusinessSettings? settings,
  }) async {
    final pdf = pw.Document();

    final businessName = settings?.businessName ?? 'Your Business';
    final businessAddress = settings?.address ?? '';
    final businessEmail = settings?.email ?? '';
    final businessPhone = settings?.phone ?? '';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          // Header
          _buildHeader(
            title: 'INVOICE',
            number: invoice.invoiceNumber,
            businessName: businessName,
            businessAddress: businessAddress,
            businessEmail: businessEmail,
            businessPhone: businessPhone,
          ),

          pw.SizedBox(height: 30),

          // Bill To & Invoice Details
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: _buildBillTo(clientName: invoice.clientName ?? 'Client'),
              ),
              pw.Expanded(
                child: _buildInvoiceDetails(
                  issueDate: invoice.issueDate,
                  dueDate: invoice.dueDate,
                  status: invoice.status,
                ),
              ),
            ],
          ),

          pw.SizedBox(height: 30),

          // Items table
          _buildItemsTable(invoice.items),

          pw.SizedBox(height: 20),

          // Totals
          _buildTotals(
            subtotal: invoice.subtotal,
            tax: invoice.taxAmount,
            total: invoice.total,
            paidAmount: invoice.paidAmount,
            balanceDue: invoice.balanceDue,
          ),

          // Notes
          if (invoice.notes != null && invoice.notes!.isNotEmpty) ...[
            pw.SizedBox(height: 30),
            _buildNotes(invoice.notes!),
          ],

          pw.SizedBox(height: 40),

          // Footer
          _buildFooter(),
        ],
      ),
    );

    return pdf.save();
  }

  /// Generate PDF for an estimate
  Future<Uint8List> generateEstimatePdf({
    required Estimate estimate,
    BusinessSettings? settings,
  }) async {
    final pdf = pw.Document();

    final businessName = settings?.businessName ?? 'Your Business';
    final businessAddress = settings?.address ?? '';
    final businessEmail = settings?.email ?? '';
    final businessPhone = settings?.phone ?? '';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          // Header
          _buildHeader(
            title: 'ESTIMATE',
            number: estimate.estimateNumber,
            businessName: businessName,
            businessAddress: businessAddress,
            businessEmail: businessEmail,
            businessPhone: businessPhone,
          ),

          pw.SizedBox(height: 30),

          // Bill To & Estimate Details
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: _buildBillTo(
                  clientName: estimate.clientName ?? 'Client',
                ),
              ),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    _buildDetailRow(
                      'Date:',
                      _dateFormat.format(estimate.issueDate),
                    ),
                    pw.SizedBox(height: 4),
                    _buildDetailRow(
                      'Valid Until:',
                      _dateFormat.format(estimate.validUntil),
                    ),
                  ],
                ),
              ),
            ],
          ),

          pw.SizedBox(height: 30),

          // Items table
          _buildItemsTable(estimate.items),

          pw.SizedBox(height: 20),

          // Totals
          _buildTotals(
            subtotal: estimate.subtotal,
            tax: estimate.taxAmount,
            total: estimate.total,
          ),

          // Notes
          if (estimate.notes != null && estimate.notes!.isNotEmpty) ...[
            pw.SizedBox(height: 30),
            _buildNotes(estimate.notes!),
          ],

          pw.SizedBox(height: 40),

          // Footer
          _buildFooter(),
        ],
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildHeader({
    required String title,
    required String number,
    required String businessName,
    required String businessAddress,
    required String businessEmail,
    required String businessPhone,
  }) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              businessName,
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue800,
              ),
            ),
            pw.SizedBox(height: 4),
            if (businessAddress.isNotEmpty)
              pw.Text(
                businessAddress,
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey700,
                ),
              ),
            if (businessEmail.isNotEmpty)
              pw.Text(
                businessEmail,
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey700,
                ),
              ),
            if (businessPhone.isNotEmpty)
              pw.Text(
                businessPhone,
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey700,
                ),
              ),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              title,
              style: pw.TextStyle(
                fontSize: 32,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue800,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              number,
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildBillTo({required String clientName}) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'BILL TO',
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.grey600,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          clientName,
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),
      ],
    );
  }

  pw.Widget _buildInvoiceDetails({
    required DateTime issueDate,
    required DateTime dueDate,
    required PaymentStatus status,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        _buildDetailRow('Issue Date:', _dateFormat.format(issueDate)),
        pw.SizedBox(height: 4),
        _buildDetailRow('Due Date:', _dateFormat.format(dueDate)),
        pw.SizedBox(height: 4),
        _buildDetailRow('Status:', status.name.toUpperCase()),
      ],
    );
  }

  pw.Widget _buildDetailRow(String label, String value) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
        ),
        pw.SizedBox(width: 8),
        pw.Text(
          value,
          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
        ),
      ],
    );
  }

  pw.Widget _buildItemsTable(List<InvoiceItem> items) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(1.5),
        3: const pw.FlexColumnWidth(1.5),
      },
      children: [
        // Header
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.blue50),
          children: [
            _buildTableCell('Description', isHeader: true),
            _buildTableCell('Qty', isHeader: true, align: pw.TextAlign.center),
            _buildTableCell('Price', isHeader: true, align: pw.TextAlign.right),
            _buildTableCell('Total', isHeader: true, align: pw.TextAlign.right),
          ],
        ),
        // Items
        ...items.map(
          (item) => pw.TableRow(
            children: [
              _buildTableCell(item.name),
              _buildTableCell(
                item.quantity.toString(),
                align: pw.TextAlign.center,
              ),
              _buildTableCell(
                _currencyFormat.format(item.price),
                align: pw.TextAlign.right,
              ),
              _buildTableCell(
                _currencyFormat.format(item.total),
                align: pw.TextAlign.right,
              ),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildTableCell(
    String text, {
    bool isHeader = false,
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: isHeader ? 10 : 9,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: isHeader ? PdfColors.blue800 : PdfColors.black,
        ),
      ),
    );
  }

  pw.Widget _buildTotals({
    required double subtotal,
    required double tax,
    required double total,
    double? paidAmount,
    double? balanceDue,
  }) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      child: pw.Container(
        width: 200,
        child: pw.Column(
          children: [
            _buildTotalRow('Subtotal', _currencyFormat.format(subtotal)),
            pw.SizedBox(height: 4),
            _buildTotalRow('Tax', _currencyFormat.format(tax)),
            pw.Divider(color: PdfColors.grey400),
            _buildTotalRow(
              'Total',
              _currencyFormat.format(total),
              isBold: true,
              isLarge: true,
            ),
            if (paidAmount != null && paidAmount > 0) ...[
              pw.SizedBox(height: 4),
              _buildTotalRow(
                'Paid',
                '- ${_currencyFormat.format(paidAmount)}',
                color: PdfColors.green700,
              ),
            ],
            if (balanceDue != null && balanceDue > 0) ...[
              pw.SizedBox(height: 4),
              _buildTotalRow(
                'Balance Due',
                _currencyFormat.format(balanceDue),
                isBold: true,
                color: PdfColors.blue800,
              ),
            ],
          ],
        ),
      ),
    );
  }

  pw.Widget _buildTotalRow(
    String label,
    String value, {
    bool isBold = false,
    bool isLarge = false,
    PdfColor? color,
  }) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: isLarge ? 12 : 10,
            fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: color ?? PdfColors.grey700,
          ),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: isLarge ? 14 : 10,
            fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: color ?? PdfColors.black,
          ),
        ),
      ],
    );
  }

  pw.Widget _buildNotes(String notes) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Notes',
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.grey600,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          notes,
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
        ),
      ],
    );
  }

  pw.Widget _buildFooter() {
    return pw.Center(
      child: pw.Text(
        'Thank you for your business!',
        style: pw.TextStyle(
          fontSize: 12,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.blue800,
        ),
      ),
    );
  }

  /// Print or share invoice PDF
  Future<void> printInvoice(
    Invoice invoice, {
    BusinessSettings? settings,
  }) async {
    final pdfBytes = await generateInvoicePdf(
      invoice: invoice,
      settings: settings,
    );
    await Printing.layoutPdf(onLayout: (format) async => pdfBytes);
  }

  /// Share invoice PDF
  Future<void> shareInvoice(
    Invoice invoice, {
    BusinessSettings? settings,
  }) async {
    final pdfBytes = await generateInvoicePdf(
      invoice: invoice,
      settings: settings,
    );
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: '${invoice.invoiceNumber}.pdf',
    );
  }

  /// Share estimate PDF
  Future<void> shareEstimate(
    Estimate estimate, {
    BusinessSettings? settings,
  }) async {
    final pdfBytes = await generateEstimatePdf(
      estimate: estimate,
      settings: settings,
    );
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: '${estimate.estimateNumber}.pdf',
    );
  }
}

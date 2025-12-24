import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';

/// Invoice template styles
enum InvoiceTemplate {
  classic, // Blue professional look
  modern, // Dark gradient with accent colors
  minimal, // Clean black & white
}

/// PDF generation service for invoices and estimates
class PdfService {
  static final PdfService _instance = PdfService._internal();
  factory PdfService() => _instance;
  PdfService._internal();

  final _currencyFormat = NumberFormat.currency(symbol: '\$');
  final _dateFormat = DateFormat('MMM d, yyyy');

  /// Generate PDF for an invoice with selected template
  Future<Uint8List> generateInvoicePdf({
    required Invoice invoice,
    BusinessSettings? settings,
    InvoiceTemplate template = InvoiceTemplate.classic,
  }) async {
    switch (template) {
      case InvoiceTemplate.classic:
        return _generateClassicInvoice(invoice, settings);
      case InvoiceTemplate.modern:
        return _generateModernInvoice(invoice, settings);
      case InvoiceTemplate.minimal:
        return _generateMinimalInvoice(invoice, settings);
    }
  }

  // ============== CLASSIC TEMPLATE (Blue Professional) ==============
  Future<Uint8List> _generateClassicInvoice(
    Invoice invoice,
    BusinessSettings? settings,
  ) async {
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
          pw.Row(
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
                    'INVOICE',
                    style: pw.TextStyle(
                      fontSize: 32,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue800,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    invoice.invoiceNumber,
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 30),
          // Bill To & Details
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: _buildBillTo(
                  invoice.clientName ?? 'Client',
                  PdfColors.grey600,
                ),
              ),
              pw.Expanded(
                child: _buildInvoiceDetails(invoice, PdfColors.grey600),
              ),
            ],
          ),
          pw.SizedBox(height: 30),
          _buildClassicItemsTable(invoice.items),
          pw.SizedBox(height: 20),
          _buildTotals(invoice, PdfColors.blue800),
          if (invoice.notes != null && invoice.notes!.isNotEmpty) ...[
            pw.SizedBox(height: 30),
            _buildNotes(invoice.notes!, PdfColors.grey600),
          ],
          pw.SizedBox(height: 40),
          pw.Center(
            child: pw.Text(
              'Thank you for your business!',
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue800,
              ),
            ),
          ),
        ],
      ),
    );
    return pdf.save();
  }

  // ============== MODERN TEMPLATE (Dark with Gradients) ==============
  Future<Uint8List> _generateModernInvoice(
    Invoice invoice,
    BusinessSettings? settings,
  ) async {
    final pdf = pw.Document();
    final businessName = settings?.businessName ?? 'Your Business';
    final businessEmail = settings?.email ?? '';
    final businessPhone = settings?.phone ?? '';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(0),
        build: (context) => [
          // Dark Header Banner
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(30),
            decoration: const pw.BoxDecoration(color: PdfColors.grey900),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      businessName,
                      style: pw.TextStyle(
                        fontSize: 22,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      businessEmail,
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey400,
                      ),
                    ),
                    pw.Text(
                      businessPhone,
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey400,
                      ),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'INVOICE',
                      style: pw.TextStyle(
                        fontSize: 28,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.teal400,
                      ),
                    ),
                    pw.Text(
                      invoice.invoiceNumber,
                      style: pw.TextStyle(fontSize: 12, color: PdfColors.white),
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 30),
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 30),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Client & Dates
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'BILL TO',
                            style: pw.TextStyle(
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.teal600,
                            ),
                          ),
                          pw.SizedBox(height: 6),
                          pw.Text(
                            invoice.clientName ?? 'Client',
                            style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text(
                            'Issue: ${_dateFormat.format(invoice.issueDate)}',
                            style: const pw.TextStyle(fontSize: 10),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            'Due: ${_dateFormat.format(invoice.dueDate)}',
                            style: const pw.TextStyle(fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 30),
                _buildModernItemsTable(invoice.items),
                pw.SizedBox(height: 20),
                _buildTotals(invoice, PdfColors.teal600),
                if (invoice.notes != null && invoice.notes!.isNotEmpty) ...[
                  pw.SizedBox(height: 30),
                  _buildNotes(invoice.notes!, PdfColors.grey600),
                ],
              ],
            ),
          ),
        ],
      ),
    );
    return pdf.save();
  }

  // ============== MINIMAL TEMPLATE (Clean Black & White) ==============
  Future<Uint8List> _generateMinimalInvoice(
    Invoice invoice,
    BusinessSettings? settings,
  ) async {
    final pdf = pw.Document();
    final businessName = settings?.businessName ?? 'Your Business';
    final businessEmail = settings?.email ?? '';
    final businessPhone = settings?.phone ?? '';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(50),
        build: (context) => [
          // Simple Header
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                businessName,
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                'Invoice ${invoice.invoiceNumber}',
                style: const pw.TextStyle(fontSize: 14),
              ),
            ],
          ),
          pw.Divider(thickness: 1, color: PdfColors.black),
          pw.SizedBox(height: 20),
          // Details row
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'To:',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    invoice.clientName ?? 'Client',
                    style: const pw.TextStyle(fontSize: 12),
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'Date: ${_dateFormat.format(invoice.issueDate)}',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                  pw.Text(
                    'Due: ${_dateFormat.format(invoice.dueDate)}',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                  if (businessEmail.isNotEmpty)
                    pw.Text(
                      businessEmail,
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  if (businessPhone.isNotEmpty)
                    pw.Text(
                      businessPhone,
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 30),
          _buildMinimalItemsTable(invoice.items),
          pw.SizedBox(height: 20),
          // Simple totals
          pw.Container(
            alignment: pw.Alignment.centerRight,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  'Subtotal: ${_currencyFormat.format(invoice.subtotal)}',
                  style: const pw.TextStyle(fontSize: 10),
                ),
                pw.Text(
                  'Tax: ${_currencyFormat.format(invoice.taxAmount)}',
                  style: const pw.TextStyle(fontSize: 10),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Total: ${_currencyFormat.format(invoice.total)}',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                if (invoice.paidAmount > 0) ...[
                  pw.Text(
                    'Paid: -${_currencyFormat.format(invoice.paidAmount)}',
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.green700,
                    ),
                  ),
                  pw.Text(
                    'Balance: ${_currencyFormat.format(invoice.balanceDue)}',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (invoice.notes != null && invoice.notes!.isNotEmpty) ...[
            pw.SizedBox(height: 30),
            pw.Text(
              'Notes:',
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(invoice.notes!, style: const pw.TextStyle(fontSize: 9)),
          ],
        ],
      ),
    );
    return pdf.save();
  }

  // ============== SHARED HELPER METHODS ==============

  pw.Widget _buildBillTo(String clientName, PdfColor labelColor) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'BILL TO',
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
            color: labelColor,
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

  pw.Widget _buildInvoiceDetails(Invoice invoice, PdfColor labelColor) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        _buildDetailRow(
          'Issue Date:',
          _dateFormat.format(invoice.issueDate),
          labelColor,
        ),
        pw.SizedBox(height: 4),
        _buildDetailRow(
          'Due Date:',
          _dateFormat.format(invoice.dueDate),
          labelColor,
        ),
        pw.SizedBox(height: 4),
        _buildDetailRow(
          'Status:',
          invoice.status.name.toUpperCase(),
          labelColor,
        ),
      ],
    );
  }

  pw.Widget _buildDetailRow(String label, String value, PdfColor labelColor) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Text(label, style: pw.TextStyle(fontSize: 10, color: labelColor)),
        pw.SizedBox(width: 8),
        pw.Text(
          value,
          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
        ),
      ],
    );
  }

  pw.Widget _buildClassicItemsTable(List<InvoiceItem> items) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(1.5),
        3: const pw.FlexColumnWidth(1.5),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.blue50),
          children: [
            _buildTableCell(
              'Description',
              isHeader: true,
              headerColor: PdfColors.blue800,
            ),
            _buildTableCell(
              'Qty',
              isHeader: true,
              align: pw.TextAlign.center,
              headerColor: PdfColors.blue800,
            ),
            _buildTableCell(
              'Price',
              isHeader: true,
              align: pw.TextAlign.right,
              headerColor: PdfColors.blue800,
            ),
            _buildTableCell(
              'Total',
              isHeader: true,
              align: pw.TextAlign.right,
              headerColor: PdfColors.blue800,
            ),
          ],
        ),
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

  pw.Widget _buildModernItemsTable(List<InvoiceItem> items) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(1.5),
        3: const pw.FlexColumnWidth(1.5),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.teal50),
          children: [
            _buildTableCell(
              'Description',
              isHeader: true,
              headerColor: PdfColors.teal800,
            ),
            _buildTableCell(
              'Qty',
              isHeader: true,
              align: pw.TextAlign.center,
              headerColor: PdfColors.teal800,
            ),
            _buildTableCell(
              'Price',
              isHeader: true,
              align: pw.TextAlign.right,
              headerColor: PdfColors.teal800,
            ),
            _buildTableCell(
              'Total',
              isHeader: true,
              align: pw.TextAlign.right,
              headerColor: PdfColors.teal800,
            ),
          ],
        ),
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

  pw.Widget _buildMinimalItemsTable(List<InvoiceItem> items) {
    return pw.Table(
      border: pw.TableBorder(
        bottom: const pw.BorderSide(width: 0.5),
        top: const pw.BorderSide(width: 0.5),
      ),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(1.5),
        3: const pw.FlexColumnWidth(1.5),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(width: 0.5)),
          ),
          children: [
            _buildTableCell('Item', isHeader: true),
            _buildTableCell('Qty', isHeader: true, align: pw.TextAlign.center),
            _buildTableCell('Price', isHeader: true, align: pw.TextAlign.right),
            _buildTableCell('Total', isHeader: true, align: pw.TextAlign.right),
          ],
        ),
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
    PdfColor? headerColor,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: isHeader ? 10 : 9,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: isHeader ? (headerColor ?? PdfColors.black) : PdfColors.black,
        ),
      ),
    );
  }

  pw.Widget _buildTotals(Invoice invoice, PdfColor accentColor) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      child: pw.Container(
        width: 200,
        child: pw.Column(
          children: [
            _buildTotalRow(
              'Subtotal',
              _currencyFormat.format(invoice.subtotal),
            ),
            pw.SizedBox(height: 4),
            _buildTotalRow('Tax', _currencyFormat.format(invoice.taxAmount)),
            pw.Divider(color: PdfColors.grey400),
            _buildTotalRow(
              'Total',
              _currencyFormat.format(invoice.total),
              isBold: true,
              isLarge: true,
            ),
            if (invoice.paidAmount > 0) ...[
              pw.SizedBox(height: 4),
              _buildTotalRow(
                'Paid',
                '- ${_currencyFormat.format(invoice.paidAmount)}',
                color: PdfColors.green700,
              ),
            ],
            if (invoice.balanceDue > 0) ...[
              pw.SizedBox(height: 4),
              _buildTotalRow(
                'Balance Due',
                _currencyFormat.format(invoice.balanceDue),
                isBold: true,
                color: accentColor,
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

  pw.Widget _buildNotes(String notes, PdfColor labelColor) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Notes',
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
            color: labelColor,
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

  /// Print invoice with template
  Future<void> printInvoice(
    Invoice invoice, {
    BusinessSettings? settings,
    InvoiceTemplate template = InvoiceTemplate.classic,
  }) async {
    final pdfBytes = await generateInvoicePdf(
      invoice: invoice,
      settings: settings,
      template: template,
    );
    await Printing.layoutPdf(onLayout: (format) async => pdfBytes);
  }

  /// Share invoice PDF with template
  Future<void> shareInvoice(
    Invoice invoice, {
    BusinessSettings? settings,
    InvoiceTemplate template = InvoiceTemplate.classic,
  }) async {
    final pdfBytes = await generateInvoicePdf(
      invoice: invoice,
      settings: settings,
      template: template,
    );
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: '${invoice.invoiceNumber}.pdf',
    );
  }

  /// Generate estimate PDF (uses classic style)
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
          pw.Row(
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
                    'ESTIMATE',
                    style: pw.TextStyle(
                      fontSize: 32,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue800,
                    ),
                  ),
                  pw.Text(
                    estimate.estimateNumber,
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 30),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: _buildBillTo(
                  estimate.clientName ?? 'Client',
                  PdfColors.grey600,
                ),
              ),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    _buildDetailRow(
                      'Date:',
                      _dateFormat.format(estimate.issueDate),
                      PdfColors.grey600,
                    ),
                    pw.SizedBox(height: 4),
                    _buildDetailRow(
                      'Valid Until:',
                      _dateFormat.format(estimate.validUntil),
                      PdfColors.grey600,
                    ),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 30),
          _buildClassicItemsTable(estimate.items),
          pw.SizedBox(height: 20),
          pw.Container(
            alignment: pw.Alignment.centerRight,
            child: pw.Container(
              width: 200,
              child: pw.Column(
                children: [
                  _buildTotalRow(
                    'Subtotal',
                    _currencyFormat.format(estimate.subtotal),
                  ),
                  pw.SizedBox(height: 4),
                  _buildTotalRow(
                    'Tax',
                    _currencyFormat.format(estimate.taxAmount),
                  ),
                  pw.Divider(color: PdfColors.grey400),
                  _buildTotalRow(
                    'Total',
                    _currencyFormat.format(estimate.total),
                    isBold: true,
                    isLarge: true,
                  ),
                ],
              ),
            ),
          ),
          if (estimate.notes != null && estimate.notes!.isNotEmpty) ...[
            pw.SizedBox(height: 30),
            _buildNotes(estimate.notes!, PdfColors.grey600),
          ],
          pw.SizedBox(height: 40),
          pw.Center(
            child: pw.Text(
              'Thank you for your business!',
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue800,
              ),
            ),
          ),
        ],
      ),
    );
    return pdf.save();
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

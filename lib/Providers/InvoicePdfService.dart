
import 'dart:io';
import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../Models/Billing model/invoice.dart';
import '../Models/Billing model/InvoiceItem.dart';

class InvoicePdfService {
  // ── Public API ─────────────────────────────────────────────────────────────

  /// PDF generate karo aur device pe save karke share sheet kholo.
  static Future<void> downloadAndShare(Invoice invoice) async {
    final bytes = await _buildPdf(invoice);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/${invoice.invoiceNumber}.pdf');
    await file.writeAsBytes(bytes);
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/pdf')],
      subject: 'Invoice ${invoice.invoiceNumber} – Fradeen Auto Garage',
    );
  }

  /// PDF print preview kholo (printing package ka built-in dialog).
  static Future<void> printPreview(Invoice invoice) async {
    final bytes = await _buildPdf(invoice);
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }

  /// WhatsApp pe customer ko message bhejo with invoice details.
  static Future<void> sendWhatsApp(Invoice invoice) async {
    final phone = invoice.customer?.mobile ?? '';
    if (phone.isEmpty) {
      throw Exception('Customer ka phone number nahi mila.');
    }

    // 10-digit number → +91 prefix
    final cleaned = phone.replaceAll(RegExp(r'\D'), '');
    final e164 = cleaned.startsWith('91') ? cleaned : '91$cleaned';

    final amount = _formatCurrency(invoice.grandTotal.round());
    final status = invoice.paymentStatus.label;
    final date   = DateFormat('dd MMM yyyy').format(invoice.invoiceDate);

    final message = '''
🔧 *Fradeen Auto Garage*

Namaste ${invoice.customer?.name ?? 'Customer'},

Aapka invoice ready hai:

📋 *Invoice:* ${invoice.invoiceNumber}
📅 *Date:* $date
🚗 *Vehicle:* ${invoice.vehicle?.displayLabel ?? '—'}
💰 *Grand Total:* $amount
✅ *Status:* $status

${invoice.notes.isNotEmpty ? '📝 Note: ${invoice.notes}\n' : ''}
Shukriya Fradeen Auto Garage choose karne ke liye! 🙏
''';

    final encoded = Uri.encodeComponent(message);
    final uri     = Uri.parse('https://wa.me/$e164?text=$encoded');

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('WhatsApp open nahi ho saka. Kya app install hai?');
    }
  }



  // ── PDF Builder ────────────────────────────────────────────────────────────

  static Future<Uint8List> _buildPdf(Invoice invoice) async {
    final pdf    = pw.Document();
    final font   = await PdfGoogleFonts.notoSansRegular();
    final fontB  = await PdfGoogleFonts.notoSansBold();
    final theme  = pw.ThemeData.withFont(base: font, bold: fontB);

    final customer = invoice.customer;
    final vehicle  = invoice.vehicle;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        theme: theme,
        margin: const pw.EdgeInsets.all(32),
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────
            pw.Container(
              decoration: const pw.BoxDecoration(
                color: PdfColor.fromInt(0xFF1565C0),
                borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              padding: const pw.EdgeInsets.all(20),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Fradeen Auto Garage',
                        style: pw.TextStyle(
                          font: fontB,
                          fontSize: 16,
                          color: PdfColors.white,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'GST: 27AABCV1234A1ZB',
                        style: const pw.TextStyle(
                          fontSize: 9,
                          color: PdfColor.fromInt(0xFFBBDEFB),
                        ),
                      ),
                      pw.Text(
                        '+91 98765 43210',
                        style: const pw.TextStyle(
                          fontSize: 9,
                          color: PdfColor.fromInt(0xFFBBDEFB),
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'TAX INVOICE',
                        style: pw.TextStyle(
                          font: fontB,
                          fontSize: 18,
                          color: PdfColors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 20),

            // ── Bill To + Invoice No ─────────────────────────────────────
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('BILL TO',
                          style: pw.TextStyle(
                              font: fontB,
                              fontSize: 8,
                              color: PdfColors.grey600,
                              letterSpacing: 0.8)),
                      pw.SizedBox(height: 4),
                      pw.Text(customer?.name ?? '—',
                          style: pw.TextStyle(font: fontB, fontSize: 13)),
                      if (customer?.mobile.isNotEmpty == true)
                        pw.Text('+91 ${customer!.mobile}',
                            style: const pw.TextStyle(
                                fontSize: 10, color: PdfColors.grey700)),
                      if (customer?.email.isNotEmpty == true)
                        pw.Text(customer!.email,
                            style: const pw.TextStyle(
                                fontSize: 10, color: PdfColors.grey700)),
                      if (vehicle != null) ...[
                        pw.SizedBox(height: 4),
                        pw.Text(vehicle.displayLabel,
                            style: pw.TextStyle(
                              font: fontB,
                              fontSize: 10,
                              color: const PdfColor.fromInt(0xFF1565C0),
                            )),
                      ],
                    ],
                  ),
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('INVOICE NO.',
                        style: pw.TextStyle(
                            font: fontB,
                            fontSize: 8,
                            color: PdfColors.grey600,
                            letterSpacing: 0.8)),
                    pw.SizedBox(height: 4),
                    pw.Text(invoice.invoiceNumber,
                        style: pw.TextStyle(font: fontB, fontSize: 12)),
                    pw.Text(
                        DateFormat('dd MMM yyyy').format(invoice.invoiceDate),
                        style: const pw.TextStyle(
                            fontSize: 10, color: PdfColors.grey700)),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      invoice.paymentStatus.label.toUpperCase(),
                      style: pw.TextStyle(
                        font: fontB,
                        fontSize: 11,
                        color: _pdfStatusColor(invoice.paymentStatus),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            pw.SizedBox(height: 16),
            pw.Divider(color: PdfColors.grey300),
            pw.SizedBox(height: 8),

            // ── Table Header ─────────────────────────────────────────────
            pw.Row(
              children: [
                pw.Expanded(
                    flex: 6,
                    child: pw.Text('ITEM',
                        style: pw.TextStyle(
                            font: fontB,
                            fontSize: 8,
                            color: PdfColors.grey600,
                            letterSpacing: 0.6))),
                pw.SizedBox(
                    width: 40,
                    child: pw.Text('QTY',
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(
                            font: fontB,
                            fontSize: 8,
                            color: PdfColors.grey600,
                            letterSpacing: 0.6))),
                pw.Expanded(
                    flex: 2,
                    child: pw.Text('RATE',
                        textAlign: pw.TextAlign.right,
                        style: pw.TextStyle(
                            font: fontB,
                            fontSize: 8,
                            color: PdfColors.grey600,
                            letterSpacing: 0.6))),
                pw.Expanded(
                    flex: 2,
                    child: pw.Text('AMT',
                        textAlign: pw.TextAlign.right,
                        style: pw.TextStyle(
                            font: fontB,
                            fontSize: 8,
                            color: PdfColors.grey600,
                            letterSpacing: 0.6))),
              ],
            ),
            pw.SizedBox(height: 6),

            // ── Line Items ───────────────────────────────────────────────
            ...invoice.items.map((item) => _pdfLineItem(item, font, fontB)),

            pw.SizedBox(height: 8),
            pw.Divider(color: PdfColors.grey300),
            pw.SizedBox(height: 8),

            // ── Totals ───────────────────────────────────────────────────
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Container(
                width: 220,
                padding: const pw.EdgeInsets.all(14),
                decoration: pw.BoxDecoration(
                  color: const PdfColor.fromInt(0xFFF5F5F5),
                  borderRadius:
                  const pw.BorderRadius.all(pw.Radius.circular(8)),
                ),
                child: pw.Column(
                  children: [
                    _pdfTotalRow('Subtotal',
                        _formatCurrency(invoice.subTotal.round()), font, fontB),
                    if (invoice.gst > 0)
                      _pdfTotalRow('GST',
                          _formatCurrency(invoice.gst.round()), font, fontB),
                    if (invoice.discount > 0)
                      _pdfTotalRow(
                          'Discount',
                          '- ${_formatCurrency(invoice.discount.round())}',
                          font,
                          fontB),
                    pw.Divider(color: PdfColors.grey300),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Grand Total',
                            style: pw.TextStyle(font: fontB, fontSize: 12)),
                        pw.Text(
                          _formatCurrency(invoice.grandTotal.round()),
                          style: pw.TextStyle(
                            font: fontB,
                            fontSize: 15,
                            color: const PdfColor.fromInt(0xFF1565C0),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ── Payment Method ───────────────────────────────────────────
            if (invoice.paymentMethod != PaymentMethod.pending) ...[
              pw.SizedBox(height: 10),
              pw.Center(
                child: pw.Text(
                  'Payment via ${invoice.paymentMethod.label}',
                  style: const pw.TextStyle(
                      fontSize: 10, color: PdfColors.grey600),
                ),
              ),
            ],

            // ── Notes ────────────────────────────────────────────────────
            if (invoice.notes.isNotEmpty) ...[
              pw.SizedBox(height: 12),
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: const PdfColor.fromInt(0xFFFFF8E1),
                  borderRadius:
                  const pw.BorderRadius.all(pw.Radius.circular(8)),
                  border: pw.Border.all(
                      color: const PdfColor.fromInt(0xFFFFCC02), width: 0.5),
                ),
                child: pw.Text(invoice.notes,
                    style: const pw.TextStyle(fontSize: 10)),
              ),
            ],

            pw.Spacer(),

            // ── Footer ───────────────────────────────────────────────────
            pw.Divider(color: PdfColors.grey300),
            pw.SizedBox(height: 6),
            pw.Center(
              child: pw.Text(
                'Thank you for choosing Fradeen Auto Garage!',
                style: const pw.TextStyle(
                    fontSize: 10, color: PdfColors.grey600),
              ),
            ),
          ],
        ),
      ),
    );

    return pdf.save();
  }

  // ── PDF helpers ────────────────────────────────────────────────────────────

  static pw.Widget _pdfLineItem(
      InvoiceItem item, pw.Font font, pw.Font fontB) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 6),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            flex: 6,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(item.itemName,
                    style: pw.TextStyle(font: fontB, fontSize: 10)),
                if (item.unit.isNotEmpty)
                  pw.Text(item.unit,
                      style: const pw.TextStyle(
                          fontSize: 8, color: PdfColors.grey600)),
              ],
            ),
          ),
          pw.SizedBox(
            width: 40,
            child: pw.Text(
              item.quantity % 1 == 0
                  ? '${item.quantity.toInt()}'
                  : item.quantity.toStringAsFixed(1),
              textAlign: pw.TextAlign.center,
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
            ),
          ),
          pw.Expanded(
            flex: 2,
            child: pw.Text(
              '₹${item.price.toInt()}',
              textAlign: pw.TextAlign.right,
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
            ),
          ),
          pw.Expanded(
            flex: 2,
            child: pw.Text(
              '₹${item.total.toInt()}',
              textAlign: pw.TextAlign.right,
              style: pw.TextStyle(font: fontB, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _pdfTotalRow(
      String label, String value, pw.Font font, pw.Font fontB) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label,
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
          pw.Text(value,
              style: pw.TextStyle(font: fontB, fontSize: 10)),
        ],
      ),
    );
  }

  static PdfColor _pdfStatusColor(PaymentStatus s) {
    switch (s) {
      case PaymentStatus.paid:    return const PdfColor.fromInt(0xFF15803D);
      case PaymentStatus.partial: return const PdfColor.fromInt(0xFFEA580C);
      case PaymentStatus.pending: return const PdfColor.fromInt(0xFFDC2626);
    }
  }

  static String _formatCurrency(int amount) {
    final formatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }
}
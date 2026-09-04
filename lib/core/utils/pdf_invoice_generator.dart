import 'dart:io';
import 'package:flutter/services.dart' show rootBundle, ByteData, Uint8List;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../core/database/database_helper.dart';
import '../../models/models.dart';

class PdfInvoiceGenerator {
  PdfInvoiceGenerator._();

  static Future<File> generateEstimatePdf({
    required CustomerEstimate estimate,
    bool isInvoice = false,
    String wireOption = 'both', // '2mm', '2.5mm', or 'both'
    CompanyProfile? companyProfile,
  }) async {
    final pdf = pw.Document();

    final dateFormat = DateFormat('dd MMM yyyy');
    final invoiceNumber = 'IG-${estimate.customer.id.toString().padLeft(4, '0')}';
    final docTitle = isInvoice ? 'TAX INVOICE' : 'QUOTATION / ESTIMATE';

    // Fetch company profile if not provided
    final company = companyProfile ?? await DatabaseHelper.instance.getCompanyProfile();

    // Color Palette for PDF
    final primaryColor = PdfColor.fromHex('#0F2744');
    final secondaryColor = PdfColor.fromHex('#0284C7');
    final neutralBg = PdfColor.fromHex('#F8FAFC');
    final borderColor = PdfColor.fromHex('#CBD5E1');

    // Attempt to load official logo
    pw.MemoryImage? logoImage;
    try {
      final ByteData data = await rootBundle.load('assets/images/logo.png');
      final Uint8List bytes = data.buffer.asUint8List();
      logoImage = pw.MemoryImage(bytes);
    } catch (_) {}

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      if (logoImage != null) ...[
                        pw.Container(
                          width: 80,
                          height: 50,
                          child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                        ),
                        pw.SizedBox(width: 10),
                      ],
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            company.companyName.toUpperCase(),
                            style: pw.TextStyle(
                              fontSize: 16,
                              fontWeight: pw.FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                          if (company.tagline.isNotEmpty)
                            pw.Text(
                              company.tagline,
                              style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700),
                            ),
                          pw.SizedBox(height: 2),
                          if (company.phone.isNotEmpty || company.email.isNotEmpty)
                            pw.Text(
                              'Phone: ${company.phone} ${company.email.isNotEmpty ? "| Email: ${company.email}" : ""}',
                              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey800),
                            ),
                          if (company.instagramId.isNotEmpty || company.facebookId.isNotEmpty)
                            pw.Text(
                              '${company.instagramId.isNotEmpty ? "Instagram: ${company.instagramId}" : ""} ${company.facebookId.isNotEmpty ? "| Facebook: ${company.facebookId}" : ""}',
                              style: pw.TextStyle(fontSize: 7.5, color: secondaryColor, fontWeight: pw.FontWeight.bold),
                            ),
                        ],
                      ),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: pw.BoxDecoration(
                      color: primaryColor,
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          docTitle,
                          style: pw.TextStyle(
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'Ref: $invoiceNumber',
                          style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.white),
                        ),
                        pw.Text(
                          'Date: ${dateFormat.format(estimate.customer.createdAt)}',
                          style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.white),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Divider(color: secondaryColor, thickness: 1.5),
              pw.SizedBox(height: 8),
            ],
          );
        },
        build: (pw.Context context) {
          final selectedWires = parseWireOptions(wireOption);

          return [
            // Customer Details Section
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: neutralBg,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                border: pw.Border.all(color: borderColor, width: 0.8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'CUSTOMER DETAILS:',
                    style: pw.TextStyle(
                      fontSize: 8.5,
                      fontWeight: pw.FontWeight.bold,
                      color: secondaryColor,
                    ),
                  ),
                  pw.SizedBox(height: 3),
                  pw.Text(
                    estimate.customer.name.toUpperCase(),
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  if (estimate.customer.phone.isNotEmpty)
                    pw.Text(
                      'Contact: ${estimate.customer.phone}',
                      style: const pw.TextStyle(fontSize: 9.5),
                    ),
                  if (estimate.customer.address.isNotEmpty)
                    pw.Text(
                      'Site Address: ${estimate.customer.address}',
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                ],
              ),
            ),
            pw.SizedBox(height: 14),

            // Section 1: Windows Measurement & Area Schedule
            pw.Text(
              '1. WINDOWS MEASUREMENT & AREA SCHEDULE',
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: primaryColor),
            ),
            pw.SizedBox(height: 6),

            (() {
              final targetEst = estimate.withWireThickness(selectedWires.first);
              final defaultRate = targetEst.totalSqFt > 0 ? (targetEst.subtotal / targetEst.totalSqFt) : 0.0;

              return pw.Table(
                border: pw.TableBorder.all(color: borderColor, width: 0.5),
                columnWidths: const {
                  0: pw.FlexColumnWidth(0.7), // Sr.
                  1: pw.FlexColumnWidth(2.6), // Room / Location
                  2: pw.FlexColumnWidth(2.6), // Window
                  3: pw.FlexColumnWidth(1.7), // Total Sq. Ft
                  4: pw.FlexColumnWidth(1.7), // Rate / Sq. Ft
                  5: pw.FlexColumnWidth(2.0), // Total Amount
                },
                children: [
                  // Header Row
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: primaryColor),
                    children: [
                      _buildCell('Sr.', isHeader: true, align: pw.TextAlign.center),
                      _buildCell('Room / Location', isHeader: true),
                      _buildCell('Window', isHeader: true),
                      _buildCell('Total Sq. Ft', isHeader: true, align: pw.TextAlign.right),
                      _buildCell('Rate / Sq. Ft', isHeader: true, align: pw.TextAlign.right),
                      _buildCell('Total Amount', isHeader: true, align: pw.TextAlign.right),
                    ],
                  ),
                  // Data Rows
                  ...(() {
                    int srNo = 1;
                    final rows = <pw.TableRow>[];
                    for (final room in estimate.rooms) {
                      final winList = estimate.windowsByRoom[room.id] ?? [];
                      for (final win in winList) {
                        final winRate = win.ratePerSqFt > 0 ? win.ratePerSqFt : defaultRate;
                        final winAmount = win.totalSqFt * winRate;

                        rows.add(
                          pw.TableRow(
                            decoration: const pw.BoxDecoration(color: PdfColors.white),
                            children: [
                              _buildCell('$srNo', align: pw.TextAlign.center),
                              _buildCell(room.name),
                              _buildCell(win.label),
                              _buildCell('${win.totalSqFt.toStringAsFixed(2)} Sq.Ft', align: pw.TextAlign.right),
                              _buildCell('Rs. ${winRate.toStringAsFixed(2)}', align: pw.TextAlign.right),
                              _buildCell('Rs. ${winAmount.toStringAsFixed(2)}', align: pw.TextAlign.right),
                            ],
                          ),
                        );
                        srNo++;
                      }
                    }
                    return rows;
                  })(),
                ],
              );
            })(),
            pw.SizedBox(height: 16),

            // Section 2: Financial Summary & Quotation Options
            pw.Text(
              isInvoice || selectedWires.length == 1
                  ? '2. FINANCIAL SUMMARY'
                  : '2. FINANCIAL SUMMARY & QUOTATION OPTIONS',
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: primaryColor),
            ),
            pw.SizedBox(height: 8),

            if (selectedWires.length > 1) ...[
              // MULTI-OPTION COMPARISON (2 or 3 columns based on selection)
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  for (int i = 0; i < selectedWires.length; i++) ...[
                    if (i > 0) pw.SizedBox(width: 8),
                    pw.Expanded(
                      child: _buildWireOptionCard(
                        estimate: estimate.withWireThickness(selectedWires[i]),
                        wireThickness: selectedWires[i],
                        optionNumber: i + 1,
                        isRecommended: selectedWires[i] == '2.5mm',
                        primaryColor: primaryColor,
                        secondaryColor: secondaryColor,
                        borderColor: borderColor,
                        neutralBg: neutralBg,
                      ),
                    ),
                  ],
                ],
              ),
            ] else ...[
              // SINGLE WIRE SELECTION
              (() {
                final wire = selectedWires.first;
                final targetEst = estimate.withWireThickness(wire);
                final wireLabel = _getWireDisplayLabel(wire);
                return pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Container(
                      width: 280,
                      padding: const pw.EdgeInsets.all(10),
                      decoration: pw.BoxDecoration(
                        color: neutralBg,
                        border: pw.Border.all(color: borderColor),
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'Configuration: $wireLabel',
                            style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: secondaryColor),
                          ),
                          pw.SizedBox(height: 6),
                          _buildSummaryRow('Subtotal', 'Rs. ${targetEst.subtotal.toStringAsFixed(2)}'),
                          if (targetEst.discountAmount > 0)
                            _buildSummaryRow(
                              'Discount',
                              '- Rs. ${targetEst.discountAmount.toStringAsFixed(2)}',
                              textColor: PdfColors.red700,
                            ),
                          if (targetEst.taxAmount > 0)
                            _buildSummaryRow('GST (${targetEst.customer.taxRate}%)', 'Rs. ${targetEst.taxAmount.toStringAsFixed(2)}'),
                          pw.Divider(color: borderColor, thickness: 1),
                          _buildSummaryRow(
                            'Grand Total',
                            'Rs. ${targetEst.grandTotal.toStringAsFixed(2)}',
                            isBold: true,
                            fontSize: 11,
                            textColor: primaryColor,
                          ),
                          if (targetEst.totalSqFt > 0)
                            _buildSummaryRow(
                              'Rate / Sq. Ft',
                              'Rs. ${targetEst.effectiveRatePerSqFt.toStringAsFixed(2)} / Sq.Ft',
                              isBold: true,
                              textColor: primaryColor,
                            ),
                          if (targetEst.advancePaid > 0) ...[
                            _buildSummaryRow('Advance Paid', 'Rs. ${targetEst.advancePaid.toStringAsFixed(2)}', textColor: PdfColors.green700),
                            _buildSummaryRow('Balance Due', 'Rs. ${targetEst.balanceDue.toStringAsFixed(2)}', isBold: true, textColor: PdfColors.red800),
                          ],
                        ],
                      ),
                    ),
                  ],
                );
              })(),
            ],
            pw.SizedBox(height: 16),

            // Section 3: Terms & Conditions and Specifications
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColors.white,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                border: pw.Border.all(color: borderColor, width: 0.8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'TERMS & CONDITIONS:',
                    style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: primaryColor),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            _buildBulletItem(
                              'Quotation Validity: Valid for 15 days from generated date (${dateFormat.format(estimate.customer.createdAt)} to ${dateFormat.format(estimate.customer.createdAt.add(const Duration(days: 15)))}).',
                              isBold: true,
                              bulletColor: primaryColor,
                            ),
                            _buildBulletItem(
                              'Marine Grade AISI 316 Stainless Steel Wire (Rust-Free)',
                              bulletColor: primaryColor,
                            ),
                            _buildBulletItem(
                              'Heavy Virgin Aluminum Channel with powder coating',
                              bulletColor: primaryColor,
                            ),
                          ],
                        ),
                      ),
                      pw.SizedBox(width: 12),
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            _buildBulletItem(
                              'High tensile strength (tested up to 400+ kg impact)',
                              bulletColor: primaryColor,
                            ),
                            _buildBulletItem(
                              '5 Years Replacement Warranty on SS 316 Wire against rust',
                              bulletColor: primaryColor,
                            ),
                            _buildBulletItem(
                              'Professional installation by certified technicians',
                              bulletColor: primaryColor,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 22),

            // Signatures
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Container(width: 140, height: 1, color: borderColor),
                    pw.SizedBox(height: 4),
                    pw.Text("Customer's Acceptance", style: const pw.TextStyle(fontSize: 8)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Container(width: 150, height: 1, color: borderColor),
                    pw.SizedBox(height: 4),
                    pw.Text('For ${company.companyName.toUpperCase()}', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 12),

            // Footer Contact Bar
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(vertical: 4),
              decoration: pw.BoxDecoration(
                border: pw.Border(top: pw.BorderSide(color: borderColor, width: 0.5)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    '${company.companyName} | ${company.phone}',
                    style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700),
                  ),
                  pw.Text(
                    '${company.instagramId.isNotEmpty ? "IG: ${company.instagramId} | " : ""}${company.facebookId.isNotEmpty ? "FB: ${company.facebookId} | " : ""}${company.email}',
                    style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700),
                  ),
                ],
              ),
            ),
          ];
        },
      ),
    );

    final outputDir = await getApplicationDocumentsDirectory();
    final sanitizedCustomerName = estimate.customer.name.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final fileName = '${company.companyName.replaceAll(" ", "_")}_${sanitizedCustomerName}_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File('${outputDir.path}/$fileName');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  static pw.Widget _buildCell(
    String text, {
    bool isHeader = false,
    pw.TextAlign align = pw.TextAlign.left,
    PdfColor? color,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: isHeader ? 8.5 : 8.0,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: isHeader ? (color ?? PdfColors.white) : (color ?? PdfColors.black),
        ),
      ),
    );
  }

  static pw.Widget _buildSummaryRow(
    String label,
    String value, {
    bool isBold = false,
    double fontSize = 8.5,
    PdfColor? textColor,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(fontSize: fontSize, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: textColor ?? PdfColors.black,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildBulletItem(
    String text, {
    bool isBold = false,
    PdfColor? color,
    PdfColor? bulletColor,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2.5),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 3.5,
            height: 3.5,
            margin: const pw.EdgeInsets.only(top: 3.5, right: 5),
            decoration: pw.BoxDecoration(
              color: bulletColor ?? PdfColor.fromHex('#0F2744'),
              shape: pw.BoxShape.circle,
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              text,
              style: pw.TextStyle(
                fontSize: 7.5,
                fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
                color: color ?? PdfColors.blueGrey900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static List<String> parseWireOptions(String wireOption) {
    if (wireOption == 'both') return ['2mm', '2.5mm'];
    final parts = wireOption.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return ['2.5mm'];
    const order = ['2mm', '2.5mm', '3mm'];
    parts.sort((a, b) {
      final ia = order.indexOf(a);
      final ib = order.indexOf(b);
      return (ia == -1 ? 99 : ia).compareTo(ib == -1 ? 99 : ib);
    });
    return parts;
  }

  static String _getWireDisplayLabel(String wire) {
    switch (wire) {
      case '2mm':
        return '2.0 mm High Tensile Wire';
      case '2.5mm':
        return '2.5 mm High Tensile Wire (Recommended)';
      case '3mm':
        return '3.0 mm High Tensile Wire (Heavy Duty)';
      default:
        return '$wire High Tensile Wire';
    }
  }

  static String _getWireOptionTitle(String wire, int optionNumber) {
    switch (wire) {
      case '2mm':
        return 'OPTION $optionNumber: WITH 2.0 MM';
      case '2.5mm':
        return 'OPTION $optionNumber: WITH 2.5 MM (REC)';
      case '3mm':
        return 'OPTION $optionNumber: WITH 3.0 MM';
      default:
        return 'OPTION $optionNumber: WITH $wire';
    }
  }

  static pw.Widget _buildWireOptionCard({
    required CustomerEstimate estimate,
    required String wireThickness,
    required int optionNumber,
    required bool isRecommended,
    required PdfColor primaryColor,
    required PdfColor secondaryColor,
    required PdfColor borderColor,
    required PdfColor neutralBg,
  }) {
    final title = _getWireOptionTitle(wireThickness, optionNumber);
    final isPrimaryHighlight = isRecommended;
    final badgeColor = isPrimaryHighlight ? primaryColor : secondaryColor;

    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: neutralBg,
        border: pw.Border.all(
          color: isPrimaryHighlight ? primaryColor : borderColor,
          width: isPrimaryHighlight ? 1.2 : 0.8,
        ),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 2.5),
            decoration: pw.BoxDecoration(
              color: badgeColor,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
            ),
            child: pw.Text(
              title,
              style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            ),
          ),
          pw.SizedBox(height: 5),
          _buildSummaryRow('Material & Work Subtotal', 'Rs. ${estimate.subtotal.toStringAsFixed(2)}', fontSize: 7.5),
          if (estimate.discountAmount > 0)
            _buildSummaryRow(
              'Discount',
              '- Rs. ${estimate.discountAmount.toStringAsFixed(2)}',
              textColor: PdfColors.red700,
              fontSize: 7.5,
            ),
          if (estimate.taxAmount > 0)
            _buildSummaryRow('GST (${estimate.customer.taxRate}%)', 'Rs. ${estimate.taxAmount.toStringAsFixed(2)}', fontSize: 7.5),
          pw.Divider(color: borderColor, thickness: 0.8),
          _buildSummaryRow(
            'Grand Total',
            'Rs. ${estimate.grandTotal.toStringAsFixed(2)}',
            isBold: true,
            fontSize: 9.5,
            textColor: primaryColor,
          ),
          if (estimate.totalSqFt > 0)
            _buildSummaryRow(
              'Rate / Sq. Ft',
              'Rs. ${estimate.effectiveRatePerSqFt.toStringAsFixed(2)} / Sq.Ft',
              isBold: true,
              fontSize: 8,
              textColor: isPrimaryHighlight ? primaryColor : secondaryColor,
            ),
          if (estimate.advancePaid > 0) ...[
            _buildSummaryRow('Advance Paid', 'Rs. ${estimate.advancePaid.toStringAsFixed(2)}', textColor: PdfColors.green700, fontSize: 7.5),
            _buildSummaryRow('Balance Due', 'Rs. ${estimate.balanceDue.toStringAsFixed(2)}', isBold: true, textColor: PdfColors.red800, fontSize: 8),
          ],
        ],
      ),
    );
  }
}

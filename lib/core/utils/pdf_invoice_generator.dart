import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../models/models.dart';
import 'unit_converter.dart';

class PdfInvoiceGenerator {
  PdfInvoiceGenerator._();

  static Future<File> generateEstimatePdf({
    required CustomerEstimate estimate,
    bool isInvoice = false,
  }) async {
    final pdf = pw.Document();

    final dateFormat = DateFormat('dd MMM yyyy');
    final invoiceNumber = 'IG-${estimate.customer.id.toString().padLeft(4, '0')}';
    final docTitle = isInvoice ? 'TAX INVOICE' : 'QUOTATION / ESTIMATE';

    // Color Palette for PDF
    final primaryColor = PdfColor.fromHex('#0F2744');
    final secondaryColor = PdfColor.fromHex('#0284C7');
    final neutralBg = PdfColor.fromHex('#F8FAFC');
    final borderColor = PdfColor.fromHex('#CBD5E1');

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
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'INVISIBLE GRILLS',
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Premium Invisible Grills, Balcony & Window Safety Solutions',
                        style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        'Phone: +91 98765 43210 | Email: contact@invisiblegrills.com',
                        style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'Ref: $invoiceNumber',
                          style: const pw.TextStyle(fontSize: 9, color: PdfColors.white),
                        ),
                        pw.Text(
                          'Date: ${dateFormat.format(estimate.customer.createdAt)}',
                          style: const pw.TextStyle(fontSize: 9, color: PdfColors.white),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 12),
              pw.Divider(color: secondaryColor, thickness: 1.5),
              pw.SizedBox(height: 10),
            ],
          );
        },
        build: (pw.Context context) {
          return [
            // Bill To Section
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: neutralBg,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                border: pw.Border.all(color: borderColor, width: 0.8),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
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
                  pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: borderColor),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                      color: PdfColors.white,
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Total Rooms: ${estimate.totalRoomsCount}', style: const pw.TextStyle(fontSize: 9)),
                        pw.Text('Total Windows: ${estimate.totalWindowsCount}', style: const pw.TextStyle(fontSize: 9)),
                        pw.Text(
                          'Total Area: ${estimate.totalSqFt.toStringAsFixed(2)} Sq. Ft',
                          style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: primaryColor),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),

            // Section 1: Window Dimensions & Area Schedule
            pw.Text(
              '1. WINDOWS MEASUREMENT & AREA SCHEDULE',
              style: pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold, color: primaryColor),
            ),
            pw.SizedBox(height: 6),

            pw.Table(
              border: pw.TableBorder.all(color: borderColor, width: 0.5),
              columnWidths: const {
                0: pw.FlexColumnWidth(2.2),
                1: pw.FlexColumnWidth(2.0),
                2: pw.FlexColumnWidth(1.8),
                3: pw.FlexColumnWidth(1.8),
                4: pw.FlexColumnWidth(0.8),
                5: pw.FlexColumnWidth(1.4),
              },
              children: [
                // Header Row
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: primaryColor),
                  children: [
                    _buildCell('Room', isHeader: true),
                    _buildCell('Window & Type', isHeader: true),
                    _buildCell('Size (Inches)', isHeader: true, align: pw.TextAlign.center),
                    _buildCell('Size (Feet)', isHeader: true, align: pw.TextAlign.center),
                    _buildCell('Qty', isHeader: true, align: pw.TextAlign.center),
                    _buildCell('Total Sq.Ft', isHeader: true, align: pw.TextAlign.right),
                  ],
                ),
                // Data Rows grouped by Room
                for (final room in estimate.rooms) ...[
                  for (final win in (estimate.windowsByRoom[room.id] ?? []))
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.white),
                      children: [
                        _buildCell(room.name),
                        _buildCell('${win.label} (${win.windowType})'),
                        _buildCell(
                          '${UnitConverter.formatInches(win.widthInches)} x ${UnitConverter.formatInches(win.heightInches)}',
                          align: pw.TextAlign.center,
                        ),
                        _buildCell(
                          '${win.widthFeet.toStringAsFixed(2)} x ${win.heightFeet.toStringAsFixed(2)} ft',
                          align: pw.TextAlign.center,
                        ),
                        _buildCell('${win.quantity}', align: pw.TextAlign.center),
                        _buildCell('${win.totalSqFt.toStringAsFixed(2)} sq.ft', align: pw.TextAlign.right),
                      ],
                    ),
                ],
                // Measurement Total Row
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: neutralBg),
                  children: [
                    _buildCell('TOTAL AREA', isHeader: true, color: PdfColors.black),
                    _buildCell(''),
                    _buildCell(''),
                    _buildCell(''),
                    _buildCell('${estimate.totalWindowsCount} Units', isHeader: true, color: PdfColors.black, align: pw.TextAlign.center),
                    _buildCell('${estimate.totalSqFt.toStringAsFixed(2)} Sq.Ft', isHeader: true, color: primaryColor, align: pw.TextAlign.right),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 16),

            // Section 2: Materials & Workmanship Breakdown
            pw.Text(
              '2. MATERIALS, HARDWARE & LABOR ESTIMATION',
              style: pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold, color: primaryColor),
            ),
            pw.SizedBox(height: 6),

            pw.Table(
              border: pw.TableBorder.all(color: borderColor, width: 0.5),
              columnWidths: const {
                0: pw.FlexColumnWidth(3.0),
                1: pw.FlexColumnWidth(1.5),
                2: pw.FlexColumnWidth(1.2),
                3: pw.FlexColumnWidth(1.2),
                4: pw.FlexColumnWidth(1.5),
              },
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: primaryColor),
                  children: [
                    _buildCell('Material / Work Description', isHeader: true),
                    _buildCell('Category', isHeader: true),
                    _buildCell('Calculated Qty', isHeader: true, align: pw.TextAlign.center),
                    _buildCell('Rate (INR)', isHeader: true, align: pw.TextAlign.right),
                    _buildCell('Amount (INR)', isHeader: true, align: pw.TextAlign.right),
                  ],
                ),
                for (final mat in estimate.materials.where((m) => m.isEnabled))
                  pw.TableRow(
                    children: [
                      _buildCell(mat.name),
                      _buildCell(mat.category),
                      _buildCell(
                        '${mat.getEffectiveQuantity(totalSqFt: estimate.totalSqFt, totalWindows: estimate.totalWindowsCount).toStringAsFixed(2)} ${mat.unit}',
                        align: pw.TextAlign.center,
                      ),
                      _buildCell('Rs. ${mat.unitPrice.toStringAsFixed(0)}', align: pw.TextAlign.right),
                      _buildCell(
                        'Rs. ${mat.getTotalCost(totalSqFt: estimate.totalSqFt, totalWindows: estimate.totalWindowsCount).toStringAsFixed(2)}',
                        align: pw.TextAlign.right,
                      ),
                    ],
                  ),
              ],
            ),
            pw.SizedBox(height: 16),

            // Section 3: Financial Summary & Totals
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Notes & Terms
                pw.Expanded(
                  flex: 3,
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: borderColor),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('TERMS & CONDITIONS:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8.5)),
                        pw.SizedBox(height: 4),
                        pw.Text('1. 50% Advance with measurement confirmation, balance upon installation.', style: const pw.TextStyle(fontSize: 7.5)),
                        pw.Text('2. Standard glass & aluminium fitting warranty applies.', style: const pw.TextStyle(fontSize: 7.5)),
                        pw.Text('3. Delivery and installation within 7-10 working days.', style: const pw.TextStyle(fontSize: 7.5)),
                        if (estimate.customer.notes.isNotEmpty) ...[
                          pw.SizedBox(height: 4),
                          pw.Text('Special Note: ${estimate.customer.notes}', style: pw.TextStyle(fontSize: 8, fontStyle: pw.FontStyle.italic)),
                        ],
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(width: 16),

                // Financial Box
                pw.Expanded(
                  flex: 2,
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      color: neutralBg,
                      border: pw.Border.all(color: borderColor),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                    ),
                    child: pw.Column(
                      children: [
                        _buildSummaryRow('Subtotal', 'Rs. ${estimate.subtotal.toStringAsFixed(2)}'),
                        if (estimate.discountAmount > 0)
                          _buildSummaryRow(
                            'Discount (${estimate.customer.discountType == "percentage" ? "${estimate.customer.discountValue}%" : "Flat"})',
                            '- Rs. ${estimate.discountAmount.toStringAsFixed(2)}',
                            textColor: PdfColors.red700,
                          ),
                        if (estimate.taxAmount > 0)
                          _buildSummaryRow('GST (${estimate.customer.taxRate}%)', 'Rs. ${estimate.taxAmount.toStringAsFixed(2)}'),
                        pw.Divider(color: borderColor, thickness: 1),
                        _buildSummaryRow('Grand Total', 'Rs. ${estimate.grandTotal.toStringAsFixed(2)}', isBold: true, fontSize: 11),
                        if (estimate.advancePaid > 0) ...[
                          _buildSummaryRow('Advance Paid', 'Rs. ${estimate.advancePaid.toStringAsFixed(2)}', textColor: PdfColors.green700),
                          _buildSummaryRow('Balance Due', 'Rs. ${estimate.balanceDue.toStringAsFixed(2)}', isBold: true, textColor: PdfColors.red800),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 24),

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
                    pw.Container(width: 140, height: 1, color: borderColor),
                    pw.SizedBox(height: 4),
                    pw.Text('For INVISIBLE GRILLS', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ];
        },
      ),
    );

    final outputDir = await getApplicationDocumentsDirectory();
    final sanitizedCustomerName = estimate.customer.name.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final fileName = 'Invisible_Grills_${sanitizedCustomerName}_${DateTime.now().millisecondsSinceEpoch}.pdf';
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
    double fontSize = 9.0,
    PdfColor? textColor,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2.5),
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
}

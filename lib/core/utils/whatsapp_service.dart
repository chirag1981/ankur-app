import 'dart:io';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/models.dart';
import 'unit_converter.dart';

class WhatsAppService {
  WhatsAppService._();

  /// Creates a nicely formatted WhatsApp text message
  static String formatEstimateMessage({
    required CustomerEstimate estimate,
    bool isInvoice = false,
  }) {
    final title = isInvoice ? 'TAX INVOICE' : 'QUOTATION / ESTIMATE';
    final buffer = StringBuffer();

    buffer.writeln('*INVISIBLE GRILLS*');
    buffer.writeln('Invisible Grills, Balcony & Safety Solutions');
    buffer.writeln('--------------------------------');
    buffer.writeln('*$title*');
    buffer.writeln('Ref: IG-${estimate.customer.id.toString().padLeft(4, '0')}');
    buffer.writeln('Customer: *${estimate.customer.name}*');
    if (estimate.customer.phone.isNotEmpty) {
      buffer.writeln('Phone: ${estimate.customer.phone}');
    }
    if (estimate.customer.address.isNotEmpty) {
      buffer.writeln('Site: ${estimate.customer.address}');
    }
    buffer.writeln('--------------------------------');
    buffer.writeln('*MEASUREMENT SUMMARY:*');
    buffer.writeln('• Total Rooms: ${estimate.totalRoomsCount}');
    buffer.writeln('• Total Windows: ${estimate.totalWindowsCount} Units');
    buffer.writeln('• Total Area: *${estimate.totalSqFt.toStringAsFixed(2)} Sq. Ft*');
    buffer.writeln('--------------------------------');
    buffer.writeln('*FINANCIAL SUMMARY:*');
    buffer.writeln('• Subtotal: ${UnitConverter.formatCurrency(estimate.subtotal)}');
    if (estimate.discountAmount > 0) {
      final discDesc = estimate.customer.discountType == 'percentage'
          ? '${estimate.customer.discountValue}%'
          : 'Flat';
      buffer.writeln('• Discount ($discDesc): -${UnitConverter.formatCurrency(estimate.discountAmount)}');
    }
    if (estimate.taxAmount > 0) {
      buffer.writeln('• GST (${estimate.customer.taxRate}%): +${UnitConverter.formatCurrency(estimate.taxAmount)}');
    }
    buffer.writeln('• *Grand Total: ${UnitConverter.formatCurrency(estimate.grandTotal)}*');
    if (estimate.totalSqFt > 0) {
      buffer.writeln('• *Rate / Sq.Ft: ${UnitConverter.formatCurrency(estimate.effectiveRatePerSqFt)} / Sq. Ft*');
    }
    if (estimate.advancePaid > 0) {
      buffer.writeln('• Advance Paid: ${UnitConverter.formatCurrency(estimate.advancePaid)}');
      buffer.writeln('• *Balance Due: ${UnitConverter.formatCurrency(estimate.balanceDue)}*');
    }
    buffer.writeln('--------------------------------');
    buffer.writeln('Quotation & measurement schedule is attached in the PDF.');
    buffer.writeln('Thank you for your business!');

    return buffer.toString();
  }

  /// Share the PDF file and summary message via the system share sheet (which allows choosing WhatsApp)
  static Future<void> sharePdf({
    required File pdfFile,
    required CustomerEstimate estimate,
    bool isInvoice = false,
  }) async {
    final text = formatEstimateMessage(estimate: estimate, isInvoice: isInvoice);
    final xFile = XFile(pdfFile.path);

    await Share.shareXFiles(
      [xFile],
      text: text,
      subject: '${isInvoice ? "Invoice" : "Quotation"} - ${estimate.customer.name} (Invisible Grills)',
    );
  }

  /// Launch WhatsApp chat directly with prefilled text
  static Future<bool> openWhatsAppChat({
    required String phone,
    required String message,
  }) async {
    // Normalize phone number (strip spaces, dashes, parentheses)
    String cleaned = phone.replaceAll(RegExp(r'[^0-9]'), '');
    // If 10 digits (standard Indian mobile), prepend 91
    if (cleaned.length == 10) {
      cleaned = '91$cleaned';
    }

    final encodedMessage = Uri.encodeComponent(message);
    final url = Uri.parse('https://wa.me/$cleaned?text=$encodedMessage');

    if (await canLaunchUrl(url)) {
      return await launchUrl(url, mode: LaunchMode.externalApplication);
    }
    return false;
  }
}

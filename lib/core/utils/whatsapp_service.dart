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
    String wireOption = 'both',
    CompanyProfile? companyProfile,
  }) {
    final company = companyProfile ?? CompanyProfile();
    final title = isInvoice ? 'TAX INVOICE' : 'QUOTATION / ESTIMATE';
    final buffer = StringBuffer();

    buffer.writeln('*${company.companyName.toUpperCase()}*');
    if (company.tagline.isNotEmpty) {
      buffer.writeln(company.tagline);
    }
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
    buffer.writeln('*WINDOWS SCHEDULE:*');
    buffer.writeln('• Total Rooms: ${estimate.totalRoomsCount}');
    buffer.writeln('• Total Windows: ${estimate.totalWindowsCount} Units');
    buffer.writeln('--------------------------------');
    buffer.writeln('*FINANCIAL SUMMARY:*');

    if (wireOption == 'both') {
      final est2mm = estimate.withWireThickness('2mm');
      final est25mm = estimate.withWireThickness('2.5mm');

      buffer.writeln('*OPTION 1 (with 2.0 mm SS 316 Wire):*');
      buffer.writeln('• Subtotal: ${UnitConverter.formatCurrency(est2mm.subtotal)}');
      if (est2mm.discountAmount > 0) {
        buffer.writeln('• Discount: -${UnitConverter.formatCurrency(est2mm.discountAmount)}');
      }
      buffer.writeln('• *Grand Total: ${UnitConverter.formatCurrency(est2mm.grandTotal)}*');
      if (est2mm.totalSqFt > 0) {
        buffer.writeln('• *Rate / Sq.Ft: ${UnitConverter.formatCurrency(est2mm.effectiveRatePerSqFt)} / Sq. Ft*');
      }
      buffer.writeln('');
      buffer.writeln('*OPTION 2 (with 2.5 mm SS 316 Wire - Recommended):*');
      buffer.writeln('• Subtotal: ${UnitConverter.formatCurrency(est25mm.subtotal)}');
      if (est25mm.discountAmount > 0) {
        buffer.writeln('• Discount: -${UnitConverter.formatCurrency(est25mm.discountAmount)}');
      }
      buffer.writeln('• *Grand Total: ${UnitConverter.formatCurrency(est25mm.grandTotal)}*');
      if (est25mm.totalSqFt > 0) {
        buffer.writeln('• *Rate / Sq.Ft: ${UnitConverter.formatCurrency(est25mm.effectiveRatePerSqFt)} / Sq. Ft*');
      }
    } else {
      final effectiveEst = wireOption == '2mm'
          ? estimate.withWireThickness('2mm')
          : (wireOption == '2.5mm' ? estimate.withWireThickness('2.5mm') : estimate);

      buffer.writeln('• Subtotal: ${UnitConverter.formatCurrency(effectiveEst.subtotal)}');
      if (effectiveEst.discountAmount > 0) {
        buffer.writeln('• Discount: -${UnitConverter.formatCurrency(effectiveEst.discountAmount)}');
      }
      if (effectiveEst.taxAmount > 0) {
        buffer.writeln('• GST (${effectiveEst.customer.taxRate}%): +${UnitConverter.formatCurrency(effectiveEst.taxAmount)}');
      }
      buffer.writeln('• *Grand Total: ${UnitConverter.formatCurrency(effectiveEst.grandTotal)}*');
      if (effectiveEst.totalSqFt > 0) {
        buffer.writeln('• *Rate / Sq.Ft: ${UnitConverter.formatCurrency(effectiveEst.effectiveRatePerSqFt)} / Sq. Ft*');
      }
      if (effectiveEst.advancePaid > 0) {
        buffer.writeln('• Advance Paid: ${UnitConverter.formatCurrency(effectiveEst.advancePaid)}');
        buffer.writeln('• *Balance Due: ${UnitConverter.formatCurrency(effectiveEst.balanceDue)}*');
      }
    }

    buffer.writeln('--------------------------------');
    final validDate = estimate.customer.createdAt.add(const Duration(days: 15));
    final validStr = '${validDate.day.toString().padLeft(2, '0')}/${validDate.month.toString().padLeft(2, '0')}/${validDate.year}';
    buffer.writeln('⏳ *Quotation Validity:* 15 days (Valid till $validStr)');
    if (company.phone.isNotEmpty) buffer.writeln('📞 Contact: ${company.phone}');
    if (company.instagramId.isNotEmpty) buffer.writeln('📸 Instagram: ${company.instagramId}');
    if (company.facebookId.isNotEmpty) buffer.writeln('🌐 Facebook: ${company.facebookId}');
    buffer.writeln('Detailed schedule is attached in the PDF.');
    buffer.writeln('Thank you for choosing *${company.companyName}*!');

    return buffer.toString();
  }

  /// Share the PDF file and summary message via the system share sheet (which allows choosing WhatsApp)
  static Future<void> sharePdf({
    required File pdfFile,
    required CustomerEstimate estimate,
    bool isInvoice = false,
    String wireOption = 'both',
    CompanyProfile? companyProfile,
  }) async {
    final text = formatEstimateMessage(
      estimate: estimate,
      isInvoice: isInvoice,
      wireOption: wireOption,
      companyProfile: companyProfile,
    );
    final xFile = XFile(pdfFile.path);

    await Share.shareXFiles(
      [xFile],
      text: text,
      subject: '${isInvoice ? "Invoice" : "Quotation"} - ${estimate.customer.name} (${companyProfile?.companyName ?? "Arham Enterprise"})',
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

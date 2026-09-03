import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../../core/utils/pdf_invoice_generator.dart';
import '../../models/models.dart';

class PdfPreviewScreen extends StatelessWidget {
  final CustomerEstimate estimate;
  final bool isInvoice;

  const PdfPreviewScreen({
    super.key,
    required this.estimate,
    this.isInvoice = false,
  });

  @override
  Widget build(BuildContext context) {
    final title = isInvoice ? 'Tax Invoice' : 'Quotation';

    return Scaffold(
      appBar: AppBar(
        title: Text('$title - ${estimate.customer.name}'),
      ),
      body: PdfPreview(
        build: (format) async {
          final file = await PdfInvoiceGenerator.generateEstimatePdf(
            estimate: estimate,
            isInvoice: isInvoice,
          );
          return await file.readAsBytes();
        },
        canChangeOrientation: false,
        canChangePageFormat: false,
        canDebug: false,
        pdfFileName: 'Invisible_Grills_${estimate.customer.name}.pdf',
      ),
    );
  }
}

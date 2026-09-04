import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../../core/utils/pdf_invoice_generator.dart';
import '../../models/models.dart';

class PdfPreviewScreen extends StatelessWidget {
  final CustomerEstimate estimate;
  final bool isInvoice;
  final String wireOption; // '2mm', '2.5mm', or 'both'

  const PdfPreviewScreen({
    super.key,
    required this.estimate,
    this.isInvoice = false,
    this.wireOption = 'both',
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
            wireOption: wireOption,
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

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

class ReportPreviewScreen extends StatelessWidget {
  final Future<Uint8List> pdfFuture;
  final String reportName;

  const ReportPreviewScreen({
    super.key,
    required this.pdfFuture,
    required this.reportName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Preview'),
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<Uint8List>(
        future: pdfFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)));
          } else if (snapshot.hasError) {
            return Center(child: Text('Error generating report: ${snapshot.error}', style: const TextStyle(color: Colors.white)));
          } else if (snapshot.hasData) {
            return PdfPreview(
              build: (format) => snapshot.data!,
              pdfFileName: reportName,
              canChangePageFormat: false,
              canChangeOrientation: false,
              allowSharing: true,
              allowPrinting: true,
            );
          }
          return const SizedBox();
        },
      ),
    );
  }
}

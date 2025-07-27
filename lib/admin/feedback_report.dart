import 'package:flutter/material.dart';
import 'package:yumme/authentication/database/DatabaseHelper.dart';
import 'package:yumme/authentication/database/feedback_entry.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

class FeedbackReportPage extends StatelessWidget {
  final int rating;
  const FeedbackReportPage({super.key, required this.rating});

  static const labels = ['Terrible','Bad','Okay','Good','Awesome'];
  static const icons = ['😠','😞','😐','😊','😍'];

  @override
  Widget build(BuildContext context) {
    final db = DatabaseHelper();
    return Scaffold(
      appBar: AppBar(title: Text('${labels[rating]} Report')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(icons[rating], style: const TextStyle(fontSize: 50)),
            const SizedBox(height: 8),
            Text('${labels[rating]} Report', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<List<FeedbackEntry>>(
                future: db.getAllFeedback(rating: rating),
                builder: (ctx, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final list = snap.data!;
                  if (list.isEmpty) {
                    return const Center(child: Text('No feedback'));
                  }
                  return ListView.builder(
                    itemCount: list.length,
                    itemBuilder: (_, i) {
                      final f = list[i];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          leading: Text(icons[rating], style: const TextStyle(fontSize: 24)),
                          title: Text(f.comment),
                          subtitle: Text(
                            '${f.createdAt.toLocal()}'.split('.')[0],
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: () async {
            final entries = await DatabaseHelper().getAllFeedback(rating: rating);
            final pdf = pw.Document();
            pdf.addPage(
              pw.Page(
                pageFormat: PdfPageFormat.a4,
                build: (pw.Context ctx) => pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Center(child: pw.Text(icons[rating], style: pw.TextStyle(fontSize: 60))),
                    pw.SizedBox(height: 8),
                    pw.Center(child: pw.Text('${labels[rating]} Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold))),
                    pw.SizedBox(height: 16),
                    ...entries.map((e) => pw.Container(
                      margin: const pw.EdgeInsets.symmetric(vertical: 4),
                      padding: const pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey), borderRadius: pw.BorderRadius.circular(4)),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Row(children: [pw.Text(icons[rating], style: pw.TextStyle(fontSize: 20)), pw.SizedBox(width: 8), pw.Text(e.comment)]),
                          pw.SizedBox(height: 4),
                          pw.Text(e.createdAt.toLocal().toString().split('.')[0], style: pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
                        ],
                      ),
                    ))
                  ],
                ),
              ),
            );
            await Printing.layoutPdf(onLayout: (fmt) => pdf.save());
          },
          child: const Text('Print Report'),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:yumme/authentication/database/DatabaseHelper.dart';

class GraphAnalyticsReportPage extends StatefulWidget {
  const GraphAnalyticsReportPage({super.key});
  @override
  State<GraphAnalyticsReportPage> createState() => _GraphAnalyticsReportPageState();
}

class _GraphAnalyticsReportPageState extends State<GraphAnalyticsReportPage> {
  final _db = DatabaseHelper();
  bool _loading = true;
  List<int> _counts = [0, 0, 0, 0, 0];
  final _icons = ['😠', '😞', '😐', '😊', '😍'];
  final _labels = ['Terrible', 'Bad', 'Okay', 'Good', 'Awesome'];
  final _colors = [Colors.red, Colors.orange, Colors.green, Colors.teal, Colors.yellow];
  final _pdfColors = [PdfColors.red, PdfColors.orange, PdfColors.green, PdfColors.teal, PdfColors.yellow];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final cs = await Future.wait(List.generate(5, (i) => _db.countByRating(i)));
    setState(() {
      _counts = cs;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Graph Analytics Report')),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text('Graph Analytics Report',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: List.generate(
                        5,
                        (i) => Column(
                          children: [
                            Text('+${_counts[i]}'),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.blue, width: 2),
                              ),
                              child: Text(_icons[i], style: const TextStyle(fontSize: 30)),
                            ),
                            Text(_labels[i]),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 200,
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: (_counts.reduce(math.max) + 2).toDouble(),
                          barGroups: List.generate(
                            5,
                            (i) => BarChartGroupData(
                              x: i,
                              barRods: [
                                BarChartRodData(
                                  toY: _counts[i].toDouble(),
                                  color: _colors[i],
                                  width: 22,
                                )
                              ],
                            ),
                          ),
                          titlesData: FlTitlesData(show: false),
                          gridData: FlGridData(show: true, horizontalInterval: 1),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: List.generate(
                        5,
                        (i) => Column(
                          children: [
                            Text(_icons[i], style: const TextStyle(fontSize: 24)),
                            Text(_labels[i]),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: () async {
              final counts = await Future.wait(List.generate(5, (i) => _db.countByRating(i)));
              final maxC = counts.reduce(math.max);
              final doc = pw.Document();
              doc.addPage(
                pw.Page(
                  pageFormat: PdfPageFormat.a4,
                  build: (pw.Context ctx) => pw.Column(
                    children: [
                      pw.Text('Graph Analytics Report',
                          style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 16),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                        children: List.generate(
                          5,
                          (i) => pw.Column(
                            children: [
                              pw.Text('+${counts[i]}', style: pw.TextStyle(fontSize: 18)),
                              pw.Text(_icons[i], style: pw.TextStyle(fontSize: 24)),
                              pw.Text(_labels[i], style: pw.TextStyle(fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 16),
                      pw.Container(
                        height: 200,
                        child: pw.Row(
                          crossAxisAlignment: pw.CrossAxisAlignment.end,
                          mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                          children: List.generate(
                            5,
                            (i) => pw.Container(
                              width: 30,
                              height: maxC > 0 ? 200 * counts[i] / maxC : 0,
                              color: _pdfColors[i],
                            ),
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                        children: List.generate(
                          5,
                          (i) => pw.Text(_icons[i], style: pw.TextStyle(fontSize: 24)),
                        ),
                      ),
                    ],
                  ),
                ),
              );
              await Printing.layoutPdf(onLayout: (fmt) => doc.save());
            },
            child: const Text('Print'),
          ),
        ),
      );
}

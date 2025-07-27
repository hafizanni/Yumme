import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yumme/authentication/database/DatabaseHelper.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:convert';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> _history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final entries = await DatabaseHelper().getNavigationHistory();
    setState(() => _history = entries);
  }

  Future<void> _printHistory() async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Header(level: 0, child: pw.Text('Navigation History')),
          ..._history.map((e) {
            final date = DateTime.fromMillisecondsSinceEpoch(e['timestamp']);
            final dateStr = DateFormat('yyyy-MM-dd HH:mm').format(date);
            return pw.Paragraph(
              text: '${e['restaurant_name']} - ${e['distance'].toStringAsFixed(2)} km on $dateStr',
            );
          }).toList(),
        ],
      ),
    );
    await Printing.layoutPdf(onLayout: (format) => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: _printHistory,
          ),
        ],
      ),
      body: _history.isEmpty
        ? const Center(child: Text('No navigation history yet.'))
        : ListView.builder(
            itemCount: _history.length,
            itemBuilder: (context, idx) {
              final e = _history[idx];
              final date = DateTime.fromMillisecondsSinceEpoch(e['timestamp']);
              final dateStr = DateFormat('yyyy-MM-dd HH:mm').format(date);
              final polyline = jsonDecode(e['polyline']); // List of lat/lng
              final restaurant = jsonDecode(e['restaurant']); // Restaurant details
              return ListTile(
                title: Text(e['restaurant_name']),
                subtitle: Text('${e['distance'].toStringAsFixed(2)} km on $dateStr'),
              );
            },
          ),
    );
  }
}

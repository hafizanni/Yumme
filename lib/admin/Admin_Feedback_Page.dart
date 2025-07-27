import 'package:flutter/material.dart';
import 'package:yumme/admin/GraphAnalyticsReportPage.dart';
import 'package:yumme/admin/feedback_report.dart';
import 'package:yumme/authentication/database/DatabaseHelper.dart';
import 'package:yumme/authentication/database/feedback_entry.dart';

class AdminFeedbackPage extends StatefulWidget {
  const AdminFeedbackPage({super.key});
  @override
  State<AdminFeedbackPage> createState() => _AdminFeedbackPageState();
}

class _AdminFeedbackPageState extends State<AdminFeedbackPage> {
  final _db = DatabaseHelper();
  final _labels = ['Terrible', 'Bad', 'Okay', 'Good', 'Awesome'];
  final _icons = ['😠', '😞', '😐', '😊', '😍'];
  int _selected = 0;
  late Future<List<FeedbackEntry>> _feedbackList;
  late List<int> _counts = [0, 0, 0, 0, 0];

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final cs = await Future.wait(List.generate(5, (i) => _db.countByRating(i)));
    setState(() {
      _counts = cs;
      _feedbackList = _db.getAllFeedback(rating: _selected);
    });
  }

  void _selectRating(int i) {
    setState(() {
      _selected = i;
      _feedbackList = _db.getAllFeedback(rating: i);
    });
  }

  @override
  Widget build(BuildContext c) => Scaffold(
        appBar: AppBar(title: const Text('User Feedback')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(5, (i) {
                  final sel = i == _selected;
                  return GestureDetector(
                    onTap: () => _selectRating(i),
                    child: Column(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: sel ? Colors.blue.withOpacity(0.08) : Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: sel ? Colors.blue : Colors.grey.shade300,
                              width: sel ? 3 : 1,
                            ),
                            boxShadow: sel
                                ? [
                                    BoxShadow(
                                      color: Colors.blue.withOpacity(0.12),
                                      blurRadius: 8,
                                      offset: Offset(0, 2),
                                    ),
                                  ]
                                : [],
                          ),
                          child: Center(
                            child: Text(
                              _icons[i],
                              style: const TextStyle(fontSize: 28),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '+${_counts[i]}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: sel ? Colors.blue : Colors.grey[700],
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          _labels[i],
                          style: TextStyle(
                            fontSize: 13,
                            color: sel ? Colors.blue : Colors.grey[600],
                            fontWeight: sel ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: FutureBuilder<List<FeedbackEntry>>(
                  future: _feedbackList,
                  builder: (ctx, snap) {
                    if (snap.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
                    final list = snap.data!;
                    if (list.isEmpty) return const Center(child: Text('No feedback'));
                    return ListView.builder(
                      itemCount: list.length,
                      itemBuilder: (_, i) {
                        final f = list[i];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            leading: Text(_icons[f.rating], style: const TextStyle(fontSize: 24)),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () => Navigator.push(
                      c,
                      MaterialPageRoute(builder: (_) => FeedbackReportPage(rating: _selected)),
                    ),
                    child: const Text('Generate Report'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.push(
                      c,
                      MaterialPageRoute(builder: (_) => const GraphAnalyticsReportPage()),
                    ),
                    child: const Text('Graph Analysis'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
}
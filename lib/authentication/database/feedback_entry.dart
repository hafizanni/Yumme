

class FeedbackEntry {
  final int? id;
  final int rating;        // 0 = Terrible ... 4 = Awesome
  final String comment;
  final DateTime createdAt;

  FeedbackEntry({
    this.id,
    required this.rating,
    required this.comment,
    DateTime? createdAt,
  }) : this.createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'rating': rating,
        'comment': comment,
        'createdAt': createdAt.toIso8601String(),
      };

  static FeedbackEntry fromMap(Map<String, dynamic> m) => FeedbackEntry(
        id: m['id'] as int?,
        rating: m['rating'] as int,
        comment: m['comment'] as String,
        createdAt: DateTime.parse(m['createdAt'] as String),
      );
}
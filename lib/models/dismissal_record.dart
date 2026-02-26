class DismissalRecord {
  final String category;
  final int attempts;
  final DateTime timestamp;

  const DismissalRecord({
    required this.category,
    required this.attempts,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'attempts': attempts,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  factory DismissalRecord.fromJson(Map<String, dynamic> json) {
    return DismissalRecord(
      category: json['category'] as String,
      attempts: json['attempts'] as int,
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int),
    );
  }
}

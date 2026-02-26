class DismissalRecord {
  final String category;
  final int attempts;
  final DateTime timestamp;
  final double confidence;
  final int durationSeconds;

  const DismissalRecord({
    required this.category,
    required this.attempts,
    required this.timestamp,
    this.confidence = 0.0,
    this.durationSeconds = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'attempts': attempts,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'confidence': confidence,
      'durationSeconds': durationSeconds,
    };
  }

  factory DismissalRecord.fromJson(Map<String, dynamic> json) {
    return DismissalRecord(
      category: json['category'] as String,
      attempts: json['attempts'] as int,
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int),
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      durationSeconds: (json['durationSeconds'] as int?) ?? 0,
    );
  }
}

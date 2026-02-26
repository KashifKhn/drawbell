class DrawingResult {
  final String category;
  final double confidence;
  final int rank;

  const DrawingResult({
    required this.category,
    required this.confidence,
    required this.rank,
  });

  String get percentLabel => '${(confidence * 100).toStringAsFixed(1)}%';
}

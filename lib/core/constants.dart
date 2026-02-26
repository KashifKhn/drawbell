enum Difficulty {
  easy,
  medium,
  hard;

  double get threshold => switch (this) {
    Difficulty.easy => 0.40,
    Difficulty.medium => 0.60,
    Difficulty.hard => 0.75,
  };

  int? get mercyAttempts => switch (this) {
    Difficulty.easy => 5,
    Difficulty.medium => 10,
    Difficulty.hard => null,
  };

  bool get usesTop3 => this == Difficulty.easy;

  String get label => switch (this) {
    Difficulty.easy => 'Easy',
    Difficulty.medium => 'Medium',
    Difficulty.hard => 'Hard',
  };
}

const String modelAssetPath = 'assets/quickdraw_model.tflite';
const String labelsAssetPath = 'assets/labels.txt';
const int modelInputSize = 28;
const int categoryCount = 345;
const double canvasSize = 360.0;
const double mercyReduction = 0.10;
const double canvasStrokeWidth = 4.0;
const double canvasBorderRadius = 16.0;
const Duration idleTimeout = Duration(seconds: 30);
const Duration snoozeDuration = Duration(minutes: 5);

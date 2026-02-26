import 'package:flutter/material.dart';

import '../../../core/constants.dart';

class DrawingCanvas extends StatelessWidget {
  final List<List<Offset>> strokes;
  final List<Offset> currentStroke;
  final GestureDragStartCallback onPanStart;
  final GestureDragUpdateCallback onPanUpdate;
  final GestureDragEndCallback onPanEnd;

  const DrawingCanvas({
    super.key,
    required this.strokes,
    required this.currentStroke,
    required this.onPanStart,
    required this.onPanUpdate,
    required this.onPanEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: canvasSize,
        height: canvasSize,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(canvasBorderRadius),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withAlpha(60),
              blurRadius: 24,
              spreadRadius: 2,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(canvasBorderRadius),
          child: GestureDetector(
            onPanStart: onPanStart,
            onPanUpdate: onPanUpdate,
            onPanEnd: onPanEnd,
            child: CustomPaint(
              painter: _StrokePainter(strokes, currentStroke),
              size: const Size(canvasSize, canvasSize),
            ),
          ),
        ),
      ),
    );
  }
}

class _StrokePainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final List<Offset> current;

  _StrokePainter(this.strokes, this.current);

  static final Paint _paint = Paint()
    ..color = Colors.black
    ..strokeWidth = canvasStrokeWidth
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..style = PaintingStyle.stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final List<List<Offset>> all = [
      ...strokes,
      if (current.isNotEmpty) current,
    ];
    for (final List<Offset> stroke in all) {
      if (stroke.isEmpty) continue;
      if (stroke.length == 1) {
        canvas.drawCircle(stroke[0], 2.5, _paint..style = PaintingStyle.fill);
        _paint.style = PaintingStyle.stroke;
        continue;
      }
      final Path path = Path()..moveTo(stroke[0].dx, stroke[0].dy);
      for (int i = 1; i < stroke.length; i++) {
        path.lineTo(stroke[i].dx, stroke[i].dy);
      }
      canvas.drawPath(path, _paint);
    }
  }

  @override
  bool shouldRepaint(_StrokePainter old) => true;
}

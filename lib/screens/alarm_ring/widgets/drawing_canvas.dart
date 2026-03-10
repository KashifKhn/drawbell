import 'package:flutter/material.dart';

import '../../../core/constants.dart';

class DrawingCanvas extends StatelessWidget {
  final List<List<Offset>> strokes;
  final List<Offset> currentStroke;
  final List<List<Offset>>? hintStrokes;
  final Widget? hintThumbnail;
  final GestureDragStartCallback? onPanStart;
  final GestureDragUpdateCallback? onPanUpdate;
  final GestureDragEndCallback? onPanEnd;

  const DrawingCanvas({
    super.key,
    required this.strokes,
    required this.currentStroke,
    this.hintStrokes,
    this.hintThumbnail,
    this.onPanStart,
    this.onPanUpdate,
    this.onPanEnd,
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
          child: Stack(
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanStart: onPanStart,
                onPanUpdate: onPanUpdate,
                onPanEnd: onPanEnd,
                child: CustomPaint(
                  painter: _StrokePainter(strokes, currentStroke, hintStrokes),
                  size: const Size(canvasSize, canvasSize),
                ),
              ),
              if (hintThumbnail != null)
                Positioned(
                  top: 8,
                  right: 8,
                  child: IgnorePointer(child: hintThumbnail!),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StrokePainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final List<Offset> current;
  final List<List<Offset>>? hintStrokes;

  _StrokePainter(this.strokes, this.current, this.hintStrokes);

  static final Paint _hintPaint = Paint()
    ..color = const Color(0x28000000)
    ..strokeWidth = canvasStrokeWidth + 2
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..style = PaintingStyle.stroke;

  static final Paint _userPaint = Paint()
    ..color = Colors.black
    ..strokeWidth = canvasStrokeWidth
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..style = PaintingStyle.stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final List<List<Offset>>? hints = hintStrokes;
    if (hints != null) {
      _drawStrokes(canvas, hints, _hintPaint);
    }
    final List<List<Offset>> all = [
      ...strokes,
      if (current.isNotEmpty) current,
    ];
    _drawStrokes(canvas, all, _userPaint);
  }

  void _drawStrokes(Canvas canvas, List<List<Offset>> list, Paint paint) {
    for (final List<Offset> stroke in list) {
      if (stroke.isEmpty) continue;
      if (stroke.length == 1) {
        final Paint dotPaint = Paint()
          ..color = paint.color
          ..style = PaintingStyle.fill;
        canvas.drawCircle(stroke[0], 2.5, dotPaint);
        continue;
      }
      final Path path = Path()..moveTo(stroke[0].dx, stroke[0].dy);
      for (int i = 1; i < stroke.length; i++) {
        path.lineTo(stroke[i].dx, stroke[i].dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_StrokePainter old) => true;
}

import 'package:flutter/material.dart';

import '../../../core/constants.dart';

class HintThumbnail extends StatelessWidget {
  final List<List<Offset>> strokes;

  const HintThumbnail({super.key, required this.strokes});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Container(
      width: hintThumbnailSize,
      height: hintThumbnailSize,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outline.withAlpha(80)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(32),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CustomPaint(painter: _ThumbnailPainter(strokes)),
      ),
    );
  }
}

class _ThumbnailPainter extends CustomPainter {
  final List<List<Offset>> strokes;

  _ThumbnailPainter(this.strokes);

  @override
  void paint(Canvas canvas, Size size) {
    final double scale = (size.width - 12) / canvasSize;
    final double pad = 6;
    final Paint paint = Paint()
      ..color = Colors.black
      ..strokeWidth = canvasStrokeWidth * scale * 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (final List<Offset> stroke in strokes) {
      if (stroke.isEmpty) continue;
      final List<Offset> scaled = stroke
          .map((Offset p) => Offset(p.dx * scale + pad, p.dy * scale + pad))
          .toList();
      if (scaled.length == 1) {
        paint.style = PaintingStyle.fill;
        canvas.drawCircle(scaled[0], canvasStrokeWidth * scale, paint);
        paint.style = PaintingStyle.stroke;
        continue;
      }
      final Path path = Path()..moveTo(scaled[0].dx, scaled[0].dy);
      for (int i = 1; i < scaled.length; i++) {
        path.lineTo(scaled[i].dx, scaled[i].dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_ThumbnailPainter old) => old.strokes != strokes;
}

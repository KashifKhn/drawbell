import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

import '../core/constants.dart';
import '../models/drawing_result.dart';

class ClassifierService {
  Interpreter? _interpreter;
  List<String> _labels = [];
  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;
  List<String> get labels => List.unmodifiable(_labels);

  Future<void> load() async {
    _interpreter = await Interpreter.fromAsset(modelAssetPath);
    final String raw = await rootBundle.loadString(labelsAssetPath);
    _labels = raw.trim().split('\n').map((String l) => l.trim()).toList();
    _isLoaded = true;
  }

  Future<List<DrawingResult>> classify(
    List<List<Offset>> strokes,
    double canvasWidth,
    double canvasHeight,
  ) async {
    if (_interpreter == null || strokes.isEmpty) return [];

    final Float32List flat = await _preprocess(
      strokes,
      canvasWidth,
      canvasHeight,
    );

    final List<List<List<List<double>>>> input = List.generate(
      1,
      (_) => List.generate(
        modelInputSize,
        (int y) => List.generate(
          modelInputSize,
          (int x) => [flat[y * modelInputSize + x]],
        ),
      ),
    );
    final List<List<double>> output = [
      List<double>.filled(_labels.length, 0.0),
    ];

    _interpreter!.run(input, output);

    final List<double> probs = List<double>.from(output[0] as List);
    final List<DrawingResult> results = List.generate(
      probs.length,
      (int i) =>
          DrawingResult(category: _labels[i], confidence: probs[i], rank: 0),
    );
    results.sort(
      (DrawingResult a, DrawingResult b) =>
          b.confidence.compareTo(a.confidence),
    );

    return results
        .take(5)
        .toList()
        .asMap()
        .entries
        .map(
          (MapEntry<int, DrawingResult> e) => DrawingResult(
            category: e.value.category,
            confidence: e.value.confidence,
            rank: e.key + 1,
          ),
        )
        .toList();
  }

  bool doesMatch(
    List<DrawingResult> results,
    String prompt,
    double threshold, {
    bool useTop3 = false,
  }) {
    if (results.isEmpty) return false;

    final int checkCount = useTop3 ? min(3, results.length) : 1;
    for (int i = 0; i < checkCount; i++) {
      if (results[i].category.toLowerCase() == prompt.toLowerCase() &&
          results[i].confidence >= threshold) {
        return true;
      }
    }
    return false;
  }

  Future<Float32List> _preprocess(
    List<List<Offset>> strokes,
    double canvasWidth,
    double canvasHeight,
  ) async {
    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;

    for (final List<Offset> s in strokes) {
      for (final Offset p in s) {
        if (p.dx < minX) minX = p.dx;
        if (p.dy < minY) minY = p.dy;
        if (p.dx > maxX) maxX = p.dx;
        if (p.dy > maxY) maxY = p.dy;
      }
    }

    final double bw = maxX - minX;
    final double bh = maxY - minY;
    minX = max(0.0, minX - bw * 0.10);
    minY = max(0.0, minY - bh * 0.10);
    maxX = min(canvasWidth, maxX + bw * 0.10);
    maxY = min(canvasHeight, maxY + bh * 0.10);

    final double cropW = maxX - minX;
    final double cropH = maxY - minY;

    const int ts = modelInputSize;
    final double scale = ts / max(cropW, cropH);
    final double scaledW = cropW * scale;
    final double scaledH = cropH * scale;
    final double offX = (ts - scaledW) / 2.0;
    final double offY = (ts - scaledH) / 2.0;

    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas c = Canvas(recorder);

    c.drawRect(
      Rect.fromLTWH(0, 0, ts.toDouble(), ts.toDouble()),
      Paint()..color = const Color(0xFFFFFFFF),
    );

    final Paint strokePaint = Paint()
      ..color = const Color(0xFF000000)
      ..strokeWidth = max(2.0, 2.5 * scale)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (final List<Offset> stroke in strokes) {
      if (stroke.length < 2) {
        final double x = (stroke[0].dx - minX) * scale + offX;
        final double y = (stroke[0].dy - minY) * scale + offY;
        c.drawCircle(
          Offset(x, y),
          max(1.0, 1.5 * scale),
          strokePaint..style = PaintingStyle.fill,
        );
        strokePaint.style = PaintingStyle.stroke;
        continue;
      }
      final Path path = Path()
        ..moveTo(
          (stroke[0].dx - minX) * scale + offX,
          (stroke[0].dy - minY) * scale + offY,
        );
      for (int i = 1; i < stroke.length; i++) {
        path.lineTo(
          (stroke[i].dx - minX) * scale + offX,
          (stroke[i].dy - minY) * scale + offY,
        );
      }
      c.drawPath(path, strokePaint);
    }

    final ui.Picture pic = recorder.endRecording();
    final ui.Image img = await pic.toImage(ts, ts);
    final ByteData? bd = await img.toByteData(
      format: ui.ImageByteFormat.rawRgba,
    );
    final Uint8List px = bd!.buffer.asUint8List();

    final Float32List result = Float32List(ts * ts);
    for (int i = 0; i < ts * ts; i++) {
      result[i] = 1.0 - (px[i * 4] / 255.0);
    }
    return result;
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _isLoaded = false;
  }
}

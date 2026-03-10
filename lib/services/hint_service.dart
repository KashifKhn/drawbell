import 'dart:convert';

import 'package:flutter/services.dart';

import '../core/constants.dart';

class HintService {
  static Map<String, List<List<List<int>>>>? _rawCache;

  static Future<List<List<Offset>>?> getStrokes(
    String category,
    double canvasSize,
  ) async {
    await _ensureLoaded();
    final List<List<List<int>>>? raw = _rawCache?[category.toLowerCase()];
    if (raw == null) return null;
    return _normalize(raw, canvasSize);
  }

  static Future<void> _ensureLoaded() async {
    if (_rawCache != null) return;
    final String jsonStr = await rootBundle.loadString(hintDrawingsAssetPath);
    final Map<String, dynamic> data =
        json.decode(jsonStr) as Map<String, dynamic>;
    final Map<String, List<List<List<int>>>> result = {};
    for (final MapEntry<String, dynamic> entry in data.entries) {
      final List<dynamic> strokes = entry.value as List<dynamic>;
      result[entry.key.toLowerCase()] = strokes
          .map<List<List<int>>>(
            (dynamic stroke) => [
              (stroke[0] as List<dynamic>)
                  .map<int>((dynamic v) => (v as num).toInt())
                  .toList(),
              (stroke[1] as List<dynamic>)
                  .map<int>((dynamic v) => (v as num).toInt())
                  .toList(),
            ],
          )
          .toList();
    }
    _rawCache = result;
  }

  static List<List<Offset>> _normalize(
    List<List<List<int>>> rawStrokes,
    double canvasSize,
  ) {
    return rawStrokes
        .map<List<Offset>>(
          (List<List<int>> stroke) => List<Offset>.generate(
            stroke[0].length,
            (int i) => Offset(
              stroke[0][i] * canvasSize / 255,
              stroke[1][i] * canvasSize / 255,
            ),
          ),
        )
        .toList();
  }
}

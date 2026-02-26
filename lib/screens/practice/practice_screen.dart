import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../models/drawing_result.dart';
import '../../services/classifier_service.dart';
import '../../theme.dart';
import '../alarm_ring/widgets/drawing_canvas.dart';
import 'widgets/category_picker_sheet.dart';
import 'widgets/practice_result_overlay.dart';
import 'widgets/prediction_tile.dart';

class PracticeScreen extends StatefulWidget {
  const PracticeScreen({super.key});

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  final ClassifierService _classifier = ClassifierService();

  final List<List<Offset>> _strokes = [];
  List<Offset> _currentStroke = [];
  List<DrawingResult> _predictions = [];

  bool _isLoading = true;
  bool _isClassifying = false;

  String? _targetCategory;
  bool _showResult = false;
  bool _lastMatchResult = false;
  double _lastConfidence = 0.0;
  int _attempts = 0;
  DateTime _startTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _initClassifier();
  }

  Future<void> _initClassifier() async {
    await _classifier.load();
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _classify() async {
    if (_strokes.isEmpty || _isClassifying) return;
    setState(() => _isClassifying = true);

    try {
      final List<DrawingResult> results = await _classifier.classify(
        _strokes,
        canvasSize,
        canvasSize,
      );

      if (!mounted) return;

      setState(() => _predictions = results);

      if (_targetCategory != null) {
        _attempts++;

        final DrawingResult? targetResult = results
            .cast<DrawingResult?>()
            .firstWhere(
              (DrawingResult? r) =>
                  r!.category.toLowerCase() == _targetCategory!.toLowerCase(),
              orElse: () => null,
            );

        if (targetResult != null) {
          _lastConfidence = targetResult.confidence;
        }

        final bool matched = _classifier.doesMatch(
          results,
          _targetCategory!,
          Difficulty.medium.threshold,
          useTop3: true,
        );

        if (matched) {
          setState(() {
            _lastMatchResult = true;
            _showResult = true;
          });
        }
      }
    } finally {
      if (mounted) setState(() => _isClassifying = false);
    }
  }

  void _clear() {
    setState(() {
      _strokes.clear();
      _currentStroke.clear();
      _predictions.clear();
    });
  }

  void _undo() {
    if (_strokes.isNotEmpty) {
      setState(() {
        _strokes.removeLast();
        _predictions.clear();
      });
      if (_strokes.isNotEmpty) _classify();
    }
  }

  void _submitDrawing() {
    if (_targetCategory == null || _predictions.isEmpty) return;

    final bool matched = _classifier.doesMatch(
      _predictions,
      _targetCategory!,
      Difficulty.medium.threshold,
      useTop3: true,
    );

    setState(() {
      _lastMatchResult = matched;
      _showResult = true;
    });
  }

  void _playAgain() {
    setState(() {
      _strokes.clear();
      _currentStroke.clear();
      _predictions.clear();
      _showResult = false;
      _lastMatchResult = false;
      _lastConfidence = 0.0;
      _attempts = 0;
      _startTime = DateTime.now();
    });
  }

  void _newCategory() {
    _playAgain();
    _showCategoryPicker();
  }

  void _pickRandom() {
    if (_classifier.labels.isEmpty) return;
    final String random =
        _classifier.labels[Random().nextInt(_classifier.labels.length)];
    setState(() {
      _targetCategory = random;
      _strokes.clear();
      _currentStroke.clear();
      _predictions.clear();
      _showResult = false;
      _lastMatchResult = false;
      _lastConfidence = 0.0;
      _attempts = 0;
      _startTime = DateTime.now();
    });
  }

  Future<void> _showCategoryPicker() async {
    final String? result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return CategoryPickerSheet(
          allCategories: _classifier.labels,
          currentCategory: _targetCategory,
        );
      },
    );

    if (!mounted) return;

    setState(() {
      _targetCategory = result;
      _strokes.clear();
      _currentStroke.clear();
      _predictions.clear();
      _showResult = false;
      _lastMatchResult = false;
      _lastConfidence = 0.0;
      _attempts = 0;
      _startTime = DateTime.now();
    });
  }

  @override
  void dispose() {
    _classifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Practice')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Loading AI model...',
                style: textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Practice'),
        actions: [
          IconButton(
            tooltip: 'Undo stroke',
            onPressed: _strokes.isNotEmpty ? _undo : null,
            icon: const Icon(Icons.undo, size: 20),
          ),
          IconButton(
            tooltip: 'Clear canvas',
            onPressed: _strokes.isNotEmpty ? _clear : null,
            icon: const Icon(Icons.delete_outline, size: 20),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: _buildModeSelector(colors, textTheme),
              ),
              if (_targetCategory != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: _buildTargetHeader(colors, textTheme),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 4),
                  child: Text(
                    'Draw anything and see what the AI thinks',
                    textAlign: TextAlign.center,
                    style: textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: DrawingCanvas(
                  strokes: _strokes,
                  currentStroke: _currentStroke,
                  onPanStart: (DragStartDetails d) {
                    setState(() => _currentStroke = [d.localPosition]);
                  },
                  onPanUpdate: (DragUpdateDetails d) {
                    setState(() => _currentStroke.add(d.localPosition));
                  },
                  onPanEnd: (_) {
                    if (_currentStroke.isNotEmpty) {
                      setState(() {
                        _strokes.add(List.from(_currentStroke));
                        _currentStroke.clear();
                      });
                      _classify();
                    }
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: _buildActionButtons(colors, textTheme),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  children: [_buildPredictions(colors, textTheme)],
                ),
              ),
            ],
          ),
          if (_showResult && _targetCategory != null)
            PracticeResultOverlay(
              isMatch: _lastMatchResult,
              category: _targetCategory!,
              confidence: _lastConfidence,
              attemptCount: _attempts,
              durationSeconds: DateTime.now().difference(_startTime).inSeconds,
              onPlayAgain: _playAgain,
              onNewCategory: _newCategory,
            ),
        ],
      ),
    );
  }

  Widget _buildModeSelector(ColorScheme colors, TextTheme textTheme) {
    return Row(
      children: [
        Expanded(
          child: _ModeChip(
            label: 'Free Draw',
            icon: Icons.brush,
            isSelected: _targetCategory == null,
            onTap: () {
              setState(() {
                _targetCategory = null;
                _clear();
              });
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ModeChip(
            label: 'Pick Category',
            icon: Icons.category,
            isSelected: _targetCategory != null,
            onTap: _showCategoryPicker,
          ),
        ),
        const SizedBox(width: 8),
        _ModeChip(
          label: 'Random',
          icon: Icons.shuffle,
          isSelected: false,
          onTap: _pickRandom,
          compact: true,
        ),
      ],
    );
  }

  Widget _buildTargetHeader(ColorScheme colors, TextTheme textTheme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.brandOrange.withAlpha(25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.brush, color: AppTheme.brandOrange, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Draw:',
                    style: textTheme.labelSmall?.copyWith(
                      color: colors.onSurfaceVariant,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    _targetCategory!,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.brandOrange,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: _pickRandom,
              icon: Icon(
                Icons.shuffle,
                color: colors.onSurfaceVariant,
                size: 20,
              ),
              tooltip: 'Random category',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(ColorScheme colors, TextTheme textTheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        OutlinedButton.icon(
          onPressed: _strokes.isNotEmpty ? _clear : null,
          icon: const Icon(Icons.delete_outline, size: 18),
          label: const Text('Clear'),
        ),
        if (_targetCategory != null) ...[
          const SizedBox(width: 12),
          FilledButton.icon(
            onPressed: _predictions.isNotEmpty ? _submitDrawing : null,
            icon: _isClassifying
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.check, size: 18),
            label: Text(_isClassifying ? 'Checking...' : 'Submit'),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.brandOrange,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPredictions(ColorScheme colors, TextTheme textTheme) {
    if (_isClassifying && _predictions.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 24),
        child: CircularProgressIndicator(),
      );
    }
    if (_predictions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Text(
          _strokes.isEmpty
              ? 'Start drawing above!'
              : 'Finish a stroke to see predictions',
          style: textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Top Predictions',
          style: textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: colors.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                for (final DrawingResult r in _predictions)
                  PredictionTile(
                    rank: r.rank,
                    label: r.category,
                    score: r.confidence,
                    targetCategory: _targetCategory,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ModeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final bool compact;

  const _ModeChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 12 : 12,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.brandOrange.withAlpha(25)
              : colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppTheme.brandOrange.withAlpha(80)
                : colors.outlineVariant,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected
                  ? AppTheme.brandOrange
                  : colors.onSurfaceVariant,
            ),
            if (!compact) ...[
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                    color: isSelected
                        ? AppTheme.brandOrange
                        : colors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../../models/drawing_result.dart';
import '../../services/audio_service.dart';
import '../../services/classifier_service.dart';
import 'widgets/attempt_counter.dart';
import 'widgets/drawing_canvas.dart';
import 'widgets/prompt_header.dart';
import 'widgets/result_feedback.dart';

class AlarmRingScreen extends StatefulWidget {
  final Difficulty difficulty;

  const AlarmRingScreen({super.key, required this.difficulty});

  @override
  State<AlarmRingScreen> createState() => _AlarmRingScreenState();
}

class _AlarmRingScreenState extends State<AlarmRingScreen> {
  final ClassifierService _classifier = ClassifierService();
  final AudioService _audio = AudioService();

  final List<List<Offset>> _strokes = [];
  List<Offset> _currentStroke = [];

  String _prompt = '';
  int _attempts = 0;
  bool? _lastResult;
  bool _isClassifying = false;
  bool _isLoading = true;
  bool _isDismissed = false;
  double _currentThreshold = 0;

  @override
  void initState() {
    super.initState();
    _currentThreshold = widget.difficulty.threshold;
    _initAlarm();
  }

  Future<void> _initAlarm() async {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    await _classifier.load();
    _pickPrompt();
    setState(() => _isLoading = false);
    _audio.startAlarm();
  }

  void _pickPrompt() {
    final List<String> labels = _classifier.labels;
    final String newPrompt = labels[Random().nextInt(labels.length)];
    setState(() => _prompt = newPrompt);
  }

  Future<void> _classify() async {
    if (_strokes.isEmpty || _isClassifying || _isDismissed) return;
    setState(() => _isClassifying = true);

    try {
      final List<DrawingResult> results = await _classifier.classify(
        _strokes,
        canvasSize,
        canvasSize,
      );

      if (!mounted) return;

      final bool matched = _classifier.doesMatch(
        results,
        _prompt,
        _currentThreshold,
        useTop3: widget.difficulty.usesTop3,
      );

      if (matched) {
        _onSuccess();
      } else {
        _onFailure();
      }
    } finally {
      if (mounted) setState(() => _isClassifying = false);
    }
  }

  void _onSuccess() {
    setState(() {
      _lastResult = true;
      _isDismissed = true;
    });
    _audio.stopAlarm();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
        context.go('/');
      }
    });
  }

  void _onFailure() {
    setState(() {
      _lastResult = false;
      _attempts++;
    });

    final int? mercy = widget.difficulty.mercyAttempts;
    if (mercy != null && _attempts >= mercy) {
      _currentThreshold = (_currentThreshold - mercyReduction).clamp(0.1, 1.0);
    }

    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && !_isDismissed) {
        setState(() {
          _strokes.clear();
          _lastResult = null;
        });
      }
    });
  }

  void _undo() {
    if (_strokes.isNotEmpty) {
      setState(() {
        _strokes.removeLast();
        _lastResult = null;
      });
    }
  }

  void _clear() {
    setState(() {
      _strokes.clear();
      _currentStroke.clear();
      _lastResult = null;
    });
  }

  @override
  void dispose() {
    _audio.dispose();
    _classifier.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: colors.surface,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: colors.surface,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Column(
              children: [
                PromptHeader(category: _prompt),
                const SizedBox(height: 24),
                DrawingCanvas(
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
                const SizedBox(height: 16),
                ResultFeedback(isCorrect: _lastResult),
                const SizedBox(height: 8),
                AttemptCounter(attempts: _attempts),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _isDismissed ? null : _undo,
                      icon: const Icon(Icons.undo, size: 18),
                      label: const Text('Undo'),
                    ),
                    const SizedBox(width: 16),
                    OutlinedButton.icon(
                      onPressed: _isDismissed ? null : _clear,
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('Clear'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

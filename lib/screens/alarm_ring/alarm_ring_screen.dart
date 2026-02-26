import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../../models/dismissal_record.dart';
import '../../models/drawing_result.dart';
import '../../services/audio_service.dart';
import '../../services/classifier_service.dart';
import '../../services/notification_service.dart';
import '../../services/storage_service.dart';
import 'widgets/attempt_counter.dart';
import 'widgets/drawing_canvas.dart';
import 'widgets/prompt_header.dart';
import 'widgets/result_feedback.dart';
import 'widgets/success_overlay.dart';

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

  Timer? _idleTimer;

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
    _resetIdleTimer();
  }

  void _pickPrompt() {
    final List<String> labels = _classifier.labels;
    final String newPrompt = labels[Random().nextInt(labels.length)];
    setState(() => _prompt = newPrompt);
  }

  void _resetIdleTimer() {
    _idleTimer?.cancel();
    if (_isDismissed) return;
    _idleTimer = Timer(idleTimeout, _onIdleTimeout);
  }

  void _onIdleTimeout() {
    if (!mounted || _isDismissed) return;
    setState(() {
      _strokes.clear();
      _currentStroke.clear();
      _lastResult = null;
    });
    _pickPrompt();
    _resetIdleTimer();
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
    _idleTimer?.cancel();
    setState(() {
      _lastResult = true;
      _isDismissed = true;
    });
    _audio.stopAlarm();
    _recordDismissal();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
        context.go('/');
      }
    });
  }

  Future<void> _recordDismissal() async {
    final StorageService storage = StorageService();
    await storage.init();
    await storage.addDismissal(
      DismissalRecord(
        category: _prompt,
        attempts: _attempts,
        timestamp: DateTime.now(),
      ),
    );
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
      _resetIdleTimer();
    }
  }

  void _clear() {
    setState(() {
      _strokes.clear();
      _currentStroke.clear();
      _lastResult = null;
    });
    _resetIdleTimer();
  }

  Future<void> _snooze() async {
    if (_isDismissed) return;
    _idleTimer?.cancel();
    _audio.stopAlarm();

    final DateTime snoozeTime = DateTime.now().add(snoozeDuration);
    final String payload = '{"difficulty":${widget.difficulty.index}}';

    await NotificationService().scheduleAlarm(
      id: snoozeTime.hashCode & 0x7FFFFFFF,
      title: 'DrawBell',
      body: 'Snoozed alarm — draw to dismiss!',
      scheduledTime: snoozeTime,
      payload: payload,
    );

    if (mounted) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      context.go('/');
    }
  }

  @override
  void dispose() {
    _idleTimer?.cancel();
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

    final bool canInteract = !_isDismissed && !_isClassifying;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: colors.surface,
        body: SafeArea(
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 24,
                ),
                child: Column(
                  children: [
                    PromptHeader(category: _prompt),
                    const SizedBox(height: 24),
                    DrawingCanvas(
                      strokes: _strokes,
                      currentStroke: _currentStroke,
                      onPanStart: canInteract
                          ? (DragStartDetails d) {
                              _resetIdleTimer();
                              setState(
                                () => _currentStroke = [d.localPosition],
                              );
                            }
                          : null,
                      onPanUpdate: canInteract
                          ? (DragUpdateDetails d) {
                              setState(
                                () => _currentStroke.add(d.localPosition),
                              );
                            }
                          : null,
                      onPanEnd: canInteract
                          ? (_) {
                              if (_currentStroke.isNotEmpty) {
                                setState(() {
                                  _strokes.add(List.from(_currentStroke));
                                  _currentStroke.clear();
                                });
                                _classify();
                              }
                            }
                          : null,
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
                          onPressed: canInteract ? _undo : null,
                          icon: const Icon(Icons.undo, size: 18),
                          label: const Text('Undo'),
                        ),
                        const SizedBox(width: 16),
                        OutlinedButton.icon(
                          onPressed: canInteract ? _clear : null,
                          icon: const Icon(Icons.delete_outline, size: 18),
                          label: const Text('Clear'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: canInteract ? _snooze : null,
                      icon: const Icon(Icons.snooze, size: 18),
                      label: const Text('Snooze (5 min)'),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              if (_isDismissed) const SuccessOverlay(),
            ],
          ),
        ),
      ),
    );
  }
}

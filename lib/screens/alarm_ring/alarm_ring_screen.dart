import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../../models/alarm_model.dart';
import '../../models/dismissal_record.dart';
import '../../models/drawing_result.dart';
import '../../providers/alarm_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/audio_service.dart';
import '../../services/classifier_service.dart';
import '../../services/hint_service.dart';
import '../../services/notification_service.dart';
import '../../services/storage_service.dart';
import 'widgets/attempt_counter.dart';
import 'widgets/drawing_canvas.dart';
import 'widgets/hint_thumbnail.dart';
import 'widgets/prompt_header.dart';
import 'widgets/result_feedback.dart';
import 'widgets/success_overlay.dart';

class AlarmRingScreen extends ConsumerStatefulWidget {
  final Difficulty difficulty;
  final List<String> categories;
  final String sound;
  final bool isTestMode;
  final String? alarmId;

  const AlarmRingScreen({
    super.key,
    required this.difficulty,
    this.categories = const [],
    this.sound = 'default',
    this.isTestMode = false,
    this.alarmId,
  });

  @override
  ConsumerState<AlarmRingScreen> createState() => _AlarmRingScreenState();
}

class _AlarmRingScreenState extends ConsumerState<AlarmRingScreen> {
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
  double _lastConfidence = 0.0;
  late DateTime _startTime;

  HintMode _hintMode = HintMode.none;
  List<List<Offset>>? _hintStrokes;
  bool _isLoadingHint = false;
  bool _pendingClassify = false;

  Timer? _idleTimer;

  @override
  void initState() {
    super.initState();
    _currentThreshold = widget.difficulty.threshold;
    _startTime = DateTime.now();
    _initAlarm();
  }

  Future<void> _initAlarm() async {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    await _classifier.load();
    _pickPrompt();
    setState(() => _isLoading = false);
    if (!widget.isTestMode) {
      final bool vibrate = ref.read(settingsProvider).vibrationEnabled;
      _audio.startAlarm(sound: widget.sound, vibrate: vibrate);
    }
    _resetIdleTimer();
  }

  void _pickPrompt({String? exclude}) {
    final List<String> pool = widget.categories.isNotEmpty
        ? widget.categories
        : _classifier.labels;
    List<String> candidates = pool;
    if (exclude != null && pool.length > 1) {
      candidates = pool.where((String c) => c != exclude).toList();
    }
    final String newPrompt = candidates[Random().nextInt(candidates.length)];
    setState(() => _prompt = newPrompt);
  }

  void _changeDoodle() {
    if (_isDismissed || _isClassifying) return;
    _idleTimer?.cancel();
    setState(() {
      _strokes.clear();
      _currentStroke.clear();
      _lastResult = null;
      _hintMode = HintMode.none;
      _hintStrokes = null;
    });
    _pickPrompt(exclude: _prompt);
    _resetIdleTimer();
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
      _hintMode = HintMode.none;
      _hintStrokes = null;
    });
    _pickPrompt(exclude: _prompt);
    _resetIdleTimer();
  }

  Future<void> _toggleHint() async {
    if (_isLoadingHint || _isDismissed) return;

    final HintMode next = switch (_hintMode) {
      HintMode.none => HintMode.thumbnail,
      HintMode.thumbnail => HintMode.trace,
      HintMode.trace => HintMode.none,
    };

    if (next == HintMode.none) {
      setState(() => _hintMode = HintMode.none);
      return;
    }

    if (_hintStrokes == null) {
      setState(() => _isLoadingHint = true);
      final List<List<Offset>>? strokes = await HintService.getStrokes(
        _prompt,
        canvasSize,
      );
      if (!mounted) return;
      setState(() {
        _hintStrokes = strokes;
        _isLoadingHint = false;
      });
    }

    setState(() => _hintMode = _hintStrokes != null ? next : HintMode.none);
  }

  Future<void> _classify() async {
    if (_strokes.isEmpty || _isDismissed) return;
    if (_isClassifying) {
      _pendingClassify = true;
      return;
    }
    setState(() => _isClassifying = true);

    try {
      final List<DrawingResult> results = await _classifier.classify(
        _strokes,
        canvasSize,
        canvasSize,
      );

      if (!mounted) return;

      final DrawingResult? promptResult = results
          .cast<DrawingResult?>()
          .firstWhere(
            (DrawingResult? r) =>
                r!.category.toLowerCase() == _prompt.toLowerCase(),
            orElse: () => null,
          );
      if (promptResult != null) {
        _lastConfidence = promptResult.confidence;
      }

      final bool matched = _classifier.doesMatch(
        results,
        _prompt,
        _currentThreshold,
        useTop3: widget.difficulty.usesTop3,
      );

      if (matched) {
        await _onSuccess();
      } else {
        _onFailure();
      }
    } finally {
      if (mounted) {
        setState(() => _isClassifying = false);
        if (_pendingClassify && !_isDismissed) {
          _pendingClassify = false;
          _classify();
        }
      }
    }
  }

  Future<void> _onSuccess() async {
    _idleTimer?.cancel();
    setState(() {
      _lastResult = true;
      _isDismissed = true;
    });
    await _audio.stopAlarm();
    await NotificationService().stopRingingAlarm();
    if (!widget.isTestMode) {
      await _recordDismissal();
      await _disableAlarmIfOneShot();
    }
    await Future<void>.delayed(const Duration(seconds: 2));
    if (mounted) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      if (widget.isTestMode) {
        context.pop();
      } else {
        context.go('/');
      }
    }
  }

  Future<void> _disableAlarmIfOneShot() async {
    final String? id = widget.alarmId;
    if (id == null) return;
    final StorageService storage = ref.read(storageServiceProvider);
    final AlarmModel? alarm = storage.getAlarm(id);
    if (alarm == null) return;
    if (alarm.repeatDays.isEmpty) {
      final AlarmModel disabled = alarm.copyWith(isEnabled: false);
      await ref.read(alarmListProvider.notifier).updateAlarm(disabled);
    }
  }

  Future<void> _recordDismissal() async {
    final int duration = DateTime.now().difference(_startTime).inSeconds;
    await ref
        .read(dismissalStatsProvider.notifier)
        .addDismissal(
          DismissalRecord(
            category: _prompt,
            attempts: _attempts,
            timestamp: DateTime.now(),
            confidence: _lastConfidence,
            durationSeconds: duration,
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
    await NotificationService().stopRingingAlarm();

    final int snoozeMinutes = ref.read(settingsProvider).snoozeMinutes;
    final DateTime snoozeTime = DateTime.now().add(
      Duration(minutes: snoozeMinutes),
    );
    final String payload = '{"difficulty":${widget.difficulty.index}}';

    await NotificationService().scheduleAlarm(
      id: snoozeTime.hashCode & 0x7FFFFFFF,
      title: 'DrawBell',
      body: 'Snoozed alarm — draw to dismiss!',
      scheduledTime: snoozeTime,
      payload: payload,
      sound: widget.sound,
    );

    if (mounted) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      context.go('/');
    }
  }

  void _closeTest() {
    _idleTimer?.cancel();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    context.pop();
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
    final bool canDraw = !_isDismissed;

    return PopScope(
      canPop: widget.isTestMode,
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
                    PromptHeader(
                      category: _prompt,
                      onChangeDoodle: canInteract ? _changeDoodle : null,
                      onToggleHint: canInteract ? _toggleHint : null,
                      hintMode: _hintMode,
                    ),
                    const SizedBox(height: 24),
                    DrawingCanvas(
                      strokes: _strokes,
                      currentStroke: _currentStroke,
                      hintStrokes: _hintMode == HintMode.trace
                          ? _hintStrokes
                          : null,
                      hintThumbnail:
                          _hintMode == HintMode.thumbnail &&
                              _hintStrokes != null
                          ? HintThumbnail(strokes: _hintStrokes!)
                          : null,
                      onPanStart: canDraw
                          ? (DragStartDetails d) {
                              _resetIdleTimer();
                              setState(
                                () => _currentStroke = [d.localPosition],
                              );
                            }
                          : null,
                      onPanUpdate: canDraw
                          ? (DragUpdateDetails d) {
                              setState(
                                () => _currentStroke.add(d.localPosition),
                              );
                            }
                          : null,
                      onPanEnd: canDraw
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
                    if (widget.isTestMode)
                      TextButton.icon(
                        onPressed: canInteract ? _closeTest : null,
                        icon: const Icon(Icons.close, size: 18),
                        label: const Text('Close Test'),
                      )
                    else
                      TextButton.icon(
                        onPressed: canInteract ? _snooze : null,
                        icon: const Icon(Icons.snooze, size: 18),
                        label: Text(
                          'Snooze (${ref.watch(settingsProvider.select((AppSettings s) => s.snoozeMinutes))} min)',
                        ),
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

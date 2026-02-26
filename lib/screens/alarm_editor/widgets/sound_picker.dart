import 'dart:async';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../../../services/ringtone_service.dart';
import '../../../theme.dart';

class SoundPicker extends StatefulWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const SoundPicker({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  State<SoundPicker> createState() => _SoundPickerState();
}

class _SoundPickerState extends State<SoundPicker> {
  List<RingtoneInfo>? _ringtones;
  bool _loadError = false;
  bool _permissionDenied = false;
  String? _previewingUri;
  final AudioPlayer _previewPlayer = AudioPlayer();
  StreamSubscription<PlayerState>? _playerStateSub;

  @override
  void initState() {
    super.initState();
    _loadRingtones();
    _playerStateSub = _previewPlayer.playerStateStream.listen((
      PlayerState state,
    ) {
      if (state.processingState == ProcessingState.completed) {
        if (mounted) setState(() => _previewingUri = null);
      }
    });
  }

  Future<void> _loadRingtones() async {
    List<RingtoneInfo> ringtones = await RingtoneService.getAlarmRingtones();

    if (ringtones.isEmpty) {
      final String permResult = await RingtoneService.requestAudioPermission();
      if (permResult == 'granted') {
        ringtones = await RingtoneService.getAlarmRingtones();
      } else {
        if (mounted) {
          setState(() {
            _ringtones = [];
            _permissionDenied = true;
          });
        }
        return;
      }
    }

    if (mounted) {
      setState(() {
        _ringtones = ringtones;
        _loadError = ringtones.isEmpty;
      });
    }
  }

  Future<void> _togglePreview(String uri) async {
    if (_previewingUri == uri) {
      await _previewPlayer.stop();
      if (mounted) setState(() => _previewingUri = null);
      return;
    }
    if (mounted) setState(() => _previewingUri = uri);
    try {
      await _previewPlayer.setAudioSource(AudioSource.uri(Uri.parse(uri)));
      await _previewPlayer.play();
    } catch (_) {
      if (mounted) setState(() => _previewingUri = null);
    }
  }

  @override
  void dispose() {
    _playerStateSub?.cancel();
    _previewPlayer.stop();
    _previewPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    if (_ringtones == null && !_loadError) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_permissionDenied) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Audio permission is required to list alarm sounds.',
                style: textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              FilledButton.tonal(
                onPressed: RingtoneService.openAppSettings,
                child: const Text('Open Settings'),
              ),
            ],
          ),
        ),
      );
    }

    if (_loadError || (_ringtones?.isEmpty ?? true)) {
      return Center(
        child: Text(
          'No alarm sounds found on this device.',
          style: textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: _ringtones!.length,
      itemBuilder: (BuildContext ctx, int i) {
        final RingtoneInfo ringtone = _ringtones![i];
        final bool isSelected = widget.selected == ringtone.uri;
        final bool isPreviewing = _previewingUri == ringtone.uri;

        return InkWell(
          onTap: () => widget.onChanged(ringtone.uri),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.brandOrange
                        : colors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.music_note_outlined,
                    size: 18,
                    color: isSelected ? Colors.white : colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    ringtone.title,
                    style: TextStyle(
                      fontSize: 15,
                      color: isSelected
                          ? AppTheme.brandOrange
                          : colors.onSurface,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isSelected) ...[
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.check_rounded,
                    size: 18,
                    color: AppTheme.brandOrange,
                  ),
                ],
                IconButton(
                  icon: Icon(
                    isPreviewing
                        ? Icons.stop_circle_outlined
                        : Icons.play_circle_outlined,
                    color: isPreviewing
                        ? AppTheme.brandOrange
                        : colors.onSurfaceVariant,
                  ),
                  onPressed: () => _togglePreview(ringtone.uri),
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.all(8),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

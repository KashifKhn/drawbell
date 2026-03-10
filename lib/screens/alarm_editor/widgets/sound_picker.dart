import 'dart:async';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../../../core/constants.dart';
import '../../../services/imported_sound_service.dart';
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
  List<ImportedSoundInfo> _importedSounds = <ImportedSoundInfo>[];
  List<RingtoneInfo>? _ringtones;
  bool _loadError = false;
  bool _permissionDenied = false;
  bool _isImporting = false;
  String? _previewingSound;
  final AudioPlayer _previewPlayer = AudioPlayer();
  StreamSubscription<PlayerState>? _playerStateSub;

  @override
  void initState() {
    super.initState();
    _loadImportedSounds();
    _loadRingtones();
    _playerStateSub = _previewPlayer.playerStateStream.listen((
      PlayerState state,
    ) {
      if (state.processingState == ProcessingState.completed) {
        if (mounted) setState(() => _previewingSound = null);
      }
    });
  }

  Future<void> _loadImportedSounds() async {
    final List<ImportedSoundInfo> importedSounds =
        await ImportedSoundService.listImportedSounds();
    if (mounted) {
      setState(() {
        _importedSounds = importedSounds;
      });
    }
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

  Future<void> _togglePreview(String soundKey) async {
    if (_previewingSound == soundKey) {
      await _previewPlayer.stop();
      if (mounted) setState(() => _previewingSound = null);
      return;
    }
    if (mounted) setState(() => _previewingSound = soundKey);
    try {
      if (ImportedSoundService.isUriSound(soundKey)) {
        await _previewPlayer.setAudioSource(
          AudioSource.uri(Uri.parse(soundKey)),
        );
      } else {
        final AlarmSound alarmSound = AlarmSound.fromKey(soundKey);
        await _previewPlayer.setAsset(alarmSound.assetPath);
      }
      await _previewPlayer.play();
    } catch (_) {
      if (mounted) {
        setState(() => _previewingSound = null);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not preview this sound')),
        );
      }
    }
  }

  Future<void> _importSound() async {
    if (_isImporting) {
      return;
    }

    setState(() => _isImporting = true);
    try {
      final ImportedSoundInfo? imported =
          await ImportedSoundService.pickAndImportSound();
      await _loadImportedSounds();
      if (imported != null && mounted) {
        widget.onChanged(imported.uri);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not import the selected audio file'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isImporting = false);
      }
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

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        FilledButton.icon(
          onPressed: _isImporting ? null : _importSound,
          icon: _isImporting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.file_upload_outlined),
          label: Text(_isImporting ? 'Importing...' : 'Import from device'),
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.brandOrange,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(48),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Built-in Sounds',
          style: textTheme.titleSmall?.copyWith(
            color: colors.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        ...AlarmSound.values.map(
          (AlarmSound sound) => _SoundOptionTile(
            title: sound.label,
            soundKey: sound.key,
            selected: widget.selected == sound.key,
            previewing: _previewingSound == sound.key,
            onTap: () => widget.onChanged(sound.key),
            onPreview: () => _togglePreview(sound.key),
          ),
        ),
        if (_importedSounds.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'Imported Sounds',
            style: textTheme.titleSmall?.copyWith(
              color: colors.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          ..._importedSounds.map(
            (ImportedSoundInfo sound) => _SoundOptionTile(
              title: sound.title,
              soundKey: sound.uri,
              selected: widget.selected == sound.uri,
              previewing: _previewingSound == sound.uri,
              onTap: () => widget.onChanged(sound.uri),
              onPreview: () => _togglePreview(sound.uri),
            ),
          ),
        ],
        const SizedBox(height: 16),
        Text(
          'Device Alarm Sounds',
          style: textTheme.titleSmall?.copyWith(
            color: colors.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        if (_ringtones == null && !_loadError)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_permissionDenied)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: [
                Text(
                  'Audio permission is required to list device alarm sounds.',
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
          )
        else if (_loadError || (_ringtones?.isEmpty ?? true))
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              'No alarm sounds found on this device.',
              style: textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          )
        else
          ..._ringtones!.map(
            (RingtoneInfo ringtone) => _SoundOptionTile(
              title: ringtone.title,
              soundKey: ringtone.uri,
              selected: widget.selected == ringtone.uri,
              previewing: _previewingSound == ringtone.uri,
              onTap: () => widget.onChanged(ringtone.uri),
              onPreview: () => _togglePreview(ringtone.uri),
            ),
          ),
      ],
    );
  }
}

class _SoundOptionTile extends StatelessWidget {
  final String title;
  final String soundKey;
  final bool selected;
  final bool previewing;
  final VoidCallback onTap;
  final VoidCallback onPreview;

  const _SoundOptionTile({
    required this.title,
    required this.soundKey,
    required this.selected,
    required this.previewing,
    required this.onTap,
    required this.onPreview,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: selected
                    ? AppTheme.brandOrange
                    : colors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                ImportedSoundService.isUriSound(soundKey)
                    ? Icons.library_music_outlined
                    : Icons.music_note_outlined,
                size: 18,
                color: selected ? Colors.white : colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  color: selected ? AppTheme.brandOrange : colors.onSurface,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (selected) ...[
              const SizedBox(width: 4),
              const Icon(
                Icons.check_rounded,
                size: 18,
                color: AppTheme.brandOrange,
              ),
            ],
            IconButton(
              icon: Icon(
                previewing
                    ? Icons.stop_circle_outlined
                    : Icons.play_circle_outlined,
                color: previewing
                    ? AppTheme.brandOrange
                    : colors.onSurfaceVariant,
              ),
              onPressed: onPreview,
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.all(8),
            ),
          ],
        ),
      ),
    );
  }
}

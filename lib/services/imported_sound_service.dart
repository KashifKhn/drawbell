import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../core/constants.dart';

class ImportedSoundInfo {
  final String title;
  final String uri;

  const ImportedSoundInfo({required this.title, required this.uri});
}

class ImportedSoundService {
  static const String _directoryName = 'imported_sounds';

  static bool isUriSound(String soundKey) {
    return soundKey.startsWith('content://') ||
        soundKey.startsWith('file://') ||
        soundKey.startsWith('http');
  }

  static String labelFor(
    String soundKey, {
    Map<String, String> ringtoneLabels = const <String, String>{},
  }) {
    if (!isUriSound(soundKey)) {
      return AlarmSound.fromKey(soundKey).label;
    }

    final String? ringtoneLabel = ringtoneLabels[soundKey];
    if (ringtoneLabel != null && ringtoneLabel.isNotEmpty) {
      return ringtoneLabel;
    }

    final Uri? uri = Uri.tryParse(soundKey);
    if (uri?.scheme == 'content') {
      return 'Custom Sound';
    }
    final List<String> segments = uri?.pathSegments ?? <String>[];
    if (segments.isEmpty) {
      return 'Custom Sound';
    }

    final String fileName = Uri.decodeComponent(segments.last);
    final String baseName = path.basenameWithoutExtension(fileName).trim();
    if (baseName.isEmpty) {
      return 'Custom Sound';
    }

    return _formatTitle(baseName);
  }

  static Future<List<ImportedSoundInfo>> listImportedSounds() async {
    final Directory directory = await _getImportDirectory();
    if (!await directory.exists()) {
      return <ImportedSoundInfo>[];
    }

    final List<FileSystemEntity> entries = await directory.list().toList();
    final List<File> files = entries.whereType<File>().toList();
    files.sort(
      (File a, File b) =>
          b.statSync().modified.compareTo(a.statSync().modified),
    );

    return files
        .map(
          (File file) => ImportedSoundInfo(
            title: _formatTitle(path.basenameWithoutExtension(file.path)),
            uri: Uri.file(file.path).toString(),
          ),
        )
        .toList();
  }

  static Future<ImportedSoundInfo?> pickAndImportSound() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowMultiple: false,
      withData: false,
    );
    if (result == null) {
      return null;
    }

    final PlatformFile selectedFile = result.files.single;
    final String? sourcePath = selectedFile.path;
    if (sourcePath == null || sourcePath.isEmpty) {
      throw const FileSystemException(
        'Unable to read the selected audio file.',
      );
    }

    final File sourceFile = File(sourcePath);
    if (!await sourceFile.exists()) {
      throw FileSystemException(
        'Selected audio file was not found.',
        sourcePath,
      );
    }

    final Directory directory = await _getImportDirectory();
    await directory.create(recursive: true);

    final String originalName = selectedFile.name.trim().isEmpty
        ? path.basename(sourcePath)
        : selectedFile.name.trim();
    final String targetPath = await _nextAvailablePath(directory, originalName);
    final File copiedFile = await sourceFile.copy(targetPath);

    return ImportedSoundInfo(
      title: _formatTitle(path.basenameWithoutExtension(copiedFile.path)),
      uri: Uri.file(copiedFile.path).toString(),
    );
  }

  static Future<Directory> _getImportDirectory() async {
    final Directory documentsDirectory =
        await getApplicationDocumentsDirectory();
    return Directory(path.join(documentsDirectory.path, _directoryName));
  }

  static Future<String> _nextAvailablePath(
    Directory directory,
    String fileName,
  ) async {
    final String sanitizedName = _sanitizeFileName(fileName);
    final String baseName = path.basenameWithoutExtension(sanitizedName);
    final String extension = path.extension(sanitizedName);

    String candidatePath = path.join(directory.path, sanitizedName);
    int suffix = 2;
    while (await File(candidatePath).exists()) {
      final String nextName = '$baseName-$suffix$extension';
      candidatePath = path.join(directory.path, nextName);
      suffix += 1;
    }

    return candidatePath;
  }

  static String _sanitizeFileName(String fileName) {
    final String trimmed = fileName.trim();
    final String safeName = trimmed.replaceAll(
      RegExp(r'[^A-Za-z0-9._ -]'),
      '_',
    );
    if (safeName.isEmpty) {
      return 'imported-sound.mp3';
    }
    return safeName;
  }

  static String _formatTitle(String raw) {
    final String normalized = raw.replaceAll(RegExp(r'[_-]+'), ' ').trim();
    if (normalized.isEmpty) {
      return 'Custom Sound';
    }

    final List<String> words = normalized.split(RegExp(r'\s+'));
    final List<String> formattedWords = words.map((String word) {
      if (word.isEmpty) {
        return word;
      }
      return word[0].toUpperCase() + word.substring(1);
    }).toList();
    return formattedWords.join(' ');
  }
}

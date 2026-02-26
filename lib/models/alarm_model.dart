import 'package:flutter/material.dart';

import '../core/constants.dart';

class AlarmModel {
  final String id;
  final TimeOfDay time;
  final List<int> repeatDays;
  final Difficulty difficulty;
  final bool isEnabled;
  final String label;
  final String sound;
  final List<String> categories;

  const AlarmModel({
    required this.id,
    required this.time,
    this.repeatDays = const [],
    this.difficulty = Difficulty.medium,
    this.isEnabled = true,
    this.label = '',
    this.sound = 'default',
    this.categories = const [],
  });

  AlarmModel copyWith({
    String? id,
    TimeOfDay? time,
    List<int>? repeatDays,
    Difficulty? difficulty,
    bool? isEnabled,
    String? label,
    String? sound,
    List<String>? categories,
  }) {
    return AlarmModel(
      id: id ?? this.id,
      time: time ?? this.time,
      repeatDays: repeatDays ?? this.repeatDays,
      difficulty: difficulty ?? this.difficulty,
      isEnabled: isEnabled ?? this.isEnabled,
      label: label ?? this.label,
      sound: sound ?? this.sound,
      categories: categories ?? this.categories,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'hour': time.hour,
      'minute': time.minute,
      'repeatDays': repeatDays,
      'difficulty': difficulty.index,
      'isEnabled': isEnabled,
      'label': label,
      'sound': sound,
      'categories': categories,
    };
  }

  factory AlarmModel.fromJson(Map<String, dynamic> json) {
    return AlarmModel(
      id: json['id'] as String,
      time: TimeOfDay(hour: json['hour'] as int, minute: json['minute'] as int),
      repeatDays: List<int>.from(json['repeatDays'] as List),
      difficulty: Difficulty.values[json['difficulty'] as int],
      isEnabled: json['isEnabled'] as bool,
      label: json['label'] as String,
      sound: json['sound'] as String,
      categories: json['categories'] != null
          ? List<String>.from(json['categories'] as List)
          : const [],
    );
  }
}

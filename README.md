# DrawBell

**Draw to dismiss your alarm.** DrawBell is an Android alarm app that forces you to wake up by drawing a specific doodle -- verified in real-time by an on-device AI model -- before the alarm stops.

The AI is a TFLite SE-ResNet trained on the [Google Quick Draw](https://quickdraw.withgoogle.com/data) dataset, recognizing 345 categories with 76% top-1 accuracy (89.5% top-3).

## Features

- **Drawing Dismissal** -- Draw the prompted doodle on a canvas. The AI classifies your strokes in real-time and only dismisses the alarm when your drawing matches.
- **345 Categories** -- From "airplane" to "zigzag". Choose which categories your alarms can prompt, or let the app pick randomly.
- **Difficulty Levels** -- Easy (40% threshold, top-3 matching, mercy after 5 attempts), Medium (60%, top-1, mercy after 10), Hard (75%, top-1, no mercy).
- **Practice Mode** -- Free draw to see AI predictions, or pick a category to practice before your alarm goes off.
- **Morning Stats** -- Track wake-up streaks, accuracy, consistency charts, hardest/easiest categories, and earn XP with achievements.
- **Custom Sounds** -- Pick from built-in alarm sounds or any ringtone on your device.
- **Snooze** -- 5-minute snooze via rescheduled notification.
- **Onboarding** -- Three-page intro shown on first launch.
- **Material 3 Theming** -- Light and dark mode with `#d94a09` as the seed color.

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter (Dart SDK ^3.8.1) |
| State Management | Riverpod (`flutter_riverpod`) |
| Navigation | GoRouter (`go_router`) |
| AI Inference | TFLite (`tflite_flutter`) |
| Storage | SharedPreferences (JSON serialization) |
| Notifications | `flutter_local_notifications` (exact alarms, full-screen intent) |
| Audio | `just_audio` |
| Other | `wakelock_plus`, `vibration`, `intl`, `uuid`, `timezone` |

## Project Structure

```
lib/
  main.dart
  theme.dart
  router.dart
  core/
    constants.dart
    utils.dart
  models/
    alarm_model.dart
    dismissal_record.dart
    drawing_result.dart
  providers/
    alarm_provider.dart
  services/
    classifier_service.dart
    alarm_service.dart
    notification_service.dart
    audio_service.dart
    storage_service.dart
    ringtone_service.dart
  screens/
    app_shell.dart
    home/
      home_screen.dart
      widgets/
        alarm_card.dart
        empty_state.dart
    alarm_editor/
      alarm_editor_screen.dart
      widgets/
        category_picker.dart
        day_selector.dart
        difficulty_selector.dart
        sound_picker.dart
    alarm_ring/
      alarm_ring_screen.dart
      widgets/
        drawing_canvas.dart
        prompt_header.dart
        result_feedback.dart
        attempt_counter.dart
        success_overlay.dart
    onboarding/
      onboarding_screen.dart
    practice/
      practice_screen.dart
      widgets/
        category_picker_sheet.dart
        practice_result_overlay.dart
        prediction_tile.dart
    stats/
      stats_screen.dart
      widgets/
        accuracy_card.dart
        category_section.dart
        consistency_chart.dart
        gamification_card.dart
        streak_card.dart
        summary_row.dart
        wake_up_time_card.dart
        week_day_selector.dart
    settings/
      settings_screen.dart
```

## Getting Started

### Prerequisites

- Flutter SDK ^3.8.1
- Android SDK (Android-first, no iOS support targeted)

### Build & Run

```bash
# Install dependencies
flutter pub get

# Run in debug mode
flutter run

# Build release APK
flutter build apk

# Build app bundle
flutter build appbundle
```

### Code Quality

```bash
# Lint
flutter analyze

# Format
dart format lib/ test/

# Run tests
flutter test
```

## Architecture

- **Services** (`lib/services/`) handle all business logic: TFLite classification, alarm scheduling, notifications, audio playback, persistence, and native ringtone access (via MethodChannel).
- **Models** (`lib/models/`) are plain data classes with JSON serialization.
- **Providers** (`lib/providers/`) expose state via Riverpod `StateNotifierProvider`.
- **Screens** (`lib/screens/`) are organized by feature, each with a `widgets/` subfolder for extracted components.
- **Routing** uses GoRouter with a `StatefulShellRoute.indexedStack` for bottom tab navigation (Alarms, Practice, Stats, Settings).

## Assets

```
assets/
  quickdraw_model.tflite    # SE-ResNet TFLite model (345 categories)
  labels.txt                # Category labels
  images/                   # App logos and icons
  sounds/                   # Built-in alarm sounds (default, gentle, urgent, melody)
```

## License

All rights reserved.

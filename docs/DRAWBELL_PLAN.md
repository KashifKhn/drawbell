# DrawBell -- Development Plan

## Current State

The AI model is trained, published, and working. A single-screen Flutter demo app exists in the reference project (`quickdraw_app/`) with a functional drawing canvas and TFLite inference. There is no alarm code, no navigation, no state management, and no proper architecture. The entire app lives in one 533-line `main.dart`. A `theme.dart` file exists but is unused.

**What works:** Draw on canvas, preprocess to 28x28, run TFLite inference, show top-5 predictions.
**What doesn't exist yet:** Everything else -- alarms, navigation, persistence, notifications, permissions, settings, proper architecture.

---

## Design Language

| Property           | Value                                            |
| ------------------ | ------------------------------------------------ |
| Primary Color      | `#d94a09`                                        |
| Theme System       | Material 3 with `ColorScheme.fromSeed`           |
| Typography         | Default Material 3 (Roboto)                      |
| Shape              | Rounded corners (12-16dp radius)                 |
| Icons              | Material Symbols Rounded                         |
| Dark Mode          | Support both light and dark, seed from `#d94a09` |
| Canvas Background  | White (both themes)                              |
| Drawing Stroke     | Black                                            |
| Alarm Active State | Full-screen, high-contrast, `#d94a09` dominant   |

---

## Architecture

### Project Structure

```
lib/
  main.dart                         -- App entry, MaterialApp, routing
  theme.dart                        -- ColorScheme from seed #d94a09, light + dark
  router.dart                       -- GoRouter configuration

  core/
    constants.dart                  -- Category lists, difficulty thresholds, defaults
    utils.dart                      -- Shared helpers (time formatting, etc.)

  models/
    alarm_model.dart                -- Alarm data class (id, time, days, difficulty, enabled, label, sound)
    drawing_result.dart             -- Classification result (category, confidence, rank)

  services/
    classifier_service.dart         -- TFLite model loading, preprocessing, inference
    alarm_service.dart              -- Scheduling, cancelling, and managing alarms via android_alarm_manager_plus
    notification_service.dart       -- Local notifications for alarm trigger
    audio_service.dart              -- Alarm sound playback and stop
    storage_service.dart            -- SharedPreferences / Isar for alarm persistence and stats

  screens/
    home/
      home_screen.dart              -- Alarm list (main screen)
      widgets/
        alarm_card.dart             -- Single alarm row with toggle
        empty_state.dart            -- Shown when no alarms exist

    alarm_editor/
      alarm_editor_screen.dart      -- Create / edit alarm (time picker, days, difficulty, sound)

    alarm_ring/
      alarm_ring_screen.dart        -- Full-screen alarm trigger with drawing challenge
      widgets/
        drawing_canvas.dart         -- Canvas with gesture handling
        prompt_header.dart          -- "Draw a cat" prompt display
        result_feedback.dart        -- Correct/wrong animation feedback
        attempt_counter.dart        -- Shows attempt count

    settings/
      settings_screen.dart          -- App-wide settings (default difficulty, snooze toggle, theme)

    stats/
      stats_screen.dart             -- Drawing stats and history (nice-to-have)

assets/
  quickdraw_model.tflite            -- Float16 TFLite model (8.5 MB)
  labels.txt                        -- 345 category labels (alphabetically sorted)
  sounds/                           -- Default alarm sound files
```

### State Management

Use `Riverpod` for state management:
- `alarmListProvider` -- list of all alarms from storage
- `classifierProvider` -- singleton classifier instance
- `activeAlarmProvider` -- currently ringing alarm state
- `settingsProvider` -- user preferences

### Navigation

Use `go_router` with these routes:
- `/` -- Home (alarm list)
- `/alarm/new` -- Create alarm
- `/alarm/:id/edit` -- Edit alarm
- `/alarm/:id/ring` -- Full-screen alarm challenge (no back button)
- `/settings` -- Settings
- `/stats` -- Stats (nice-to-have)

---

## Dependencies

| Package                        | Purpose                                     |
| ------------------------------ | ------------------------------------------- |
| `tflite_flutter`               | On-device TFLite inference                  |
| `flutter_riverpod`             | State management                            |
| `go_router`                    | Declarative routing                         |
| `android_alarm_manager_plus`   | Scheduling exact alarms on Android          |
| `flutter_local_notifications`  | Notification when alarm fires               |
| `just_audio`                   | Alarm sound playback                        |
| `shared_preferences`           | Lightweight key-value persistence           |
| `isar` + `isar_flutter_libs`   | Structured local DB for alarms and stats    |
| `wakelock_plus`                | Keep screen on during alarm ring            |
| `vibration`                    | Vibrate on alarm                            |
| `permission_handler`           | Request alarm, notification permissions     |
| `intl`                         | Date/time formatting                        |

---

## Android Permissions Required

- `SCHEDULE_EXACT_ALARM` -- fire alarms at exact time
- `USE_FULL_SCREEN_INTENT` -- show full-screen alarm UI on lock screen
- `WAKE_LOCK` -- keep device awake during alarm
- `RECEIVE_BOOT_COMPLETED` -- reschedule alarms after device reboot
- `VIBRATE` -- vibrate on alarm
- `POST_NOTIFICATIONS` -- show notification (Android 13+)
- `DISABLE_KEYGUARD` -- show alarm over lock screen
- `SYSTEM_ALERT_WINDOW` -- overlay alarm screen (if needed)

---

## Screens -- Detail

### 1. Home Screen

- App bar with title "DrawBell" and settings icon
- FAB with `+` icon to add new alarm (color: `#d94a09`)
- List of alarm cards, each showing:
  - Time (large, bold)
  - Repeat days (Mon, Tue, ... or "Once")
  - Difficulty badge (Easy / Medium / Hard)
  - Toggle switch to enable/disable
  - Swipe to delete
- Empty state illustration when no alarms exist
- Bottom navigation or drawer with: Alarms, Stats, Settings

### 2. Alarm Editor Screen

- Time picker (Material 3 style)
- Day selector (horizontal chips for Mon-Sun)
- Difficulty selector (segmented button: Easy / Medium / Hard)
  - Easy: confidence threshold 40%
  - Medium: confidence threshold 60%
  - Hard: confidence threshold 75%
- Alarm label (optional text field)
- Sound picker (list of bundled sounds)
- Snooze toggle (off by default)
- Save / Cancel buttons

### 3. Alarm Ring Screen (most critical screen)

This is a full-screen, immersive screen that appears when the alarm fires. The user cannot dismiss it without drawing correctly.

- **No back button, no swipe to dismiss, no status bar**
- **Layout:**
  - Top: Prompt text -- "Draw a [category]" in large bold text
  - Center: White drawing canvas (full width, square)
  - Below canvas: Attempt counter ("Attempt 3") and feedback text
  - Bottom: Undo button and Clear button
- **Flow:**
  1. Screen appears with alarm sound playing and vibration
  2. Random category selected from the 345 labels
  3. User draws on canvas
  4. After each stroke ends, auto-classify (same as reference app)
  5. If top-1 prediction matches the prompt AND confidence >= threshold:
     - Show success animation (green check, confetti-style)
     - Stop alarm sound and vibration
     - Navigate back to home after 2 seconds
  6. If wrong or below threshold:
     - Show "Try again" feedback with brief red flash
     - Canvas clears automatically after 1 second
     - Increment attempt counter
     - Alarm continues ringing
- **Edge cases:**
  - If user draws nothing for 30 seconds, re-prompt with a different category
  - If after 10 failed attempts, lower threshold by 10% (mercy rule)
  - Top-3 match accepted on Easy mode (any of top-3 predictions matching the prompt counts)

### 4. Settings Screen

- Default difficulty level
- Snooze settings (enable/disable, snooze duration)
- Theme toggle (light / dark)
- About section (version, credits, model info)

### 5. Stats Screen (nice-to-have)

- Total alarms dismissed
- Average attempts per dismissal
- Hardest categories (most attempts)
- Easiest categories (dismissed first try)
- Weekly streak

---

## Difficulty System

| Level  | Confidence Threshold | Match Rule               | Mercy After |
| ------ | -------------------- | ------------------------ | ----------- |
| Easy   | 40%                  | Top-3 prediction matches | 5 attempts  |
| Medium | 60%                  | Top-1 prediction matches | 10 attempts |
| Hard   | 75%                  | Top-1 prediction matches | Never       |

---

## Classifier Integration

Reuse the existing classifier logic from the reference app with these adaptations:

- Extract into a standalone `ClassifierService` class
- Load model once at app startup (not on every screen)
- Expose via Riverpod provider as a singleton
- Keep the same preprocessing pipeline: render strokes to 28x28, invert pixels, run inference
- Return structured `DrawingResult` objects instead of raw map entries
- Add a method `bool doesMatch(String prompt, double threshold)` for the alarm screen to call

### Category Selection Logic

When alarm fires, pick a random category from the 345 labels. Optionally, if the user has configured preferred categories, pick from those. Avoid categories the user consistently fails at (unless Hard mode).

---

## Alarm Scheduling Flow

1. **User creates alarm** -- saved to Isar DB, scheduled via `android_alarm_manager_plus`
2. **Alarm fires** -- callback triggers notification with full-screen intent
3. **Full-screen intent opens** `AlarmRingScreen` -- sound starts, vibration starts, prompt shown
4. **User draws correctly** -- alarm dismissed, stats saved
5. **Device rebooted** -- `RECEIVE_BOOT_COMPLETED` triggers rescheduling of all active alarms from DB

---

## Development Phases

### Phase 1 -- Foundation (Week 1)

- Initialize Flutter project with proper package ID (`dev.kashifkhan.drawbell`)
- Set up project structure (folders, files, router, theme)
- Implement Material 3 theme with `#d94a09` seed color (light + dark)
- Add Riverpod, GoRouter, and all dependencies to `pubspec.yaml`
- Copy model and labels from reference project into `assets/`
- Extract classifier into `ClassifierService` and verify inference works

### Phase 2 -- Core Alarm (Week 2)

- Build `AlarmModel` data class
- Set up Isar database for alarm storage
- Build Home Screen with alarm list UI
- Build Alarm Editor Screen (time, days, difficulty, sound, label)
- CRUD operations for alarms (create, read, update, delete)

### Phase 3 -- Alarm Trigger (Week 3)

- Add Android permissions to manifest
- Implement alarm scheduling with `android_alarm_manager_plus`
- Implement notification service with full-screen intent
- Build Alarm Ring Screen with drawing canvas
- Integrate classifier into alarm ring flow
- Implement match logic (prompt vs prediction, confidence threshold)
- Handle alarm dismiss (success) and retry (failure) flows
- Sound playback and vibration

### Phase 4 -- Polish (Week 4)

- Undo functionality on canvas
- Success/failure animations
- Mercy rule implementation
- Boot-completed alarm rescheduling
- Snooze support (optional)
- Edge case handling (no strokes, timeout, app killed during alarm)
- Test on multiple devices

### Phase 5 -- Nice-to-Have (Week 5+)

- Stats screen (attempts, streaks, category performance)
- Custom category selection per alarm
- Custom alarm sounds
- Onboarding / first-launch tutorial
- App icon and splash screen with `#d94a09` branding

---

## Risks and Mitigations

| Risk                                        | Mitigation                                                          |
| ------------------------------------------- | ------------------------------------------------------------------- |
| Alarm not firing reliably on all OEMs       | Use `android_alarm_manager_plus` with exact alarms + boot receiver  |
| User force-kills app to avoid alarm         | Use foreground service for alarm; cannot be easily killed           |
| Model too slow on low-end devices           | Float16 model is 8.5 MB, inference is fast; int8 (4.4 MB) fallback |
| Some categories are nearly impossible       | Mercy rule lowers threshold after N attempts                        |
| Battery drain from wakelock                 | Release wakelock immediately after dismissal                        |
| Android 14+ restricts exact alarms          | Request `SCHEDULE_EXACT_ALARM` permission explicitly                |
| User draws something close but not matching | Top-3 matching on Easy mode provides flexibility                    |

---

## Out of Scope (for v1)

- iOS support (Android-first, iOS alarm APIs differ significantly)
- Web support
- Cloud sync
- Social features
- Custom model training
- Category packs / downloadable content

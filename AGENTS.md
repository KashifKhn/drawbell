# AGENTS.md -- DrawBell

## Project Overview

DrawBell is a Flutter alarm app that requires users to draw a specific doodle (verified by on-device AI) to dismiss the alarm. The AI model is a TFLite SE-ResNet trained on Google Quick Draw (345 categories, 76% top-1 accuracy). Android-first. Package ID: `dev.kashifkhan.drawbell`.

## Build Commands

```bash
# Get dependencies
flutter pub get

# Run the app (debug)
flutter run

# Build APK
flutter build apk

# Build app bundle
flutter build appbundle

# Analyze (lint)
flutter analyze

# Format code
dart format lib/ test/

# Format check (CI)
dart format --set-exit-if-changed lib/ test/

# Run all tests
flutter test

# Run a single test file
flutter test test/path/to/test_file.dart

# Run a single test by name
flutter test --name "test description" test/path/to/test_file.dart

# Run tests with coverage
flutter test --coverage
```

## Code Style Rules

### Formatting
- Line length: 80 characters (Dart default)
- Use `dart format` before every commit
- Trailing commas on all argument lists (widgets, functions) for consistent formatting
- No manual line breaks inside formatted code -- let `dart format` handle it

### Comments
- No comments and no doc comments unless absolutely necessary
- Never write `// TODO`, `// FIXME`, or commented-out code
- If a comment is needed, it must explain WHY, never WHAT

### Imports
- Dart SDK imports first, then package imports, then relative imports
- One blank line between each import group
- Always use relative imports for project files (`import '../models/alarm_model.dart'`)
- Never use `package:drawbell/` for internal imports
- Remove all unused imports

### Naming Conventions
- Files: `snake_case.dart` (e.g. `alarm_model.dart`, `home_screen.dart`)
- Classes: `PascalCase` (e.g. `AlarmModel`, `HomeScreen`)
- Variables/functions: `camelCase` (e.g. `alarmList`, `formatTime`)
- Constants: `camelCase` (e.g. `defaultDifficulty`, `maxAttempts`)
- Private members: prefix with `_` (e.g. `_counter`, `_onTap`)
- Enums: `PascalCase` name, `camelCase` values (e.g. `Difficulty.easy`)
- Providers (Riverpod): `camelCase` ending with `Provider` (e.g. `alarmListProvider`)

### Types
- Always specify types explicitly -- no `var`, no `dynamic` unless unavoidable
- Use `final` for all local variables that are not reassigned
- Use `const` constructors wherever possible
- Prefer `List<Widget>` over `<Widget>[]` in type annotations
- Use `required` for all named parameters that must be provided

### Error Handling
- Never silently swallow errors -- always log or handle
- Use specific exception types, not generic `Exception`
- Services should return result types or throw typed exceptions
- UI should show user-facing error messages via SnackBar

### Architecture
- State management: Riverpod (flutter_riverpod)
- Navigation: GoRouter (go_router)
- Storage: SharedPreferences for settings, Isar for structured data
- All business logic lives in `lib/services/`
- All data classes live in `lib/models/`
- All constants and helpers live in `lib/core/`
- Screens live in `lib/screens/<feature>/` with a `widgets/` subfolder

### Widget / Component Rules
- Every widget must be small and single-purpose
- Extract reusable widgets into the screen's `widgets/` subfolder
- DRY -- never duplicate widget trees, extract shared components
- Stateless over Stateful -- use `ConsumerWidget` (Riverpod) when state is needed
- All widget constructors must be `const` when possible
- No inline styles -- use `Theme.of(context)` for colors, text styles, shapes
- No magic numbers -- extract to constants

### UI/UX Consistency
- Theme color: `#d94a09` as Material 3 seed color
- Use `ColorScheme.fromSeed(seedColor: Color(0xFFD94A09))` for both light and dark
- Always use theme colors from `Theme.of(context).colorScheme`
- Never hardcode colors in widgets (except canvas: white bg, black stroke)
- Shapes: 12-16dp border radius consistently
- Spacing: use multiples of 4 (4, 8, 12, 16, 24, 32)
- All interactive elements must have proper touch targets (min 48x48)
- Follow Material 3 design guidelines throughout
- Support both light and dark mode

### Project Structure

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
    drawing_result.dart
  services/
    classifier_service.dart
    alarm_service.dart
    notification_service.dart
    audio_service.dart
    storage_service.dart
  screens/
    home/
      home_screen.dart
      widgets/
    alarm_editor/
      alarm_editor_screen.dart
    alarm_ring/
      alarm_ring_screen.dart
      widgets/
    settings/
      settings_screen.dart
```

### Testing
- Test files mirror `lib/` structure inside `test/`
- File naming: `<source_file>_test.dart`
- Group related tests with `group()`
- Use descriptive test names that state expected behavior
- Widget tests use `pumpWidget` with required providers wrapped

### Git
- Run `flutter analyze` and `dart format lib/ test/` before every commit
- Fix all analyzer warnings before committing
- Commit messages: `type: short description` (e.g. `feat: add home screen with alarm list`)
- Types: `feat`, `fix`, `refactor`, `chore`, `docs`, `test`, `style`

### Dependencies (planned)
- `tflite_flutter` -- on-device TFLite inference
- `flutter_riverpod` -- state management
- `go_router` -- routing
- `android_alarm_manager_plus` -- alarm scheduling
- `flutter_local_notifications` -- notifications
- `just_audio` -- alarm sound
- `shared_preferences` -- key-value storage
- `isar` / `isar_flutter_libs` -- structured DB
- `wakelock_plus` -- keep screen on
- `vibration` -- vibrate on alarm
- `permission_handler` -- runtime permissions
- `intl` -- date/time formatting

### Reference
- AI model: `/home/zarqan-khn/mycoding/ai-ml-dl/kaggle/quickdraw-345-classifier/model/`
- Reference Flutter app: `/home/zarqan-khn/mycoding/ai-ml-dl/kaggle/quickdraw-345-classifier/quickdraw_app/`
- Plan: `docs/DRAWBELL_PLAN.md`
- Proposal: `docs/DRAWBELL_PROPOSAL.md`

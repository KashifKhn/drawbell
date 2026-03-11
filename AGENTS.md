# AGENTS.md -- DrawBell

## Project Overview

DrawBell is a Flutter alarm app that requires users to draw a specific doodle
(verified by on-device AI) to dismiss the alarm. The AI model is a TFLite
SE-ResNet trained on Google Quick Draw (345 categories, 76% top-1 accuracy).
Android-first. Package ID: `dev.kashifkhan.drawbell`.

- Flutter **3.32.8** / Dart **3.8.1**
- No code generation (no Freezed, no json_serializable, no Isar)
- Manual `toJson` / `fromJson` everywhere

## Build Commands

```bash
# Get dependencies
flutter pub get

# Add a new dependency (never edit pubspec.yaml manually)
flutter pub add <package_name>

# Run the app (debug)
flutter run

# Build APK (all ABIs)
flutter build apk

# Build split APKs per ABI (release)
flutter build apk --split-per-abi

# Build app bundle
flutter build appbundle

# Analyze (lint) -- must pass with zero warnings before commit
flutter analyze --fatal-infos

# Format code
dart format lib/ test/

# Format check (CI -- exits non-zero if any file would change)
dart format --set-exit-if-changed lib/ test/

# Run all tests
flutter test

# Run a single test file
flutter test test/widget_test.dart

# Run a single test by name (substring match)
flutter test --name "AlarmModel round-trip JSON serialisation" test/widget_test.dart

# Run tests with coverage
flutter test --coverage
```

## Pre-commit Checklist

Run these in order and fix all issues before committing:

```bash
dart format lib/ test/
flutter analyze --fatal-infos
flutter test
```

## Architecture

```
lib/
  main.dart            # app entry, provider overrides, notification cold-start
  theme.dart           # AppTheme.light() / AppTheme.dark(), brand color
  router.dart          # GoRouter, StatefulShellRoute for 4 nav-bar tabs
  core/
    constants.dart     # Difficulty/HintMode/AlarmSound enums, top-level consts
    utils.dart         # pure formatting helpers (formatTimeOfDay, formatDays…)
  models/              # plain immutable Dart classes, toJson/fromJson, copyWith
    alarm_model.dart
    drawing_result.dart
    dismissal_record.dart
  providers/           # Riverpod StateNotifierProviders and plain Providers
    alarm_provider.dart
    settings_provider.dart
  services/            # all business logic; no Flutter imports
    alarm_service.dart
    audio_service.dart
    classifier_service.dart
    hint_service.dart
    imported_sound_service.dart
    native_alarm_service.dart
    notification_service.dart
    ringtone_service.dart
    storage_service.dart
  screens/
    app_shell.dart
    home/            home_screen.dart + widgets/
    alarm_editor/    alarm_editor_screen.dart + widgets/
    alarm_ring/      alarm_ring_screen.dart + widgets/
    practice/        practice_screen.dart + widgets/
    stats/           stats_screen.dart + widgets/
    settings/        settings_screen.dart
    onboarding/      onboarding_screen.dart
    info/            about / contact / privacy / terms screens
android/
  app/src/main/kotlin/dev/kashifkhan/drawbell/
    MainActivity.kt
    AlarmReceiver.kt           # BroadcastReceiver for exact alarm firing
    AlarmPlaybackService.kt    # foreground service keeps audio alive
    NativeAlarmScheduler.kt    # wraps AlarmManager exact alarms
    NativeAlarmStore.kt        # native-side persistence for boot rescheduling
```

Key decisions:
- **Storage**: SharedPreferences only (JSON blobs); alarms under key `'alarms'`, stats under `'dismissal_stats'`, settings as individual typed keys.
- **Alarm scheduling**: Custom Kotlin `NativeAlarmScheduler` + `AlarmManager`, not a Flutter plugin.
- **Navigation**: `StatefulShellRoute.indexedStack` for 4 bottom-nav tabs; full-screen modal routes for editor/ring/onboarding.
- **TFLite**: Float16 model, 28×28 pixel input rendered via `ui.PictureRecorder` in `classifier_service.dart`.

## Code Style Rules

### Formatting

- Line length: 80 characters (Dart default)
- `dart format` manages all line breaks -- never add manual breaks in formatted code
- Trailing commas on every argument list and parameter list so `dart format` produces stable multi-line output

### Comments

- No comments and no doc comments unless absolutely necessary
- Never write `// TODO`, `// FIXME`, or commented-out code
- If a comment is needed, it must explain WHY, never WHAT

### Imports

- Group order: Dart SDK → Flutter SDK → third-party packages → relative project files
- One blank line between each group
- Always use relative imports for project files: `import '../models/alarm_model.dart'`
- Never use `package:drawbell/` for internal imports
- Remove all unused imports

### Naming Conventions

- Files: `snake_case.dart` (e.g. `alarm_model.dart`, `home_screen.dart`)
- Classes: `PascalCase` (e.g. `AlarmModel`, `HomeScreen`)
- Variables / functions: `camelCase` (e.g. `alarmList`, `formatTime`)
- Constants: `camelCase` (e.g. `defaultDifficulty`, `maxAttempts`)
- Private members: prefix with `_` (e.g. `_counter`, `_onTap`)
- Enums: `PascalCase` name, `camelCase` values (e.g. `Difficulty.easy`)
- Riverpod providers: `camelCase` ending with `Provider` (e.g. `alarmListProvider`)

### Types

- Always specify types explicitly -- no `var`, no `dynamic` unless unavoidable
- Use `final` for all local variables that are not reassigned
- Use `const` constructors wherever possible
- Use `required` for all named parameters that must be provided

### Error Handling

- Never silently swallow errors -- always log or rethrow
- Use specific exception types, not generic `Exception`
- Services throw typed exceptions or return typed result objects
- UI shows user-facing errors via `ScaffoldMessenger.of(context).showSnackBar`

### Models

- Plain immutable Dart classes only -- no codegen, no Freezed
- All fields `final` with explicit types
- Provide `copyWith`, `toJson`, `fromJson` on every model
- Use safe casting in `fromJson` (`as int`, `?? defaultValue`); never assume type

### Services

- No Flutter imports in `lib/services/`; services are pure Dart
- Provide explicit `load()` / `dispose()` lifecycle where needed
- Guard with `isLoaded` / `isInitialized` before use
- `StorageService` must be `await init()` before any other service

### Providers (Riverpod)

- Use `StateNotifierProvider` for mutable lists / complex state
- Use `Provider` for plain singletons (e.g. `storageServiceProvider`)
- Override `storageServiceProvider` in `main()` with the pre-initialised instance
- Every mutating notifier method: persist → update state → reschedule if needed

### Widget / Component Rules

- Prefer `ConsumerWidget` over `StatefulWidget`; only use `ConsumerStatefulWidget` when lifecycle methods are required
- Every widget must be small and single-purpose
- Extract reusable widgets to the screen's `widgets/` subfolder
- Never duplicate widget trees -- extract shared components
- All widget constructors must be `const` when possible
- No inline styles -- use `Theme.of(context).colorScheme` and `Theme.of(context).textTheme`
- No magic numbers -- extract to `lib/core/constants.dart`

### UI/UX Consistency

- Brand color: `Color(0xFFD94A09)` (defined as `AppTheme.brandOrange`)
- Light theme: `ColorScheme.fromSeed(seedColor: AppTheme.brandOrange)`
- Dark theme: hand-crafted warm `ColorScheme` (surface `#1A1210`, container `#2A1F1A`)
- Always read colors from `Theme.of(context).colorScheme` in widgets
- Exception: drawing canvas uses white background, black stroke (hardcoded by design)
- Border radius: 12–16 dp consistently
- Spacing: multiples of 4 (4, 8, 12, 16, 24, 32)
- Minimum touch target: 48×48 dp
- Material 3 throughout; support both light and dark mode

### Analyzer

`analysis_options.yaml` enables strict mode -- all three flags are on:

```yaml
strict-casts: true
strict-inference: true
strict-raw-types: true
```

`missing_required_param`, `missing_return`, and `dead_code` are treated as
errors. `flutter analyze --fatal-infos` must exit 0 before any commit.

## Testing

- Test files mirror `lib/` structure inside `test/` with suffix `_test.dart`
- Group related tests with `group('ClassName', () { ... })`
- Test names state expected behaviour: `'round-trip JSON serialisation'`
- Widget tests wrap with `ProviderScope` and a minimal `GoRouter`:

```dart
final GoRouter testRouter = GoRouter(
  initialLocation: '/',
  routes: [GoRoute(path: '/', builder: (_, __) => const HomeScreen())],
);
await tester.pumpWidget(
  ProviderScope(child: MaterialApp.router(routerConfig: testRouter)),
);
await tester.pumpAndSettle();
```

## Git Workflow

- `main` is a protected branch -- never push directly
- Branch naming: `feat/<slug>`, `fix/<slug>`, `docs/<slug>`, `refactor/<slug>`
- Always open a PR against `main`; link the relevant GitHub issue in the PR body (`Closes #<n>`)
- Commit messages: `type: short description`
  - Types: `feat`, `fix`, `refactor`, `chore`, `docs`, `test`, `style`
  - Example: `feat: add home screen with alarm list`

## Reference Paths

- TFLite model: `/home/zarqan-khn/mycoding/ai-ml-dl/kaggle/quickdraw-345-classifier/model/`
- Reference Flutter app: `/home/zarqan-khn/mycoding/ai-ml-dl/kaggle/quickdraw-345-classifier/quickdraw_app/`
- Plan: `docs/DRAWBELL_PLAN.md`
- Proposal: `docs/DRAWBELL_PROPOSAL.md`

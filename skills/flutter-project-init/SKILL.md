---
name: flutter-project-init
description: Creates a new Flutter project with Clean Architecture, domain pattern boilerplate, and production-ready setup
---

# Flutter Project Initialization

Use when: "new project", "create project", "start project", "init flutter"

## Workflow Overview

```
Step 1: Project Info     → name, org, description
Step 2: Domain Pattern   → Simple/Stateful/Categorized/Tracked/Relational/Custom
Step 3: Tech Stack       → State Management, Features
Step 4: Generate & Verify → create, build, analyze
```

---

## Step 1: Gather Project Info

Ask user for:

| Field | Example | Required |
|-------|---------|----------|
| Project name | `my_app` (snake_case) | Yes |
| Organization | `com.example` | Yes |
| Description | "Task management app" | Yes |
| Entity name | `Task`, `Note`, `Expense` | Yes |

---

## Step 2: Domain Pattern Selection (CRUD-based)

Ask user to choose:

| Pattern | Examples | Generated Structure |
|---------|----------|---------------------|
| **Simple** | Note, Memo, Bookmark | Single-entity CRUD |
| **Stateful** | Todo, Task, Order | Includes a status field (done/in-progress, etc.) |
| **Categorized** | Expense, Product, Recipe | Includes a category relationship |
| **Tracked** | Habit, Workout, Study | Time/date-based tracking |
| **Relational** | Blog (User-Post-Comment) | Multi-entity relationships |
| **Custom** | - | User-defined fields |

### Generated Code per Pattern

#### Simple Pattern
```dart
// Entity
@freezed
sealed class Note with _$Note {
  const factory Note({
    required String id,
    required String title,
    required String content,
    required DateTime createdAt,
    DateTime? updatedAt,
  }) = _Note;
}
```

#### Stateful Pattern
```dart
// Entity with status
@freezed
sealed class Task with _$Task {
  const factory Task({
    required String id,
    required String title,
    required String description,
    @Default(TaskStatus.pending) TaskStatus status,
    required DateTime createdAt,
    DateTime? completedAt,
  }) = _Task;
}

enum TaskStatus { pending, inProgress, completed, cancelled }
```

#### Categorized Pattern
```dart
// Entity with category relation
@freezed
sealed class Expense with _$Expense {
  const factory Expense({
    required String id,
    required String title,
    required double amount,
    required String categoryId,
    required DateTime date,
    String? note,
  }) = _Expense;
}

@freezed
sealed class Category with _$Category {
  const factory Category({
    required String id,
    required String name,
    required String icon,
    required String color,
  }) = _Category;
}
```

#### Tracked Pattern
```dart
// Entity with time tracking
@freezed
sealed class Habit with _$Habit {
  const factory Habit({
    required String id,
    required String name,
    required String description,
    required HabitFrequency frequency,
    required List<DateTime> completedDates,
    required int currentStreak,
    required int bestStreak,
    required DateTime createdAt,
  }) = _Habit;
}

enum HabitFrequency { daily, weekly, monthly }
```

#### Relational Pattern
```dart
// Multiple related entities
@freezed
sealed class User with _$User {
  const factory User({
    required String id,
    required String name,
    required String email,
    required DateTime createdAt,
  }) = _User;
}

@freezed
sealed class Post with _$Post {
  const factory Post({
    required String id,
    required String authorId,
    required String title,
    required String content,
    required DateTime createdAt,
    @Default(0) int likeCount,
  }) = _Post;
}

@freezed
sealed class Comment with _$Comment {
  const factory Comment({
    required String id,
    required String postId,
    required String authorId,
    required String content,
    required DateTime createdAt,
  }) = _Comment;
}
```

---

## Step 3: Tech Stack Selection

### State Management (required choice)

| Option | Description |
|--------|-------------|
| **Riverpod** (Recommended) | Modern, compile-safe, testable |
| **BLoC** | Event-driven, enterprise-grade |

### Feature Presets

| Preset | Includes |
|--------|----------|
| **Minimal** | Core only (Freezed, Drift, DI) |
| **Essential** | + GoRouter, Dio, Error handling |
| **Full** | + Auth, Localization, Responsive |

### Feature Details

**Prerequisite:** a recent stable Flutter SDK (Dart >= 3.9). On older SDKs pub
silently resolves a broken `-dev` prerelease of freezed that generates nothing.
Check `flutter --version` and run `flutter upgrade` first if outdated.

Install EVERYTHING your preset needs in ONE `flutter pub add` command — a
single resolver pass. Sequential installs wedge the solver: each pass pins
the newest carets, and the codegen cluster (freezed / drift_dev /
injectable_generator / riverpod_generator) rides different analyzer majors,
so a later group can become unsolvable against what an earlier group locked.
One pass lets pub pick a mutually compatible all-stable set.

```bash
# Full preset + Riverpod (remove what your preset doesn't need — but never
# split runtime and dev: codegen packages into separate commands).
# path_provider/path are required by app_database.dart.
# fpdart = Either for error handling (dartz is unmaintained).
flutter pub add freezed_annotation drift path_provider path get_it injectable flutter_riverpod riverpod_annotation go_router dio fpdart easy_localization responsive_framework dev:freezed dev:build_runner dev:injectable_generator dev:drift_dev dev:riverpod_generator

# Using BLoC instead of Riverpod: drop flutter_riverpod, riverpod_annotation
# and dev:riverpod_generator from the command above and run:
flutter pub add flutter_bloc

# Optional (Full preset):
flutter pub add firebase_auth
```

After installing, confirm no `-dev`/`-beta` prerelease slipped into
pubspec.yaml — a prerelease there means the solver couldn't find a stable
set and the codegen output is not trustworthy.

---

## Step 4: Project Generation

### 4.1 Create Flutter Project

```bash
flutter create --org <org> --project-name <name> <name>
cd <name>
```

### 4.2 Setup Folder Structure

```
lib/
├── core/
│   ├── constants/
│   │   └── app_constants.dart
│   ├── database/
│   │   └── app_database.dart
│   ├── di/
│   │   └── injection.dart
│   ├── errors/
│   │   ├── exceptions.dart
│   │   └── failures.dart
│   ├── router/
│   │   └── app_router.dart
│   ├── theme/
│   │   ├── app_colors.dart
│   │   └── app_theme.dart
│   └── utils/
│       └── extensions.dart
├── features/
│   └── <entity>/
│       ├── domain/
│       │   ├── entities/
│       │   │   └── <entity>.dart
│       │   ├── repositories/
│       │   │   └── <entity>_repository.dart
│       │   └── usecases/
│       │       ├── create_<entity>.dart
│       │       ├── delete_<entity>.dart
│       │       ├── get_<entity>s.dart
│       │       └── update_<entity>.dart
│       ├── data/
│       │   ├── datasources/
│       │   │   └── <entity>_local_datasource.dart
│       │   ├── models/
│       │   │   └── <entity>_model.dart
│       │   └── repositories/
│       │       └── <entity>_repository_impl.dart
│       └── presentation/
│           ├── bloc/          # or providers/
│           │   ├── <entity>_bloc.dart
│           │   ├── <entity>_event.dart
│           │   └── <entity>_state.dart
│           ├── pages/
│           │   ├── <entity>_list_page.dart
│           │   └── <entity>_detail_page.dart
│           └── widgets/
│               └── <entity>_card.dart
├── shared/
│   └── widgets/
│       └── loading_widget.dart
└── main.dart
```

### 4.3 Generate Base Files

#### core/errors/failures.dart
```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'failures.freezed.dart';

@freezed
sealed class Failure with _$Failure {
  const factory Failure.server({required String message, int? code}) = ServerFailure;
  const factory Failure.cache({required String message}) = CacheFailure;
  const factory Failure.network({@Default('No internet connection') String message}) = NetworkFailure;
  const factory Failure.validation({required String message}) = ValidationFailure;
}
```

#### core/database/app_database.dart
```dart
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'app_database.g.dart';

// Tables will be added per domain pattern
@DriftDatabase(tables: [])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'app.db'));
    return NativeDatabase.createInBackground(file);
  });
}
```

#### core/di/injection.dart
```dart
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'injection.config.dart';

final getIt = GetIt.instance;

@InjectableInit(preferRelativeImports: true)
Future<void> configureDependencies() async => getIt.init();
```

### 4.4 Update pubspec.yaml

Based on selected preset, add all required dependencies.

### 4.5 Run Code Generation

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

### 4.6 Validation (REQUIRED)

```bash
flutter analyze
```

**Must pass with 0 errors.** Info/warning level issues are acceptable.

If errors exist:
1. Fix each error
2. Re-run `dart run build_runner build`
3. Re-run `flutter analyze`
4. Repeat until 0 errors

---

## Step 5: Initialize Git

```bash
git init
git add .
git commit -m "Initial commit: <project_name> with Clean Architecture

- Domain pattern: <selected_pattern>
- State management: <Riverpod/BLoC>
- Features: <selected_preset>

🤖 Generated with flutter-craft"
```

---

## Completion Checklist

- [ ] Project created with correct name/org
- [ ] Folder structure matches Clean Architecture
- [ ] Domain entities generated with Freezed
- [ ] Database tables created in Drift
- [ ] DI configured with injectable
- [ ] `flutter pub get` successful
- [ ] `dart run build_runner build` successful
- [ ] `flutter analyze` returns 0 errors
- [ ] Git initialized with initial commit

---

## Output to User

After completion, inform:

```
✅ Project '<name>' created successfully!

📁 Structure: Clean Architecture
📦 Pattern: <selected_pattern>
🔄 State: <Riverpod/BLoC>
✨ Features: <preset>

Next steps:
1. cd <name>
2. flutter run
3. Use /brainstorm to plan your first feature
```

---

## References

For detailed code templates per pattern, see:
- `references/simple-pattern.md`
- `references/stateful-pattern.md`
- `references/categorized-pattern.md`
- `references/tracked-pattern.md`
- `references/relational-pattern.md`

> **Note:** The Custom pattern has no dedicated template because you design the user-defined fields yourself.

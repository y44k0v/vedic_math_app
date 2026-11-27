# Vedic Math Mastery

[![Release](https://img.shields.io/github/v/release/y44k0v/vedic_math_app)](https://github.com/y44k0v/vedic_math_app/releases)
![Android](https://img.shields.io/badge/Platform-Android-3DDC84?logo=android&logoColor=white)

A Flutter application designed to help you learn and practice **Vedic Mathematics** for faster mental calculations. Includes a comprehensive theoretical guide in this repository alongside built-in theory, worked examples, timed 25-exercise drills, progress charts, multi-player profiles, and local WiFi multiplayer races.

<img src="assets/icon/icon_monochrome.png" alt="Vedic Math Mastery Icon" width="120" />

> **Icons Note:** Only Android launcher icons are bundled in this repository. To generate icons for additional platforms, configure and run `flutter_launcher_icons`.

---

## Changelog

## [1.2.0] - 2026-11-27

### Added

- **Local WiFi Multiplayer:** Added Host/Client real-time racing over WiFi using an authoritative Host server (`HttpServer` + `WebSocket`), monotonic server-side arrival timing, half-RTT latency compensation (`250ms` grace window), live competitor scoreboard, and resumable matches by Match ID (`v2 → v3` SQLite migration).
- **Comprehensive Test Suite:** Added unit, SQLite migration, real WebSocket protocol, and widget test batteries (`generator_test.dart`, `database_test.dart`, `multiplayer_protocol_test.dart`, and `widget_test.dart`).

### Fixed

- **Android Activity & Schema:** Aligned `MainActivity.kt` package with `com.data_dev_labs.vedic_math_app` and updated SQLite `onCreate` to initialize both v2 and v3 tables on fresh installs.
- **UI & Widget Test Stability:** Fixed widget-test `FakeAsync` isolation with `FakeDatabaseHelper` and resolved remaining analyzer deprecations.

## [1.1.0] - 2026-11-26

### Added

- **Multi-Player Profiles:** Added SQLite `players` table (`id`, `uuid`, `name`, `is_active`) with automatic `v1 → v2` database migration.
- **First-Launch Player Setup:** Added onboarding screen (`PlayerInitScreen`) to initialize the first player on startup.
- **Player Management & Menu:** Added `Players` tab and AppBar player-switcher menu supporting full profile management and instant switching.
- **Per-Player Score Tracking:** Scoped `session_history` and `item_progress` to `player_id` with cascade deletion.

### Improved

- **Non-Repeating Exercises:** Upgraded `ExerciseGenerator` with `Random.secure()`, expanded operand pools across all 29 modules, and commutative deduplication so all 25 drill questions are unique.

### Fixed

- **Score Refreshing:** Replaced `IndexedStack` in `HomeScreen` so Progress charts, Sutra mastery badges, and player totals update immediately after completing a drill.
- **Android Edge-to-Edge & Button Layout:** Added `SafeArea` and scrollable containers to `ExerciseScreen` and the Vedic Solution bottom sheet; prevented `"Solution"` button text from wrapping onto 2 lines.
- **Player Menu & Dialog Stability:** Fixed 6.7px right overflow in the AppBar player menu, removed `(CRUD)` label text, and fixed the red-screen `TextEditingController` crash on Edit → Cancel.
- **Progress Chart Y-Axis:** Widened `leftTitles` (`reservedSize: 48`) so 3-digit numbers (`150`, `200`, `250`) render on a single line.
- **Android Build & CI:** Removed hyphens from `applicationId`/`namespace` and fixed `$` password escaping in the GitHub Actions keystore step.
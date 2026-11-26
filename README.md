# Vedic Math Mastery

A Flutter project. Includes background guide in this repo and short background in the app. Created to assist to permform faster mental calculations.

Only android icons included. Use dart to generate other platform icons via flutter launcher icons package, the randomness of excercises needs some work.

![Alt text](assets/icon/icon_monochrome.png)


## [1.1.0] - 2026-11-26

### Added
- **Multi-Player Profiles:** Added SQLite `players` table (`id`, `uuid`, `name`, `is_active`) with automatic `v1 → v2` database migration.
- **First-Launch Player Setup:** Added onboarding screen (`PlayerInitScreen`) to initialize the first player on startup.
- **Player Management & Menu:** Added `Players` tab and AppBar player-switcher menu supporting full Create, Read, Update, Delete, and instant profile switching.
- **Per-Player Score Tracking:** Scoped `session_history` and `item_progress` to `player_id` with cascade deletion.

### Improved
- **Non-Repeating Exercises:** Upgraded `ExerciseGenerator` with `Random.secure()`, expanded operand pools across all 29 modules, and commutative deduplication so all 25 drill questions are unique.

### Fixed
- **Score Refreshing:** Replaced `IndexedStack` in `HomeScreen` so Progress charts, Sutra mastery badges, and player totals update immediately after completing a drill.
- **Android Edge-to-Edge & Button Layout:** Added `SafeArea` and scrollable containers to `ExerciseScreen` and the Vedic Solution bottom sheet; prevented `"Solution"` button text from wrapping onto 2 lines.
- **Player Menu & Dialog Stability:** Fixed 6.7px right overflow in the AppBar player menu, removed `(CRUD)` label text, and fixed the red-screen `TextEditingController` crash on Edit → Cancel.
- **Progress Chart Y-Axis:** Widened `leftTitles` (`reservedSize: 48`) so 3-digit numbers (`150`, `200`, `250`) render on a single line.
- **Android Build & CI:** Removed hyphens from `applicationId`/`namespace` (`com.datadevlabs.vedic_math_app`) and fixed `$` password escaping in the GitHub Actions keystore step.


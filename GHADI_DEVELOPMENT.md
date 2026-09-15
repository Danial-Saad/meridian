# GHADI_DEVELOPMENT.md

Independent development log for work added on top of the existing Meridian
project. This file only covers what gets added *after* the project was
received for further development. It does not replace, edit, or duplicate
`README.md`, which is the original developer's own documentation and is
left untouched.

---

## Project Starting Point

Meridian was received as a Flutter/Android port of an existing Next.js +
TypeScript web app of the same name (see `README.md` for the original
developer's own account of that port). At the point this file was created:

- 37 Dart files, ~7,900 lines total, organized under `lib/models`,
  `lib/store`, `lib/screens`, `lib/widgets`, `lib/theme`, `lib/utils`.
- **The project has never been compiled.** `README.md` states its author
  had no Flutter/Dart SDK or pub.dev access and reviewed the code by hand
  only. This analysis environment also has no Flutter/Dart SDK and no
  network access, so nothing in this document — including this
  starting-point review itself — has been build-verified. Everything below
  comes from careful manual reading, the same method the original port
  used. Running `flutter pub get && flutter analyze` on a real machine as
  a first step is strongly recommended, independent of any new feature
  work.
- No prior `GHADI_DEVELOPMENT.md` or equivalent change log existed. This is
  the first one.
- **No feature code has been changed yet.** This document currently
  records only the pre-implementation analysis. See "Change Log" at the
  bottom.

---

## Existing Features At Start

*(Everything below already existed before this document was created. None
of it should be read as work done by Ghadi.)*

- **Dashboard** — greeting header with live date/time, "Plan my day" and
  (evening-only) "Day review" actions, the Day Ring visual, Focus-time and
  Productivity-score stat cards, an "Up next" task card, a mini schedule
  list, and a mini habits grid.
- **Planner** — single-day timeline (05:00–24:00), previous/next-day
  navigation plus a "Today" jump, long-press-drag to move a task,
  drag-handle resize, side-by-side layout for overlapping tasks, tap an
  empty slot to create a task.
  - **Plan My Day** (`store/plan_my_day.dart`) — a rule-based (non-AI)
    auto-scheduler: takes a list of priorities, a focus-hours target, and
    free-text "commitments" (parsed with a time-range regex), and lays out
    task blocks with breaks around existing tasks for the target day.
  - **End-of-day review** — a per-day `DailyReview` (completed/total
    tasks, focus minutes, habits done, free-text "went well" / "what to
    improve"), saved from the Dashboard's evening-only button.
- **Tasks** — full CRUD; Status filter (All/Open/Completed/Skipped); Date
  filter (Any date/Today/Upcoming/Past); Category filter.
- **Habits** — full CRUD; per-habit streak, best streak, 30-day completion
  rate, 30-day heatmap, daily mark-done toggle.
- **Focus Mode** — Pomodoro presets 25/5, 50/10, and Custom (durations
  configurable in Settings); the countdown is derived from a captured
  wall-clock end-time, so it stays accurate if the app is backgrounded;
  logs a `FocusLogEntry` when a focus phase completes or is manually
  marked "Complete".
- **Analytics** — Today/Week/Month range toggle; 4 stat cards
  (productivity score, focus time, completion rate, avg session); a
  focus-time trend chart; a category-distribution donut; a
  completed-vs-skipped bar chart; a weekly habit-completion strip. All
  charts are hand-drawn `CustomPainter`s — no charting package dependency.
- **Resources** — full in-app CRUD: title, optional description, URL, and
  an image chosen via the gallery/camera; tap a card to open its URL;
  responsive 1/2/3-column layout depending on screen width. *(This is more
  complete than what `README.md` currently describes — see "Notes /
  Discrepancies Found" below.)*
- **Settings** — Theme (Dark/Light/System), time format (12h/24h),
  week-start day, default focus/break duration, Export backup / Import
  backup / Load example data / Reset all local data, an About block.
- **Local persistence** — a single versioned JSON blob in
  `SharedPreferences`, with a step-by-step migration function and a
  corruption-recovery fallback (never crashes on bad data — resets to
  empty and tells the user).
- **Backup / Restore** — export builds an `{app, version, exportedAt,
  data}` JSON envelope shared via the OS share sheet; import validates
  structure and version, and reports a specific reason if a file is
  rejected.

---

## Architecture At Start

- **Framework:** Flutter/Dart, Android only (no iOS target).
- **State management:** `provider` (^6.1.2) — one main `ChangeNotifier`
  (`MeridianStore`, in `store/meridian_store.dart`) holding all
  tasks/habits/resources/settings/focus-log/reviews, plus derived stats
  cached and invalidated on data change or day rollover; one small
  secondary `ChangeNotifier` (`ThemeController`, in `theme/app_theme.dart`)
  for the theme preference.
- **Persistence:** `shared_preferences`, single key `meridian-data`,
  JSON-encoded. `kMeridianDataVersion` is currently `2`.
  `store/persistence.dart` is the *only* file that touches
  `SharedPreferences` directly — the store and every screen go through it.
- **Networking:** none. `AndroidManifest.xml` deliberately declares no
  `INTERNET` permission, with a source comment explaining this is
  intentional (the app is local-first and makes no network calls; even
  `url_launcher` hands off to another app via an intent rather than
  needing this permission itself).
- **Navigation:** a 5-tab bottom `NavigationBar` (Today / Planner / Focus /
  Tasks / Habits) kept alive via `IndexedStack`; Analytics, Resources, and
  Settings are reached from 3 AppBar icons and pushed as full-screen
  routes, by design, rather than crowding the tab bar.
- **UI/Theme:** a `MeridianColors` token class with complete Dark and
  Light palettes (`theme/app_theme.dart`); Material widgets; charts and
  rings are hand-drawn `CustomPainter`s; no bundled custom fonts yet
  (falls back to the platform default).
- **Full directory layout:** see `README.md`'s own "Architecture" section
  — intentionally not duplicated here so the two documents can't drift
  out of sync with each other.

### Data models (`lib/models/domain.dart`)

| Model | Holds |
|---|---|
| `Task` / `NewTask` | title, category, priority, status, start (minutes since midnight), duration, notes, taskDate (`YYYY-MM-DD`), optional link |
| `Habit` / `NewHabit` | name, emoji, color, `logs` (dateKey → done) |
| `HabitWithStats` | derived only, never stored: streak, best streak, 30-day completion rate, last30/last7 |
| `FocusLogEntry` | taskId (nullable), minutes, timestamp |
| `DailyReview` | tasksCompleted/Total, focusMinutes, habitsCompleted/Total, free-text wentWell/improve, savedAt |
| `UserSettings` | pomodoroFocus, pomodoroBreak, timeFormat24, weekStart |
| `DayStats` | derived only, **today-only**: completed/total/skipped/actionable/pct/focusMinutes/nextTask/productivityScore |
| `HistoryDay` | derived only, trailing 28 days: date/totalTasks/completed/skipped/focusMinutes |
| `UserResource` | title, description, imagePath, url, createdAt |
| `MeridianData` | the persisted root: version, tasks[], habits[], resources[], settings, focusLog[], reviews{} |

No model exists yet for: reminders/notifications, app-blocking or
website-blocking rules, sleep/wake data, or anything AI-related.

---

## Notes / Discrepancies Found During Initial Analysis

Recorded here for visibility — nothing below has been changed, per the
"don't silently fix things outside the current task" rule.

1. **`README.md`'s "Resources / Courses feature" section is out of date.**
   It describes a static, developer-edited `lib/resources_config.dart`
   list with no persistence layer. The actual code has full in-app
   add/edit/delete via `UserResource` (in `models/domain.dart`), stored
   through `MeridianStore` like everything else. No `resources_config.dart`
   file exists anywhere in the project. `assets/resources/README.md` also
   still refers to that non-existent file. This reads like the feature was
   upgraded after that README section was written, and the section was
   never updated to match. Left untouched (not the file to edit for this
   kind of change) — flagged here only.
2. **The app's current visual identity is Blue-accent with Light as the
   default theme**, not "Violet/Indigo, Dark" as summarized in the
   original project brief. Both a full Dark and a full Light palette exist
   in `theme/app_theme.dart`; the Light palette's own comments suggest it
   was a deliberate, later addition. This isn't a bug — just a gap between
   the one-line project summary and what's actually shipped in code.
   Noted so a future change doesn't "correct" it back to violet by
   mistake. *(Superseded — see "This Session's Work" below: the palette
   itself has since been rewritten again, to a new Light/Dark pair.)*
3. **`HistoryDay.focusMinutes`** (`store/history.dart`, used by Analytics'
   Week/Month views) only counts completed-task durations.
   **`DayStats.focusMinutes`** (`store/meridian_store.dart`, used by
   Dashboard/Today) adds real Focus-session minutes on top of that. Week
   and Month focus-time in Analytics can therefore under-report relative
   to what Today shows. Not changed — noted for whichever feature next
   touches Analytics' time ranges. *(Resolved — see "Update — Analytics
   Pass 1: Base Analytics + Feature 1.")*
4. **Analytics' "Productivity score" stat card always shows *today's*
   score**, even when the Today/Week/Month toggle is set to Week or Month;
   **"Category distribution" always shows all-time data**, ignoring the
   toggle entirely. Not changed — same reason as above. *(Resolved — see
   "Update — Analytics Pass 1: Base Analytics + Feature 1.")*

---

## Update — Features 1–4 Received (Outside This Log)

Between this file's creation and this update, Features 1–4 from the table
below were implemented directly by the project owner — git commits
`df11e10` ("Feature 1: Added Advanced Productivity Progress and fixed
bugs"), `d672d21` ("Feature 2: Added Task Delay Analysis with safe data
migration"), `17fce75` ("Feature 3: Added Habit Commitment Analysis"), and
`28de54d` ("Feature 4: Added Productivity Pattern Analysis") — independent
of this log, the same way the original port in "Project Starting Point"
was also independent of it. This session picks up from that point: an
in-progress theme rewrite had been left uncommitted and broke the build,
and Feature 5 hadn't been started. See "This Session's Work" below for
both.

What's new in the codebase since the original snapshot above (recorded
here rather than editing "Existing Features At Start", which is a fixed
point-in-time record and is left as-is):

- **`lib/analysis/`** — a new folder, one file per feature
  (`analytics_charts.dart`, `delay_analysis.dart`, `habit_analysis.dart`,
  `pattern_analysis.dart`), all surfaced together on the existing
  Analytics screen (`analytics_screen.dart`).
- **`Task.postponedCount`** (`models/domain.dart`) — new field for
  Feature 2, `int`, defaults to `0` with a safe `fromJson` fallback, so
  old saved data keeps working.
- **`google_fonts` dependency** — added for Poppins as the app-wide
  typeface (`main.dart`'s `_buildThemeData`); correctly declared in both
  `pubspec.yaml` and `pubspec.lock`.
- Project size, as of the end of this session (theme fix + Features 5
  and 6 included): 42 Dart files, ~9,260 lines (was 37 / ~7,900 at the
  point this file was first created, before any of Features 1–6).

---

## Feature Conflict Check

*(Status column updated this session for #1–5; original "What already
exists" analysis for each left untouched below it, since that describes
what was true at the time this table was first written.)*

| # | Requested feature | Status | What already exists |
|---|---|---|---|
| 1 | Advanced Productivity Progress | **Implemented** — see note | `DayStats.productivityScore` (today, weighted: 70% completion + 30% focus-vs-240min target) and 28-day `HistoryDay` history already power Analytics' range toggle. *Note: the three gaps this row used to list — a range-aware score, a range-aware category chart, "planned vs actual time" — were closed in "Update — Analytics Pass 1," which also fixed Discrepancy #3/#4 above; those two discrepancies are no longer open.* |
| 2 | Task Delay / Overdue Analysis | **Implemented** — `DelayAnalysisCard` in `lib/analysis/delay_analysis.dart`, backed by `Task.postponedCount` and (as of "Update — Feature 2 to 10/10") `Task.originalDate`. | *Note: the "no delay amount, no reschedule history" gap this row used to list was closed — see "Update — Feature 2 to 10/10" below.* |
| 3 | Habit Commitment Analysis | **Implemented** — see note | Per-habit streak/best/30-day-rate/heatmap already computed in `_computeHabitStats`. Cross-habit ranking (most/least consistent) added by `HabitCommitmentCard`. *Note: the weekly-vs-monthly breakdown and missed-days count this row used to list as open were closed in "Update — Feature 3 to 10/10"; both computed age-aware in `_computeHabitStats`, same reasoning as the existing `completionRate` fix.* |
| 4 | Productivity Pattern Analysis | **Implemented** — `ProductivityPatternCard` in `lib/analysis/pattern_analysis.dart`: peak focus time-of-day, best day-of-week by completion rate, most-delayed priority. | *Note: as of "Update — Feature 4 to 10/10," the focus and delay patterns respect the Today/Week/Month toggle (the weekly-pattern one deliberately doesn't — see that update), and all three now require a minimum sample before naming a "pattern" rather than overclaiming from a single data point.* |
| 5 | Productivity Insights | **Implemented this session** — `ProductivityInsightsCard` in `lib/analysis/insights_analysis.dart`. See "This Session's Work" below. | No natural-language insight generation; would sit on top of #1/#3/#4's output once those exist. |
| 6 | Notifications & Reminders | **Implemented, first case only** — see note | No package, no permission, no data model. Existing "toasts" are in-app-only — a Focus session that finishes while the app is backgrounded currently produces no alert at all. *Note: only the specific case this table's own "Recommended Implementation Order" called out — a Focus/Break timer completing — is done, via `lib/services/notification_service.dart`. Scheduled/future-dated reminders (e.g. a habit reminder at a set time) are a different, larger piece of work — exact-alarm permission, `zonedSchedule`, a boot receiver, a data model for what to remind about and when — and are still open. See "This Session's Work" below.* |
| 7 | App Blocking | **Not implemented** | No native Android groundwork exists. Needs feasibility research (Usage Access / Accessibility Service) before any UI is built. |
| 8 | Website Blocking | **Not implemented** | No native groundwork exists. Reliable blocking typically needs a local VPN service or DNS interception — a significant step for an app that currently declares zero network permissions. Needs feasibility research first. |
| 9 | Personalized AI Routine | **Not implemented** | A non-AI, rule-based scheduler already exists (`plan_my_day.dart`) as a natural starting anchor. Per the project's own instructions this should come last, after 1–6 exist as real data. Feature 5 (this session) is deliberately still rule-based/local, not this — the network-permission decision for a real AI routine remains a separate, explicit future step (see "Risks"). |

---

## Recommended Implementation Order

1. Feature 1 or Feature 3 first — both are partial, additive on top of
   data that's already computed, and don't need a persistence/schema
   change. Lowest risk.
2. Feature 2 next — needs one deliberate, small schema decision if
   reschedule-history is wanted (a genuinely "not implemented" data point,
   not just a missing view).
3. Feature 4, then Feature 5 — both build on what 1–3 produce.
4. Feature 6 — a naturally scoped first case is already visible in the
   code: notify when a Focus session finishes, since that's currently
   silent if the app isn't open.
5. Feature 7 and Feature 8 — feasibility research first; implementation
   only if the research supports it.
6. Feature 9 last, and local/offline by default, given the app's current
   zero-network-permission design.

*(Followed as written: 1/3, then 2, then 4, then 5, then the Feature 6
first case — this session's work completes that sequence up through
Feature 6. Features 7–9 are unchanged and still ahead.)*

---

## Risks

- **No compiler available to either the original author or this session.**
  Nothing in this project has been build-verified. Every change — past or
  future — should be treated as "carefully reviewed, not yet run" until
  someone actually runs `flutter analyze` / `flutter run` on a real
  machine. *(This session found a concrete example of why this matters:
  see "This Session's Work" — a broken import path had been sitting in
  the Feature 1 commit undetected.)*
- **Feature 6 is a materially bigger leap of faith than Features 1–5,
  precisely because of the point above.** Every feature before it was
  pure Dart/Flutter widget code — no native permissions, no new plugin,
  nothing platform-specific. Feature 6 is the first to add a real Android
  permission (`POST_NOTIFICATIONS`) and a third-party native plugin
  (`flutter_local_notifications`), and manual code review genuinely
  cannot catch everything a native integration can hit (OEM-specific
  notification quirks, a Gradle version mismatch, a permission dialog
  that behaves differently on a given Android build). Treat it as
  "review this section of the diff first" once this is actually run on a
  device — see "This Session's Work" for exactly what was and wasn't
  possible to verify.
- **Schema changes must go through `persistence.dart`'s existing
  versioning** (`kMeridianDataVersion`, `_migrateData`) and be mirrored in
  `backup.dart`'s validation — skipping either one risks breaking old
  local data, or a restored backup, once a new field is introduced.
- **Features 7 and 8 carry real platform/permission risk** and deserve a
  dedicated feasibility check before any UI work starts on them.
- **Any future external AI API call (Feature 9) would be this app's
  first-ever network permission.** That's a deliberate, explicit decision
  point to have separately — not a default to slide into. Feature 5 (this
  session) was kept deliberately rule-based/local specifically so it
  doesn't quietly become that decision by accident.
- **Copying a file into a new folder without updating its relative
  imports is an easy, silent mistake.** This session found one real
  instance (`lib/analysis/analytics_charts.dart` still using `../../`
  paths sized for its old location two folders deeper). Worth a quick
  double-check any time a file moves or gets copied as a starting point
  for a new one.

---

## This Session's Work

### 1. Theme system migration (bug fix, not a numbered feature)

The project owner had rewritten `lib/theme/app_theme.dart` from scratch —
its own new comments call the result "Nordic Minimal (Strong & Bold)" for
Light and "Deep Focus" for Dark — but the change was **uncommitted**, and
had only been propagated to `main.dart` and `app_shell.dart`. Every other
screen and widget (~25 files) still referenced the old `MeridianColors`
API, and `ThemeController`'s public methods had also been renamed. Left
as-is, none of it would have compiled.

**What changed in `MeridianColors`, and how each old field was resolved:**

| Old field | Resolution |
|---|---|
| `accent` | renamed to `primary` |
| `accentStrong` | folded into `primary` (matches how `app_shell.dart` had already been migrated, for the selected nav-bar label/icon) |
| `accentDeep` | folded into `primary` (only one caller — a low-opacity background wash on the splash screen) |
| `accentInk` | renamed to `primaryInk` — **new field added** to the theme, `0xFFFFFFFF` in both palettes, identical to the old value, so this is a pure rename with zero visual change |
| `accentSoft` | renamed to `primaryBg` |
| `accentGlow`, `surfaceActive` | confirmed unused anywhere in the codebase already — no action needed |
| `borderStrong`, `borderTrack` | both folded into the single new `border` token (matches how `main.dart` had already been migrated; the new theme's `border` is a solid, clearly-visible color, unlike the old translucent-white hairline, so nothing reads as washed-out) |
| `scrim` | **new field added** — this concept (the dimmed backdrop behind a modal) didn't survive the rewrite at all; one caller (`confirm_dialog.dart`'s `barrierColor`) |
| `periodNight` / `periodMorning` / `periodAfternoon` / `periodEvening` | **new fields added** — these power the Dashboard's Day Ring time-of-day legend (`widgets/dashboard/day_ring.dart`), a real, visible, pre-existing feature that would otherwise have silently lost its 4-color legend entirely. Chosen to harmonize with the new palettes rather than reuse the old hex values: Night is the same deep indigo in both Light and Dark (the old palette also kept Night identical across both), Morning reuses each theme's own `warning` amber, Afternoon reuses each theme's own `primary`, Evening is a new warm orange. These four are a judgment call — nothing in the new palette dictated a "correct" answer — so the exact hex values are easy to change later; they live in `theme/app_theme.dart` right next to every other color, for exactly that reason. |
| `ThemeModePref` (custom enum) | replaced with Flutter's built-in `ThemeMode` — only affected `settings_screen.dart` (3 call sites); the `.dark` / `.light` / `.system` values carried over unchanged |
| `ThemeController.mode` / `.setMode()` | renamed to `.themeMode` / `.setThemeMode()` — only remaining callers were in `settings_screen.dart` |
| `ThemeController.loaded` / `.theme` / `.load()` / `.updateSystemBrightness()` | removed in the rewrite; confirmed there were no remaining callers anywhere |

All renames above were applied as a mechanical find-and-replace across
every `.dart` file under `lib/` (`lib/theme/app_theme.dart` itself
excluded, since it *defines* the new names rather than consuming them) —
nothing about *what* any screen does changed, only *which token name* it
reads the color from.

**Also removed:** `lib/widgets/analytics/analytics_charts.dart`. Feature 1
had copied this file to `lib/analysis/analytics_charts.dart` and extended
it there (600 lines vs. the original 475), repointing
`analytics_screen.dart`'s import at the new copy, but left the old copy in
place. A repo-wide search confirmed nothing imported it anymore, so it was
dead code — and dead code nobody imports is also code nobody would ever
be prompted to fix, so it would have sat there permanently failing
analysis on the same old-token errors. Its full history is still in
`git log -- lib/widgets/analytics/analytics_charts.dart` if it's ever
needed.

**Also found and fixed — not theme-related, but blocked compilation
entirely, so it had to be fixed too:** `lib/analysis/analytics_charts.dart`
itself had five `import '../../...'` paths left over from when the file
lived two folders under `lib/` (`lib/widgets/analytics/`) instead of one
(`lib/analysis/`); copying it over without updating the relative paths
meant every one of those imports pointed outside the project entirely.
Corrected to `import '../...'`. This predates the theme rewrite — it was
already broken in the Feature 1 commit (`df11e10`) — flagged here so it
isn't mistaken for a theme-related change.

**Verification performed** (still no Flutter/Dart SDK available in this
environment, so — same as every prior review in this file — this is
careful manual verification, not a compiler run):
- Repo-wide search confirms zero remaining references to any
  removed/renamed token, anywhere in `lib/`.
- Every relative `import '...'` in every `.dart` file under `lib/` was
  checked against the actual filesystem — all resolve correctly.
- Every widget/type `analytics_screen.dart` references was confirmed to
  have exactly one definition somewhere in the project, and there are no
  duplicate public class names anywhere in `lib/`.
- Brace/paren/bracket counts balance on every file touched this session.
- `pubspec.yaml` / `pubspec.lock` already had `google_fonts` correctly
  declared and locked — that part of the owner's in-progress work was
  already consistent and needed no fix.

**Still recommended, independent of this log:** run
`flutter pub get && flutter analyze` on a real machine as the first thing
after pulling this — the same standing recommendation this file has
carried since it was created.

### 2. Feature 5 — Productivity Insights

Implemented in `lib/analysis/insights_analysis.dart`
(`ProductivityInsightsCard`), wired into `lib/screens/analytics_screen.dart`
in the same place, and the same way, Features 1–4 already are (one import
line, one card placed after Feature 4's, inside the same
`// --- FEATURE N: ... ---` comment convention).

Rather than repeating any single one of Features 1/3/4, this looks
*across* their data for connections none of them surface alone:

1. **Week-over-week completion trend** — compares the last 7 days of
   `store.history` against the previous 7. Only shown once both windows
   have at least a handful of real tasks, so it isn't noise from
   comparing two nearly-empty weeks.
2. **Best active habit streak** — the habit with the highest *current*
   streak (≥3 days to qualify). Distinct from Feature 3's "Most
   Consistent," which ranks by all-time completion rate, not current
   streak.
3. **A normally-solid habit that's gone quiet** — a habit with decent
   overall history (≥40% completion) whose current streak just broke.
   Distinct from Feature 3's "Needs Attention," which flags chronically
   low completion rather than a recent lapse in an otherwise-good habit.
4. **Focus-time vs. task-scheduling alignment** — buckets both focus
   sessions and completed tasks into Morning / Afternoon / Evening /
   Night (same boundaries Feature 4 already uses) and flags whether they
   line up. This is the one genuinely new cross-reference: Feature 4
   already reports focus-time-of-day and task-delay-by-priority, but as
   two separate observations — this connects "when you focus best" to
   "when you actually schedule work."
5. **Urgent tasks still slipping** — open (not completed or skipped)
   tasks that are both `priority == urgent` and have
   `postponedCount > 0`.

If none of the five currently apply (a fresh install, or too little data
yet), the card shows a plain "check back after a few more days" message
instead of an empty box — the same pattern Features 2 and 3 already use
for their own empty states.

Everything is computed synchronously from data already loaded into
`MeridianStore` — no new package, no network call, nothing that would
need the `INTERNET` permission the manifest deliberately doesn't request.
This matches the project's own stated intent for this feature (rule-based
and local, explicitly *not* Feature 9's future AI routine) and keeps the
app's zero-network-permission design intact.

### 3. Feature 6 — Notifications & Reminders (first case)

Scoped deliberately narrow, exactly as this file's own "Recommended
Implementation Order" called out: *"notify when a Focus session finishes,
since that's currently silent if the app isn't open."* Extended by one
small, same-effort step to also cover a Break finishing (same code path,
same risk, and leaving it out would have made the feature feel oddly
half-done — see the code comment at the call site). Scheduled/future
reminders (e.g. "remind me about this habit at 6pm") are **not** part of
this — that's a separate, larger piece of work (see the Feature Conflict
Check table note and "Risks" below).

**New dependency:** `flutter_local_notifications: ^19.0.0`. Deliberately
not pinned to the newest major (22.x at the time of writing) — the
newest requires a very recent minimum Dart SDK, and this project's own
`pubspec.yaml` only guarantees `>=3.3.0`. Version 19 is over a year old,
widely used, and has every API this feature needs
(`requestNotificationsPermission()`, `.show()`), so it's the safer
default until someone confirms what Flutter/Dart SDK is actually
installed locally — bumping the constraint later, if wanted, is a
one-line change.

**New Android permission:** `POST_NOTIFICATIONS` (`AndroidManifest.xml`)
— required on Android 13+ before an app can show *any* notification.
Declaring it only makes requesting it possible; it's still requested
explicitly (see below), not silently assumed. Nothing else was added to
the manifest — no `SCHEDULE_EXACT_ALARM`, no boot receiver — because
those are only needed for *scheduled* notifications, which this isn't.

**New file:** `lib/services/notification_service.dart`. A small static
wrapper around the plugin — `initialize()`, `requestPermission()`,
`show()` — so nothing else in the app imports the plugin directly.
Every method is wrapped in a try/catch that fails silently: a
notification not showing must never be able to crash the timer, the
task list, or anything else. `show()` always reuses the same
notification ID on purpose, so a new Focus/Break completion replaces the
last one in the tray instead of piling up.

**Where it's wired in:**
- `main.dart` — `NotificationService.initialize()` at startup (sets up
  the plugin/channel only; does not prompt for permission).
- `settings_screen.dart` — a new "Focus session notifications" row in
  the existing "Focus Mode" section (same `_Row`/`_toggleBtn` pattern as
  every other setting here). Turning it on is also the moment
  `requestPermission()` is called — Android's own guidance is to ask in
  context, not unprompted at launch, so this is the first point in the
  app where asking makes sense. If the OS permission ends up denied, a
  toast says so; the app does not treat that as an error.
- `focus_screen.dart`'s `_tick()` — the exact method already logging the
  focus session and showing the existing in-app toast on natural
  completion. The notification call sits right next to that toast,
  gated on `store.settings.notificationsEnabled`, and does nothing if a
  session is ended early via the manual "Complete" button (`_complete()`)
  since the user is already looking at the app in that case — the toast
  alone is enough there, same as before.

**New `UserSettings` field:** `notificationsEnabled` (`bool`, default
`true`) — same safe, additive pattern as `Task.postponedCount` from
Feature 2: a `fromJson` fallback (`?? true`), no `_migrateData` step and
no `kMeridianDataVersion` bump needed, because `UserSettings` is a single
object deserialized in one place, not a list of many records — every
other field on this model already relies on exactly this same fallback
pattern.

**Verification performed** — same manual-review method as every prior
entry in this file, with one important difference spelled out below:
- Confirmed `@mipmap/ic_launcher` (used as the notification icon) exists
  in every density folder under `android/app/src/main/res/`.
- Confirmed the project's `compileSdk`/Java 17/AGP 8.3.2/Kotlin 1.9.22
  setup is comfortably recent enough for both the permission API and the
  package version chosen — no other `build.gradle` changes were needed.
- Confirmed every direct `UserSettings(...)` construction in the project
  (there are exactly four, all in `domain.dart` itself) supplies the new
  required field — nothing elsewhere in the codebase builds a
  `UserSettings` by hand.
- Same brace/paren/bracket balance and full-project relative-import
  checks as every prior change, on every file touched this round.

**What could *not* be verified, and is different in kind from every
earlier check in this file:** everything above confirms the *Dart* code
is internally consistent. It cannot confirm the plugin's generated
native Android code actually links correctly, that the permission dialog
behaves as expected on a real device, or that `flutter pub get` resolves
cleanly against whatever Flutter SDK is actually installed. **Feature 6
needs an actual `flutter pub get && flutter run` on a real Android
device (or emulator) before it can be considered done** — this is a
stronger version of the standing recommendation every earlier feature in
this file has carried, not a new one.

---

## Features Added By Ghadi

- **Theme system migration (bug fix).** Finished the in-progress rewrite
  of `lib/theme/app_theme.dart` that had been left uncommitted, so every
  screen and widget in `lib/` compiles against the new palette instead of
  ~25 files still calling removed/renamed color tokens. Added back
  `primaryInk`, `scrim`, and the four `period*` fields (removed in the
  rewrite but still needed by existing screens/widgets). Removed the
  now-unreferenced duplicate `lib/widgets/analytics/analytics_charts.dart`.
  Fixed five broken `../../` import paths in
  `lib/analysis/analytics_charts.dart` (pre-dates the theme rewrite, but
  also blocked compilation). Full before/after token mapping is under
  "This Session's Work" above.
- **Feature 5: Productivity Insights.** New file
  `lib/analysis/insights_analysis.dart` (`ProductivityInsightsCard`);
  wired into `lib/screens/analytics_screen.dart` (one import line, one
  card, following the exact pattern already established for Features
  1–4). Full description under "This Session's Work" above.
- **Feature 6: Notifications & Reminders (first case).** New file
  `lib/services/notification_service.dart`; new `POST_NOTIFICATIONS`
  permission; new `flutter_local_notifications` dependency; new
  `UserSettings.notificationsEnabled` field; wired into `main.dart`,
  `settings_screen.dart`, and `focus_screen.dart`. Scoped to immediate
  Focus/Break-complete notifications only — no scheduling. Needs a real
  device run before it's done; see "This Session's Work" above and
  "Risks" below.

---

## Change Log

1. **Theme system migration (bug fix).** Migrated every screen/widget in
   `lib/` from the old `MeridianColors` API (`accent`, `accentStrong`,
   `accentInk`, `accentSoft`, `accentDeep`, `borderStrong`, `borderTrack`,
   `scrim`, `periodNight`/`periodMorning`/`periodAfternoon`/`periodEvening`,
   `ThemeModePref`) to the new one — previously only `main.dart` and
   `app_shell.dart` had been migrated. Added `primaryInk`, `scrim`, and
   the four `period*` fields back to `MeridianColors` in
   `theme/app_theme.dart`. Removed the unreferenced duplicate
   `lib/widgets/analytics/analytics_charts.dart`. Fixed five broken
   `../../` import paths in `lib/analysis/analytics_charts.dart`. Files
   touched: `theme/app_theme.dart`, `lib/analysis/analytics_charts.dart`,
   every file under `lib/screens/` and `lib/widgets/` that referenced a
   renamed color token, and `lib/screens/settings_screen.dart` for the
   `ThemeModePref` → `ThemeMode` rename. `main.dart` and `app_shell.dart`
   were already correct and were not touched.
2. **Feature 5: Productivity Insights.** Added
   `lib/analysis/insights_analysis.dart` (`ProductivityInsightsCard`).
   Wired into `lib/screens/analytics_screen.dart`: one new import line,
   one new card inserted after Feature 4's, using the same
   `// --- FEATURE N: ... ---` comment convention already established by
   Features 1–4. No other files touched for this feature.
3. **Feature 6: Notifications & Reminders (first case).** Added
   `flutter_local_notifications: ^19.0.0` to `pubspec.yaml`. Added
   `android.permission.POST_NOTIFICATIONS` to `AndroidManifest.xml`.
   Added `lib/services/notification_service.dart`
   (`NotificationService.initialize()` / `.requestPermission()` /
   `.show()`). Added `UserSettings.notificationsEnabled` (`bool`,
   default `true`) to `models/domain.dart`, following the same additive
   `fromJson` fallback pattern as `Task.postponedCount`. Wired in:
   `main.dart` (`initialize()` at startup), `settings_screen.dart` (new
   toggle row in the "Focus Mode" section; also requests the OS
   permission when turned on), `focus_screen.dart` (`_tick()` — shows a
   notification when a Focus or Break phase completes naturally, gated
   on the new setting). Scoped to immediate notifications only —
   scheduled/future-dated reminders are separate, larger, future work.
   **Needs a real `flutter pub get && flutter run` on an Android
   device before this feature can be considered done** — see "This
   Session's Work" and "Risks".
4. **Debugging + performance pass (this session).** A real build was
   attempted on Windows since the last entry and left behind hard
   evidence in `android/.gradle/kotlin/errors/` (now removed — see
   below): a Kotlin daemon crash (`IllegalArgumentException: this and
   base files have different roots`) caused by the project living on a
   different drive letter (`D:`) than the pub-cache (`C:`), and — the
   actual blocker — a missing Core Library Desugaring config that
   `flutter_local_notifications` 19.x requires to even start compiling
   (`:app:checkDebugAarMetadata` failure). Fixes and findings:
   - `android/app/build.gradle`: added `coreLibraryDesugaringEnabled
     true` + `coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.1.4'`.
     Without this the Android build cannot succeed at all with Feature 6
     in the dependency graph. This was the top priority fix.
   - `lib/widgets/planner/plan_my_day_modal.dart`: the priority
     `TextField`s had no `onChanged`, so the "Continue" button's
     `_priorityCtrls[0].text.trim().isEmpty` check was only ever
     evaluated once, at the first (empty) build. Typing a priority never
     rebuilt the sheet, so the button stayed permanently disabled — the
     whole Plan My Day wizard was stuck on step 1. Added
     `onChanged: (_) => setState(() {})`.
   - `lib/store/persistence.dart`: `jsonEncode`/`jsonDecode` of the full
     `MeridianData` blob ran inline on the UI isolate on every save
     (i.e. on every task/habit/focus mutation, after the 150ms debounce)
     and on every cold start. Cost scales with total saved history, which
     only grows — matches "the app feels slower the more I use it."
     Moved both through `compute()` to a background isolate.
   - `lib/app_shell.dart` + `lib/screens/focus_screen.dart`: `AppShell`
     did `context.watch<MeridianStore>()` purely to read `store.toast`,
     which reconstructed the non-const `DashboardScreen`/`PlannerScreen`/
     `FocusScreen` widgets on *every* store mutation regardless of which
     tab was active. Extracted toast rendering into its own `_ToastLayer`
     widget with its own subscription. Separately, `FocusScreen`'s
     `Timer.periodic(250ms)` called `setState` unconditionally, which —
     because `IndexedStack` keeps every tab mounted — kept rebuilding the
     entire Focus screen four times a second even while the user was on
     a different tab for the whole duration of a session. Added an
     `isActive` flag (`AppShell` passes `_index == 2`) so the tick only
     triggers a rebuild while Focus is the visible tab; time-tracking and
     session-completion logic still run correctly in the background.
   - `lib/widgets/resources/resource_card_widget.dart`: used
     `context.watch<MeridianStore>()` even though `store` was only ever
     read inside `onLongPress`/`onPressed` callbacks — every resource
     card (each holding a decoded image) was rebuilding on every
     unrelated store change app-wide. Changed to `context.read`.
   - `lib/theme/app_theme.dart`: `ThemeController` didn't observe system
     brightness itself, so when `ThemeMode.system` was active and the OS
     flipped dark/light, only `main.dart`'s own observer fired (rebuilding
     just the outer `MaterialApp` shell) — every screen that reads
     `context.watch<ThemeController>().colors` directly stayed on the
     stale color scheme until an unrelated rebuild happened to refresh
     it. `ThemeController` now mixes in `WidgetsBindingObserver` itself
     and calls `notifyListeners()` on `didChangePlatformBrightness()`
     when in system mode.
   - Removed `android/.gradle/` (4.6MB of another machine's build cache,
     including the Kotlin crash logs above) and the committed
     `android/local.properties` (hardcoded to a different developer's
     Windows paths: `C:\Users\Victus\...`, `D:\C\flutter`) from the
     project — neither should ever be shipped or version-controlled, and
     having no `.gitignore` is how they ended up tracked. Added a
     standard Flutter/Android `.gitignore`.
   - Full manual review (imports, brace/paren balance, package-vs-pubspec
     cross-check) across all 42 `lib/` files found no other broken
     references. No Flutter/Dart SDK was available in this environment to
     run `flutter analyze` or a real build — the drive-letter Kotlin
     issue noted above is an environment/workspace issue on whichever
     Windows machine builds this next (keep the project and Flutter SDK/
     pub-cache on the same drive letter), not something fixable from
     inside the repo.

---

## Update — Localization + App Blocking Received (Outside This Log)

Between the previous entry and this one, localization (Arabic/English/
Russian via `lib/l10n/`, `lib/utils/bidi_utils.dart`,
`lib/widgets/shared/mrd_bidi_text_field.dart`) and Feature 7 — App
Blocking (`lib/services/app_blocking_service.dart`,
`lib/screens/app_selection_screen.dart`, the Kotlin
`MeridianAccessibilityService`, and the `POST_NOTIFICATIONS`/
`QUERY_ALL_PACKAGES`/accessibility-service manifest entries) were added
directly by the project owner, independent of this log — the same way
Features 1–6 were. This session picks up from that point to find and fix
what was blocking compilation.

### This Session's Work — Bug Fixes

**No Flutter/Dart SDK or network access was available in this
environment**, same as every prior entry in this file — everything below
is careful manual review, not a compiler run.

1. **Three files imported the localization class from a removed
   synthetic package.** `lib/main.dart`, `lib/app_shell.dart`, and
   `lib/screens/settings_screen.dart` all had
   `import 'package:flutter_gen/gen_l10n/app_localizations.dart';`. That
   synthetic-package mechanism was deprecated and then fully removed from
   Flutter starting with the 3.32 stable line — `package:flutter_gen`
   no longer exists to resolve, regardless of what Flutter/Dart SDK is
   installed locally. Meanwhile the actual generated-style output already
   lives directly in the repo at `lib/l10n/app_localizations.dart` (plus
   `_ar.dart`/`_en.dart`/`_ru.dart`) — the standard non-synthetic
   location, matching `l10n.yaml`'s `arb-dir: lib/l10n`. Fixed by
   pointing all three imports at that real location instead
   (`'l10n/app_localizations.dart'` from `lib/`,
   `'../l10n/app_localizations.dart'` from `lib/screens/`). No dependency
   or `l10n.yaml` change needed — this was purely an import-path bug.
2. **Ten `l10n.<getter>` calls in `settings_screen.dart` had no matching
   getter anywhere.** `localization`, `focusDuration`, `minUnit`,
   `breakDuration`, `notifications`, `taskReminders`,
   `taskRemindersSub`, `habitReminders`, `dailyPlanning`, and
   `dailyPlanningSub` were referenced (Localization section title, the
   Focus Mode duration/unit labels, and the Notifications section title +
   its three reminder rows) but were never added to `app_en.arb` /
   `app_ar.arb` / `app_ru.arb`, nor to the abstract `AppLocalizations`
   class or its three locale subclasses — every one of the ten would
   have been an "isn't defined" error. Added all ten as plain strings
   (no placeholders needed) to all three `.arb` files and all four
   generated-style `.dart` files, by hand, following the exact pattern
   every existing key already uses in each file — since there's no SDK
   here to actually run `flutter gen-l10n` and regenerate these from the
   `.arb` source of truth, that's still the recommended follow-up once
   this is pulled onto a machine with Flutter installed, to confirm the
   hand-written getters match what the real tool would have produced.

**Verification performed** — same method as every prior entry: repo-wide
brace/paren/bracket balance on every file, every relative import checked
against the filesystem, every `l10n.<x>` call site cross-checked against
all four localization files and all three `.arb` files, every `c.<x>`
(`MeridianColors`) call site across all of `lib/` cross-checked against
the theme's actual field list (found clean — no leftover pre-rewrite
tokens anywhere), and the App Blocking Dart/Kotlin boundary checked for
matching method names and payload keys (`checkPermission`,
`openSettings`, `getInstalledApps`, `syncSession`, `cancelSession`;
`package`/`name`/`icon`) — all consistent.

**Still recommended, independent of this log** — same standing
recommendation every entry here has carried: run
`flutter pub get && flutter analyze` (and ideally `flutter gen-l10n`
specifically, to confirm the hand-written localization getters above
match) on a real machine as the first step.

### Follow-up — `flutter analyze` run confirmed the fix

The project owner ran `flutter analyze` on a real machine after pulling
the two fixes above: zero errors, one `info`-level `unnecessary_import`
lint on `lib/services/app_blocking_service.dart`'s `import
'dart:typed_data';` — `Uint8List` is already re-exported by
`package:flutter/services.dart`, imported on the line above it. Removed
the redundant import; `Uint8List` still resolves the same way. This is
the first entry in this file backed by an actual compiler run rather
than manual review alone.

---

## Update — Full Localization Pass (AR/EN/RU)

Prior to this session, localization covered roughly 20 strings (Settings'
own labels and the bottom nav). This session extended it to effectively
every user-facing string in the app: all 10 screens, every modal
(task/habit/resource create-edit, Plan My Day, End of Day Review), all 5
analytics cards under `lib/analysis/`, every shared widget that renders
text (buttons, checkboxes, toasts, confirm dialogs, empty states), and —
importantly — the two places that generate real user-visible *data*
rather than static UI chrome:

- **`store/plan_my_day.dart`**: the "Break"/"Focus block" task titles and
  "Generated by Plan My Day" note it writes into saved `Task` records are
  now passed in from the caller (`plan_my_day_modal.dart`, which has a
  `BuildContext`) instead of being hardcoded English baked into the data.
- **`services/notification_service.dart`**: native OS notification
  title/body text (task/habit/daily-planning reminders) can fire from a
  background/scheduled context with no `BuildContext` at all. Gave it the
  same static `l10n` field + `setLocalizations()` pattern used below for
  the store, kept current by `AppShell.build()`, with an English fallback
  if a schedule call ever races ahead of the first call.
- **`store/meridian_store.dart`**: same problem for its ~13 toast
  messages (add/delete/complete task, habit, resource, reflection saved,
  data reset, etc.) — none of its methods have a `BuildContext`. Same
  fix: a static-ish `l10n` field set by `AppShell.build()` each rebuild
  (including on locale change), `l10n?.key(...) ?? 'English fallback'` at
  every call site.
- **`constants.dart`**: `kCategories`/`kPriorities` `.label` fields are
  `const` (compile-time), so they can't hold a `BuildContext`-dependent
  value. Left the color data on the const maps as-is and added
  `categoryLabel(context, cat)` / `priorityLabel(context, pri)` /
  `taskStatusLabel(context, status)` functions instead; every call site
  that previously read `.label` now calls these.
- **`planner_screen.dart`**: the weekday/month name arrays used to build
  the date header were hand-rolled English (`'Monday'`, `'January'`,
  ...). Replaced with `intl`'s `DateFormat('EEEE, MMMM d', localeCode)`,
  which is already available as a direct dependency and picks up correct
  weekday/month names for all three locales automatically via the
  `GlobalMaterialLocalizations` delegate already registered in
  `main.dart`.
- Deliberately left **not** localized: the app's own name ("Meridian",
  in the app bar and `MaterialApp.title`), and the language-picker's own
  entries ("English" / "العربية" / "Русский") — both are standard
  practice to keep in their own script regardless of the active locale,
  not oversights.

**Missing-key gap found and fixed along the way**: several delete
confirmation dialogs (`showMrdConfirm`) didn't pass an explicit
`confirmLabel`, silently falling back to the dialog helper's own
hardcoded default `'Delete'`. Made `confirmLabel` nullable with the
fallback resolved from `l10n.deleteLabel` inside `confirm_dialog.dart`
itself (which does have a `BuildContext`, unlike the store), and added
explicit `confirmLabel: l10n.deleteLabel` at every call site that was
missing it.

**Scale**: ~325 translation keys total (up from 20), across
`app_en.arb` / `app_ar.arb` / `app_ru.arb` and the four
`app_localizations*.dart` files. ~35 of those are parameterized
(interpolated values like task titles, counts, minutes) rather than
plain strings.

**Verification performed** (same no-SDK manual-review method as every
prior entry, plus one addition): the usual repo-wide brace/paren/bracket
balance and import-path check, PLUS a script cross-checking every single
`l10n.<key>` call site anywhere in `lib/` (325 distinct usages) against
the generated abstract `AppLocalizations` class — zero undefined
references. All three `.arb` files parse as valid JSON with matching key
counts (400 entries each, including `@key` placeholder metadata for the
parameterized strings).

**Still recommended**: `flutter pub get && flutter analyze`, and
specifically `flutter gen-l10n` to confirm the hand-written
`app_localizations*.dart` files above match what the real code-gen tool
would produce from the `.arb` source of truth — same standing
recommendation as every prior entry in this file, since there's still no
Flutter/Dart SDK available in the environment these changes were made
in.

---

## Update — Dashboard Taken to 10/10

Went through the Dashboard screen item by item against a self-assessed
gap list, implementing each one individually rather than as one big
sweep:

1. **Live clock/greeting** — `DashboardScreen` converted from
   `StatelessWidget` to `StatefulWidget` with a once-a-minute `Timer`
   driving `setState`, so the greeting, date/time header, and the
   evening-only Day Review button all stay correct if the screen is left
   open across an hour boundary instead of only updating on the next
   unrelated rebuild.
2. **"View all" on the Habits section** — matches the existing "Open
   planner" action on the Today's Schedule section; added
   `onGoHabits` callback threaded from `AppShell`.
3. **"+N more" overflow indicators** — tasks beyond the 4 shown get a
   tappable "+N more" row (→ Planner); habits beyond 4 show 3 real cards
   + a "+N more" tile so the grid stays a clean 2×2 instead of a lopsided
   5th cell.
4. **Empty-habits action** — swapped the plain "No habits yet." text for
   the same `EmptyState` (title/subtitle/action button) pattern the Tasks
   section already used, wired to open the habit-creation modal directly.
5. **Smarter habit ordering** — habits not yet done today sort first,
   ranked by streak length (most to protect first); already-done habits
   sink to the bottom (and are first to fall into "+N more" on overflow).
6. **Name personalization** — added `userName` to `UserSettings` (nullable,
   backward compatible) plus a new "Profile" section in Settings. Greeting
   becomes "Good morning, {name}." when set, falls back to the generic
   greeting otherwise.
7. **Add-name banner (deliberately not onboarding)** — discussed forcing
   a name-entry screen on first launch vs. a soft, dismissible in-context
   nudge; went with the latter, since a mandatory field up front cuts
   against "no account, everything local" being the app's whole pitch,
   and adds friction before someone's seen any value. Added
   `nameBannerDismissed` to `UserSettings` so a "No thanks" tap hides it
   permanently; filling in a name from the banner's own lightweight
   dialog also makes it disappear naturally (no separate flag needed for
   that path).
8. **Overdue indicator on the Up Next card** — the card's border tints
   toward `c.danger` and a small "OVERDUE" pill (same visual language as
   the existing "URGENT" priority pill on the Planner) appears once the
   task's start time has passed, using the same live timer from item 1
   so it clears/appears in real time without user action.
9. **Stat-card trend + tap-through** — `StatCard` (shared widget, also
   used on the Analytics screen) gained optional `onTap`/`trendText`/
   `trendUp` params. Dashboard's Focus-time and Score cards now link to
   Analytics and show an up/down arrow with a "+Xm vs yesterday" /
   "+X vs yesterday" caption, computed from `store.history` (already
   cached, 28 days). Score's day-over-day comparison reimplements
   `_computeStats`'s productivity-score formula against `HistoryDay`
   fields (`_historyDayScore` in `dashboard_screen.dart`) since
   `HistoryDay` doesn't store a precomputed score of its own — worth
   keeping in sync manually if that formula ever changes in
   `meridian_store.dart`.

Added ~20 more localization keys along the way (name/profile fields,
overflow/trend/overdue strings) — same three-language treatment as
everything else, verified with the same usage-cross-check script as
every prior localization entry (all defined, zero dangling references).

**Scope note for next time:** Website Blocking and the "Personalized AI
Routine" feature are still fully unimplemented (0/10, as before) — out
of scope for this pass, which was specifically about raising existing
features to their best possible version rather than adding net-new ones.

---

## Update — Planner Taken to 10/10

1. **`postponedCount` data-loss bug (also present in Tasks screen).**
   Both screens' task-edit `onSave` rebuilt a brand-new `Task(...)` from
   the modal's form data instead of calling `.copyWith(...)` on the
   current task the callback actually receives — silently zeroing
   `postponedCount` on every edit. This wasn't just a missing field:
   `updateTask` in `meridian_store.dart` itself increments
   `t.postponedCount + 1` when a date moves later, so the whole feature
   depends on callers passing through the real current value. Fixed both
   call sites to use `current.copyWith(...)`.
2. **Tasks between midnight and 5 AM were completely invisible** on the
   grid (`_plannerStartHour` was 5) — not rendered, not editable/draggable
   there, and the empty state could claim "Your day is clear" while one
   existed. Changed to a full 0–24 range; the existing "now" line
   visibility check and the one-time auto-scroll-to-now both already
   computed off relative offsets, so this needed no other changes and
   also fixed the "now" line being invisible before 5 AM.
3. **Date picker on tap** — the date pill now opens `showDatePicker` to
   jump to any date directly, instead of only ±1-day arrows.
4. **Swipe-to-change-day** — added `onHorizontalDragEnd` over the grid
   (velocity-thresholded so small incidental horizontal motion doesn't
   trigger it); coexists with the vertical hour scroll and the
   long-press-based block dragging without conflict since they're
   different gesture families.
5. **"Jump to now" floating button** — appears once the scroll position
   drifts far enough from the current-time line (today's view only);
   animates back to the same offset the one-time auto-scroll uses.
6. **Drag-and-drop no longer rejects overlaps.** It used to always
   snap back + show an error toast on any collision, even though
   `_layoutColumns` already renders overlapping tasks side by side and
   manually typing an overlapping time in the edit modal has always been
   allowed — blocking only the drag path was an inconsistency, not a real
   guardrail. The red tint during the drag gesture itself stays as a
   heads-up.
7. **Category color-only accessibility gap.** Added an `icon` field to
   `CategoryInfo` (constants.dart) — task blocks on the grid now show a
   small per-category icon (with a tooltip) next to the title, so
   category is distinguishable by shape as well as color.

## Update — Plan My Day Taken to 10/10

1. **Schedule could start in the past.** Generation always began at
   9 AM regardless of the actual time — using this after 9 AM for
   *today* meant every block landed before "now" and showed as overdue
   the instant it was created (this is exactly the overdue indicator
   added to Dashboard/Planner earlier in this log). `generateScheduleFromInputs`
   now takes an optional `notBeforeMinutes`; the modal passes the current
   time (rounded up to the next 15 minutes) only when `targetDate` is
   today, so future-day plans are unaffected. Added a clear message on
   the review step for the edge case where this leaves no room at all
   (very late in the day, or the remaining hours fully booked) instead of
   an unexplained empty list.
2. **The 30-minute-per-priority floor could silently exceed the stated
   time budget** with no indication why. Left the floor in place (a
   10-minute "focus block" isn't very usable) but added a live warning
   under the hours slider whenever `priorities × 30min` exceeds what's
   set, so the trade-off is visible before generating, not just
   discoverable by eyeballing the review step afterward.
3. **Every generated block was hardcoded to `TaskCategory.study`**
   regardless of what the priority actually was, which skewed
   Analytics' category-distribution chart for anyone whose priorities
   weren't study-related. Added a compact per-priority category picker
   (reusing the same icons added for Planner's accessibility fix) in the
   wizard; `generateScheduleFromInputs` takes a parallel `categories`
   list now, defaulting to Work if omitted.
4. **Commitments the parser couldn't understand were dropped with zero
   feedback** (e.g. "Meeting at 3" — no end time) — not blocked off, and
   the generator could schedule directly over one. Added
   `findUnparsedCommitmentLines()` and a live warning under the
   commitments field listing exactly which lines weren't understood, so
   they can be fixed before generating instead of only surfacing as an
   unexplained overlap later.
5. **Hard cap of exactly 3 priority fields.** The wizard now supports
   adding up to 6 (an "Add another priority" button, plus a small remove
   button on every priority after the first, which stays mandatory).

Added ~15 more localization keys across both features (same three-language
treatment, verified with the same usage-cross-check script as every prior
entry — zero dangling references throughout).

---

## Update — Tasks Taken to 10/10

1. **Duration field had no validation.** `int.tryParse(_durationCtrl.text) ?? 30`
   silently substituted 30 minutes for empty/non-numeric/zero/negative
   input — unlike every other field in the same modal (title, link),
   which all show a real error. Now validates 1–1440 minutes and shows
   `taskInvalidDurationError` otherwise, with the same live-clears-on-edit
   behavior the other fields already have.
2. **`TaskStatus.inProgress` was invisible.** A task manually set to "In
   progress" rendered pixel-identical to a plain "To do" task in the
   Tasks list — same color, same everything — even though the status
   dropdown in the edit modal lets you pick it. Added an "In progress"
   badge (same visual language as the existing category/priority badges)
   to `_TaskRow`. Found the identical gap in Planner's time blocks while
   in this area and fixed it there too, with a small icon instead of a
   full badge to fit the tighter space (shown in non-compact blocks only,
   same rule the existing "URGENT" badge already follows).
3. **Category dropdown in the edit modal was text-only**, inconsistent
   with the icon+color treatment added everywhere else this session
   (Planner blocks, Plan My Day's category picker). Each dropdown item
   now shows the category's icon next to its name.
4. **No text search on the Tasks screen**, which is the one place in the
   app that aggregates every task across every date — only status/
   category/date filters existed. Added a bidi-aware search field (title
   substring match, case-insensitive) that composes with the existing
   filters rather than replacing them.

Added 3 more localization keys (duration error, in-progress label reused
from the existing `statusInProgress` key, search hint) — usage-cross-check
script confirms zero dangling references across all 347 `l10n.*` call
sites in the app so far.

---

## Update — Habits Taken to 10/10

1. **Completion-rate stat was misleading for new habits.** The 30-day
   completion percentage always divided by a flat 30, regardless of how
   long the habit had actually existed — a brand-new habit completed
   perfectly for its first 3 days showed "10%" (3/30), reading as a
   failing habit on day one. `Habit` had no creation-date field at all,
   so this couldn't be fixed without adding one. Added `createdDate`
   (backfilled to 45 days ago for any habit saved before this field
   existed, so existing habits' numbers don't change), and the
   completion-rate denominator is now `min(30, days since creation)`.
   Manually re-verified every `Habit(...)`/`NewHabit(...)` construction
   site in the codebase (5 total) to make sure none were missed, since
   this added a new required field.
2. **Setting a per-habit reminder while the global "Habit reminders"
   toggle in Settings is off did nothing, silently.** `updateHabit`
   already only schedules a reminder when that toggle is on, so the
   per-habit time picker in the habit modal could produce a reminder that
   would never fire, with zero indication of why. Added a warning under
   the reminder picker in that case, with a one-tap "Turn on" action that
   flips the Settings toggle right there without leaving the modal.
3. **No way to pause a habit without deleting it and losing its history**
   — the only previous option for a seasonal or temporarily-on-hold habit.
   Added a `paused` field plus a pause/resume button on each habit card.
   A paused habit: disappears from the Dashboard's "what's left today"
   list, stops sending reminders immediately regardless of the global
   toggle (and any previously-scheduled reminder is explicitly cancelled,
   not just left to lapse), and moves to a separate, slightly-dimmed
   "Paused" section at the bottom of the Habits screen — logs, streak,
   and completion history are all untouched, and resuming picks back up
   exactly where it left off.

Added 5 more localization keys (reminders-off warning, pause/resume
labels, paused-section header) — usage-cross-check confirms zero
dangling references across all 351 `l10n.*` call sites.

---

## Update — Focus Mode Taken to 10/10

1. **Skipping a phase discarded partial focus time with no record at
   all.** `_skip()` never called `store.logFocusSession`, unlike
   `_complete()` — 20 real minutes of focus work could vanish from the
   stats entirely just because the person tapped "Skip" instead of
   "Complete" once a task was done early. Now computes elapsed time the
   same way `_complete()` does and logs it (against the active task, or
   as a free session) before switching phases — only for the focus
   phase, since breaks were never tracked as focus minutes.
2. **No confirmation before "Reset" during an active session** — every
   other destructive action in the app (delete task/habit, reset all
   data) confirms first; this one silently zeroed real progress. Added a
   confirm dialog, but only when there's actually something to lose — a
   fresh, untouched timer resets immediately with no dialog, so it
   doesn't nag on the common case.
3. **Custom focus/break duration fields had no upper bound** (99999
   minutes was valid input), inconsistent with Settings' own pomodoro
   sliders (capped at 180 min focus / 60 min break). `_customField` now
   takes `min`/`max` and clamps silently — no error UI, since there isn't
   room for one next to this compact inline field, and clamping doesn't
   fight the user's typing since the field is uncontrolled
   (`initialValue`-based, not backed by a live controller).
4. **No explicit handling for the app being suspended in the
   background.** The countdown is wall-clock based (`_endAt`), so it's
   correct in principle regardless of elapsed background time, but if
   Android suspends the isolate's timers while backgrounded (common
   after a while under battery optimization), the periodic timer that
   would normally self-correct every 250ms just doesn't fire until
   foregrounded again. Added `WidgetsBindingObserver` and force one
   immediate `_tick()` reconciliation on `AppLifecycleState.resumed`, so
   the displayed time is never stale even for a moment after returning.

No new localization keys beyond the reset-confirmation dialog text (2
keys) — the other three fixes were pure logic/behavior changes. Usage
cross-check confirms zero dangling references across all 353 `l10n.*`
call sites in the app so far.

---

## Update — Resources Taken to 10/10

1. **The cover image was mandatory** — couldn't save a resource without
   picking one, even though the app already had a graceful fallback
   design (`_ImageFallback`) that was only ever used for a *failed*
   image load, never proactively for "no image at all." Made the image
   fully optional: `_submit()` no longer requires it, the card widget
   shows `_ImageFallback` directly when `imagePath` is empty, and added
   a small remove (×) button on the image preview so someone who picked
   one can go back to image-free. Verified file cleanup stays correct in
   every direction — deleting a resource already correctly removed its
   image file (confirmed while investigating, not a bug), and clearing
   an existing image now cleans up the old file too, not just the
   "replaced with a different image" case that already worked.
2. **The URL wasn't validated until someone actually tried to open the
   resource** — title and image were checked immediately at save time,
   but a malformed URL only surfaced as an error the next time the
   resource was opened, possibly weeks later. Moved the exact same
   lenient check `resource_card_widget.dart` already uses when opening
   (auto-prepend `https://` if missing, just needs something that
   resolves to a domain) to save time as well — deliberately the same
   rule, not a stricter one, and only checked on submit like the title
   field, not on every keystroke.
3. **No text search**, and — found while adding it — **no way to add a
   resource at all once the list wasn't empty**, since the only "Add"
   button lived inside the empty state. Added a bidi-aware search field
   (shown once there's at least one resource) plus an always-visible
   floating action button for adding, with a distinct "no results" empty
   state separate from the "no resources yet" one.

Added 5 more localization keys — usage cross-check confirms zero
dangling references across all 354 `l10n.*` call sites in the app.

---

## Update — Settings Taken to 10/10

All three issues found in this pass were fixed together (the person
asked for all of them in one go rather than one at a time):

1. **"Reset all local data" quietly reset far more than it warned
   about.** The confirmation dialog only mentions tasks, habits, focus
   sessions, and reviews — but `resetAllData()` rebuilt the entire
   `MeridianData` via `createEmptyData()`, which also resets `settings`
   to `UserSettings.defaults()`. That silently wiped the person's name,
   language choice, custom pomodoro durations, every notification
   toggle, and their blocked-apps list, none of which the dialog ever
   mentioned. Now preserves `_data.settings` explicitly — only the
   content actually described in the dialog gets cleared.
2. **No stale-notification cleanup on reset.** `deleteTask`/`deleteHabit`
   already cancel that item's own scheduled reminder one at a time, but
   `resetAllData()` bypassed both of them by replacing the whole data set
   directly — so any already-scheduled task/habit reminder would keep
   firing later for something that no longer existed. Now explicitly
   cancels every task and habit reminder before clearing.
3. **"Week starts on" (Sunday/Monday) was a fully non-functional
   setting** — stored, with a complete toggle UI and a description
   promising it "Affects weekly views and reviews," but never actually
   read anywhere in the codebase. Analytics' "This week" filter always
   meant a fixed rolling 7 days regardless of this setting. Wired it in
   properly: "This week" is now the actual current calendar week so far
   (from whichever day is configured, inclusive of today), computed
   consistently across the task/focus stats, the habit-consistency
   calculation (previously relied on `HabitWithStats.last7`, a separate
   fixed rolling window — recomputed directly from logs over the same
   calendar-aligned range instead so the two can't disagree), and the
   chart subtitle text (was hardcoded "last 7 days," now says "this
   week" since the window length itself is no longer always 7).

Added 1 more localization key (the corrected chart subtitle) — usage
cross-check confirms zero dangling references across all 354 `l10n.*`
call sites in the app.

---

## Update — Native Android Build Fix (found via a real `flutter run`)

The person ran `flutter run` against the previous zip on their own
machine — the first time in this whole log that an actual Gradle build
ran, since this environment has no Android SDK to verify against
directly. It failed at `assembleDebug` with an AAPT2 resource-linking
error mentioning `description (attr) reference`.

**Root cause**: `android/app/src/main/res/xml/accessibility_service_config.xml`
(part of the App Blocking feature) set:
```xml
android:description="Meridian requires this service to intercept and block distracting apps during an active Focus session."
```
`android:description` on an `<accessibility-service>` element must be a
`@string` resource reference, not an inline literal — AAPT2 rejects a
literal there. This was a pre-existing bug in the original native
scaffold, not something introduced by any change in this log; it simply
couldn't be caught without a real Android build environment.

**Fix**: created `android/app/src/main/res/values/strings.xml` (didn't
exist before) holding the description as a proper string resource, and
pointed the accessibility config at `@string/accessibility_service_description`
instead of the inline text. Also swept the rest of `AndroidManifest.xml`
and `res/xml/` for the same literal-where-reference-expected pattern —
nothing else matched.

## Update — Backup/Restore Taken to 10/10

1. **Import-error messages were hardcoded English, never localized** —
   the one set of user-facing error text in the whole app that slipped
   through the earlier full localization pass, because
   `parseBackupFile()` is a pure function with no `BuildContext` to pull
   translations from, unlike everywhere else. Refactored `ImportResult`
   to carry a `BackupImportError` enum code instead of a raw string;
   `settings_screen.dart` (which does have a `BuildContext`) now maps
   each code to a localized message via `_backupErrorMessage()`.

Added 5 more localization keys for the backup error messages. Usage
cross-check confirms zero dangling references across all 359 `l10n.*`
call sites in the app.

2. **A backup never actually included resource images** — only each
   resource's `imagePath`, an absolute file path on the device that made
   the backup. Restoring on a different phone, after a fresh install, or
   after the app's storage was cleared meant every resource's cover image
   silently pointed at a file that no longer existed — the backup wasn't
   a full backup of what was actually saved. `buildBackup` now embeds
   each resource's image as base64 directly in the exported JSON;
   `parseBackupFile` decodes and writes them back out to fresh files on
   import (same directory and naming convention `resource_modal.dart`
   already uses for a newly-picked image). Both functions had to become
   `async` for the file I/O — updated their two call sites in
   `settings_screen.dart` accordingly. Failure is scoped per-resource:
   an image that can't be read/restored just leaves that one resource
   without an image (a valid state since the Resources-screen fix earlier
   in this log made images optional) rather than failing the whole
   export or import.

Backup/Restore + Persistence is now the ninth core feature at 10/10 in
this log — every core feature has now been through this pass.

---

## Update — Analytics Pass 1: Base Analytics + Feature 1

*(All nine core features are now 10/10. This starts the pass on
Analytics — the one section the Feature Conflict Check table left with
open items. Doing it as several smaller updates rather than one giant
one, same as every other feature above, since nothing here can be
compiler-verified — see "Risks.")*

This update closes **Discrepancy #3 and #4** from "Notes / Discrepancies
Found During Initial Analysis" (both were left deliberately unfixed back
then, "noted for whichever feature next touches Analytics' time ranges" —
that's now), and with them, the two open items against **Feature 1
(Advanced Productivity Progress)** in the Feature Conflict Check table: a
range-aware score, a range-aware category chart, and "planned vs actual
time."

1. **Discrepancy #3 — `HistoryDay.focusMinutes` silently dropped real
   Focus Mode session minutes for every day except today.**
   `store/history.dart`'s `_realDay` only ever counted completed tasks'
   planned `duration`; `store/meridian_store.dart`'s `_computeStats`
   (which powers Dashboard/Today) added real `FocusLogEntry` session
   minutes on top of that same task-duration base. Any day reached
   through Analytics' Week/Month toggle used the first, incomplete
   formula — under-reporting focus time relative to what Today showed,
   and making a real "planned vs actual" comparison impossible (the
   "actual" side wasn't actually actual). Rewrote `_realDay`/`_emptyDay`
   into one `_buildDay` that also takes each day's real session minutes
   (grouped from `focusLog` by `dayKey(DateTime.fromMillisecondsSinceEpoch(f.at))`,
   the same grouping `_computeStats` already uses for "today"), so the
   two formulas now genuinely match. `buildHistory` takes a second
   parameter, `focusLog`, for this — its one call site
   (`MeridianStore.history`) updated accordingly. Cache invalidation
   already covered this (`logFocusSession` goes through `_setData`,
   which invalidates `_historyCache`) — only the computation itself was
   incomplete, not the cache lifecycle.
2. **Discrepancy #4a — the "Productivity score" stat card always showed
   *today's* score, ignoring the Today/Week/Month toggle.** It read
   `store.stats.productivityScore`, a `DayStats` field that's
   today-only by definition. Every other stat card on the screen
   (focus time, completion rate, avg session) already reacted to the
   toggle; this one didn't. `analytics_screen.dart` now computes the
   score locally from the same `slice` as everything else, using the
   same weighted formula as `_computeStats` (70% completion of
   actionable tasks + 30% focus-time-vs-target), with the 240 min/day
   target scaled by the number of days actually in the range — so Week
   and Month aren't held to a single day's target.
3. **Discrepancy #4b — "Category distribution" always aggregated every
   task ever created, ignoring the toggle entirely.** Now scoped to
   `rangeDayKeys` (the exact set of day-keys `slice` covers, so it can
   never disagree with the rest of the screen about what "this week"
   means) via each task's `taskDate`. Subtitle changed from the static
   `allActiveTasksLabel` to a new range-aware
   `categoryBreakdownRangeLabel(range)` ("Tasks · Today" / "· this
   week" / "· last 28 days"). `allActiveTasksLabel` itself was left in
   place in all three `.arb` files and their generated
   `app_localizations_*.dart` — it's just unused now, not deleted;
   removing a translated string that something else might still
   reference somewhere felt like more risk than an unused getter is
   worth.
4. **Feature 1's "planned vs actual time" gap.** Added a third bar to
   `AdvancedProgressOverview` (`lib/analysis/analytics_charts.dart`):
   planned = sum of every task's planned `duration` whose `taskDate`
   falls in `rangeDayKeys`; actual = that range's `focusMinutes` (now
   correct, per fix #1 above). Percentage is actual/planned, clamped to
   100 (if someone logs more real focus time than they'd planned for,
   the bar reads "on track" at 100% rather than overflowing past it —
   the label itself still shows the real, uncapped numbers either way).
   New `plannedVsActualTimeLabel(planned, actual)` l10n key, added to
   all three languages plus their generated files. New small shared
   helper, `fmtDurationShort(mins)` in `utils/format_utils.dart` (`"Xh
   Ym"`), to stop hand-rolling that formatting at yet another call site.

**Also fixed while in this file:** `analytics_screen.dart` had
`import '../utils/format_utils.dart';` twice (harmless, but sloppy —
removed the duplicate since this pass was already touching every line
around it).

**Left open, still:** Feature 3 (Habit Commitment)'s weekly-vs-monthly
breakdown and missed-days count; a closer look at Feature 2 and
Feature 4, which scored higher but weren't re-reviewed this session;
Feature 5 (Insights) wasn't touched. Next update in this section should
pick one of those up the same way — see "Recommended Implementation
Order," which already put Feature 3 right after Feature 1.

**Verification status — same caveat as everywhere else in this log:**
manually re-read line by line, cross-checked against the exact
discrepancies this project's own analysis had already flagged, but
**not run**. `flutter analyze && flutter run` on a real machine remains
the first thing to do before trusting this further.

---

## Update — UI/UX Pass 1: Theme Not Following System + Frozen Title

*(Separate from the Analytics work above — this is the start of a
different pass, reviewing bugs a UI/UX pass on the running app surfaced.
Reported via a screenshot of the Settings screen: Theme was set to
"System," the user's phone was in system dark mode, but the whole screen
rendered in the Light palette. The same screenshot showed a second,
unrelated bug: the AppBar title read "Настройки" (Russian) while the
page body underneath — heading, labels, the Language field showing
"English" — was entirely in English.)*

### 1. Theme=System not picking up the OS's actual dark/light state

Reviewed everything already in place for this — and most of it check out:
- `ThemeController.isDarkMode` reads
  `WidgetsBinding.instance.platformDispatcher.platformBrightness` on
  every access when mode is `system` — correct, and not the bug.
- `AndroidManifest.xml`'s `<activity>` already declares `uiMode` in
  `android:configChanges` — so Android does *not* destroy/recreate the
  Activity on a system theme change; it hands the new configuration
  straight to the running Flutter engine. Also not the bug.
- `ThemeController` already observes `didChangePlatformBrightness()` (a
  prior session's fix, see "Theme system migration" above) and
  `notifyListeners()`s every screen that watches it.

What's still missing: the phone's Dark-mode toggle lives inside the
phone's own Settings app, not inside Meridian — so *changing it
necessarily backgrounds Meridian first*. `didChangePlatformBrightness()`
is not reliably delivered to an engine that's currently backgrounded on
real Android hardware (unlike on some emulators/dev setups, which is
presumably why this wasn't caught earlier) — so the OS-side switch
happens, but Meridian never hears about it, and keeps rendering whatever
brightness was true when it was last in the foreground, until some
unrelated rebuild happens to refresh it.

**Fix:** `ThemeController` now also overrides
`didChangeAppLifecycleState()` and re-notifies its listeners on every
`AppLifecycleState.resumed` (only while `_themeMode == ThemeMode.system`
— explicit Dark/Light picks are unaffected either way). Coming back to
the app now always re-reads the *current* platform brightness fresh,
closing the gap regardless of whether the missed-while-backgrounded
notification would ever have arrived on its own.

**Not fully verified — flagging honestly:** I don't have a real Android
device or a Flutter SDK in this environment, so I can't reproduce
"change system theme, background the app, resume it" myself. This fix
targets the most standard, well-documented cause of exactly this
symptom, and is a safe, additive change (it only ever calls
`notifyListeners()` — a no-op re-render if brightness turns out
unchanged). If it *doesn't* fully resolve it after testing on the real
device, the next diagnostic step is narrowing down *when* it fails:
toggle the phone's dark mode while Meridian is open and in the
foreground (does it flip live, immediately? — isolates whether the
underlying brightness read is even correct at all) versus toggling it
while backgrounded and then reopening the app (does *this* fix now cover
it?). That split would point at whether any further, more
device/OEM-specific investigation is needed.

### 2. AppBar title frozen in whatever language was active at navigation time

`app_shell.dart`'s `_openFullScreen(Widget child, String title)` resolved
`title` once, at the call site (e.g. `l10n.settings`), and handed the
plain, already-resolved `String` to `_FullScreenPage` — a
`StatelessWidget` with a fixed `title` field. The page's *body*
(`SettingsScreen`, `AnalyticsScreen`, `ResourcesScreen`) reads
`AppLocalizations.of(context)!` live in its own `build()`, so it always
reflects the current language — but the AppBar title above it, being a
frozen `String`, could never update again after the route was pushed.
Concretely: open Settings while the active language is Russian (title
resolves to "Настройки"), then change the Language field to English
*while still on that screen* — the body re-renders in English
immediately, but the AppBar keeps showing "Настройки" until the page is
closed and reopened. Exactly what the screenshot showed.

**Fix:** `_openFullScreen` now takes a `String Function(AppLocalizations)
titleBuilder` instead of a resolved `String`; `_FullScreenPage` calls it
with a fresh `AppLocalizations.of(context)!` inside its own `build()`,
so the title is exactly as reactive as the body already was. Updated all
four call sites (`onGoAnalytics` on the Dashboard, and the three AppBar
icon buttons for Analytics/Resources/Settings) from
`_openFullScreen(const XScreen(), l10n.xTitle)` to
`_openFullScreen(const XScreen(), (l10n) => l10n.xTitle)`.

**Verification:** manually re-read; brace/paren counts balance on both
files touched (`theme/app_theme.dart`, `app_shell.dart`); confirmed via
repo-wide grep that all four `_openFullScreen` call sites and the one
`_FullScreenPage` constructor call were updated consistently, with no
leftover references to the old `title:` parameter name. Not run —
`flutter analyze` on a real machine, same standing recommendation, this
time also worth actually reproducing the original repro steps (switch
language while a pushed screen is open) to confirm the title now updates
live.

### 3. "PROFILE" section was one field wearing a whole section's clothes

Reported directly, with a screenshot of just this one card: an uppercase
"PROFILE" header plus a bordered card, for a single "Your name" field —
flagged as unnecessary text/structure for one setting.

**Fix:** `_Section`'s `title` is now optional (`String?` instead of
`required String`) — when omitted, the uppercase header + spacing is
skipped entirely and only the bordered card renders. The Profile section
is now `_Section(c: c, children: [...])`, no `title:` at all. The field's
own label was also shortened from `l10n.yourNameLabel` ("Your name") to
the already-existing generic `l10n.nameLabel` ("Name") — no new l10n key
needed, it already existed and was already translated in all three
languages, just unused for this particular field. The description below
it ("Used to personalize greetings on the dashboard.") was left as-is —
only the section title and field label were called out as redundant,
and that line is the only place a first-time user learns *why* this
field exists at all. All six other `_Section`s on this screen
(Localization, Appearance, Focus Mode, Notifications, Your Data, About)
are unaffected — they still pass `title:` as before.

**Verification:** manually re-read; brace/paren counts balance;
confirmed via grep that all seven `_Section(` call sites on this screen
still resolve correctly (six with `title:`, one without) and that
`l10n.nameLabel` already existed, pre-translated, in all three `.arb`
files before this change — nothing new added to any of the six l10n
files this time. `profileTitle` and `yourNameLabel` are now unused (left
in place, not deleted — same reasoning as `allActiveTasksLabel` earlier
in this log). Not run.

### 4. Real Flutter overflow banner rendered inside a Planner task block

Reported with a screenshot: a task block on the Planner grid ("Break")
showed Flutter's own debug-mode "BOTTOM OVERFLOWED BY 4.0 PIXELS"
yellow/black striped banner, rendered directly over the task's text.

**Root cause, worked out from the numbers in `_buildTimeBlock`:** a task
block's height is `clampDouble((duration/60) * _hourHeight, 26.0,
double.infinity)` with `_hourHeight = 68`, and it switches from a
"compact" single-row layout (icon + title only, vertically centered — no
overflow risk, it has no second row) to a taller two-row layout (adds a
start–end time subtitle underneath) once `height >= 46`. Roughly costing
out what that second layout actually needs — ~18-20px for the icon/title
row, ~13-14px for the subtitle row, 1px of spacing between them, plus
7px+7px of container padding — lands at ~46-49px *before* real font
rendering/rounding is even accounted for. The `46` cutoff was drawn right
at that estimate, with essentially no safety margin — so any task whose
computed height landed just at or barely above 46 (a plain ~40-minute
task, nothing unusual — matches the repro, a task literally named
"Break") got the taller layout without quite enough room for it,
overflowing by a few pixels. Short tasks (under ~23 min, clamped to the
26px floor) always stay comfortably in the safe single-row layout, which
is exactly why the neighboring "drink water" / "eat ice" blocks in the
same screenshot rendered fine — they never approached the danger zone.

**Fix:** raised the cutoff from `height < 46` to `height < 56` (~49
minutes instead of ~40), giving roughly 10px of real breathing room
above the estimated content need. Trade-off: some medium-length tasks
(now up to ~49 minutes instead of ~40) show the simpler single-row
layout and lose the start–end time subtitle they could technically have
fit before — a minor information reduction, clearly worth it over a
visibly broken block. Full reasoning left as an inline comment at the
`compact` computation in `_buildTimeBlock` (`lib/screens/planner_screen.dart`).

**What this fix does *not* rule out:** a device with a larger
accessibility text-scale setting could still push the two-row layout's
real content height above even the new, safer cutoff — I couldn't
render this to measure real font metrics, so 56 is a reasoned estimate
with margin, not a value verified against actual layout output. If this
resurfaces specifically with large system font sizes, that's the next
thing to check.

**Verification:** manually re-read; brace/paren counts balance. Not
run — this is exactly the kind of bug that's easiest to confirm by
actually looking at a ~40-49 minute task block on a real device now
that the threshold moved, ideally at a couple of different accessibility
text-scale settings.

### 5. Hard crash on "Complete" in Focus Mode

Reported with two screenshots: a Focus session running with a task
selected ("download sth."), then tapping "Complete" threw Flutter to its
red error screen with a `DropdownButton` assertion failure — "There
should be exactly one item with [DropdownButton]'s value... Either zero
or 2 or more [DropdownMenuItem]s were detected with the same value."

**Root cause:** `focus_screen.dart`'s "Working on" `DropdownButton`
builds its `items` from `_incomplete` (today's tasks with completed ones
filtered out), but its `value` came from `_activeTask(todaysTasks,
incomplete)` — which searched the *unfiltered* `todaysTasks` list for
`widget.focusTaskId` and returned whatever it found there, completed or
not. `widget.focusTaskId` is a sticky selection that nothing ever
cleared. So: select a task, hit Complete → `_complete()` marks it
`TaskStatus.completed` → next rebuild, `_activeTask` still finds it (by
id, in the unfiltered list) and hands it back as `activeTask` → the
Dropdown gets a `value` that no longer exists in its own `items` (which
correctly excluded it) — precisely the invariant that assertion exists
to catch. Zero matches, not a duplicate-id case, despite the assertion
message mentioning both possibilities generically.

**Fix:** `_activeTask` now searches `incomplete` instead of
`todaysTasks` — the exact same list the Dropdown's `items` are built
from — so it can never return a task that isn't also a valid dropdown
item. Falls through to `incomplete.first`, or `null` (which the Dropdown
already handles via its `hint`) once the previously-selected task is no
longer a valid choice, instead of a stale reference to it. This made the
`todaysTasks` parameter dead, so it was dropped from `_activeTask`'s
signature entirely, and the two now-unnecessary
`final todaysTasks = store.todaysTasks;` / `final todays =
store.todaysTasks;` locals at its two other call sites (`_tick()`,
`build()`) were removed too — left in place, they'd have been unused
variables and shown up as new `flutter analyze` issues.

**Verification:** manually re-read; brace/paren counts balance; grepped
the whole file for `todaysTasks` afterward to confirm no leftover
references anywhere outside `_incomplete`'s own (correct, unfiltered)
fetch. All three `_activeTask(...)` call sites updated to the new
single-argument form. Not run — this one in particular is worth
deliberately reproducing (select a task, let it run a bit, tap
Complete) to confirm the crash is actually gone and the Dropdown falls
back to the next incomplete task (or its empty-state hint) cleanly.

**Also raised in the same message, not a bug — a design question:**
whether Focus Mode should show only Pause + Complete instead of
Pause + Reset + Skip + Complete. Answered in chat rather than changed in
code this round: Reset and Skip aren't redundant with each other or with
Complete — Reset restarts the *current* phase's countdown from zero
(same task, same phase, timer back to full), Skip ends the current phase
early and moves to the next one *while still crediting elapsed focus
time* (see the "Skip discarded elapsed time" fix already in this log),
and Complete finishes the underlying *task* itself (only shown during
the focus phase, not break). Recommended keeping all four for now;
open to revisiting the visual hierarchy (e.g. Reset/Skip as lighter
secondary actions) if it still reads as cluttered once seen fixed on a
real device.

### 6. Duration controls stayed live during an active session

Follow-up correction on the point above: the actual, concrete complaint
was that the preset buttons (25/5, 50/10, Custom) and the custom
focus/break fields stayed visible **and tappable** while a session was
already running (visible in the first Focus Mode screenshot: timer at
24:51, presets still sitting right below it) — not a request to delete
Reset/Skip. Tapping a preset mid-session calls
`_resetForPhaseOrPreset()`, silently resetting the running timer — an
easy, surprising mis-tap. The "Working on" task picker and the
app-blocking row directly above already avoid exactly this by being
wrapped in `if (!_running) ...`; the preset row and custom fields just
never got the same treatment.

**Fix:** wrapped the whole preset section (the `Wrap` of preset chips,
plus the custom-duration `Row` when `_isCustom`) in the same
`if (!_running) ...` guard already used above it. Choosing/changing a
duration only makes sense before a session is running, same reasoning
as the task picker.

**Still open:** what exactly the action-button row (Pause / Reset /
Skip / Complete) should look like while running is still being
clarified in chat — not changed this round.

**Verification:** manually re-read; brace/bracket/paren counts balance
across the whole file. Not run.

### 7. Action row while running: exactly Pause + Complete

Clarified precisely: while the timer is actively counting down, only
two buttons should show — Pause and Complete. Reset and Skip aren't
being removed, just hidden while running; they come back once paused
(or before a session starts), same as Start/Resume already behaves.

**Fix:** wrapped `MrdIconButton(onTap: _confirmReset, ...)` and
`MrdIconButton(onTap: _skip, ...)` in `if (!_running) ...[...]`. Net
effect: running + focus phase → [Pause, Complete] (2 buttons, as asked);
running + break phase → [Pause] alone (Complete was already
`if (_phase == _Phase.focus)`-only, unchanged); not running → all four
again, exactly as before this whole mini-thread started.

**Verification:** manually re-read; brace/bracket/paren counts balance.
Not run.

### 8. New Task modal: "Start Hour" redundantly baked in ":00"

Reported with a screenshot: the New Task modal's "Start Hour" dropdown
showed a full time like "9:00 AM" — hour *and* minute — sitting directly
next to a separate "Minute" dropdown (0/15/30/45) for the same field.
The hour dropdown always rendered ":00" no matter what the Minute
dropdown was actually set to, which reads as contradictory, not just
redundant (picking Minute=30 still left the sibling field visibly
saying ":00").

**Root cause:** the Start Hour items were built with
`minutesToLabel(h * 60, ...)` — the general "minutes since midnight"
formatter, always showing a `:00` minute component since `h * 60` is by
definition exactly on the hour, regardless of the real, separately-
selected `_startM`.

**Fix:** added `hourToLabel(hour, [format24])` to `utils/format_utils.dart`
— same AM/PM logic as `minutesToLabel`, but hour-only, no minute
component at all. Start Hour's items now use
`hourToLabel(h, widget.timeFormat24)` instead. Checked for the same
pattern elsewhere in the app first (`grep` for `minutesToLabel(h * 60`
and for other `List.generate(24, ...)` hour pickers) — this was the only
place it occurred, so no other screen needed the same fix.

**Verification:** manually re-read; brace/bracket/paren counts balance
on both files touched (`utils/format_utils.dart`,
`widgets/tasks/task_modal.dart`); confirmed via grep that no
`minutesToLabel` call remains in `task_modal.dart`. Not run.

### 9. Weekday/month names stuck in English + a full-app translation audit

Reported: in Arabic and Russian, the day name at the top of the Today
screen stayed in English, plus a general ask to verify nothing in the
app is untranslated except the app name and anything genuinely needed
in English.

**Root cause:** `fmtDate`/`fmtDateShort` (`utils/format_utils.dart`)
used hardcoded English `_weekdayNames`/`_monthNames`/`_monthNamesShort`
word lists with no locale awareness at all — not a translation gap so
much as these two functions never having been locale-aware in the first
place. Genuinely surprising find while fixing it: **the translated
strings already existed.** A complete, correctly-translated
`weekdayMon..Sun` / `monthJan..Dec` / `monthShortJan..Dec` set (31 keys)
was already sitting in all three `.arb` files — Russian months already
correctly in the *genitive* case a date needs, Arabic already using
full names for both long and short forms — but with **no corresponding
getter in any of the four generated `app_localizations*.dart` files**,
and `fmtDate`/`fmtDateShort` never called any of it. Presumably added in
an earlier session anticipating this exact fix, then the wiring never
happened. Confirmed via grep before assuming anything: zero references
to `weekdayMon` or `monthJan` anywhere in `lib/` outside the `.arb`
files themselves.

**Fix:**
- Generated the 31 missing getters (abstract declarations in
  `app_localizations.dart`, concrete `@override` implementations in the
  `_en`/`_ar`/`_ru` files) from the existing `.arb` values — no new
  translation authoring needed, purely mechanical wiring, scripted to
  avoid transcription slips across 124 new lines of near-identical code.
- `fmtDate`/`fmtDateShort` now take an `AppLocalizations l10n` parameter
  and build their word lists from it instead of the old hardcoded
  arrays.
- Also made word *order* locale-aware, not just the words: English is
  "Month Day" ("September 7"); Arabic and Russian both read more
  naturally "Day Month" ("7 سبتمبر" / "7 сентября") — decided via
  `l10n.localeName`.
- Updated all four call sites to pass `l10n` through:
  `dashboard_screen.dart` (the reported Today-screen header),
  `analytics_charts.dart` (chart axis labels + the active-point
  tooltip — `_xLabels` also gained an `l10n` parameter), and
  `tasks_screen.dart` (`_dateBadgeLabel`, also gained an `l10n`
  parameter).

**Audit for the broader ask** ("nothing untranslated except the app
name and what's genuinely necessary"): grepped for hardcoded
capitalized string literals passed straight to `Text(...)` across
`lib/screens`, `lib/widgets`, `lib/analysis`. One hit —
`Text('English')` next to `Text('العربية')` / `Text('Русский')` in the
Settings language picker itself — each language's name shown in its
*own* script regardless of the app's current language, which is
correct, standard practice for a language picker (not a bug; this is
one of the "necessary" exceptions). Spot-checked the theme pills
(Dark/Light/System) too — already routed through `l10n.darkLabel` /
`l10n.lightLabel` / `l10n.systemLabel`, not hardcoded.

**One real gap found, not fixed yet — flagging for a decision rather
than silently expanding this fix further:** `minutesToLabel`,
`hourToLabel`, and `fmtClock` all hardcode the English `'AM'`/`'PM'`
suffix, with no translated equivalent. Arabic has a standard pair for
this ("ص" / "م"); Russian doesn't have a clean two-word equivalent the
way English does (colloquially it's closer to a four-way morning/
day/evening/night split than a binary AM/PM), so getting that one right
needs a deliberate choice, not just a mechanical wire-up like the
weekday/month fix — flagging that difference explicitly rather than
guessing at a translation for it. Affects 8 call sites across
`planner_screen.dart`, `dashboard_screen.dart` (×3),
`tasks_screen.dart`, and `task_modal.dart`.

**Verification:** manually re-read; brace/bracket/paren counts balance
on every file touched (`utils/format_utils.dart`,
`screens/dashboard_screen.dart`, `analysis/analytics_charts.dart`,
`screens/tasks_screen.dart`); confirmed via grep that no old
single-argument `fmtDate(`/`fmtDateShort(` call remains anywhere in
`lib/`; confirmed the three `.arb` files still have identical key sets
(425 keys each) after the ARB-injection step aborted safely on already-
existing keys rather than silently duplicating anything. Not run — this
one is easy to verify visually: switch to Arabic or Russian and check
the Today screen's header, the New Task date field's short-date
displays, and the Analytics focus-trend chart's axis labels.

### 10. AM/PM localized (Russian confirmed as a plain two-way split)

Follow-up on the flagged gap above. Asked rather than guessed, since
Russian doesn't have a clean AM/PM equivalent — confirmed: a plain
two-way split, morning/evening only.

**Fix:** added `periodAm`/`periodPm` to all three `.arb` files and their
four generated files — EN "AM"/"PM" (unchanged), AR "ص"/"م" (the
standard pair), RU "утра"/"вечера" (morning/evening, as confirmed).
`minutesToLabel`, `hourToLabel`, and `fmtClock`
(`utils/format_utils.dart`) now all take an `AppLocalizations l10n`
parameter and read the period from it instead of the old hardcoded
`'AM'`/`'PM'` literals. Updated all 8 call sites across
`planner_screen.dart`, `dashboard_screen.dart` (×3 — one of which,
`_MiniTaskRow`, didn't have an `l10n` in scope yet and needed
`final l10n = AppLocalizations.of(context)!;` added), `tasks_screen.dart`,
and `task_modal.dart`.

**Verification:** manually re-read; brace/bracket/paren counts balance
on all nine files touched; confirmed via grep that no old-signature
`minutesToLabel(`/`fmtClock(`/`hourToLabel(` call remains anywhere in
`lib/`; confirmed all three `.arb` files still hold identical key sets
(427 each) after the injection step. Not run — worth checking a 12-hour-
format time display in Russian specifically, since "утра"/"вечера" is a
simplification of how Russian would ideally express time-of-day (a
real four-way morning/day/evening/night split), accepted deliberately
in exchange for reusing the same simple AM/PM-shaped code path as
English and Arabic rather than a bespoke Russian-only branch.

### 11. Reminder-hour steppers didn't line up with each other

Reported with a screenshot of the Morning/Evening reminder hour
steppers: "8 h" on one row, "20 h" on the other, the +/- buttons visibly
not aligned between the two rows.

**Root cause:** `_NumberStepper` centered the whole `"$value $suffix"`
string as a single block in a fixed-width box. Monospace font, so each
character has the same width — but "8 h" is 3 characters and "20 h" is
4, so centering each as its own block put the digit(s) at a different
distance from center in each case (one character left-of-center for
"8", a digit and a half left-of-center for "20"). The numbers — and the
buttons flanking them — never line up between two steppers unless their
values happen to have the same digit count.

**Fix:** split the number and suffix into two parts instead of one
centered string: the number now sits in its own fixed-width,
right-aligned sub-box, followed by the suffix at a fixed gap. That pins
the number's right edge (and the suffix's left edge) to the same
position regardless of digit count. Sized the sub-box for up to 3
digits, since this same widget also renders values up to "180" for the
focus-duration stepper elsewhere on this screen — checked that call
site before picking a width, not just the two reminder-hour rows that
were actually reported.

**Verification:** manually re-read; brace/bracket/paren counts balance.
`_NumberStepper` has exactly 4 call sites in this file (checked via
grep) — all four now get the fix, not just the two reported ones. Not
run.

### 12. Keyboard very slow to appear when adding a task/habit

Reported plainly: the keyboard takes a long time to show up when adding
a task, a habit, "or anything" — annoying.

**Root cause:** an *earlier* fix, already documented in this log,
deliberately added the delay that's now being reported as the bug. That
earlier fix solved a real problem — `autofocus: true` requesting the
keyboard the instant the New Task/New Habit sheet's title/name field
first built, which is *during* the bottom sheet's own ~250ms slide-up
entrance animation, so two animations (the sheet's transform and the
keyboard's rise) fought each other and read as janky. The fix for that
was `Future.delayed(milliseconds: 300)` before requesting focus — a
flat guess, deliberately longer than the real ~250ms animation so it
would never overlap. That safety margin is exactly the extra lag being
reported now: correct fix for the jank, at the cost of a genuinely
slower keyboard than necessary.

**Fix:** replaced the guessed delay with actually listening for the
sheet's entrance animation to finish. New shared helper,
`requestFocusOnRouteSettled()` (`widgets/shared/modal_focus.dart`):
reads `ModalRoute.of(context)?.animation` and requests focus the moment
its status hits `AnimationStatus.completed`, falling back to a plain
post-frame callback if there's no route animation to wait on (e.g. a
hot-reload re-entry where it's already `completed`). This fires focus
exactly when the sheet is actually done settling — never earlier (still
avoids the original two-animations-at-once jank) and never later than
necessary (no guessed padding on top of the real animation, so the
keyboard shows meaningfully sooner than the old fixed 300ms). Wired into
both `task_modal.dart` and `habit_modal.dart` — grepped for the same
`Future.delayed(...300...)` pattern across all of `lib/` first and
found exactly these two (a third hit, `splash_screen.dart`, is an
unrelated splash-animation delay, not a text-field-focus one, so left
alone). Both call sites moved from `initState()` to
`didChangeDependencies()`, since `ModalRoute.of(context)` isn't
reliably available as early as `initState()`; guarded with a
`_focusRouteListenerAttached` flag so it only attaches once per widget
lifetime (`didChangeDependencies()` can run more than once).

**Verification:** manually re-read; brace/bracket/paren counts balance
on all three files touched (new `widgets/shared/modal_focus.dart`,
`widgets/tasks/task_modal.dart`, `widgets/habits/habit_modal.dart`).
Not run — this one's easy to feel the difference on: open New Task or
New Habit and see how quickly the keyboard now appears versus before.

---

## Update — Full Audit Pass: 8 Issues Fixed

Requested explicitly: a full critical audit of the whole app, then fix
everything found, one at a time, carefully. The audit itself covered
files never touched earlier in this log — `services/`, `store/backup.dart`
& `persistence.dart`, `habits_screen.dart`, `resources_screen.dart`,
`app_selection_screen.dart` — not just the screens reported via
screenshot so far. Findings and fixes below, numbered to match the
report sent to the person before starting.

### 1. Restoring a backup never rescheduled (or cancelled) any reminders

`MeridianStore.replaceAllData()` — the only call site is backup import —
was a single line, `_setData(next)`. No reminder bookkeeping at all:
anything scheduled with the OS for a task/habit id that doesn't exist in
the *restored* data stayed scheduled (stale, pointing at content that's
gone), and anything in the restored data with a reminder enabled did NOT
actually get one scheduled with the OS, since only the create/update
paths call `scheduleTaskReminder`/`scheduleHabitReminder`. **Fix:**
cancel every reminder tied to the *old* data first, then call the
already-existing `resyncAllReminders()` (the same method the app already
runs after startup and after a reminder-relevant settings change) to
schedule everything the *new* data needs. Reused trusted logic rather
than writing new one-off scheduling code.

### 2. Task link button: no validation, no error handling, no feedback

`tasks_screen.dart`'s "open link" button was a bare
`launchUrl(Uri.parse(task.link!), ...)`. `resource_card_widget.dart`
already solved the identical problem correctly for Resources: normalize
(add `https://` if the scheme's missing — which is exactly what the New
Task modal's own Link field hint suggests typing, "coursera.org/learn/
your-course"), validate with `Uri.tryParse` + `hasAuthority`, launch
inside try/catch, toast on any failure. **Fix:** added `_openTaskLink()`
to `tasks_screen.dart` mirroring that exact pattern, reusing the
already-translated, already-generic `resourceInvalidLinkError` /
`resourceOpenLinkError` strings (checked their actual text in all three
languages first — genuinely generic, no "resource"-specific wording, so
reusable without new l10n keys). Guard condition on the button itself
tightened from `task.link != null` to also require non-empty after
trimming.

### 3 & 4. App Blocking screen: no error handling + wrong-timed permission recheck

Two related problems in `app_selection_screen.dart`, fixed together
since both needed the same `WidgetsBindingObserver` addition:

- **No error handling anywhere.** Every `AppBlockingService` call was
  unguarded; a thrown `PlatformException` would skip the final
  `setState(() => _isLoading = false)` entirely, leaving the screen
  stuck on its loading spinner forever with no recovery short of leaving
  and reopening it.
- **Permission recheck fired at the wrong moment.** After sending the
  person to Android Settings, the old code waited a flat one second
  (timed from when Settings *opened*, not from when the person actually
  *returned*) then checked permission exactly once. Granting an
  accessibility permission always takes longer than a second in
  practice, so the recheck almost always fired while still inside
  Settings, read "not granted yet" (correctly, at that moment), and
  never asked again — the screen could be stuck showing the permission
  gate even after the permission really was granted.

**Fix:** rewrote the screen's state class with
`WidgetsBindingObserver`. `_checkPermissionAndLoad()` is now fully
try/catch-wrapped with `_isLoading` cleared in a `finally`, plus a real
error state (icon, message, Retry button) instead of an infinite
spinner. `didChangeAppLifecycleState` re-checks permission on
`AppLifecycleState.resumed`, guarded on `!_hasPermission` so an
unrelated resume (pulling down a notification and back) doesn't reload
the whole app list once permission is already granted and nothing needs
refreshing — reacts to the actual event that matters (coming back to
Meridian) instead of guessing how long Settings will take.

### 5. Bidi-detected fields defaulted to LTR regardless of app language

`detectTextDirection`'s own `fallback` parameter already existed and
defaults to `TextDirection.ltr` — a reasonable library-level default,
but `MrdBidiTextField` never overrode it. A genuinely empty field (no
text yet, and no hint, or a hint with no strongly-directional
characters) always started left-aligned no matter what language the app
was in — a visible mismatch against an otherwise fully-RTL Arabic
screen for as long as the field stayed empty. **Fix:** `_detect()` now
passes `fallback: Directionality.of(context)` — the same direction the
rest of that screen is already using — instead of leaving it unset.
Considered also handling a live language change while the field is
already open (`didChangeDependencies()`, mirroring the AppBar-title fix
earlier in this log) but left that out: this app's navigation structure
doesn't allow the language picker (Settings, a separate pushed route) to
be open at the same time as a modal with a bidi text field, so that
specific edge case can't actually occur here.

### 6. App Blocking list: full-resolution icons for every app, no search

Folded into the same `app_selection_screen.dart` rewrite as #3/#4.
`Image.memory(app.icon, width: 44, height: 44)` had no `cacheWidth`/
`cacheHeight`, so every icon decoded at full native resolution before
being downsampled for a 44px display — real memory/CPU cost multiplied
by however many apps are installed (100-300+ is normal). **Fix:** added
`cacheWidth: 88, cacheHeight: 88` (2x the display size, enough headroom
for higher-density screens without decoding at full native size for
nothing). Also added a search field above the list (filters by app
name, case-insensitive) — there was no way to narrow a long,
unsorted-by-relevance list otherwise.

### 7. NotificationService: most plugin calls had no error handling

Two spots (timezone detection, the exact→inexact scheduling fallback)
already had careful try/catch; every other method didn't. **Most severe
instance found while fixing this:** `initialize()` itself was
unguarded, and its one call site (`splash_screen.dart`, inside a
`Future.wait([...])`) has no try/catch of its own around it either — a
thrown exception there wouldn't just skip notification setup, it could
strand the app on its splash screen, unable to ever reach AppShell, over
what should be an entirely optional feature. **Fix:** wrapped
`initialize()`'s whole plugin-setup body in try/catch, leaving
`_initialized` false on failure so every other method's own
`if (!_initialized) return;` guard quietly no-ops instead of throwing —
a device that hits this loses notifications, not the ability to open
the app at all. Also wrapped: `show()`, `cancelTaskReminder()`,
`cancelHabitReminder()`, `cancelDailyPlanningReminders()`,
`_scheduleDailyFixed()`, `requestPermission()`,
`requestExactAlarmPermissionIfNeeded()`, and the previously-unprotected
fallback branch inside `_scheduleWithFallback()` (if *both* the exact
and inexact scheduling attempts fail, that's caught now too — it wasn't
before). All fail safe: catch, do nothing further, same reasoning
already established for timezone detection.

**Caught during verification, not part of the audit report itself:**
the `initialize()` rewrite left a stray duplicate `}` right after the
method's real closing brace — found via a proper brace-depth scan (not
just a raw count) before packaging, not left for `flutter analyze` to
catch. Fixed before this file was considered done.

### 8. Icon-only buttons (edit/pause/delete) under the minimum tap target

`MrdIconOnlyButton`'s tap target was identical to its 36x36 visual
footprint — under Android's recommended 48dp minimum. Three of these
sit directly adjacent with zero gap on every habit card (edit / pause /
delete), one of them destructive. **Fix:** same `OverflowBox` technique
already established in `MrdCheckbox` for this exact problem elsewhere —
the *visual* box and every layout that assumes this widget occupies
36x36 stay untouched, only the invisible hit area grows. Used 44, not
the full 48: with the three buttons sitting edge-to-edge, a bigger
expansion would make neighboring buttons' hit areas overlap each other,
which is a worse regression than the original problem for a destructive
action. Paired with a small `SizedBox(width: 8)` added between each
button (both here and in the analogous spot in `tasks_screen.dart`'s
task row) — 44's 4px-per-side overflow plus an 8px gap meet exactly,
with zero overlap.

**New l10n keys this pass:** `couldntLoadAppsError`, `retryLabel`,
`searchAppsHint` — added to all three `.arb` files and all four
generated files (3 new strings × 3 languages, all newly authored, not
reused from elsewhere). Verified key-parity across all three `.arb`
files afterward: 430 keys each, zero diff.

**Verification:** manually re-read every change. Ran a proper
string/comment-aware brace-balance scanner (not just a raw character
count, which the `initialize()` incident above shows isn't reliable
enough on its own) across every single `.dart` file in `lib/` — zero
files flagged. Confirmed ARB key-parity one final time. Not run —
`flutter analyze` on the real machine remains the next real signal, same
as every fix in this log.

---

## Update — UI/UX Design Critique Pass

Requested explicitly, separate from the code-audit pass above: a design
critique, then fix what's found. Sent a written critique first; findings
and fixes below, matched to that critique's numbering.

### 1 & 2. No onboarding at all + notifications requested cold

Two related gaps, fixed together as one flow. Grepped the whole app for
any onboarding/welcome/first-run trace first — genuinely zero. A brand
new person landed straight on 5 bottom tabs + 3 top icons with no
context for any of it, and separately, `app_shell.dart` fired Android's
own notification-permission dialog on a flat 600ms timer on that very
first launch, with no explanation from the app at all — while
`app_selection_screen.dart`'s App Blocking permission gate already does
this correctly (a real explanation screen before asking).

**Fix:** new `screens/onboarding_screen.dart` — a 4-page swipeable
`PageView` (Welcome → Plan-and-Focus → Habits-and-Analytics →
Notifications) with a dot indicator, a Skip button on pages 1-3, and the
last page ending on the exact same honest pattern App Blocking already
established: explain first, then let the person choose (Enable
Notifications / Not Now), never force it. `splash_screen.dart` now
checks `OnboardingScreen.hasBeenSeen()` and routes there instead of
`AppShell` on a genuinely first launch; the old unexplained
`Future.delayed(600ms, ...)` block was deleted from `app_shell.dart`
entirely — the notification ask now only ever happens from that one
explicit, informed tap.

**Existing-user consideration, not just new-install:** this flag only
exists in `SharedPreferences` going forward, so anyone updating from a
build before this flow existed would otherwise look identical to a
fresh install and see a tour for an app they already use. Added a check
in `splash_screen.dart`: if the onboarding-seen flag isn't set but the
person already has real data (`store.tasks.isNotEmpty ||
store.habits.isNotEmpty`), mark it seen without ever showing it —
presence of real data is a far better "not actually new" signal than a
preference flag that couldn't have existed for them yet.

**Correction on the way in:** the "Enable Notifications" button reuses
the exact permission-and-settings-toggle logic that used to live in
`app_shell.dart`'s deleted block (`requestInitialPermissionIfNeeded()`,
then enabling all four reminder toggles and requesting the exact-alarm
permission on success) — moved, not rewritten from scratch, so behavior
on a granted permission is unchanged from before.

### 3. Color contrast — computed properly, not eyeballed

The critique flagged this only as "worth verifying with a contrast
checker" — verified it for real this time with an actual WCAG
contrast-ratio calculation (relative luminance → contrast formula) run
against every color in `app_theme.dart`, rather than shipping another
guess. Two real, confirmed failures:

- **`primaryInk`** (pure white in both themes) — the color used for text
  on every primary-colored button across the app (~14 call sites:
  Dashboard, Tasks, Habits, Resources, Planner, and every modal's
  primary action). Computed contrast against `primary`: **2.77:1 in
  light mode, 2.14:1 in dark mode** — both fail WCAG AA even for large
  text (needs 3:1), let alone the normal-text 4.5:1 floor most of those
  buttons' text actually renders at. Changed to dark navy
  (`0xFF0F172A`) in both themes — computed: **6.44:1 light, 4.85:1
  dark**, both comfortably clearing the normal-text threshold. Chose
  this over darkening the `primary` brand color itself, which would
  have meant a real brand-identity change for a contrast fix that has a
  cleaner, more targeted solution.
- **`textFaint`** — was the identical `0xFF64748B` in both themes.
  Computed **4.55:1 in light mode** (technically over the 4.5:1 floor,
  but by a margin thin enough that font-rendering variance across
  devices could tip it under in practice — this color is used at 10-11px
  in plenty of places, under the size that would relax the requirement)
  and **3.75:1 in dark mode** (an outright, unambiguous failure). Light
  theme's value darkened slightly to `0xFF5D6B85` (5.14:1, real
  headroom instead of a hair over the line); dark theme's lightened to
  `0xFF7C8CA6` (5.24:1) — the two themes no longer share one value,
  since what reads as "faint but legible" against a light background and
  against a dark one aren't the same actual color. Picked to stay
  visually distinct from `textDim` in the dark theme too (luminance 0.28
  vs 0.36), preserving the existing three-tier text/textDim/textFaint
  hierarchy rather than collapsing two tiers into looking the same.

**Found while fixing, not part of the original critique:** two places
already used `color: c.bg` instead of the app's own established
`c.primaryInk` token for text on a primary button —
`app_selection_screen.dart`'s permission-gate button (pre-existing code)
and this pass's own new `onboarding_screen.dart` (written earlier in
this same pass, before the contrast fix). Both inconsistent with every
other primary button in the app, and coincidentally the exact color
whose contrast needed fixing anyway. Grepped for the same pattern
(`color: c.bg` paired with bold/button text) across the rest of `lib/`
afterward — no other instances found. Both switched to `c.primaryInk`.

### "High priority by default" — checked, not actually true

The critique guessed the New Task modal defaults `Priority` to "High"
based on a screenshot, reasoning that a high default encourages priority
inflation. Checked the actual code before changing anything:
`_priority = t?.priority ?? TaskPriority.medium;` — new tasks already
default to Medium (the second of four levels: low/medium/high/urgent).
The screenshot almost certainly showed a task where the person had
already changed it themselves before the screenshot, not the true
default. Corrected in chat; no code change made, since there was nothing
to fix.

### Text-length variance across AR/EN/RU — flagged, not resolved

The critique named this as a systemic risk category (Arabic and Russian
text run measurably longer than English in most UI strings — already
confirmed once, concretely, by the Planner overflow bug fixed earlier in
this log) rather than a specific new bug. Attempted a static-analysis
sweep for other fixed-width containers holding translatable text: found
~80 fixed-width `SizedBox`/`Container` uses across `lib/`, far too many
to individually verify without a way to actually measure rendered text
width, and most are almost certainly icon-button sizing or spacing gaps
rather than text containers at all — filtering the real risks from the
noise via grep alone produced unreliable results. Concluded honestly
that this needs either a full manual read of all ~80 sites or, far more
reliably, actually running the app in Arabic and Russian and watching
for clipped/overflowing text on a real device — asked the person to keep
sending screenshots of anything that looks wrong, the same way the
Planner bug was actually found, rather than shipping a low-confidence
guess at "probably fine."

**Verification:** manually re-read every change; full-repo brace/bracket/
paren scan (every `.dart` file in `lib/`) came back clean; confirmed
ARB key-parity (442 keys, zero diff) after the 12 new onboarding strings
were added on top of the audit pass's keys. The two computed-contrast
fixes are the first color values changed anywhere in this whole log
based on an actual calculation rather than visual judgment — worth
specifically eyeballing on a real screen once run, since a formula
match doesn't replace seeing it. Not run.

---

## Update — First Real `flutter analyze` Results Since the UI/UX Pass

The person ran `flutter analyze` after the design-critique pass above
and got 7 issues — the first real compiler signal since that whole
pass started. 4 were genuine errors (would have failed the build), 3
were info/warning-level. All fixed:

1. **`widgets/shared/buttons.dart:152-155` — 4 errors, "argument type
   'num' can't be assigned to parameter type 'double?'".** My own bug,
   introduced while fixing the tap-target-size issue in the design
   pass: `final hitSize = tapTargetSize > 36 ? tapTargetSize : 36;` —
   `36` is an `int` literal, `tapTargetSize` is a `double`, so the
   ternary's inferred type was `num`, not `double`, and `OverflowBox`'s
   `minWidth`/`minHeight`/`maxWidth`/`maxHeight` (typed `double?`)
   rejected it outright. This is exactly the class of mistake the
   brace/paren-balance scanner used throughout this log can't catch —
   it checks structure, not types. Fixed: `36` → `36.0`.
2. **`utils/format_utils.dart:73` — warning, unused `_weekdayKeys`.**
   Leftover from an earlier draft of the weekday/month localization fix
   in the previous pass — `_weekdayNames(l10n)` ended up listing the
   `l10n.weekdayMon` etc. getters directly instead of using this
   constant, and the now-pointless declaration never got deleted.
   Removed; confirmed via grep afterward that nothing referenced it.
3. **`screens/app_selection_screen.dart:201` — info, deprecated
   `Switch.activeColor`.** Renamed to `activeThumbColor` (deprecated
   since Flutter 3.31 in favor of it). Checked for the same property
   elsewhere first: one more hit, `plan_my_day_modal.dart`, but that's
   a `Slider.activeColor` — a different, still-valid property on a
   different widget — so left alone.
4. **`screens/splash_screen.dart:135` — info,
   use_build_context_synchronously.** Two `await`s
   (`OnboardingScreen.hasBeenSeen()`, and conditionally `markSeen()`)
   happened after the last `mounted` check and before `context` gets
   used again for `Navigator.of(context)`. Added one more `if (!mounted)
   return;` immediately before that line rather than trusting the
   earlier check to still hold two awaits later.

**Verification:** manually re-read each fix; full-repo brace/bracket/
paren scan still clean; grepped for lingering references to the removed
`_weekdayKeys` and for other `Switch.activeColor` usages before touching
anything. This is the first turn in the whole log where a real compiler
found something the manual-review-plus-balance-scanner process didn't —
worth remembering going forward: the balance scanner catches structural
mistakes, not type errors, and `flutter analyze` remains the only real
check for the latter until this environment has an SDK of its own.

---

## Update — Feature 3 (Habit Commitment Analysis) to 10/10

Closed the two gaps this row had listed since the Feature Conflict Check
table was first written: a weekly-vs-monthly breakdown, and a
missed-days count.

**Data layer first, not just UI.** `HabitWithStats` gained five new
fields (`weeklyRate`, `weeklyCompletedDays`, `weeklyWindowDays`,
`monthlyCompletedDays`, `monthlyWindowDays`) plus two convenience
getters (`missedThisWeek`, `missedThisMonth`), computed in
`_computeHabitStats` (`store/meridian_store.dart`). The weekly window is
age-aware the exact same way the existing `completionRate` field already
handles the monthly one — a habit created 3 days ago is judged against a
3-day week, not docked for days before it existed. Exposed the raw
completed/window counts rather than only a rounded percentage, so the
UI can say "missed 3 of 20 days" honestly instead of back-computing an
approximation from `100 - rate%`.

**`analysis/habit_analysis.dart`:** kept the existing "Most Consistent" /
"Needs Attention" summary tiles at the top untouched, and added a new
per-habit breakdown list below a divider — for every habit: this week's
rate, this month's rate (color-coded green/amber/red at 80%/50%
thresholds for at-a-glance scanning), and a missed-days line when
relevant.

**Caught and fixed during the same pass, not left for later:** the
first draft put the two rate stats on the *same* row as the emoji and
habit name, competing for horizontal space — and Arabic's and Russian's
"this week"/"this month" run measurably longer than English's, which is
exactly the fixed-row-width squeeze that caused the real Planner
overflow bug earlier in this log. Restructured before finishing: the
stats now sit on their own full-width row below the name, in a `Wrap`
instead of a `Row`, so a long translation wraps to a second line instead
of overflowing. Also caught a `EdgeInsets.only(left:)` that should have
been `EdgeInsetsDirectional.only(start:)` for correct RTL indentation —
fixed before it shipped rather than becoming another Arabic-specific bug
report later.

**Verification:** manually re-read; ran the proper string/comment-aware
brace-paren-bracket scanner (not a raw character count — see the
`flutter analyze` incident above) across every `.dart` file in `lib/`,
zero flagged; confirmed the one `HabitCommitmentCard()` call site in
`analytics_screen.dart` needed no changes (the widget's public interface
didn't change, only its internals and the underlying model); confirmed
ARB key-parity (444 keys, zero diff) after the 2 new keys
(`perHabitBreakdownLabel`, `missedDaysLabel`) were added. Not run.

---

## Update — Feature 2 (Task Delay Analysis) to 10/10

Closed the gap this row had listed since the Feature Conflict Check
table was first written: "no delay amount, and no reschedule history."
Unlike Feature 3's equivalent pass, this one genuinely needed a small
schema addition — the existing `Task.postponedCount` only ever recorded
*how many times* a task was pushed back, nothing about *by how much*.

**Schema change, done additively:** new `Task.originalDate` (`String?`,
`models/domain.dart`) — null for a task that's never been postponed
(including every pre-existing task from before this field existed;
`fromJson` reads it as `null` when absent rather than guessing a value).
Set in exactly one place, `updateTask()` in `meridian_store.dart`, at
the same `taskDate.compareTo(t.taskDate) > 0` check that already
increments `postponedCount` — but only when `t.originalDate` is still
null. A second or third postponement leaves it alone, so it always
holds the *true* original date rather than the most recent "previous"
one, meaning the gap between it and wherever `taskDate` ends up is the
*total* delay accumulated across every reschedule, not just the latest
move. Fully backward compatible: an optional named field with a default
of null needs no changes at either of the app's other two `Task(...)`
construction sites (`meridian_store.dart`'s `addTask`, `seed.dart`'s demo
data) — checked both before considering this done.

**`analysis/delay_analysis.dart`:** kept the existing "Delayed Tasks" /
"Most Delayed Category" tiles, added a third — "Average delay (days)",
computed from `originalDate` vs current `taskDate` across every delayed
task that has one. Below that, two new full breakdowns (by category, by
priority — the priority one needed no schema change at all, just reading
data that already existed) as small horizontal bar rows, sorted by
count, color-matched to each category's/priority's existing app color.

**Caught and fixed while building, not left for later:**
- Three `_InfoTile`s in a row instead of two meant less width each;
  wrapped the row in `IntrinsicHeight` so a longer translated label
  wrapping to a second line in one tile doesn't leave the three tiles
  visibly uneven heights (Text wrapping itself was never going to
  overflow anything — no fixed-height container involved, unlike the
  Planner bug — but uneven card heights is still a real, visible polish
  issue worth a two-line fix).
- Added `maxLines: 1, overflow: TextOverflow.ellipsis` to `_InfoTile`'s
  value line (not the label — a wrapped label is fine, but a category
  name mid-wrap at 15px bold in a narrower tile isn't) and to
  `_DelayBar`'s label column, both defensively, before either had an
  actual reported problem.

**Verification:** manually re-read; ran the proper string/comment-aware
scanner across every `.dart` file in `lib/`, zero flagged; grepped for
every `Task(...)` construction site in the app (2 more beyond
`domain.dart` itself) to confirm the new optional field needed no
changes at either; confirmed ARB key-parity (447 keys, zero diff) after
the 3 new keys (`averageDelayDaysLabel`, `byCategoryLabel`,
`byPriorityLabel`) were added. Not run — this is the first feature in
this whole "bring it to 10/10" sequence with an actual data-model
change behind it, so it's worth specifically testing the real flow:
create a task, push its date back twice, confirm the average-delay
number and the category/priority bars all reflect it correctly.

---

## Update — Feature 2, Actually Perfect This Time

Asked directly to double-check Feature 2 for what would still be missing
from genuinely perfect, rather than trust the "10/10" from the update
above at face value. Two real gaps found on re-inspection — worth being
honest that the earlier 10/10 was premature, not just adding polish to
something already complete:

**1. Ignored the Today/Week/Month toggle entirely.** `DelayAnalysisCard`
took zero parameters and read `store.tasks` directly — *every* task ever
created, regardless of what range the person had selected above it.
This is exactly the "Discrepancy #4" class of bug already found and
fixed for the top-level Productivity Score and Category Distribution
much earlier in this log — it just never got propagated to this card
when this feature was built. **Worth flagging honestly: the same check
turned up that `HabitCommitmentCard`, `ProductivityPatternCard`, and
`ProductivityInsightsCard` (Features 3, 4, 5) all take zero parameters
too and have the identical gap** — not fixed here, since only Feature 2
was in scope for this pass, but it means "perfect" for 4 and 5 whenever
they're taken on next should include this same check from the start
rather than being found after the fact again.

**Fix:** `DelayAnalysisCard` now takes the same `rangeDayKeys`/
`rangeLabel` that `analytics_screen.dart` already computes for every
other card — `delayedTasks` filtered to `rangeDayKeys.contains
(t.taskDate)`, subtitle updated to show which range is active (matching
the `categoryBreakdownRangeLabel` convention already used elsewhere on
this screen).

**2. Purely retrospective — no "what needs attention right now."**
Everything on this card was historical (tasks ever delayed, at any
point, regardless of current status) with nothing surfacing what's
*currently* sitting overdue and unresolved — arguably the more
actionable question for a "delay analysis" feature than a purely
backward-looking count. **Fix:** new `_OverdueBanner`, shown whenever
count > 0, counting tasks that are still `todo`/`inProgress` (explicitly
*not* `skipped` — a skipped task is a resolved outcome the person
deliberately chose, not something still needing attention just because
its date passed) with a `taskDate` before today. Deliberately *not*
filtered by the range toggle — unlike the rest of the card, "what's
overdue right now" is a real-time question that should read the same
whether Today, Week, or Month is selected, the same way a persistent
alert would.

**Verification:** manually re-read; ran the proper scanner across the
three files touched (`analysis/delay_analysis.dart`,
`screens/analytics_screen.dart`, plus the l10n files for the one new
`currentlyOverdueLabel` key), zero flagged; confirmed ARB key-parity
(448 keys, zero diff); confirmed the call site in `analytics_screen.dart`
was updated to pass the two new required parameters. Not run.

---

## Update — Feature 4 (Productivity Pattern Analysis) to 10/10

Applied the same self-critical check the Feature 2 pass established —
verify range-awareness and statistical soundness before calling
anything perfect — to this card from the start, rather than shipping it
and finding the gap later a third time.

**Range-awareness, but not uniformly.** `ProductivityPatternCard` had
the same zero-parameter gap as Feature 2 did. Fixed for two of its three
patterns (focus time-of-day, most-delayed priority) the same way. The
third, "best day of the week," is a genuinely different kind of
question — it's inherently a *cross-day-of-week* comparison, so forcing
it to respect a single-day or single-week range would ask it to find
"the best weekday" from one occurrence of one weekday, which isn't a
question that range can answer. Left it on the same fixed `store.history`
rolling window regardless of the toggle, and said so explicitly in its
own sentence ("· last 28 days") so it doesn't read as broken when it's
the one pattern that doesn't move as the toggle changes.

**Statistical soundness — all three patterns could overclaim from too
little data:**
- Focus pattern: a single 5-minute session would win a "peak focus"
  claim by default, being the only session logged. Added a 30-minute
  floor on the winning time-of-day bucket before calling it a peak.
- Weekly pattern: a weekday appearing exactly once in the history — one
  lucky 100% Tuesday — could beat a day with ten occurrences at a real
  85%, a statistically weak result dressed up as a confident one. Added
  a minimum-occurrences floor (≥2) per candidate weekday.
- Delay pattern: one task postponed once could get named as a
  "frequently postponed" priority level. Added a minimum-count floor
  (≥2) before naming one.

**Consistency fix, found while re-reading the weekly-pattern code:** it
called `DateTime.parse(day.date)` wrapped in its own try/catch, instead
of the `parseDayKey()` helper already used everywhere else in this
codebase for the exact same "YYYY-MM-DD" string shape. Not a live bug —
`store.history` entries are always built from `dayKey()` internally, so
the string this ever receives can't actually be malformed — but an
unnecessary one-off parsing path with a defensive try/catch that could
never fire. Switched to `parseDayKey()`, dropped the now-pointless
try/catch.

**No new l10n keys needed this time** — the range/window qualifier on
each pattern sentence reuses the existing "· {label}" concatenation
convention already established elsewhere on this screen
(`categoryBreakdownRangeLabel`, etc.) plus the already-existing
`last28DaysLabel`, rather than adding new strings for what's structurally
the same pattern.

**Verification:** manually re-read; ran the proper scanner across both
files touched (`analysis/pattern_analysis.dart`,
`screens/analytics_screen.dart`), zero flagged; no ARB changes this
pass, so no key-parity check needed. Not run.

---

## Update — Android Release Build Hardening (Gradle/R8/ProGuard)

Requested: review and update `android/build.gradle`,
`android/app/build.gradle`, `android/app/proguard-rules.pro`, and
`android/gradle/wrapper/gradle-wrapper.properties` for a reliably stable
`flutter build apk --release`, with 4 specific target contents supplied.
Read all four files' actual current content before changing anything,
same as every other change in this log — 3 of the 4 already matched
(or, in one case, already exceeded) what was asked for:

- **`android/build.gradle`** — already exactly matched (google() +
  mavenCentral() repos, the custom `rootProject.buildDir` redirection,
  `evaluationDependsOn`, the `clean` task). No change.
- **`android/app/build.gradle`** — release `buildTypes` block already
  had `signingConfig`, `minifyEnabled true`, and `proguardFiles` pointed
  correctly at `proguard-rules.pro` — and already had `shrinkResources
  true` too, which wasn't even asked for. No change.
- **`android/gradle/wrapper/gradle-wrapper.properties`** — already on
  Gradle 8.6. Checked compatibility against the AGP version actually
  declared in `settings.gradle` (8.3.2) before leaving it alone rather
  than assuming: AGP 8.3.x requires Gradle 8.4+, so 8.6 is within the
  supported range, not just "already matches the request." No change.
- **`android/app/proguard-rules.pro`** — the one real gap. Had Flutter's
  own embedding keep-rules, annotation-preserving attributes, and Kotlin
  metadata rules already, but was missing the Google Play Core
  `-dontwarn`/`-keep` pair. This is a real, well-known R8 failure mode:
  Flutter's engine embedding references Play Core's `SplitCompat`/
  `PlayStoreDeferredComponentManager` classes even when an app never
  uses split APKs or dynamic feature delivery, and since Play Core isn't
  a declared dependency by default, R8 can hard-fail the release
  minify step over classes it can't find rather than just warn about
  them — exactly the kind of thing that would make `flutter build apk
  --release` specifically (not debug) fail unpredictably. **Fix:** added
  the two missing lines, appended to the end of the existing file rather
  than replacing it wholesale, so the already-good explanatory comments
  documenting why other plugins' rules aren't duplicated here stayed
  intact instead of being lost to a full overwrite.

**Verification:** read all four files' real content before writing
anything, rather than trusting the request's premise that all four
needed changing; cross-checked the Gradle/AGP compatibility claim
against `settings.gradle`'s actual declared AGP version instead of
assuming the given Gradle version was simply correct. Not run — this
one in particular is only really verified by an actual `flutter build
apk --release` on the real machine, which is the whole point of the
fix.

---

## Update — Feature 3 Range-Awareness (Catching Up With 2 and 4)

Follow-up flagged honestly during the Feature 4 pass and picked up now:
`HabitCommitmentCard` had the same zero-parameter, toggle-ignoring gap
Features 2 and 4 had. Fixed on its own terms rather than copying either
of their fixes directly, since this card's data shape is genuinely
different — `HabitWithStats` already carries a `weeklyRate` and a
monthly `completionRate` as two separately-computed rolling windows
(from the Feature 3 "to 10/10" pass earlier), not a flat list of dated
records that can be re-filtered by day-key the way tasks/focus-sessions
can.

**Fix:** the "Most Consistent" / "Needs Attention" ranking — previously
always based on `completionRate` regardless of the toggle — now takes a
`useWeeklyView` flag from `analytics_screen.dart` (`_range !=
_Range.month`) and ranks by `weeklyRate` for Today/Week, `completionRate`
for Month. Today doesn't get its own dedicated computation — a single
day isn't a consistency measure on its own — so it shares the weekly
figure as the closest genuinely-computed match, same reasoning Feature
4's peak-focus pattern used for an analogous case. Also fixed the tiles'
displayed percentage (`overallPctLabel`), which still read
`completionRate` unconditionally even after the ranking itself changed
basis — would have shown a number that didn't match why that habit was
actually picked.

**Deliberately left alone:** the per-habit breakdown rows added in the
Feature 3 "to 10/10" pass already show *both* the weekly and monthly
rate side by side for every habit, unconditionally — arguably more
complete than making them toggle-dependent too, so no change there.

**`_Range` stayed private to `analytics_screen.dart`** — passed a plain
`bool` instead of exposing the enum, lower-risk than widening its
visibility for one call site.

**Verification:** manually re-read; ran the proper scanner across both
files touched (`analysis/habit_analysis.dart`,
`screens/analytics_screen.dart`), zero flagged; no ARB changes, no
key-parity check needed. Not run.

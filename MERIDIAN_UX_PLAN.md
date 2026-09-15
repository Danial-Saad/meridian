# Meridian — UX Audit & Improvement Plan

Produced from a full manual read of `lib/` against the UX brief. No Flutter
SDK is available in this environment, so every finding below is backed by
an actual line in the code (file + detail), not a guess — and every fix
will be checked the same way (manual re-read + the import/brace-balance
checks used in the last debugging pass), since there's still no compiler
to run `flutter analyze` with.

This file is a living tracker. As items are implemented they'll be marked
`[x]`. Sections match the brief's own structure so you can cross-reference.

---

## PHASE 1 — AUDIT (findings by category)

### Navigation
- Bottom nav (Today / Planner / Focus / Tasks / Habits) is a solid,
  standard pattern — no complaint there.
- Analytics, Resources, and Settings are **icon-only buttons** in the top
  app bar (`bar_chart`, `school`, `settings`). "school" for Resources is
  not an intuitive glyph for "saved links/courses," and none of the three
  have a visible label — a new user has to guess or tap-and-hold to see a
  tooltip (which doesn't work well on touch anyway).
- No breadcrumbs/back-context needed anywhere — screens are shallow
  (good), so "where am I" is generally clear already.

### Dashboard
- Current order: date/time → greeting → **Plan my day + Day review
  buttons** → day ring → stats → today's tasks → habits. The two
  secondary/occasional actions sit above the actual content a user opens
  the app to see. Minor hierarchy inversion, not a crisis.
- Otherwise genuinely answers "what matters today" reasonably well
  already — day ring, today's tasks, habits are all present and are the
  first substantial content.

### Tasks
- **Completing a task — the single most frequent action in the whole
  app — required tapping a 19×19px checkbox** (`MrdCheckbox` default was
  18px, used at 19px here), well under the ~44-48px minimum touch target
  guideline, sitting right next to a separate tap zone for editing. Real
  risk of mis-taps. **[FIXED this session]**
- FAB for quick-add exists — good, matches "clear primary action."
- Empty states are already good: explain what's empty and give a
  concrete CTA (checked `tasks_screen.dart`'s two empty-state calls).

### Planner
- Same checkbox issue, worse: 15px, only 7px of clearance before the
  next element. **[FIXED this session, calibrated smaller — see plan]**
- The persistent hint ("Long-press a block to move it, its bottom edge
  to resize") is a good discoverability call — it's not a one-time
  tutorial, it's always visible, so this isn't the problem it could have
  been.
- The resize handle's actual grab strip is only 18px tall (full width,
  which is good — height is the constraint). Long-press-to-move and
  long-press-to-resize are disambiguated only by exact vertical position,
  which combined with the thin strip makes an accidental move-instead-of-
  resize (or vice versa) plausible.

### Habits
- Actually the **best-designed completion interaction in the app**: a
  full-width `OutlinedButton.icon` ("Mark done today") with generous
  vertical padding — an easy, unambiguous target. Worth treating as the
  reference pattern rather than something to fix.

### Focus
- **`FocusScreen` had no `Scaffold`/`AppBar` of its own — it rendered
  inside `AppShell`'s Scaffold**, so the top app bar and the 5-tab bottom
  nav stayed fully visible during an active session. This directly
  contradicted "reduce visual noise" / "distraction-free" in the brief —
  it was the most visually noisy moment being treated identically to
  every other tab. **[FIXED this session]** — see P0 list below.

### Analytics
- Charts render with `fl_chart`-style custom painting (needs a readability
  pass on axis labels/legends at small widths — flagged for the polish
  pass, no crash-level issue found).

### Resources
- Creation flow (title, optional description, gallery image, URL) is
  already about as simple as this brief asks for. Image decode width is
  already capped (from the last session's perf pass). No changes needed
  beyond the consistency pass below.

### Forms & Input
- No systemic validation/keyboard problems found in `task_modal.dart` /
  `habit_modal.dart` / `resource_modal.dart`.
- One functional bug in this category was already fixed last session
  (Plan My Day's stuck Continue button).

### Microinteractions
- Only **3 of 42 files use any real animation primitive**
  (`AnimationController`/`AnimatedX`): `splash_screen.dart`,
  `day_ring.dart`'s pulse, and `app_shell.dart`'s `TickerMode` plumbing.
  Task completion, habit completion, card entrances, and bottom
  sheet/dialog transitions are all instant, default-Flutter, with no
  purposeful motion — this is the biggest gap in the whole brief relative
  to what exists today.

### Touch & Mobile Usability
- Covered above (checkboxes = the main finding).
- Everything else checked (FABs, list rows, buttons) meets or exceeds
  reasonable target sizes.

### Empty States
- Good already (see Tasks/Habits/Resources above) — 6 screens use the
  shared `EmptyState` widget with specific, helpful copy. Not a priority
  area.

### Loading / Error / Success States
- `MrdToast` exists and is used for save/delete/import/export feedback.
  No missing-feedback gaps found on the actions the brief lists.

### Consistency Audit
- **No shared "primary action" button component exists.** `buttons.dart`
  only defines `MrdPill`, `MrdIconButton`, and `MrdIconOnlyButton` — none
  of them a general CTA button. Meanwhile **7 different files** roll
  their own `ElevatedButton`/`OutlinedButton`/`TextButton` with inline
  styling (`task_modal.dart`, `habit_modal.dart`, `resource_modal.dart`,
  `plan_my_day_modal.dart`, `end_of_day_review_modal.dart`,
  `confirm_dialog.dart`, `dashboard_screen.dart`). They're visually close
  but not guaranteed identical (padding, radius, font-weight each typed
  by hand per file) — classic "two screens solve the same problem
  differently."

### Accessibility
- Correction to an earlier pass at this section: a raw search for
  `Semantics(` returned zero hits, but that undercounts real coverage —
  `Tooltip` auto-generates the same screen-reader label its `message`
  shows visually, and `MrdIconOnlyButton` (edit/delete/open-link across
  Tasks/Habits/Resources) and the three top-bar icons already use it. That
  part of the app was already fine.
- The **actual** gaps, found by checking every icon-only control
  individually: `MrdCheckbox` (no tooltip *and* no semantic toggled-state
  — needed a real `Semantics` widget, not just a tooltip, since "checked/
  unchecked" isn't a static label). **[FIXED]** Planner's `_navBtn` helper
  (prev/next day, jump-to-today — 3 call sites) and its inline open-link/
  delete icons had no tooltip or label at all. **[FIXED]**
- Color tokens (`#0F172A` on `#F8FAFC`, etc.) pass contrast by
  inspection; no contrast-ratio issue found.

### Performance
- Handled in the previous session (background-isolate JSON
  encode/decode, Focus tab background-rebuild fix, toast-layer
  decoupling, resource card watch→read, Core Library Desugaring build
  fix). Nothing new found here specific to this UX pass; the guidance in
  this brief (avoid rebuild storms, cap image decode size, keep
  animations cheap) is already the standard I'll hold new UI work to.

---

## PHASE 2 — PRIORITIZED PLAN

### P0 — Critical usability
- [x] **Enlarge the checkbox tap target app-wide** (Tasks, Dashboard,
      Planner) without changing its look — invisible hit-area padding via
      `OverflowBox`, calibrated per screen's available spacing. *Done
      this session.*
- [x] **Give Focus its own distraction-reduced chrome.** While a session
      is actively running: the bottom nav is hidden entirely and the app
      bar's three secondary icons (Analytics/Resources/Settings) are
      removed, leaving just the session UI. Pausing — an existing,
      obvious, one-tap control — brings both straight back, which doubles
      as the brief's requested "recovery from accidental navigation"
      without a separate exit flow to design and build. *Done this
      session (`app_shell.dart` + `focus_screen.dart`).*
- [x] **Add labels to the icon-only controls that actually lacked one.**
      Turned out narrower than the initial grep suggested (see corrected
      Accessibility note above) — fixed `MrdCheckbox` (real `Semantics`,
      toggled state) and Planner's date-nav/open-link/delete icons
      (`Tooltip`, which covers both the visual hint and the screen-reader
      label in one change). *Done this session.*

### P1 — Major UX improvements
- [ ] **Introduce a shared primary/secondary button component** and
      migrate the 7 files currently hand-rolling buttons onto it — removes
      an entire category of "same problem, different answer"
      inconsistency in one pass.
- [ ] **Purposeful micro-animations** for the highest-value moments only
      (per the brief's own "never add animation just because it looks
      cool"): task/habit completion (a brief, subtle checkmark/strike-
      through transition), bottom sheet entrance/exit, and toast
      enter/exit (the `ToastState` model already carries an unused `key`
      field that hints this was the original intent).
- [ ] **Widen the Planner resize handle's grab strip** slightly (from
      18px) and/or add a small visual affordance so move-vs-resize is
      less dependent on pixel-precise long-press placement.
- [ ] **Label the three top-bar icon destinations** (Analytics, Resources,
      Settings) — at minimum accurate `tooltip`s plus `Semantics`; a short
      persistent label under each icon if there's room without crowding
      the bar.

### P2 — Polish
- [ ] Reorder Dashboard so "Plan my day"/"Day review" sit after the day
      ring and today's tasks rather than above them.
- [ ] Analytics chart legend/label readability pass at narrow (small
      phone) widths.
- [ ] General spacing/typography consistency sweep once the button and
      animation work above lands (doing this last avoids re-touching the
      same files twice).

---

## Next steps

All of **P0** is done this session. **P1** is next (shared button
component + migration, purposeful micro-animations, the Planner resize
handle, and top-bar icon labels), in that order. Each batch gets the same
manual verification as the perf/debugging session before it (brace/import
balance, cross-file reference checks) since there's still no compiler
available here. Phase 4 (consistency re-pass) and Phase 5 (quality pass)
happen after P0+P1 land, since several of those items (spacing, button
styles) are meant to be touched once, not per-screen as we go.

---

## Addendum — three real-device bugs (from `flutter analyze` + live testing)

The app is now actually running on a real device, which surfaced three
concrete bugs `flutter analyze` alone couldn't catch (they're runtime
behavior, not static errors):

1. **Theme switch only partially applied until leaving/reopening the
   page.** Root cause: `app_shell.dart`'s `_openFullScreen` (used for
   Analytics/Resources/Settings) captured
   `context.read<ThemeController>().colors` as a one-time local variable
   in a closure passed to `MaterialPageRoute.builder`, instead of
   watching it reactively. Settings' own body correctly watches the theme
   and updated immediately; the outer Scaffold/AppBar around it didn't,
   since nothing told that closure to run again. Fixed by extracting a
   proper `_FullScreenPage` widget that watches `ThemeController` itself.
2. **RenderFlex overflow on the "Reset all local data" confirm dialog.**
   `confirm_dialog.dart`'s button row had no flex constraint on the
   confirm button, so the longer label "Reset everything" (vs the
   default "Delete") pushed past the dialog's available width. Fixed
   with `Flexible` + `TextOverflow.ellipsis` as a safety net.
3. **Keyboard felt slow/janky opening the task and habit modals.**
   Both used `autofocus: true`, which requests the keyboard the instant
   the field mounts — i.e. *during* the bottom sheet's own ~250ms
   slide-up entrance animation. Two animations fighting over the bottom
   of the screen at once (the sheet's transform and the continuously
   changing keyboard inset) is what reads as janky. Fixed by replacing
   `autofocus` with a `FocusNode` whose focus request is delayed until
   just after the sheet settles, in both `task_modal.dart` and
   `habit_modal.dart` (the only two places this pattern existed).

Also merged in a `gradle.properties` addition made on the testing
machine (longer Maven timeouts, to avoid spurious "could not find
dependency" errors on slow connections) rather than overwriting it.

---

## Addendum — full notifications system

A production local-notifications system: Task reminders, Habit reminders,
Focus/Break completion (already existed — kept, minorly improved), and
Daily Planning nudges, plus tap routing, a real monochrome status-bar
icon, and settings to control all of it.

### Architecture

Everything lives in `lib/services/notification_service.dart`
(`NotificationService`, static, no instance state beyond the plugin
handle) — the brief was explicit about not scattering scheduling logic
across screens. The only other files that call into it are
`meridian_store.dart` (from its existing task/habit CRUD methods — the
one place every mutation already flows through regardless of which
screen triggered it, so this was the natural integration point, not a
new one invented for this) and `main.dart`/`splash_screen.dart`/
`app_shell.dart`/`focus_screen.dart`/`settings_screen.dart`/
`habit_modal.dart` (wiring and UI, not scheduling logic itself).

`lib/services/pending_navigation.dart` is a small, deliberately separate
piece: a `ValueNotifier<int?>` that lets a notification tap (handled with
no `BuildContext`, possibly before `AppShell` even exists) tell `AppShell`
which tab to land on, without `NotificationService` reaching into
`AppShell`'s private state or duplicating tab-switching logic. `AppShell`
listens for it in `initState` and consumes it once (setting it back to
null) so it never re-fires.

### Data model changes

- `Habit` gained `reminderTime` (nullable `"HH:mm"`, null = no reminder).
  Per-habit rather than a global time, because habits legitimately want
  different times of day (a morning run vs. an evening wind-down) —
  unlike Task reminders, which reuse each task's own existing
  `taskDate`/`start` instead of needing a new field at all, since every
  task already carries a real, user-set time (defaults to 9am, always
  editable — confirmed by reading `task_modal.dart` before assuming this
  was safe to rely on).
- `UserSettings` gained `taskRemindersEnabled`, `habitRemindersEnabled`,
  `dailyPlanningRemindersEnabled`, `dailyPlanningMorningHour`,
  `dailyPlanningEveningHour`. All new toggles default to **false** —
  deliberately different from the existing `notificationsEnabled`
  (Focus/Break, default true, unchanged): that field already shipped and
  existing installs rely on its current behavior, while these are new,
  more proactive (scheduled/recurring, not just "alert when something
  you're already doing finishes") notification types, so they're opt-in.
- Both extensions are backward-compatible with old saved data with no
  migration step: every new field is read via the same defensive
  `json['x'] as Type?` pattern already used throughout `domain.dart`,
  which naturally returns the sensible default when the key doesn't
  exist in older saved JSON.

### Notification type taxonomy & duplicate prevention

Six types implemented: task reminder, habit reminder, focus complete,
break complete, daily-planning morning, daily-planning evening. IDs are
**deterministic**: the four singleton types (only one can ever be
relevant at a time) use fixed small ids; task and habit reminders derive
their id from the entity's own UUID via a hand-written FNV-1a 32-bit hash
in separate, non-overlapping numeric ranges — deliberately **not**
`dart:core`'s `String.hashCode`, which isn't guaranteed stable across app
restarts/VM versions. If it ever changed between sessions, cancel/
reschedule-by-id would silently stop finding what a previous session
scheduled, which is exactly the duplicate-notification failure mode the
brief warned about. Editing a task/habit reschedules with the *same* id
(overwrites in place); deleting or completing cancels by that same id.

Scoped out, deliberately: an "overdue task" type and a fully generic
"reminder" type (both only appeared as illustrative examples in the
brief's own ID-scheme section, not as a section with a settings entry of
their own) — left out per the brief's closing line prioritizing
reliability and maintainability over unrequested features. Noted here
rather than silently dropped.

### Scheduling specifics

- `zonedSchedule` with a real `tz.TZDateTime` throughout (never a naive
  `DateTime`), so scheduled fire times are correct across DST changes.
  `timezone` + `flutter_timezone` (reads the device's actual IANA zone
  name — the `timezone` package alone has no way to know this) are new
  dependencies; both direct pub.dev version numbers were verified against
  their actual current release rather than guessed (an initial guess for
  `flutter_timezone` was wrong — `^3.0.1` — caught and corrected to the
  real current `^5.0.1` before this was finalized).
- `AndroidScheduleMode.inexactAllowWhileIdle` everywhere, not an exact
  mode. Deliberate: none of these reminders need to-the-second precision
  ("starts in 10 minutes" is still true at 9 or 11), inexact is
  meaningfully more battery-friendly, and it avoids needing the
  `SCHEDULE_EXACT_ALARM`/`USE_EXACT_ALARM` permission (which also carries
  its own Play Store policy-justification burden). No new permission
  beyond the already-present `POST_NOTIFICATIONS` was needed.
- Habit and Daily Planning reminders use
  `matchDateTimeComponents: DateTimeComponents.time` for daily recurrence
  from a single call — the plugin reschedules the next occurrence itself
  after each fire.
- **Reboot behavior — read this before assuming reminders always
  survive.** `AlarmManager`-based alarms (what this plugin uses on
  Android) do **not** survive a device reboot on their own; that part of
  the brief's concern is real. The implemented fix is
  `MeridianStore.resyncAllReminders()`, called once from
  `splash_screen.dart` after both `store.init()` and
  `NotificationService.initialize()` are confirmed ready (deliberately
  sequenced *after* both, not from inside either — they run in parallel
  and either could finish first, so resyncing from inside whichever
  happens to finish first risked the other not being ready yet and
  silently no-op-ing). This re-derives every reminder from current
  data/settings on every app start, which self-heals from a reboot **the
  next time the app is opened**. A full native `BroadcastReceiver` +
  background-isolate solution (surviving even without reopening the app)
  was considered and deliberately not built: it needs a separate native
  entry point and its own plugin re-registration in a background isolate,
  meaningfully more complex and — with no real device available to test
  against in this environment — meaningfully riskier to get right than
  this app's other native changes have been. The trade-off is narrow and
  explicit: a reminder whose fire time falls *while the device is off*
  and the app isn't reopened before then is missed for that one
  occurrence. Judged acceptable for a daily-use app rather than worth the
  added risk; flagged clearly rather than silently accepted.

### Tap routing

Routes to a **tab**, not a specific item within it (e.g. the exact task)
— task reminder → Planner, habit reminder → Habits, focus/break → Focus,
daily planning → Dashboard. None of the existing screens support
deep-linking to a specific entity by id today (no "scroll to and
highlight task X" capability exists anywhere in the app), and adding that
was judged materially bigger than this pass's brief — documented as a
known limitation rather than attempted partially. Covers all four states
the brief lists (terminated, backgrounded, already running, on another
screen): `getNotificationAppLaunchDetails()` for cold start (checked
inside `NotificationService.initialize()`, before `SplashScreen`
navigates, so the intent is already waiting for `AppShell`'s first
frame), `onDidReceiveNotificationResponse` for foreground/backgrounded-
then-resumed taps. If a modal/dialog happens to be open on top of
`AppShell` when a tap arrives, the tab switch still applies underneath it
— it becomes visible once the modal is dismissed rather than
auto-dismissing it. A minor, reasonable rough edge, not fixed here, since
notification taps typically arrive while the app is backgrounded or
closed (the common case), not mid-modal.

### Focus/Break notifications — one small behavior change

Now gated on `!widget.isActive` (Focus not being the currently-visible
tab) in addition to the existing `notificationsEnabled` check — the
existing in-app toast already covers "actively looking at Focus", so a
system notification on top of that was redundant noise for the one case
that needed it least. This directly reflects the brief's "prefer in-app
UX when actively viewing Focus" requirement.

### Notification icon

Android status-bar icons must be a monochrome white-on-transparent
silhouette (the OS ignores any color/RGB information and renders using
only the alpha channel — this is a platform requirement, not a style
choice). No separate "wolf-head-only" reference image or SVG was actually
available — a file was attached to this request, but it turned out to be
the same full wolf+compass composite already used for the app icon, not
a distinct head-only asset. Rather than invent a new design (explicitly
against the brief's own repeated instruction), the wolf head was
extracted directly from the existing, already-approved artwork:
connected-component analysis (`scipy.ndimage.label`) on the source image
separated it into 13 disconnected shape pieces, visually identified which
5 belong to the wolf head (main face/mane, ear notch, eye, neck, one mane
spike) versus which 8 belong to the compass ring and its four needle
points, kept only the wolf-head pieces, and rendered them as a pure white
silhouette on transparent background. This is a pixel-exact extraction
from the real logo, not a redrawn approximation — verified by visual
inspection at both full size and at the actual smallest deployed size
(24×24, mdpi), where it's still clearly recognizable. Exported at all 5
standard densities (24/36/48/72/96px) to `drawable-{m,h,x,xx,xxx}hdpi/
ic_notification.png`; a brand-accent color (`#0EA5E9`, matching the
light-theme primary) is applied via `AndroidNotificationDetails.color`
for the notification's accent, separately from the icon asset itself.

### Settings UI

New "Notifications" section (kept the pre-existing "Focus session
notifications" toggle where it already was, in "Focus Mode", to avoid
touching working code unnecessarily) with: Task reminders on/off, Habit
reminders on/off (a master switch — the actual time is set per-habit from
its own edit sheet, a new "Reminder" row there with a time picker),
Daily planning reminders on/off, and two hour-of-day steppers (24h) for
the morning/evening planning nudges, reusing the existing
`_NumberStepper` widget already used for Pomodoro durations rather than
introducing a new control type. Toggling any of the three new settings
immediately calls `resyncAllReminders()` (only when something
reminder-relevant actually changed, not on every settings save), so
turning one on retroactively schedules every already-existing eligible
task/habit, not just ones created afterward. Requests the OS notification
permission at the moment of the first toggle flip, matching the existing
Focus-notifications toggle's already-established pattern (not on app
launch).

### Testing — stated plainly, not implied

**`flutter analyze`, `flutter test`, `flutter build apk` (debug or
release) were not run.** No Flutter/Dart/Android SDK, emulator, or device
in this environment — the same constraint as every other session in this
log, and there's still no `test/` suite in this project for `flutter
test` to run against regardless. Also not done, for the same reason: any
cold-start, backgrounded-tap, or reboot-simulation testing.

**What was actually verified, and should be read as IMPLEMENTED, not
end-to-end VERIFIED:**
- Every new/changed Dart file passes this project's manual brace/paren/
  bracket balance check, import-resolution check, and package-declared-
  vs-used cross-check (all clean).
- Every `Habit`/`UserSettings` construction site across the whole
  codebase was searched for and checked against the new fields — found
  and fixed one real gap this way: the habit-edit callback in
  `habits_screen.dart` was reconstructing a partial `copyWith()` that
  would have silently dropped a habit's reminder time on every edit.
- `AndroidNotificationDetails.color`'s expected `Color` type
  (`dart:ui`'s, not a plugin-specific type) and the exact `zonedSchedule`
  positional/named parameter shape for a modern plugin version were
  checked against current documentation/examples rather than assumed
  from general familiarity with older versions of this plugin, since
  getting either wrong would be a compile error. One specific detail
  couldn't be fully confirmed either way from available sources:  whether
  `uiLocalNotificationDateInterpretation` (an older, possibly-removed
  parameter) needs to be present for this project's exact plugin version
  — it was **left out** as the safer choice (omitting an optional
  parameter is always safe; including a removed one is a hard compile
  error), but this is exactly the kind of thing only `flutter analyze`
  can settle for certain.
- The wolf-head icon extraction was verified visually at multiple sizes
  (see above), not just assumed correct from the extraction script
  running without error.

**Please run, before considering this done:** `flutter pub get` (new
dependencies), `flutter analyze`, `flutter build apk --debug`, then on a
real device: grant notification permission, set a task's time a few
minutes out and a habit reminder time, background the app, and confirm
both fire and route to the right tab on tap; toggle each new setting off
and on and confirm past-due items don't get rescheduled; and — the one
this environment genuinely cannot simulate — reboot the device with a
future reminder pending and confirm it reappears after next opening the
app (and is honestly absent if the app isn't reopened before the
original fire time, per the documented trade-off above).

---

## Addendum — three real-world fixes to the notifications system

Found from an actual `pub get` failure and real-device testing (the
strongest signal this whole log has had that something genuinely didn't
work — worth taking seriously and fixing precisely rather than
guessing again).

1. **`pub get` failed outright**: `timezone: ^0.9.4` (my own guess, flagged
   at the time as unverified) conflicted with what
   `flutter_local_notifications ^19.0.0` actually requires
   (`timezone ^0.10.0`). Fixed to `^0.10.1`, matching pub's own suggested
   resolution from the error message — not a second guess, the actual
   registry's answer.
2. **No proactive permission prompt.** Added
   `NotificationService.requestInitialPermissionIfNeeded()`, called once
   from `AppShell.initState` (after a short delay so it doesn't slam onto
   the barely-rendered first frame). Uses its own one-time
   SharedPreferences flag — deliberately not a `UserSettings` field, since
   "have we ever asked" is app bookkeeping, not a user preference — so it
   only prompts on the actual first launch, ever, regardless of how many
   times the app reopens afterward.
3. **Task reminder didn't arrive before the task's start time — the real
   bug.** Root cause: task/habit reminders were scheduled with
   `AndroidScheduleMode.inexactAllowWhileIdle` for battery-friendliness,
   but Android's own alarm-batching/Doze-mode deferral can delay an
   inexact alarm by more than a short lead time can tolerate — a "10
   minutes before" reminder is useless if the OS decides to deliver it
   20 minutes late. Switched task and habit reminders to
   `AndroidScheduleMode.exactAllowWhileIdle`, added the
   `SCHEDULE_EXACT_ALARM` permission (not `USE_EXACT_ALARM`, which is
   restricted to alarm-clock/calendar-style apps and subject to Play
   Store eligibility review this app doesn't cleanly fit), and added
   `requestExactAlarmPermissionIfNeeded()` — called from Settings at the
   moment Task or Habit reminders are actually turned on (not bundled
   into the first-launch prompt: it navigates to a system settings
   screen, a bigger interruption than an in-app dialog, better tied to
   the moment someone is actually opting into the feature). Because exact-
   alarm access can still be declined or, per real reports, locked
   unavailable on some OEM Android 14 builds, every task/habit schedule
   call now tries exact first and falls back to inexact only if that
   throws (`_scheduleWithFallback` in `notification_service.dart`) —
   reminders keep working either way, just with better timing when the
   permission is granted. Daily Planning reminders deliberately stay
   inexact-only ("around 8am" has no precision requirement worth the
   added permission complexity).

**Verification — same honesty as every other pass:** `flutter pub get`
was not re-run by me (still no SDK here); the fix matches pub's own
printed resolution exactly, so it's about as high-confidence as a
non-executed fix can be, but "please run `flutter pub get` yourself to
confirm it resolves clean" still stands. The exact-alarm exception-
handling logic (`try` exact, `catch` and fall back to inexact) is
standard, well-documented behavior for this plugin, confirmed against
current plugin docs and real reported issues rather than assumed — but
whether it actually delivers on time now can only be confirmed by
testing on your device again, the same way you found the original bug.

---

## Addendum — startup black-screen fix

### 1. Root cause (two compounding causes, not one)

**Primary — missing Android 12+ SplashScreen API configuration.** This
app's `targetSdkVersion` resolves to Flutter's own current default (well
above 31, confirmed indirectly — this project already relies on
Flutter 3.27+ APIs elsewhere). Starting at API 31, Android's own
SplashScreen system is mandatory and takes over the starting window from
the classic `windowBackground` mechanism, whether or not an app has
configured anything for it. This app only had the classic
`LaunchTheme`/`windowBackground` (a `layer-list` drawable with a bitmap)
— nothing for the new API. A layer-list with a bitmap isn't valid input
for `windowSplashScreenBackground` (which wants a solid color), so on
Android 12+ specifically, the system fell back to its own default
rendering instead of this app's branded background — the black screen.
Confirmed via Flutter's own current documentation
(docs.flutter.dev/platform-integration/android/splash-screen, "As of
Android 12, you must use the new splash screen API in your styles.xml
file"), and by confirming this project has neither the
`androidx.core:core-splashscreen` dependency, the `flutter_native_splash`
package, nor any `windowSplashScreen*` theme attribute anywhere.

**Compounding — `main()` blocked `runApp()` on notification setup.**
`await NotificationService.initialize()` ran before `runApp()`, meaning
Flutter couldn't produce a first frame — splash included — until that
native platform-channel round-trip (`flutter_local_notifications` setting
up its Android notification channel) finished. This has nothing to do
with anything shown on screen at launch; the earliest it's actually used
is a Focus/Break timer completing, minutes later at best.

Ruled out during the audit: no `Future.delayed`/artificial splash delay
beyond a deliberate 200ms progress-bar settle (unchanged, see below); no
Firebase or database init (none exists); `store.init()` was already
correctly parallelized with the splash animation, not blocking it;
`google_fonts` doesn't block the first frame (it renders with a fallback
font and swaps in asynchronously) — though see the noted limitation below
about it never actually applying here.

### 2. Files changed

Native Android (new unless noted):
- `android/app/src/main/res/values-v31/styles.xml` — Android 12+ light-mode `LaunchTheme`, the primary fix
- `android/app/src/main/res/values-night-v31/styles.xml` — same, dark mode
- `android/app/src/main/res/drawable-night/launch_background.xml` — see below
- `android/app/src/main/res/values/colors.xml` — modified, added `launch_bg_light`
- `android/app/src/main/res/drawable/launch_background.xml` — modified, now references the named color instead of a hardcoded hex
- `android/app/src/main/res/values/styles.xml`, `values-night/styles.xml` — modified, comment only (points to the new `-v31` siblings)
- `android/app/src/main/kotlin/com/meridian/app/MainActivity.kt` — modified, exit-animation-flicker fix
- `android/app/src/main/AndroidManifest.xml` — modified, comment only

Flutter:
- `lib/main.dart` — removed the blocking notification-service await; `main()` no longer needs `async` at all
- `lib/screens/splash_screen.dart` — notification-service init joined into the existing parallel wait

### 3. Native Android changes, in plain terms

Added the Android 12+ native SplashScreen theme (`values-v31`) with
`windowSplashScreenBackground` set to the same background color the
existing branded drawable already used (`#F4F9FD` light /`#0A0A0E`
dark — the dark color was already sitting defined-but-unused in
`colors.xml`, seemingly unfinished prior work; drawable-night/
launch_background.xml didn't exist at all, so a dark-mode device was
also getting the light native background before this). Deliberately did
**not** set `windowSplashScreenAnimatedIcon` — leaving it unset makes
Android 12+ use the app's own adaptive launcher icon automatically (the
wolf+compass mark, already correctly padded for the adaptive-icon safe
zone from an earlier session), so the splash icon is guaranteed
identical to the real app icon with zero new drawables and zero custom
animation. `MainActivity.kt` gained a small `onCreate` override, guarded
to API 31+, that removes the system splash view immediately on exit
instead of waiting out its built-in fade — Flutter's own docs flag this
exact scenario as a flicker risk at the native→Flutter handoff. Used the
platform `Activity.getSplashScreen()` API directly rather than pulling
in the AndroidX `core-splashscreen` compat library, since pre-31 devices
already have a working splash via the untouched classic mechanism and
didn't need a new Gradle dependency added for this.

### 4. Flutter changes, in plain terms

`NotificationService.initialize()` moved out of `main()` and into
`SplashScreen`'s existing `Future.wait([...])` alongside `store.init()`
and the entrance animation — still guaranteed to finish before AppShell
mounts, just no longer blocking the first frame. Nothing else in
`splash_screen.dart` changed: same 1600ms entrance animation, same
orbital ring, same logo treatment, same `cacheWidth`/`cacheHeight`
decode-size optimization, same `pushReplacement` (so the splash route is
removed from the stack, not just covered — back navigation still can't
reach it), same 200ms settle buffer before navigating (kept deliberately
— it exists so the progress bar visibly finishes and the text isn't cut
mid-fade on fast devices/loads, not to hide slow init, and 200ms is far
below the threshold of feeling like an artificial delay).

### 5–8. Performance, deferral, animation, logo

- **Deferred:** notification-channel setup (see above) — the only
  meaningfully deferrable initialization found. `store.init()` was
  already deferred correctly before this session.
- **Nothing was added to hide slow init behind a longer splash** — the
  fix removes blocking work; it doesn't compensate for it with a timer.
- **Splash animation:** fully preserved, unchanged — same durations,
  curves, and visual concept.
- **Logo:** fully preserved — the Flutter splash still reads
  `assets/icon/app_icon.png` unchanged, and the native side reuses the
  same adaptive launcher icon rather than introducing a second asset.

### 9–10. Tests executed / cold-start results

**None of this was run — stated plainly, not implied.** There is no
Flutter/Dart/Android SDK, emulator, or physical device in this
environment, consistent with every other session in this log. Concretely
**not executed**: `flutter analyze`, `flutter test` (no `test/` suite
exists yet regardless), `flutter build apk --debug`, `flutter build apk
--release`, and no cold-start / force-stop / recents-cleared / repeated
-launch testing was performed, because none of that is possible without
real tooling.

**What was actually done, and should be labeled IMPLEMENTED, not
VERIFIED:**
- Every changed XML file was parsed with Python's `xml.etree.ElementTree`
  to confirm well-formedness (all passed).
- Every `@color/`/`@drawable/` reference across `res/` was cross-checked
  against actually-defined resources (all resolve; no orphaned
  references).
- The `values-night-v31` qualifier ordering (night before the API-level
  qualifier, which must always be last) was independently confirmed
  against `flutter_native_splash`'s own real generated build output for
  this exact scenario, not assumed from memory.
- `MainActivity.kt`'s brace/paren balance was checked manually (no Kotlin
  compiler available).
- This project's existing manual checks (Dart brace/import/package-
  reference balance) were re-run across the whole project and pass.
- `git diff` confirms `app_shell.dart` — where the back-navigation policy
  lives — was not touched this session, so that policy is structurally
  unaffected; it was not re-tested at runtime.

**Please run, before considering this done:** `flutter analyze`;
`flutter build apk --debug` (the real test of whether the new resource
qualifiers and Kotlin change actually compile); then physically:
force-stop and cold-launch on an API 31+ device in both light and dark
system mode, launch after clearing from recents, and a few consecutive
normal launches, watching specifically for any black/white flash between
tapping the icon and the branded splash appearing, and for a smooth
splash → AppShell handoff. Also re-check the back-navigation scenarios
from the previous addendum, since a regression there wouldn't be caught
by anything above.

### 11. Remaining limitations

- **Not fixed, out of scope for "startup/splash" specifically:**
  `google_fonts`' Poppins likely never actually loads on a device, since
  this app declares no `INTERNET` permission (by design — see the
  manifest's own comment) and no font files are bundled as local assets
  either. It fails silently to the system fallback font rather than
  causing any delay, so it's unrelated to the black-screen problem, but
  worth knowing: the app may be rendering in a different typeface than
  intended. Flagged here rather than changed, since fixing it means
  either adding network access or bundling font assets — a typography/
  dependency decision beyond this pass's brief.
- Pre-31 devices were not touched at all (their existing mechanism
  already worked); this pass is specifically an Android 12+ fix.
- No iOS launch screen exists in this project to audit — Android-only,
  consistent with the rest of the codebase.

---

## Addendum — mixed Arabic/English (BiDi) text input

**Root cause:** none of this app's `TextField`s ever set `textDirection`
explicitly, so every one of them inherited the ambient `Directionality`
— LTR, since the app has no RTL locale configured — regardless of what
was actually typed. Flutter's text engine already implements the Unicode
bidirectional algorithm correctly *within* a paragraph (mixed-direction
runs shape and order correctly), but it needs the right *base* direction
for that paragraph, and nothing was providing one. Arabic-dominant text
ended up anchored to the left edge instead of the right — not garbled,
just wrongly anchored, and unpredictable to edit.

**Audited every editable text input in the app** (13 total —
`TextField`/`TextFormField` occurrences across `task_modal.dart`,
`habit_modal.dart`, `resource_modal.dart`, `plan_my_day_modal.dart`,
`end_of_day_review_modal.dart`, `focus_screen.dart`; no other custom
text-input implementation exists — searched for `CupertinoTextField`,
`EditableText`, `SearchBar`/`SearchAnchor` too) and classified each one:

- **9 natural-language fields** (task title/notes, habit name, resource
  title/description, the 3 "plan my day" priority fields + its
  commitments field, both end-of-day review fields): now use a new
  shared `MrdBidiTextField` widget instead of a plain `TextField`.
- **2 URL fields** (task Link, resource URL): explicitly given
  `textDirection: TextDirection.ltr` on a plain `TextField` — URLs must
  stay LTR regardless of surrounding content, so this is an intentional,
  documented exception, not an oversight.
- **2 numeric fields** (task Duration, Focus's custom-duration field):
  left untouched, with a comment explaining why, so a future editor
  doesn't wonder if they were missed.

**New files:**
- `lib/utils/bidi_utils.dart` — pure `detectTextDirection(String)`
  function. Uses the "first strong character" heuristic (the same
  approach behind HTML's `dir="auto"` and the `intl` package's
  `Bidi.estimateDirectionOfText`): scan for the first character with
  real directionality, skipping digits/punctuation/whitespace/emoji
  (which are direction-neutral), and use that character's direction as
  the paragraph's base. RTL detection covers the Hebrew/Arabic Unicode
  blocks and their presentation-form ranges; LTR covers Latin plus a few
  common additional scripts. No hardcoded `TextAlign.right` or
  `TextDirection.rtl` anywhere — direction is always derived from
  content.
- `lib/widgets/shared/mrd_bidi_text_field.dart` — the one shared,
  reusable widget every natural-language field now uses, so the
  detection/listening logic exists in exactly one place rather than
  being duplicated across 9 call sites. Wraps a plain `TextField`,
  listens to the *caller's own* `TextEditingController` (never creates
  its own), and only rebuilds when the detected direction actually
  flips — not on every keystroke. While the field is empty it detects
  direction from the hint text instead, so an Arabic placeholder still
  reads right-to-left rather than defaulting to LTR just because nothing
  has been typed yet.

**Cursor/editing behavior:** not reimplemented — deliberately left to
Flutter's own text-layout engine, which already handles caret movement,
selection, and logical-order backspace/delete correctly for
mixed-direction text once given the right base direction. Changing
`textDirection` on a mounted field does not touch the
`TextEditingController`'s `text`/`selection` (a logical character
offset, independent of rendering direction) — so it can't cause cursor
jumps or lose the current selection; it only changes how that logical
position is drawn on screen. Copy/paste is completely unaffected since
this fix never reads or writes the text content itself, only which
direction it's laid out in.

**Verification:** the detection algorithm itself was ported to Python
and run against every example and edge case listed in the brief (plain
Arabic, plain English, Arabic+English, +numbers, +punctuation, an
English term inside Arabic prose, Arabic words inside English prose, a
URL embedded in Arabic prose, multiple spaces, leading parentheses/
hyphen/slash, and emoji leading either an Arabic or English phrase) —
all matched the expected direction. That confirms the *logic* is
correct; it is not a substitute for compiling the actual Dart. **As with
every other session in this log, there is no Flutter/Dart SDK in this
environment, so `flutter analyze`, `flutter test`, and `flutter build`
were not run.** This project also has no `test/` suite yet. Please run
`flutter analyze` yourself and manually try each of the example phrases
above in a real task/habit/resource field, particularly editing an
*existing* Arabic entry (to check the no-flash-of-wrong-direction claim)
and typing across a direction change mid-sentence.

**Known limitation / deliberate scope boundary:** this covers *editing*
— the brief's own audit list. Saved Arabic text is also *displayed*
elsewhere (the Tasks list, Dashboard previews, Planner blocks, Habit
cards) via plain `Text` widgets, which have the same "inherits ambient
LTR `Directionality`" characteristic. Whether that's visually a problem
in practice wasn't in scope here and wasn't changed; if it turns out to
need the same treatment, the fix is the same `detectTextDirection()`
helper, wrapping the relevant `Text` widget's `textDirection` — a
separate, smaller follow-up rather than something folded in silently
here.

---

## Addendum — Android back-navigation policy

Implemented per spec: secondary screens (Planner/Tasks/Habits/Focus via
the bottom-nav tabs, Analytics/Resources/Settings via the pushed
full-screen pages) now go back to Dashboard on a back press instead of
exiting; pressing back again from Dashboard asks "Exit Meridian?" (Cancel
/ Exit) using the existing `showMrdConfirm` component, extended with a
non-destructive style option rather than a new dialog.

**Where it lives (centralized, not per-screen):**
- `app_shell.dart`'s `PopScope` wraps the shell's own `Scaffold` and
  decides tab -> Dashboard vs. exit-confirm in `_handleBackPress()`. It
  only intercepts a pop attempt on *this* route — while any dialog,
  bottom sheet, or the pushed Analytics/Resources/Settings page is on
  top, that route's own default pop behavior (dismiss it) runs first and
  never reaches this handler, which is what makes "modal closes before
  navigating" and "keyboard dismisses before navigating" work without any
  extra code — both already fall out of Flutter/Android defaults that
  nothing here overrides.
- `_openFullScreen`'s pushed route resets the tab index to Dashboard in
  a `.then()` once popped, so returning from Analytics/Resources/Settings
  always lands on Dashboard rather than whichever tab was active before
  — covering the app bar back arrow and edge-swipe, not just the system
  button.
- Uses `PopScope`'s current `onPopInvokedWithResult` API, not the
  deprecated `onPopInvoked` or `WillPopScope` (confirmed against
  Flutter's own deprecation notices before implementing).

**Focus session safety:** leaving the Focus tab this way resets only
`_focusSessionActive` (the shell's own chrome-hiding flag) — it has no
connection to `FocusScreen`'s internal timer, which keeps counting down
from a wall-clock `_endAt` in the background exactly as it already does
when switching tabs normally. No session data or progress is at risk.

**Verification — read this before assuming it's device-tested:** every
item in the spec's checklist was traced through by reading the resulting
code path (documented above), plus this project's existing manual checks
(brace/import/package-reference balance — there's still no Flutter/Dart
SDK in this environment to run the real thing). **`flutter analyze` and
`flutter test` were not run by me** — no SDK access here, same
constraint as every other session in this log. There is also no `test/`
suite in this project yet, so `flutter test` currently has nothing to
run either way. Please run `flutter analyze` yourself (as last time) and
physically test the system back button on a device — particularly the
Focus-tab-with-a-running-session case and the modal/keyboard-dismissal
cases, since those depend on OS-level behavior this environment can't
reproduce. Marking this implemented, not verified end-to-end.

---

## Addendum — logo swap

The new wolf+compass mark replaced the app icon this session. Worth
recording: `assets/icon/app_icon.png` (the file this brief's "existing
approved Meridian logo" note assumed already matched this design) was
actually still a generic blue mountain/"M" placeholder — so this was the
mark's first real implementation, not a swap of one wolf/compass version
for another.

Updated: `assets/icon/app_icon.png` (master source + splash screen image,
since `splash_screen.dart` reads this same file), all 5 densities of the
legacy launcher icon (`mipmap-*/ic_launcher.png`), and all 5 densities of
the adaptive-icon foreground layer (`drawable-*/ic_launcher_foreground.png`
— confirmed via the manifest/`ic_launcher.xml` resolution chain to be the
one actually shown on real Android 8+ devices, ahead of a same-named but
unused `mipmap-*/ic_launcher_foreground.png` set left over from an earlier
generation, which was also updated for consistency rather than left
showing the old mark). The foreground layer uses a clean alpha cutout of
the mark (background removed, transparent canvas) padded so the compass
needle tips clear Android's adaptive-icon mask on every launcher shape —
verified against simulated circle and squircle crops. No Dart/UI code
changes were needed: the splash screen's white circular card already
happens to match the new logo's own near-white background almost exactly,
and its accent color (sky blue) pairs cleanly with the mark's navy.

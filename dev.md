# Meridian - Development Log

## 1. Project Starting Point
This log documents all features, modifications, and extensions added to the Meridian project by Danial. The goal is to extend the app strictly adhering to the `Offline-first` and `Minimal Change` principles, preserving the original developer's architecture, UI design, and existing data.

## 2. Existing Features At Start
Before my work began, the application already contained:
- **Dashboard:** Interactive DayRing, up-next tasks, and habit summaries.
- **Planner:** Drag-and-drop daily time-blocking grid.
- **Focus Mode:** Custom Pomodoro timer linked to tasks.
- **Tasks:** CRUD operations with date and status filtering.
- **Habits:** Daily tracking with 30-day visual heatmaps and streak calculations.
- **Analytics:** Custom-painted charts for focus trends, category distribution, and completion rates.
- **Resources:** URL and image storage for educational materials.
- **Settings:** Local JSON Backup/Restore, theme switching, and pomodoro preferences.

## 3. Architecture At Start
- **State Management:** `Provider` (`ChangeNotifier`).
- **Data Persistence:** Local JSON storage via `shared_preferences` containing a unified `MeridianData` object.
- **UI/Theme:** Custom design system driven by `ThemeController` and `MeridianColors` (No heavy reliance on default Material UI).

---

## 4. Features Added By Danial

### Feature 1: Advanced Productivity Progress
**Status:** Completed
**Purpose:** 
To provide the user with a deeper understanding of their productivity by comparing planned vs completed tasks and measuring overall habit consistency across specific time ranges (Today, This week, This month).
**Existing Feature Check:** 
Partially existed. The app already calculated completion rates and habit streaks, but lacked an aggregated view of "Planning vs Execution" and global "Habit Adherence".
**Implementation:** 
- Computed `habitConsistency` dynamically based on the selected time range (`_range`) using existing `store.habits` data.
- Leveraged the existing `history` slice to aggregate total planned tasks vs completed tasks.
- Created a new UI component `AdvancedProgressOverview` inside `analytics_charts.dart` to visually represent these two metrics using the established progress bar design.
**Files Modified:** 
- `lib/screens/analytics_screen.dart`
- `lib/widgets/analytics/analytics_charts.dart`
**Files Added:** None.
**Dependencies Added:** None.
**Data Changes:** None (Data integrity strictly preserved).
**UI Changes:** Added a new `ChartCard` named "Execution & Consistency" to the Analytics screen.
**Logic Changes:** Added dynamic percentage calculation logic for habit adherence across variable timeframes.
**Testing:** Verified compilation and checked that changing the time range tab successfully updates the metrics dynamically.
**Known Limitations:** None.

---

### Feature 2: Task Delay / Overdue Analysis
**Status:** Completed
**Purpose:** 
To discover patterns in postponed tasks without penalizing the user, identifying how many tasks are delayed and which category suffers the most delays.
**Existing Feature Check:** 
Not implemented. Previously, changing a task's date simply overwrote the old date without tracking the shift.
**Implementation:** 
- Modified the `Task` model to include a `postponedCount` integer field (default 0).
- Bumped `kMeridianDataVersion` to `3` in `persistence.dart` and wrote a safe migration to initialize `postponedCount` for all legacy tasks, preventing data loss.
- Added intelligent tracking in `meridian_store.dart`: when a task is updated to a future date, `postponedCount` increments automatically.
- Created a new UI component `DelayAnalysisCard` inside the newly created `analysis` folder to extract and display the total delayed tasks and the most frequently postponed category.
**Files Modified:** 
- `lib/models/domain.dart`
- `lib/store/persistence.dart`
- `lib/store/meridian_store.dart`
- `lib/screens/analytics_screen.dart`
**Files Added:** 
- `lib/analysis/delay_analysis.dart`
**Dependencies Added:** None.
**Data Changes:** Added `postponedCount` to `Task` model. Migrated local storage to version 3 safely.
**UI Changes:** Added "Task Delays" card to the Analytics screen.
**Known Limitations:** Currently tracks count of delays but does not store the original intended date.
### Feature 3: Habit Commitment Analysis
**Status:** Completed
**Purpose:** 
To dynamically identify and display patterns in habit adherence, specifically highlighting the most consistent habit and flagging habits that need attention.
**Existing Feature Check:** 
Partially existed. Streak tracking and completion rates were already computed internally in `HabitWithStats`, but no analytical UI existed to extract and present behavior patterns.
**Implementation:** 
- Created `HabitCommitmentCard` within a new `habit_analysis.dart` file.
- Used local sorting to evaluate `completionRate` across all habits.
- Displayed the "Most Consistent" habit and intelligently flagged a "Needs Attention" habit only if its completion rate drops below 50%.
**Files Modified:** 
- `lib/screens/analytics_screen.dart`
**Files Added:** 
- `lib/analysis/habit_analysis.dart`
**Dependencies Added:** None.
**Data Changes:** None. Fully utilized existing derived stats to ensure 0% risk to user data.
**UI Changes:** Added "Habit Commitment" insights card to the Analytics screen.
**Known Limitations:** Analysis is based on lifetime completion rate, not bounded by the active 7/30 day filters.
### Feature 4: Productivity Pattern Analysis
**Status:** Completed
**Purpose:** 
To extract and present behavioral insights based purely on recorded data, avoiding speculative reasoning. It highlights peak focus times, best performing weekdays, and priorities most prone to delay.
**Existing Feature Check:** 
Not implemented. The app collected the raw data (`focusLog`, `history`, `tasks`) but lacked a unifying layer to observe and translate this data into readable trends.
**Implementation:** 
- Created `ProductivityPatternCard` in `pattern_analysis.dart`.
- Parsed `focusLog` timestamps to group focus minutes into Day parts (Morning, Afternoon, Evening, Night).
- Evaluated the 28-day `history` to calculate the mathematical completion rate per weekday.
- Counted delay frequencies grouped by `TaskPriority`.
**Files Modified:** 
- `lib/screens/analytics_screen.dart`
**Files Added:** 
- `lib/analysis/pattern_analysis.dart`
**Dependencies Added:** None.
**Data Changes:** 0% risk. Strictly read-only operations parsing existing local data structures.
**UI Changes:** Added "Productivity Patterns" insights card to the Analytics screen displaying 3 data-driven observations.
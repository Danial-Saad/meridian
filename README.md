# Meridian — Precision Productivity 

> A local-first, offline-first personal productivity application built with Flutter & Dart. 
> Designed to be a unified control center for your daily planning, tasks, habits, focus, and analytics.

---

## 📱 About the Project
Meridian is a hand-written Flutter port of a modern productivity web application. It combines deep time-blocking, habit adherence tracking, a built-in Pomodoro focus mode, and comprehensive productivity analytics into a single, clean mobile experience.

- **No Backend / No Cloud:** 100% private. All data is securely stored locally on your device using `SharedPreferences`.
- **No Sign-in Required:** Open the app and start planning immediately.
- **Minimalist Dark & Light Themes:** Intentionally designed color tokens for maximum legibility and focus.

---

## 🚀 Key Features

- **Dashboard:** Interactive 24-hour DayRing gauge, quick daily greeting, "Plan My Day" wizard, and evening reviews.
- **Planner:** Precision time-blocking grid with smooth long-press-and-drag reordering and resizing.
- **Focus Mode:** Custom and preset Pomodoro timers linked directly to your active tasks with background time-tracking resilience.
- **Tasks Management:** Advanced filtering by date (Today, Upcoming, Past, Any date), category, and status with priority badges.
- **Habit Tracking:** Daily streaks, best records, 30-day visual heatmaps, and quick completion.
- **Analytics:** Custom-painted charts (focus trends, category distribution, completion breakdown, and execution consistency).
- **Resources Hub:** Keep course links, documentation, and useful references organized in one place with local cover images.
- **Data Portability:** Full JSON backup export and import, with versioned migration support.

---

## 🛠️ Tech Stack & Architecture

- **Framework:** Flutter (Dart)
- **State Management:** `Provider` (`ChangeNotifier`) architecture mimicking a unified local store.
- **Persistence:** `shared_preferences` with structural validation and corruption recovery.
- **Graphics:** Custom-painted visual elements via `CustomPainter` for high performance.

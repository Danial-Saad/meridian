import 'package:flutter/foundation.dart';

/// NOTIFICATIONS SYSTEM — tap routing bridge.
///
/// A notification tap is handled by `NotificationService` at the
/// `MaterialApp` level, with no `BuildContext` inside any particular
/// screen — the app might be terminated, backgrounded, or sitting on any
/// tab when it happens. Rather than reaching into `AppShell`'s private
/// state directly (or duplicating navigation logic per notification
/// type, which section 20 of the brief explicitly asks to avoid),
/// `NotificationService` just records *which tab* the tap wants and
/// `AppShell` — the one place that already owns tab state — applies it.
/// This is the entire integration surface with the existing
/// back-navigation policy: nothing about how back navigation itself
/// works is touched.
///
/// [tabIndex] matches `AppShell`'s own tab order: 0 Dashboard, 1 Planner,
/// 2 Focus, 3 Tasks, 4 Habits.
class PendingNavigation {
  PendingNavigation._();

  /// Null when there's nothing to apply. AppShell sets it back to null
  /// immediately after consuming it, so it never re-fires on an
  /// unrelated rebuild.
  static final ValueNotifier<int?> tabIndex = ValueNotifier<int?>(null);

  static void requestTab(int index) => tabIndex.value = index;
}

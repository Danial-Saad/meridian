import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemNavigator;
import 'package:provider/provider.dart';
import 'l10n/app_localizations.dart'; // استيراد ملفات الترجمة

import 'models/domain.dart';
import 'screens/analytics_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/focus_screen.dart';
import 'screens/habits_screen.dart';
import 'screens/planner_screen.dart';
import 'screens/resources_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/tasks_screen.dart';
import 'services/notification_service.dart';
import 'services/pending_navigation.dart';
import 'store/meridian_store.dart';
import 'theme/app_theme.dart';
import 'utils/format_utils.dart';
import 'widgets/planner/end_of_day_review_modal.dart';
import 'widgets/planner/plan_my_day_modal.dart';
import 'widgets/shared/confirm_dialog.dart';
import 'widgets/shared/mrd_toast.dart';
import 'widgets/tasks/task_modal.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;
  String? _focusTaskId;
  bool _focusSessionActive = false;

  @override
  void initState() {
    super.initState();
    PendingNavigation.tabIndex.addListener(_onPendingNavigation);
    if (PendingNavigation.tabIndex.value != null) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _onPendingNavigation());
    }
    // UI/UX FIX (design critique #2): the automatic, unexplained
    // notification-permission prompt that used to fire here 600ms after
    // first launch now only ever happens from an explicit, informed tap
    // on the last page of onboarding_screen.dart — see that file for the
    // reasoning. First-time launches go through onboarding before ever
    // reaching AppShell, so by the time this screen exists at all, that
    // choice (enable now / not now) has already been made deliberately.
  }

  @override
  void dispose() {
    PendingNavigation.tabIndex.removeListener(_onPendingNavigation);
    super.dispose();
  }

  void _onPendingNavigation() {
    final target = PendingNavigation.tabIndex.value;
    if (target == null) return;
    PendingNavigation.tabIndex.value = null;
    setState(() {
      _index = target;
      _focusSessionActive = false;
    });
  }

  void _goTo(int index) => setState(() => _index = index);

  void _setFocusSessionActive(bool active) {
    if (active == _focusSessionActive) return;
    setState(() => _focusSessionActive = active);
  }

  void _openNewTaskModal({int? presetStart, String? presetDate}) {
    final store = context.read<MeridianStore>();
    showTaskModal(
      context,
      mode: 'create',
      presetStart: presetStart,
      presetDate: presetDate ?? dayKey(DateTime.now()),
      timeFormat24: store.settings.timeFormat24,
      onSave: store.addTask,
    );
  }

  void _openPlanMyDay() {
    final store = context.read<MeridianStore>();
    final l10n = AppLocalizations.of(context)!;
    final today = dayKey(DateTime.now());
    showPlanMyDayModal(
      context,
      targetDate: today,
      existingTasksForDate:
          store.tasks.where((t) => t.taskDate == today).toList(),
      onApply: (blocks) {
        for (final b in blocks) {
          store.addTask(b);
        }
        store.notify(
            ToastKind.success, l10n.blocksAddedToast(blocks.length));
      },
    );
  }

  void _openEndOfDayReview() {
    final store = context.read<MeridianStore>();
    final stats = store.stats;
    final habits = store.habits;
    final todayKey = dayKey(DateTime.now());
    final habitsCompletedToday =
        habits.where((h) => h.logs[todayKey] == true).length;
    showEndOfDayReviewModal(
      context,
      stats: stats,
      habitsCompleted: habitsCompletedToday,
      habitsTotal: habits.length,
      onSave: (wentWell, improve) {
        store.saveReview(
          todayKey,
          DailyReview(
            tasksCompleted: stats.completed,
            tasksTotal: stats.actionable,
            focusMinutes: stats.focusMinutes,
            habitsCompleted: habitsCompletedToday,
            habitsTotal: habits.length,
            wentWell: wentWell,
            improve: improve,
            savedAt: DateTime.now().millisecondsSinceEpoch,
          ),
        );
      },
    );
  }

  void _openFullScreen(Widget child, String Function(AppLocalizations) titleBuilder) {
    Navigator.of(context)
        .push(MaterialPageRoute(
      builder: (ctx) => _FullScreenPage(titleBuilder: titleBuilder, child: child),
    ))
        .then((_) {
      if (mounted && _index != 0) setState(() => _index = 0);
    });
  }

  void _handleBackPress() {
    if (_index != 0) {
      setState(() {
        _index = 0;
        _focusSessionActive = false;
      });
      return;
    }
    _confirmExit();
  }

  void _confirmExit() {
    final l10n = AppLocalizations.of(context)!;
    showMrdConfirm(
      context,
      title: l10n.exitMeridianTitle,
      description: l10n.exitMeridianDesc,
      confirmLabel: l10n.exitLabel,
      isDestructive: false,
      icon: Icons.exit_to_app,
      confirmIcon: Icons.exit_to_app,
      onConfirm: () => SystemNavigator.pop(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ThemeController>().colors;
    final l10n = AppLocalizations.of(context)!; // جلب نصوص الترجمة
    context.read<MeridianStore>().setLocalizations(l10n);
    NotificationService.setLocalizations(l10n);

    final screens = [
      DashboardScreen(
        onGoPlanner: () => _goTo(1),
        onGoFocus: (id) => setState(() {
          _focusTaskId = id;
          _index = 2;
        }),
        onNew: () => _openNewTaskModal(),
        onOpenPlanDay: _openPlanMyDay,
        onOpenReview: _openEndOfDayReview,
        onGoHabits: () => _goTo(4),
        onGoAnalytics: () =>
            _openFullScreen(const AnalyticsScreen(), (l10n) => l10n.analyticsTitle),
      ),
      PlannerScreen(
          onSlotClick: (start, date) =>
              _openNewTaskModal(presetStart: start, presetDate: date)),
      FocusScreen(
          focusTaskId: _focusTaskId,
          setFocusTaskId: (id) => setState(() => _focusTaskId = id),
          isActive: _index == 2,
          onSessionActiveChanged: _setFocusSessionActive),
      const TasksScreen(),
      const HabitsScreen(),
    ];

    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBackPress();
      },
      child: Scaffold(
        backgroundColor: c.bg,
        appBar: AppBar(
          backgroundColor: c.bg,
          elevation: 0,
          scrolledUnderElevation: 0,
          titleSpacing: 16,
          title: Text('Meridian',
              style: TextStyle(
                  color: c.text,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.3)),
          actions: _focusSessionActive
              ? const []
              : [
                  IconButton(
                    icon: Icon(Icons.bar_chart_outlined, color: c.textDim),
                    tooltip: l10n.analyticsTitle,
                    onPressed: () =>
                        _openFullScreen(const AnalyticsScreen(), (l10n) => l10n.analyticsTitle),
                  ),
                  IconButton(
                    icon: Icon(Icons.school_outlined, color: c.textDim),
                    tooltip: l10n.resourcesTitle,
                    onPressed: () =>
                        _openFullScreen(const ResourcesScreen(), (l10n) => l10n.resourcesTitle),
                  ),
                  IconButton(
                    icon: Icon(Icons.settings_outlined, color: c.textDim),
                    tooltip: l10n.settings, // النص المترجم للإعدادات
                    onPressed: () =>
                        _openFullScreen(const SettingsScreen(), (l10n) => l10n.settings),
                  ),
                  const SizedBox(width: 4),
                ],
        ),
        body: Stack(
          children: [
            IndexedStack(
              index: _index,
              children: [
                for (var i = 0; i < screens.length; i++)
                  TickerMode(enabled: i == _index, child: screens[i]),
              ],
            ),
            const _ToastLayer(),
          ],
        ),
        bottomNavigationBar: _focusSessionActive
            ? null
            : NavigationBarTheme(
                data: NavigationBarThemeData(
                  backgroundColor: c.bgElevated,
                  indicatorColor: c.primaryBg,
                  labelTextStyle: WidgetStateProperty.resolveWith((states) {
                    final selected = states.contains(WidgetState.selected);
                    return TextStyle(
                        fontSize: 10,
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.w500,
                        color: selected ? c.primary : c.textFaint);
                  }),
                  iconTheme: WidgetStateProperty.resolveWith((states) {
                    final selected = states.contains(WidgetState.selected);
                    return IconThemeData(
                        color: selected ? c.primary : c.textFaint, size: 22);
                  }),
                ),
                child: NavigationBar(
                  selectedIndex: _index,
                  onDestinationSelected: _goTo,
                  height: 62,
                  destinations: [
                    NavigationDestination(
                        icon: const Icon(Icons.home_outlined),
                        selectedIcon: const Icon(Icons.home),
                        label: l10n.navToday), // النص المترجم
                    NavigationDestination(
                        icon: const Icon(Icons.calendar_month_outlined),
                        selectedIcon: const Icon(Icons.calendar_month),
                        label: l10n.navPlanner), // النص المترجم
                    NavigationDestination(
                        icon: const Icon(Icons.track_changes_outlined),
                        selectedIcon: const Icon(Icons.track_changes),
                        label: l10n.navFocus), // النص المترجم
                    NavigationDestination(
                        icon: const Icon(Icons.checklist_outlined),
                        selectedIcon: const Icon(Icons.checklist),
                        label: l10n.navTasks), // النص المترجم
                    NavigationDestination(
                        icon: const Icon(Icons.local_fire_department_outlined),
                        selectedIcon: const Icon(Icons.local_fire_department),
                        label: l10n.navHabits), // النص المترجم
                  ],
                ),
              ),
      ),
    );
  }
}

class _FullScreenPage extends StatelessWidget {
  final Widget child;
  // BUG FIX: this used to be a plain `String title` resolved once, at
  // the moment the user tapped the icon that opened this page
  // (`l10n.settings` etc., evaluated at the *caller's* build time). A
  // StatelessWidget with a fixed String field never rebuilds that field
  // on its own, so if the in-app language was changed *while this page
  // was already open* (Settings is the obvious case — you're looking
  // right at the language picker), the page body re-rendered correctly
  // (it reads `AppLocalizations.of(context)` live, every build) but this
  // AppBar's title stayed frozen in whatever language was active at
  // push-time — e.g. a Russian "Настройки" title above an English
  // Settings body. Taking a builder instead and calling it with a fresh
  // `AppLocalizations.of(context)!` inside this widget's own `build()`
  // makes the title just as reactive as the body already was.
  final String Function(AppLocalizations) titleBuilder;
  const _FullScreenPage({required this.child, required this.titleBuilder});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ThemeController>().colors;
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.bg,
        elevation: 0,
        foregroundColor: c.text,
        title: Text(titleBuilder(l10n),
            style: TextStyle(
                color: c.text, fontSize: 17, fontWeight: FontWeight.w600)),
      ),
      body: child,
    );
  }
}

class _ToastLayer extends StatelessWidget {
  const _ToastLayer();

  @override
  Widget build(BuildContext context) {
    final toast = context.watch<MeridianStore>().toast;
    if (toast == null) return const SizedBox.shrink();
    final c = context.watch<ThemeController>().colors;
    return Positioned.fill(
      child: IgnorePointer(child: MrdToast(toast: toast, c: c)),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app_shell.dart';
import '../l10n/app_localizations.dart';
import '../services/notification_service.dart';
import '../store/meridian_store.dart';
import '../theme/app_theme.dart';

// UI/UX FIX (design critique #1 + #2): Meridian had no first-run
// experience at all — a brand-new person landed straight on 5 bottom
// tabs + 3 top icons with zero context for what any of it was for, and
// separately, the very first thing that could happen on that first
// launch was Android's own notification-permission dialog firing cold,
// 600ms in, with no explanation from the app at all — while the App
// Blocking permission elsewhere in this same app already does this
// correctly (a real explanation screen before asking). This flow fixes
// both at once: a short, swipeable introduction to what Meridian
// actually does, ending on the notification ask presented the same
// honest way App Blocking's gate already does it — explain first, let
// the person choose, and never force it.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  static const _prefsKey = 'meridian_has_seen_onboarding';

  static Future<bool> hasBeenSeen() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefsKey) ?? false;
  }

  static Future<void> markSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, true);
  }

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;
  static const _pageCount = 4;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goToPage(int page) {
    _controller.animateToPage(
      page,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _finish() async {
    await OnboardingScreen.markSeen();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const AppShell()),
    );
  }

  // Same permission-and-settings logic app_shell.dart used to run
  // automatically and unexplained on a timer — now it only ever runs
  // from this explicit, informed tap.
  Future<void> _enableNotifications() async {
    final granted = await NotificationService.requestInitialPermissionIfNeeded();
    if (granted && mounted) {
      final store = context.read<MeridianStore>();
      store.updateSettings((s) => s.copyWith(
            notificationsEnabled: true,
            taskRemindersEnabled: true,
            habitRemindersEnabled: true,
            dailyPlanningRemindersEnabled: true,
          ));
      await NotificationService.requestExactAlarmPermissionIfNeeded();
    }
    await _finish();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ThemeController>().colors;
    final l10n = AppLocalizations.of(context)!;
    final isLastPage = _page == _pageCount - 1;

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Skip — hidden on the last page; there's nothing left to skip.
            SizedBox(
              height: 48,
              child: Align(
                alignment: AlignmentDirectional.topEnd,
                child: isLastPage
                    ? null
                    : Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: TextButton(
                          onPressed: _finish,
                          child: Text(l10n.skipButtonLabel,
                              style: TextStyle(color: c.textFaint)),
                        ),
                      ),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  _OnboardingPage(
                    c: c,
                    icon: Icons.explore_outlined,
                    title: l10n.onboardingWelcomeTitle,
                    subtitle: l10n.onboardingWelcomeSubtitle,
                  ),
                  _OnboardingPage(
                    c: c,
                    icon: Icons.center_focus_strong_outlined,
                    title: l10n.onboardingPlanTitle,
                    subtitle: l10n.onboardingPlanSubtitle,
                  ),
                  _OnboardingPage(
                    c: c,
                    icon: Icons.local_fire_department_outlined,
                    title: l10n.onboardingHabitsTitle,
                    subtitle: l10n.onboardingHabitsSubtitle,
                  ),
                  _OnboardingPage(
                    c: c,
                    icon: Icons.notifications_active_outlined,
                    title: l10n.onboardingNotifTitle,
                    subtitle: l10n.onboardingNotifSubtitle,
                  ),
                ],
              ),
            ),
            // Dots
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_pageCount, (i) {
                  final active = i == _page;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: active ? 20 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: active ? c.primary : c.border,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: isLastPage
                  ? Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _finish,
                            style: OutlinedButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16),
                              side: BorderSide(color: c.border),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text(l10n.notNowButton,
                                style: TextStyle(
                                    color: c.text,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: _enableNotifications,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: c.primary,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text(l10n.enableNotificationsButton,
                                style: TextStyle(
                                    color: c.primaryInk,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    )
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _goToPage(_page + 1),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: c.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(l10n.onboardingNextButton,
                            style: TextStyle(
                                color: c.primaryInk, fontWeight: FontWeight.bold)),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  final MeridianColors c;
  final IconData icon;
  final String title;
  final String subtitle;

  const _OnboardingPage({
    required this.c,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: c.primaryBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 56, color: c.primary),
          ),
          const SizedBox(height: 40),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: c.text, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 14),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(color: c.textDim, fontSize: 15, height: 1.5),
          ),
        ],
      ),
    );
  }
}

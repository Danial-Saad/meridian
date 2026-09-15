import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MeridianColors {
  final Color bg;
  final Color bgElevated;
  final Color surface;
  final Color surfaceHover;
  final Color border;
  final Color text;
  final Color textDim;
  final Color textFaint;
  final Color primary;
  final Color primaryHover;
  final Color primaryBg;
  final Color primaryInk;
  final Color danger;
  final Color dangerBg;
  final Color success;
  final Color successBg;
  final Color warning;
  final Color warningBg;
  final Color scrim;
  final Color periodNight;
  final Color periodMorning;
  final Color periodAfternoon;
  final Color periodEvening;
  final bool isDark;

  const MeridianColors({
    required this.bg,
    required this.bgElevated,
    required this.surface,
    required this.surfaceHover,
    required this.border,
    required this.text,
    required this.textDim,
    required this.textFaint,
    required this.primary,
    required this.primaryHover,
    required this.primaryBg,
    required this.primaryInk,
    required this.danger,
    required this.dangerBg,
    required this.success,
    required this.successBg,
    required this.warning,
    required this.warningBg,
    required this.scrim,
    required this.periodNight,
    required this.periodMorning,
    required this.periodAfternoon,
    required this.periodEvening,
    required this.isDark,
  });

  // --- Nordic Minimal (Strong & Bold) - Light Theme ---
  factory MeridianColors.light() {
    return const MeridianColors(
      bg: Color(0xFFF8FAFC),
      bgElevated: Color(0xFFF1F5F9),
      surface: Color(0xFFFFFFFF),
      surfaceHover: Color(0xFFE2E8F0),
      border: Color(0xFFCBD5E1),
      text: Color(0xFF0F172A),
      textDim: Color(0xFF334155),
      // UI/UX FIX (design critique #3): was 0xFF64748B, computed contrast
      // 4.55:1 on this theme's bg — technically over WCAG AA's 4.5:1
      // floor for normal text, but by a margin so thin that font
      // rendering/anti-aliasing differences across devices could tip it
      // under in practice, and this color is used extensively at 10-11px
      // (well below the 18pt/14pt-bold "large text" threshold that would
      // relax the requirement to 3:1). Darkened slightly for real
      // headroom — verified: 5.14:1 on this bg, 5.37:1 on white surfaces.
      textFaint: Color(0xFF5D6B85),
      primary: Color(0xFF0EA5E9),
      primaryHover: Color(0xFF0284C7),
      primaryBg: Color(0xFFE0F2FE),
      // UI/UX FIX (design critique #3): was pure white. Computed contrast
      // of white text on this theme's `primary` (0xFF0EA5E9) is 2.77:1 —
      // fails WCAG AA even for large text (needs 3:1), let alone the
      // normal-text 4.5:1 floor most of the ~14 call sites using this
      // token (buttons across Dashboard/Tasks/Habits/Resources/Planner
      // and every modal's primary action) render at. Dark navy instead:
      // verified 6.44:1 against this theme's `primary`, comfortably
      // clearing the normal-text threshold.
      primaryInk: Color(0xFF0F172A),
      danger: Color(0xFFEF4444),
      dangerBg: Color(0xFFFEE2E2),
      success: Color(0xFF10B981),
      successBg: Color(0xFFD1FAE5),
      warning: Color(0xFFF59E0B),
      warningBg: Color(0xFFFEF3C7),
      scrim: Color(0x99000000),
      periodNight: Color(0xFF1E3A8A),
      periodMorning: Color(0xFFF59E0B),
      periodAfternoon: Color(0xFF0EA5E9),
      periodEvening: Color(0xFFF97316),
      isDark: false,
    );
  }

  // --- Deep Focus - Dark Theme ---
  factory MeridianColors.dark() {
    return const MeridianColors(
      bg: Color(0xFF0F172A),
      bgElevated: Color(0xFF1E293B),
      surface: Color(0xFF1E293B),
      surfaceHover: Color(0xFF334155),
      border: Color(0xFF334155),
      text: Color(0xFFF8FAFC),
      textDim: Color(0xFF94A3B8),
      // UI/UX FIX (design critique #3): was the exact same 0xFF64748B as
      // the light theme's textFaint — reasonable for a light background,
      // but computed contrast against *this* theme's dark bg is only
      // 3.75:1, failing WCAG AA's 4.5:1 normal-text floor outright (this
      // color is used at 10-11px in plenty of places, well under the
      // "large text" size that would relax the requirement to 3:1).
      // Lightened for dark mode specifically instead of sharing one
      // value across both themes — verified 5.24:1 against this theme's
      // bg, and kept meaningfully dimmer than `textDim` (luminance
      // 0.28 vs 0.36) so the two remain visually distinct tiers.
      textFaint: Color(0xFF7C8CA6),
      primary: Color(0xFF3B82F6),
      primaryHover: Color(0xFF60A5FA),
      primaryBg: Color(0xFF1E3A8A),
      // UI/UX FIX (design critique #3): was pure white — computed
      // contrast against this theme's `primary` (0xFF3B82F6) is 2.14:1,
      // failing WCAG AA even for large text. Same dark-navy fix as the
      // light theme: verified 4.85:1 against this theme's `primary`,
      // clearing the normal-text 4.5:1 floor.
      primaryInk: Color(0xFF0F172A),
      danger: Color(0xFFF87171),
      dangerBg: Color(0xFF7F1D1D),
      success: Color(0xFF34D399),
      successBg: Color(0xFF064E3B),
      warning: Color(0xFFFBBF24),
      warningBg: Color(0xFF78350F),
      scrim: Color(0xB3000000),
      periodNight: Color(0xFF1E3A8A),
      periodMorning: Color(0xFFFBBF24),
      periodAfternoon: Color(0xFF3B82F6),
      periodEvening: Color(0xFFFB923C),
      isDark: true,
    );
  }
}

class ThemeController extends ChangeNotifier with WidgetsBindingObserver {
  static const String _prefsKey = 'meridian_theme_mode';
  ThemeMode _themeMode = ThemeMode.system;

  ThemeController() {
    // BUG FIX: previously only main.dart's own WidgetsBindingObserver
    // reacted to a system dark/light switch, and it only rebuilt the
    // outer MaterialApp shell (which sets the theme: property). Every
    // screen reads colors via `context.watch<ThemeController>().colors`
    // directly though, not via Theme.of(context) — so none of them were
    // actually notified when ThemeMode.system followed the OS brightness,
    // leaving screen content on the stale color scheme until some
    // unrelated rebuild happened to refresh it. Observing here means the
    // controller itself notifies every listener when that happens.
    WidgetsBinding.instance.addObserver(this);
    _loadTheme();
  }

  @override
  void didChangePlatformBrightness() {
    if (_themeMode == ThemeMode.system) notifyListeners();
  }

  // BUG FIX (reported: "phone is in dark mode but Theme=System keeps
  // showing Light"): the OS dark/light toggle almost always lives inside
  // the phone's own Settings app, which means Meridian is backgrounded
  // the instant it's changed — this is a `didChangePlatformBrightness()`
  // firing while the app isn't in the foreground, and on a real
  // (non-emulator) Android device that signal is not reliably delivered
  // to a backgrounded engine the same way it is to a resumed one. So the
  // switch happens on the OS side, but Meridian never hears about it
  // until something else happens to trigger a rebuild. Re-checking
  // platform brightness explicitly on every resume closes that gap: even
  // if the change notification itself was missed while backgrounded,
  // coming back to the app re-reads the *current* brightness fresh and
  // applies it immediately, rather than waiting on a signal that may
  // never arrive for an already-stale session.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _themeMode == ThemeMode.system) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode {
    if (_themeMode == ThemeMode.system) {
      final brightness =
          WidgetsBinding.instance.platformDispatcher.platformBrightness;
      return brightness == Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }

  MeridianColors get colors =>
      isDarkMode ? MeridianColors.dark() : MeridianColors.light();

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final savedMode = prefs.getString(_prefsKey);
    if (savedMode != null) {
      _themeMode = ThemeMode.values.firstWhere(
        (e) => e.toString() == savedMode,
        orElse: () => ThemeMode.system,
      );
      notifyListeners();
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, mode.toString());
  }

  void toggleTheme() {
    setThemeMode(isDarkMode ? ThemeMode.light : ThemeMode.dark);
  }
}

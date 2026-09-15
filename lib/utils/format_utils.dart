import 'dart:math' as math;
import '../l10n/app_localizations.dart';

/// Small shared helpers, ported verbatim from format.ts. dayKey()
/// deliberately uses local date components (year/month/day), never UTC —
/// the same fix the original app carries to avoid a task silently landing
/// on the wrong calendar day depending on timezone.
String pad2(int n) => n.toString().padLeft(2, '0');

String dayKey(DateTime date) => '${date.year}-${pad2(date.month)}-${pad2(date.day)}';

final _rand = math.Random();

String uid() {
  const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
  return List.generate(8, (_) => chars[_rand.nextInt(chars.length)]).join();
}

int clampInt(int v, int min, int max) => math.max(min, math.min(max, v));
double clampDouble(double v, double min, double max) => math.max(min, math.min(max, v));

int snapInt(double v, int step) => (v / step).round() * step;

/// Formats a duration in minutes as "Xh Ym" (e.g. 90 -> "1h 30m") — the
/// same shape that used to be hand-rolled ad-hoc at each Analytics call
/// site. Centralized so new call sites (e.g. the "planned vs actual time"
/// comparison) don't duplicate it again.
String fmtDurationShort(int mins) => '${mins ~/ 60}h ${mins % 60}m';

// BUG FIX (follow-up to the weekday/month fix above, reported
// separately: AM/PM stayed hardcoded English no matter the app
// language — "9:00 AM" even in Arabic/Russian). Russian doesn't have a
// clean binary AM/PM the way English does; confirmed with the person
// what to use rather than guessing — a simple two-way утра/вечера
// (morning/evening) split, stored as `l10n.periodAm`/`l10n.periodPm`.
String minutesToLabel(int mins, AppLocalizations l10n,
    [bool format24 = false]) {
  final h = (mins ~/ 60) % 24;
  final m = ((mins % 60) + 60) % 60;
  if (format24) return '${pad2(h)}:${pad2(m)}';
  final period = h < 12 ? l10n.periodAm : l10n.periodPm;
  var h12 = h % 12;
  if (h12 == 0) h12 = 12;
  return '$h12:${pad2(m)} $period';
}

// UI FIX (reported: the task modal's "Start Hour" dropdown showed a
// full "9:00 AM" — hour *and* minute — right next to a separate
// "Minute" dropdown for picking 0/15/30/45) — the hour field always
// displayed ":00" regardless of what minute was actually selected,
// which reads as contradictory rather than just redundant. This
// formats the hour alone, for pickers where a sibling control already
// owns the minute.
String hourToLabel(int hour, AppLocalizations l10n, [bool format24 = false]) {
  final h = hour % 24;
  if (format24) return pad2(h);
  final period = h < 12 ? l10n.periodAm : l10n.periodPm;
  var h12 = h % 12;
  if (h12 == 0) h12 = 12;
  return '$h12 $period';
}

String fmtClock(DateTime date, AppLocalizations l10n, [bool format24 = false]) {
  final h = date.hour;
  final m = date.minute;
  if (format24) return '${pad2(h)}:${pad2(m)}';
  final period = h < 12 ? l10n.periodAm : l10n.periodPm;
  var h12 = h % 12;
  if (h12 == 0) h12 = 12;
  return '${pad2(h12)}:${pad2(m)} $period';
}

// BUG FIX (reported: the weekday/month header at the top of the Today
// screen — and every other fmtDate/fmtDateShort call site — stayed in
// English no matter what language the app was set to). These used to be
// plain hardcoded English word lists with no locale awareness at all.
// Turns out the translated strings themselves already existed — a full,
// correctly-translated `weekdayMon..Sun` / `monthJan..Dec` /
// `monthShortJan..Dec` set was already sitting in all three .arb files,
// just never wired into any generated getter or ever actually called
// from here. This was a dead-data bug, not a missing-translation one:
// the fix was almost entirely wiring, with one real content gap closed
// along the way — see the ordering note below.
List<String> _weekdayNames(AppLocalizations l10n) => [
      l10n.weekdayMon, l10n.weekdayTue, l10n.weekdayWed, l10n.weekdayThu,
      l10n.weekdayFri, l10n.weekdaySat, l10n.weekdaySun,
    ];
List<String> _monthNames(AppLocalizations l10n) => [
      l10n.monthJan, l10n.monthFeb, l10n.monthMar, l10n.monthApr,
      l10n.monthMay, l10n.monthJun, l10n.monthJul, l10n.monthAug,
      l10n.monthSep, l10n.monthOct, l10n.monthNov, l10n.monthDec,
    ];
List<String> _monthNamesShort(AppLocalizations l10n) => [
      l10n.monthShortJan, l10n.monthShortFeb, l10n.monthShortMar,
      l10n.monthShortApr, l10n.monthShortMay, l10n.monthShortJun,
      l10n.monthShortJul, l10n.monthShortAug, l10n.monthShortSep,
      l10n.monthShortOct, l10n.monthShortNov, l10n.monthShortDec,
    ];

// The Russian month strings above are stored in the *genitive* case
// (e.g. "сентября", not "сентябрь") — the case Russian grammar requires
// right next to a day number, which is the only place these are ever
// used. English puts the month before the day ("September 7"); Arabic
// and Russian both read more naturally day-first ("7 سبتمبر" /
// "7 сентября") — so word order below is locale-aware, not just the
// words themselves.
bool _dayBeforeMonth(AppLocalizations l10n) =>
    l10n.localeName == 'ar' || l10n.localeName == 'ru';

String fmtDate(DateTime date, AppLocalizations l10n) {
  final weekday = _weekdayNames(l10n)[date.weekday - 1];
  final month = _monthNames(l10n)[date.month - 1];
  final monthDay =
      _dayBeforeMonth(l10n) ? '${date.day} $month' : '$month ${date.day}';
  return '$weekday, $monthDay';
}

String fmtDateShort(DateTime date, AppLocalizations l10n) {
  final month = _monthNamesShort(l10n)[date.month - 1];
  return _dayBeforeMonth(l10n) ? '${date.day} $month' : '$month ${date.day}';
}

/// Parses a "YYYY-MM-DD" dayKey into a local DateTime at midnight.
DateTime parseDayKey(String key) {
  final parts = key.split('-');
  if (parts.length != 3) return DateTime.now();
  return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
}

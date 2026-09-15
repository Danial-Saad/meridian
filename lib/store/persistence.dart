import 'dart:convert';
import 'package:flutter/foundation.dart' show compute;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/domain.dart';
import '../utils/format_utils.dart';

const String _storageKey = 'meridian-data';
const int kMeridianDataVersion = 3; // --- FEATURE 2: رفعنا الإصدار إلى 3 ---

MeridianData createEmptyData() => MeridianData(
      version: kMeridianDataVersion,
      tasks: const [],
      habits: const [],
      resources: const [],
      settings: UserSettings.defaults(),
      focusLog: const [],
      reviews: const {},
    );

Map<String, dynamic> _migrateData(Map<String, dynamic> data) {
  final version =
      (data['version'] is num) ? (data['version'] as num).toInt() : 0;

  if (version < 1) {
    final today = dayKey(DateTime.now());
    final rawTasks = (data['tasks'] as List?) ?? [];
    data = {
      ...data,
      'version': 1,
      'tasks': rawTasks.map((t) {
        final m = Map<String, dynamic>.from(t as Map);
        if (m['taskDate'] is! String) m['taskDate'] = today;
        return m;
      }).toList(),
    };
  }

  if (version < 2) {
    data = {
      ...data,
      'version': 2,
      'resources': [],
    };
  }

  // --- FEATURE 2: Data Migration لحماية المهام القديمة ---
  if (version < 3) {
    final rawTasks = (data['tasks'] as List?) ?? [];
    data = {
      ...data,
      'version': 3,
      'tasks': rawTasks.map((t) {
        final m = Map<String, dynamic>.from(t as Map);
        m['postponedCount'] = m['postponedCount'] ?? 0;
        return m;
      }).toList(),
    };
  }

  return data;
}

bool _isPlausibleMeridianData(dynamic value) {
  if (value is! Map) return false;
  return value['tasks'] is List &&
      value['habits'] is List &&
      value['settings'] is Map &&
      value['focusLog'] is List &&
      value['reviews'] is Map;
}

MeridianData _dataFromJson(Map<String, dynamic> json) {
  final today = dayKey(DateTime.now());
  final tasks = ((json['tasks'] as List?) ?? [])
      .map((t) => Task.fromJson(Map<String, dynamic>.from(t as Map),
          fallbackDate: today))
      .toList();
  final habits = ((json['habits'] as List?) ?? [])
      .map((h) => Habit.fromJson(Map<String, dynamic>.from(h as Map)))
      .toList();
  final resources = ((json['resources'] as List?) ?? [])
      .map((r) => UserResource.fromJson(Map<String, dynamic>.from(r as Map)))
      .toList();
  final settings = json['settings'] is Map
      ? UserSettings.fromJson(
          Map<String, dynamic>.from(json['settings'] as Map))
      : UserSettings.defaults();
  final focusLog = ((json['focusLog'] as List?) ?? [])
      .map((f) => FocusLogEntry.fromJson(Map<String, dynamic>.from(f as Map)))
      .toList();
  final rawReviews = (json['reviews'] as Map?) ?? {};
  final reviews = <String, DailyReview>{
    for (final e in rawReviews.entries)
      e.key.toString():
          DailyReview.fromJson(Map<String, dynamic>.from(e.value as Map)),
  };
  return MeridianData(
    version: kMeridianDataVersion,
    tasks: tasks,
    habits: habits,
    resources: resources,
    settings: settings,
    focusLog: focusLog,
    reviews: reviews,
  );
}

class LoadResult {
  final MeridianData data;
  final bool isFresh;
  final bool recoveredFromCorruption;

  const LoadResult(
      {required this.data,
      required this.isFresh,
      required this.recoveredFromCorruption});
}

Future<LoadResult> loadData() async {
  SharedPreferences prefs;
  try {
    prefs = await SharedPreferences.getInstance();
  } catch (_) {
    return LoadResult(
        data: createEmptyData(), isFresh: true, recoveredFromCorruption: false);
  }

  final raw = prefs.getString(_storageKey);
  if (raw == null) {
    return LoadResult(
        data: createEmptyData(), isFresh: true, recoveredFromCorruption: false);
  }

  dynamic parsed;
  try {
    // PERF FIX: jsonDecode of the whole saved blob used to run inline on
    // the UI isolate. After months of daily use (hundreds of tasks/focus
    // sessions), that blob is big enough to cost real milliseconds —
    // compute() runs it on a background isolate instead.
    parsed = await compute(jsonDecode, raw);
  } catch (_) {
    return LoadResult(
        data: createEmptyData(), isFresh: false, recoveredFromCorruption: true);
  }

  if (!_isPlausibleMeridianData(parsed)) {
    return LoadResult(
        data: createEmptyData(), isFresh: false, recoveredFromCorruption: true);
  }

  try {
    final migrated = _migrateData(Map<String, dynamic>.from(parsed as Map));
    final data = _dataFromJson(migrated);
    return LoadResult(
        data: data, isFresh: false, recoveredFromCorruption: false);
  } catch (_) {
    return LoadResult(
        data: createEmptyData(), isFresh: false, recoveredFromCorruption: true);
  }
}

Future<bool> saveData(MeridianData data) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    // PERF FIX: this runs on every single mutation (every task toggle,
    // every habit check-off, every focus session) after the store's
    // 150ms debounce. jsonEncode of the *entire* app data blob used to
    // run synchronously on the UI isolate, so the cost grew with the
    // total amount of data ever saved — exactly the "app gets slower
    // the more I use it" pattern. compute() offloads the encode to a
    // background isolate so it can no longer block a frame.
    final encoded = await compute(jsonEncode, data.toJson());
    final ok = await prefs.setString(_storageKey, encoded);
    return ok;
  } catch (_) {
    return false;
  }
}

Future<void> clearData() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  } catch (_) {}
}

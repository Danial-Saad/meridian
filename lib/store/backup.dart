import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../models/domain.dart';
import '../utils/format_utils.dart';
import 'persistence.dart';

/// Backup file shape: MeridianData plus a small envelope, so an exported
/// backup can run through the same forward-migration path as local storage.
class MeridianBackup {
  final String app;
  final int version;
  final String exportedAt;
  // Holds the already-built data JSON (with resource images embedded, see
  // buildBackup) rather than a typed MeridianData, since the envelope
  // needs to carry fields (imageBase64/imageExt per resource) that
  // UserResource.toJson() itself deliberately doesn't produce — those
  // exist only for normal local persistence, where imagePath alone is
  // enough because the file is already sitting on the same device.
  final Map<String, dynamic> dataJson;

  const MeridianBackup({
    required this.app,
    required this.version,
    required this.exportedAt,
    required this.dataJson,
  });

  Map<String, dynamic> toJson() => {
        'app': app,
        'version': version,
        'exportedAt': exportedAt,
        'data': dataJson,
      };
}

/// BUG FIX: a backup used to only ever store each resource's imagePath —
/// an absolute file path on *this* device. Restoring that backup after a
/// fresh install, on a new phone, or after the app's own storage was
/// cleared meant every resource's cover image silently pointed at a file
/// that no longer existed — the backup wasn't actually a full backup of
/// what the person saved. Now embeds each resource's image bytes
/// (base64) directly in the exported file; parseBackupFile writes them
/// back out to fresh files on import. Non-fatal on a per-resource basis:
/// if one image can't be read, that resource's backup entry just ends up
/// without an image (same as any other image-less resource) rather than
/// failing the whole export.
Future<MeridianBackup> buildBackup(MeridianData data) async {
  final baseJson = data.toJson();
  final resourcesJson =
      (baseJson['resources'] as List).cast<Map<String, dynamic>>();
  final augmentedResources = <Map<String, dynamic>>[];
  for (var i = 0; i < resourcesJson.length; i++) {
    final resourceMap = Map<String, dynamic>.from(resourcesJson[i]);
    final imagePath = data.resources[i].imagePath;
    if (imagePath.isNotEmpty) {
      try {
        final file = File(imagePath);
        if (await file.exists()) {
          resourceMap['imageBase64'] = base64Encode(await file.readAsBytes());
          resourceMap['imageExt'] = p.extension(imagePath);
        }
      } catch (_) {
        // Leave this one resource without embedded image data.
      }
    }
    augmentedResources.add(resourceMap);
  }
  return MeridianBackup(
    app: 'meridian',
    version: kMeridianDataVersion,
    exportedAt: DateTime.now().toIso8601String(),
    dataJson: {...baseJson, 'resources': augmentedResources},
  );
}

/// Pretty-printed JSON string ready to be written to a file and shared.
Future<String> backupToJsonString(MeridianData data) async {
  const encoder = JsonEncoder.withIndent('  ');
  return encoder.convert((await buildBackup(data)).toJson());
}

String backupFileName() {
  final now = DateTime.now();
  final stamp = '${now.year}-${pad2(now.month)}-${pad2(now.day)}';
  return 'meridian-backup-$stamp.json';
}

/// Reason an import was rejected, as a code rather than a raw string, so
/// the UI layer (which has a BuildContext / AppLocalizations, unlike this
/// pure parsing function) can localize the message shown to the person.
/// Previously this returned hardcoded English text directly — it worked,
/// but meant import failures were the one error message in the whole app
/// that never respected the chosen language.
enum BackupImportError {
  invalidJson,
  notABackup,
  wrongApp,
  missingData,
  corruptData,
}

class ImportResult {
  final bool ok;
  final MeridianData? data;
  final BackupImportError? reason;
  const ImportResult.success(MeridianData this.data)
      : ok = true,
        reason = null;
  const ImportResult.failure(BackupImportError this.reason)
      : ok = false,
        data = null;
}

/// Validates and (if needed) migrates an imported file's contents. Never
/// throws — every failure path returns an explanatory reason so the
/// Settings screen can show exactly why an import was rejected.
Future<ImportResult> parseBackupFile(String raw) async {
  dynamic parsed;
  try {
    parsed = jsonDecode(raw);
  } catch (_) {
    return const ImportResult.failure(BackupImportError.invalidJson);
  }

  if (parsed is! Map) {
    return const ImportResult.failure(BackupImportError.notABackup);
  }

  if (parsed['app'] != 'meridian') {
    return const ImportResult.failure(BackupImportError.wrongApp);
  }

  final dataField = parsed['data'];
  if (dataField is! Map) {
    return const ImportResult.failure(BackupImportError.missingData);
  }

  if (dataField['tasks'] is! List ||
      dataField['habits'] is! List ||
      (dataField['resources'] != null && dataField['resources'] is! List) ||
      dataField['settings'] is! Map ||
      dataField['focusLog'] is! List ||
      dataField['reviews'] is! Map) {
    return const ImportResult.failure(BackupImportError.corruptData);
  }

  try {
    final today = dayKey(DateTime.now());
    final version =
        (parsed['version'] is num) ? (parsed['version'] as num).toInt() : 0;
    final d = Map<String, dynamic>.from(dataField);

    final tasks = ((d['tasks'] as List?) ?? []).map((t) {
      final m = Map<String, dynamic>.from(t as Map);
      if (version < 1 && m['taskDate'] is! String) m['taskDate'] = today;
      return Task.fromJson(m, fallbackDate: today);
    }).toList();
    final habits = ((d['habits'] as List?) ?? [])
        .map((h) => Habit.fromJson(Map<String, dynamic>.from(h as Map)))
        .toList();

    // Restore each resource's embedded image (if any) to a fresh file on
    // this device, then point imagePath at it before building the
    // UserResource — mirrors exactly how a newly-picked image gets saved
    // in resource_modal.dart (same directory, same uid()-based naming).
    final appDir = await getApplicationDocumentsDirectory();
    final resources = <UserResource>[];
    for (final rawResource in (d['resources'] as List? ?? [])) {
      final m = Map<String, dynamic>.from(rawResource as Map);
      final imageBase64 = m['imageBase64'] as String?;
      if (imageBase64 != null && imageBase64.isNotEmpty) {
        try {
          final ext = (m['imageExt'] as String?) ?? '.jpg';
          final bytes = base64Decode(imageBase64);
          final newFile = File(p.join(appDir.path, '${uid()}$ext'));
          await newFile.writeAsBytes(bytes);
          m['imagePath'] = newFile.path;
        } catch (_) {
          // Fall through with whatever imagePath (if any) was already in
          // the backup — almost certainly stale, but no worse than doing
          // nothing, and the resource itself still imports successfully.
        }
      }
      resources.add(UserResource.fromJson(m));
    }

    final settings =
        UserSettings.fromJson(Map<String, dynamic>.from(d['settings'] as Map));
    final focusLog = ((d['focusLog'] as List?) ?? [])
        .map((f) => FocusLogEntry.fromJson(Map<String, dynamic>.from(f as Map)))
        .toList();
    final rawReviews = (d['reviews'] as Map?) ?? {};
    final reviews = <String, DailyReview>{
      for (final e in rawReviews.entries)
        e.key.toString():
            DailyReview.fromJson(Map<String, dynamic>.from(e.value as Map)),
    };

    return ImportResult.success(MeridianData(
      version: kMeridianDataVersion,
      tasks: tasks,
      habits: habits,
      resources: resources,
      settings: settings,
      focusLog: focusLog,
      reviews: reviews,
    ));
  } catch (_) {
    return const ImportResult.failure(BackupImportError.corruptData);
  }
}

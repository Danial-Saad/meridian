import 'package:flutter/services.dart';

class InstalledApp {
  final String packageName;
  final String name;
  final Uint8List icon;

  InstalledApp({
    required this.packageName,
    required this.name,
    required this.icon,
  });
}

class AppBlockingService {
  static const MethodChannel _channel = MethodChannel('meridian/app_blocker');

  // فحص صلاحية إمكانية الوصول
  static Future<bool> isPermissionGranted() async {
    return await _channel.invokeMethod('checkPermission') ?? false;
  }

  // فتح إعدادات الجهاز لمنح الصلاحية
  static Future<void> openSettings() async {
    await _channel.invokeMethod('openSettings');
  }

  // جلب التطبيقات المثبتة وأيقوناتها الحقيقية
  static Future<List<InstalledApp>> getInstalledApps() async {
    final List<dynamic> result =
        await _channel.invokeMethod('getInstalledApps');
    return result.map((e) {
      final map = e as Map<dynamic, dynamic>;
      return InstalledApp(
        packageName: map['package'] as String,
        name: map['name'] as String,
        icon: map['icon'] as Uint8List, // الأيقونة الأصلية كـ Bytes
      );
    }).toList();
  }

  // بدء جلسة الحظر
  static Future<void> startSession(
      List<String> packages, int durationMinutes) async {
    if (packages.isEmpty) return;
    final endTime = DateTime.now()
        .add(Duration(minutes: durationMinutes))
        .millisecondsSinceEpoch;
    await _channel.invokeMethod('syncSession', {
      'packages': packages,
      'endTime': endTime,
    });
  }

  // إنهاء جلسة الحظر
  static Future<void> endSession() async {
    await _channel.invokeMethod('cancelSession');
  }
}

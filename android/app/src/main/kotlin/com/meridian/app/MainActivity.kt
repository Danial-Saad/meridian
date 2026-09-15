package com.meridian.app
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.provider.Settings
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream

class MainActivity: FlutterActivity() {
    private val CHANNEL = "meridian/app_blocker"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "checkPermission" -> {
                    val enabled = isAccessibilityServiceEnabled(context, MeridianAccessibilityService::class.java)
                    result.success(enabled)
                }
                "openSettings" -> {
                    startActivity(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS))
                    result.success(true)
                }
                "syncSession" -> {
                    // استقبال التطبيقات المحظورة والوقت من Flutter وحفظها في نظام الأندرويد مباشرة
                    val packages = call.argument<List<String>>("packages") ?: emptyList()
                    val endTime = call.argument<Long>("endTime") ?: 0L
                    
                    val prefs = context.getSharedPreferences("meridian_blocking", Context.MODE_PRIVATE)
                    prefs.edit()
                        .putStringSet("blocked_packages", packages.toSet())
                        .putLong("end_time", endTime)
                        .apply()
                    result.success(true)
                }
                "cancelSession" -> {
                    // إنهاء الحظر
                    val prefs = context.getSharedPreferences("meridian_blocking", Context.MODE_PRIVATE)
                    prefs.edit().remove("end_time").apply()
                    result.success(true)
                }
                "getInstalledApps" -> {
                    // جلب قائمة التطبيقات المثبتة مع أيقوناتها بالخلفية عشان ما يعلق التطبيق
                    Thread {
                        val apps = getLaunchableApps()
                        runOnUiThread { result.success(apps) }
                    }.start()
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun isAccessibilityServiceEnabled(context: Context, service: Class<out android.accessibilityservice.AccessibilityService>): Boolean {
        val am = context.getSystemService(Context.ACCESSIBILITY_SERVICE) as android.view.accessibility.AccessibilityManager
        val enabledServices = Settings.Secure.getString(context.contentResolver, Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES) ?: return false
        return enabledServices.contains(service.simpleName)
    }

    private fun getLaunchableApps(): List<Map<String, Any>> {
        val pm = packageManager
        val intent = Intent(Intent.ACTION_MAIN, null).apply { addCategory(Intent.CATEGORY_LAUNCHER) }
        val resolveInfos = pm.queryIntentActivities(intent, PackageManager.MATCH_ALL)
        
        val apps = mutableListOf<Map<String, Any>>()
        for (info in resolveInfos) {
            val pkg = info.activityInfo.packageName
            // استثناء تطبيقنا وتطبيقات النظام الأساسية لمنع قفل الجهاز بالخطأ
            if (pkg == context.packageName || pkg.contains("com.android.settings") || pkg.contains("launcher")) continue
            
            val name = info.loadLabel(pm).toString()
            val drawable = info.loadIcon(pm)
            
            val bitmap = if (drawable is BitmapDrawable) {
                drawable.bitmap
            } else {
                val bmp = Bitmap.createBitmap(drawable.intrinsicWidth.coerceAtLeast(1), drawable.intrinsicHeight.coerceAtLeast(1), Bitmap.Config.ARGB_8888)
                val canvas = Canvas(bmp)
                drawable.setBounds(0, 0, canvas.width, canvas.height)
                drawable.draw(canvas)
                bmp
            }
            
            val stream = ByteArrayOutputStream()
            bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)
            val iconBytes = stream.toByteArray()
            
            apps.add(mapOf("package" to pkg, "name" to name, "icon" to iconBytes))
        }
        return apps.sortedBy { it["name"].toString().lowercase() }
    }
}
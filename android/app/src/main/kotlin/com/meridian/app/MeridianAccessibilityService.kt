package com.meridian.app
import android.accessibilityservice.AccessibilityService
import android.content.Context
import android.graphics.Color
import android.graphics.PixelFormat
import android.os.CountDownTimer
import android.view.Gravity
import android.view.View
import android.view.WindowManager
import android.view.accessibility.AccessibilityEvent
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView

class MeridianAccessibilityService : AccessibilityService() {

    private var overlayView: View? = null
    private var windowManager: WindowManager? = null
    private var countdownTimer: CountDownTimer? = null
    private var lastBlockedPackage: String? = null

    override fun onServiceConnected() {
        super.onServiceConnected()
        windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event?.eventType == AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) {
            val packageName = event.packageName?.toString() ?: return
            
            val prefs = getSharedPreferences("meridian_blocking", Context.MODE_PRIVATE)
            val endTime = prefs.getLong("end_time", 0L)
            val blockedPackages = prefs.getStringSet("blocked_packages", emptySet()) ?: emptySet()
            val currentTime = System.currentTimeMillis()

            // إذا الجلسة شغالة والتطبيق المفتوح موجود بقائمة الحظر
            if (currentTime < endTime && blockedPackages.contains(packageName)) {
                showOverlay(packageName, endTime)
            } else if (packageName != this.packageName && overlayView != null) {
                // إذا المستخدم طلع من التطبيق المحظور، بنشيل شاشة الحظر
                hideOverlay()
            }
        }
    }

    private fun showOverlay(blockedPackage: String, endTime: Long) {
        if (overlayView != null && lastBlockedPackage == blockedPackage) return
        hideOverlay()
        lastBlockedPackage = blockedPackage

        // تصميم شاشة الحظر (نفس هوية Meridian) بدون الحاجة لـ Flutter
        val layout = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setBackgroundColor(Color.parseColor("#0A0D14")) // لون Deep Midnight
            setPadding(64, 64, 64, 64)
        }

        val iconText = TextView(this).apply {
            text = "🐺"
            textSize = 64f
            gravity = Gravity.CENTER
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply { bottomMargin = 48 }
        }

        val title = TextView(this).apply {
            text = "Stay with your focus."
            setTextColor(Color.WHITE)
            textSize = 22f
            typeface = android.graphics.Typeface.DEFAULT_BOLD
            gravity = Gravity.CENTER
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply { bottomMargin = 16 }
        }

        val subtitle = TextView(this).apply {
            text = "This app is blocked for your current session."
            setTextColor(Color.parseColor("#A0A0A0"))
            textSize = 16f
            gravity = Gravity.CENTER
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply { bottomMargin = 48 }
        }

        val timerText = TextView(this).apply {
            setTextColor(Color.parseColor("#0EA5E9")) // لون Electric Blue
            textSize = 32f
            typeface = android.graphics.Typeface.DEFAULT_BOLD
            gravity = Gravity.CENTER
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply { bottomMargin = 64 }
        }

        val button = Button(this).apply {
            text = "Back to Meridian"
            setBackgroundColor(Color.parseColor("#0EA5E9"))
            setTextColor(Color.parseColor("#0A0D14"))
            setPadding(32, 16, 32, 16)
            setOnClickListener {
                // إرجاع المستخدم للشاشة الرئيسية
                performGlobalAction(GLOBAL_ACTION_HOME)
                hideOverlay()
                val intent = packageManager.getLaunchIntentForPackage(packageName)
                if (intent != null) startActivity(intent)
            }
        }

        layout.addView(iconText)
        layout.addView(title)
        layout.addView(subtitle)
        layout.addView(timerText)
        layout.addView(button)

        overlayView = layout

        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
            PixelFormat.TRANSLUCENT
        )

        windowManager?.addView(overlayView, params)

        // مؤقت العد التنازلي المباشر
        countdownTimer = object : CountDownTimer(endTime - System.currentTimeMillis(), 1000) {
            override fun onTick(millisUntilFinished: Long) {
                val minutes = (millisUntilFinished / 1000) / 60
                val seconds = (millisUntilFinished / 1000) % 60
                timerText.text = String.format("%02d:%02d remaining", minutes, seconds)
            }
            override fun onFinish() {
                hideOverlay()
            }
        }.start()
    }

    private fun hideOverlay() {
        countdownTimer?.cancel()
        countdownTimer = null
        if (overlayView != null) {
            windowManager?.removeView(overlayView)
            overlayView = null
            lastBlockedPackage = null
        }
    }

    override fun onInterrupt() { hideOverlay() }
}
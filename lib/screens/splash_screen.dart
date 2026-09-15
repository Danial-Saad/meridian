import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_shell.dart';
import '../services/notification_service.dart';
import '../store/meridian_store.dart';
import '../theme/app_theme.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainCtrl;
  late AnimationController _rotationCtrl;

  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;
  late Animation<double> _textFade;
  late Animation<Offset> _textSlide;
  late Animation<double> _progressAnim;
  late final TickerFuture _entranceAnimation;

  @override
  void initState() {
    super.initState();

    _mainCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _rotationCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();

    _fadeAnim = CurvedAnimation(
      parent: _mainCtrl,
      curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
    );

    _scaleAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.0, 0.55, curve: Curves.easeOutBack),
      ),
    );

    _textFade = CurvedAnimation(
      parent: _mainCtrl,
      curve: const Interval(0.4, 0.8, curve: Curves.easeIn),
    );

    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _mainCtrl,
      curve: const Interval(0.4, 0.85, curve: Curves.easeOutCubic),
    ));

    _progressAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.3, 0.95, curve: Curves.easeInOutCubic),
      ),
    );

    _entranceAnimation = _mainCtrl.forward();
    _navigateNext();
  }

  Future<void> _navigateNext() async {
    final store = context.read<MeridianStore>();

    // Data loading (SharedPreferences read + JSON decode), notification
    // channel setup, and the brand animation now all run side by side
    // instead of the animation finishing and then the app just sitting
    // idle for a fixed 2.1s no matter how fast the device is. We
    // navigate as soon as everything is actually done, so a fast device
    // gets a noticeably snappier launch while a slow load still gets
    // covered by the splash instead of a blank frame.
    // store.init() is idempotent (see MeridianStore), so this safely joins
    // the same load main.dart already kicked off rather than starting a
    // second one. NotificationService.initialize() moved here from
    // main.dart for the same reason — see the comment there — and is
    // similarly safe to call more than once.
    await Future.wait(
        [store.init(), NotificationService.initialize(), _entranceAnimation]);

    // NOTIFICATIONS SYSTEM: must run only after *both* of the above are
    // done — store.init() and NotificationService.initialize() run in
    // parallel above and either could finish first, so resyncing inside
    // whichever one happens to complete first would risk the other not
    // being ready yet (schedule calls silently no-op until
    // NotificationService is initialized). Not awaited: this reschedules
    // potentially many tasks/habits, and nothing about navigating to
    // AppShell needs to wait for it.
    store.resyncAllReminders();

    if (!mounted) return;
    // Brief settle so the progress bar visibly reaches full and the text
    // isn't cut off mid-fade on very fast devices/loads.
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;

    // UI/UX FIX (design critique #1): first launch ever now goes through
    // a short onboarding flow instead of landing directly on AppShell —
    // see onboarding_screen.dart for why. Every subsequent launch skips
    // straight to AppShell exactly as before.
    //
    // Also treats anyone who already has real data (tasks or habits from
    // before this flow existed) as having "seen" it, without ever
    // showing it to them: this flag only exists in SharedPreferences
    // going forward, so an existing person updating to this version
    // would otherwise look identical to a genuinely new install and see
    // an onboarding tour for an app they've already been using —
    // presence of real data is a much better signal of "not new" than a
    // preference flag that couldn't have existed for them yet.
    var seenOnboarding = await OnboardingScreen.hasBeenSeen();
    if (!seenOnboarding && (store.tasks.isNotEmpty || store.habits.isNotEmpty)) {
      await OnboardingScreen.markSeen();
      seenOnboarding = true;
    }
    // BUG FIX (flutter analyze — use_build_context_synchronously): two
    // more `await`s happened above since the last `mounted` check, and
    // `context` gets used again right below. A very quick device could
    // in principle unmount this screen in that window (killed the app,
    // or the mounted MaterialApp was rebuilt some other way) — cheap
    // enough to guard again immediately before the one line that
    // actually touches `context`, rather than trust the earlier check
    // still holds two awaits later.
    if (!mounted) return;
    final nextScreen =
        seenOnboarding ? const AppShell() : const OnboardingScreen();

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (_, __, ___) => nextScreen,
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _mainCtrl.dispose();
    _rotationCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ThemeController>().colors;
    final mq = MediaQuery.of(context);
    final size = mq.size;
    // The logo is painted in a 58x58 logical-pixel box (86 card minus its
    // 14px padding on each side). The source PNG is 1254x1254, so decoding
    // it at full resolution just to shrink it on the GPU wastes CPU time
    // and holds ~50x more decoded bitmap memory than the splash actually
    // needs. cacheWidth/cacheHeight make the image codec decode at (close
    // to) the size it's actually displayed at.
    final logoDecodePx = (58 * mq.devicePixelRatio).round();

    return Scaffold(
      backgroundColor: c.bg,
      body: Stack(
        alignment: Alignment.center,
        children: [
          // 1. إضاءة محيطية في الخلفية (Ambient Radial Glow)
          Positioned(
            top: size.height * 0.26,
            child: Container(
              width: 340,
              height: 340,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    c.primaryBg.withValues(alpha: 0.4),
                    c.bgElevated.withValues(alpha: 0.2),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.45, 1.0],
                ),
              ),
            ),
          ),

          // 2. المحتوى المركزي: الشعار المحاط بالحلقة المدارية
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ScaleTransition(
                  scale: _scaleAnim,
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: SizedBox(
                      width: 140,
                      height: 140,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // حلقة مدارية خارجية تدور بنعومة متناهية
                          AnimatedBuilder(
                            animation: _rotationCtrl,
                            builder: (_, __) {
                              return Transform.rotate(
                                angle: _rotationCtrl.value * 2 * math.pi,
                                child: CustomPaint(
                                  size: const Size(130, 130),
                                  painter: _OrbitalRingPainter(
                                    color: c.primary.withValues(alpha: 0.35),
                                    accentColor: c.primary,
                                  ),
                                ),
                              );
                            },
                          ),

                          // بطاقة الشعار الدائرية النقية
                          Container(
                            width: 86,
                            height: 86,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: c.primary.withValues(alpha: 0.08),
                                  blurRadius: 24,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Image.asset(
                              'assets/icon/app_icon.png',
                              fit: BoxFit.contain,
                              cacheWidth: logoDecodePx,
                              cacheHeight: logoDecodePx,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // اسم التطبيق مع السلوغان
                SlideTransition(
                  position: _textSlide,
                  child: FadeTransition(
                    opacity: _textFade,
                    child: Column(
                      children: [
                        Text(
                          'Meridian',
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.6,
                            color: c.text,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Precision Productivity',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.8,
                            color: c.textDim,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 3. شريط تقدم رفيع جداً ومدمج في الأسفل
          Positioned(
            bottom: 44,
            child: FadeTransition(
              opacity: _textFade,
              child: SizedBox(
                width: 90,
                child: AnimatedBuilder(
                  animation: _progressAnim,
                  builder: (context, child) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: _progressAnim.value,
                        minHeight: 2,
                        backgroundColor: c.border.withValues(alpha: 0.35),
                        valueColor: AlwaysStoppedAnimation<Color>(c.primary),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// رسم الحلقة المدارية المتقطعة بنعومة
class _OrbitalRingPainter extends CustomPainter {
  final Color color;
  final Color accentColor;

  _OrbitalRingPainter({required this.color, required this.accentColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final trackPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    canvas.drawCircle(center, radius, trackPaint);

    final dotPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.fill;

    // نقطة مضيئة تمثل الجرم/المؤشر المداري
    canvas.drawCircle(Offset(center.dx + radius, center.dy), 2.8, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

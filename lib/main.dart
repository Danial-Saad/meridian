import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart'; // استيراد مكتبة الخطوط
import 'package:flutter_localizations/flutter_localizations.dart'; // مكتبات الترجمة
import 'l10n/app_localizations.dart'; // الملف المولد تلقائياً

import 'screens/splash_screen.dart';
import 'store/meridian_store.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // STARTUP FIX: this used to be `await NotificationService.initialize()`
  // right here, blocking runApp() on a native platform-channel round-trip
  // (flutter_local_notifications setting up its Android notification
  // channel) before Flutter could paint a single frame — directly adding
  // to the black-screen window on cold start. Nothing needs this ready
  // before the splash, let alone the first frame: the earliest it's
  // actually used is a Focus/Break timer completing, minutes later at
  // best. It now runs from SplashScreen alongside the existing
  // store.init() + entrance-animation wait, so it's still guaranteed
  // ready before AppShell mounts, without being on the startup-critical
  // path. See splash_screen.dart's _navigateNext().
  runApp(const MeridianApp());
}

class MeridianApp extends StatelessWidget {
  const MeridianApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // أزلنا ..load() لأن ThemeController الجديد يقوم بتحميل الثيم تلقائياً
        ChangeNotifierProvider(create: (_) => ThemeController()),
        ChangeNotifierProvider(create: (_) => MeridianStore()..init()),
      ],
      child: const _MeridianMaterialApp(),
    );
  }
}

class _MeridianMaterialApp extends StatefulWidget {
  const _MeridianMaterialApp();

  @override
  State<_MeridianMaterialApp> createState() => _MeridianMaterialAppState();
}

class _MeridianMaterialAppState extends State<_MeridianMaterialApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() {
    // تحديث الواجهة تلقائياً عند تغير ثيم النظام (Dark/Light)
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final themeController = context.watch<ThemeController>();
    final store = context.watch<MeridianStore>(); // مراقبة المتجر لجلب اللغة

    final c = themeController.colors;
    final isDark = themeController.isDarkMode;
    final langCode = store.settings.languageCode; // جلب رمز اللغة (en, ar, ru)

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      systemNavigationBarColor: c.bgElevated,
      systemNavigationBarIconBrightness:
          isDark ? Brightness.light : Brightness.dark,
    ));

    return MaterialApp(
      title: 'Meridian',
      debugShowCheckedModeBanner: false,

      // --- إعدادات اللغة والترجمة المضافة ---
      locale:
          langCode != null ? Locale(langCode) : null, // null يعني لغة النظام
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'), // الإنكليزية
        Locale('ar'), // العربية
        Locale('ru'), // الروسية
      ],
      // ------------------------------------

      theme: _buildThemeData(c, isDark ? Brightness.dark : Brightness.light),
      home: const SplashScreen(),
    );
  }

  ThemeData _buildThemeData(MeridianColors c, Brightness brightness) {
    final base =
        brightness == Brightness.dark ? ThemeData.dark() : ThemeData.light();
    return base.copyWith(
      brightness: brightness,
      scaffoldBackgroundColor: c.bg,
      primaryColor: c.primary, // تم تعديلها لتتوافق مع الثيم الجديد
      colorScheme: base.colorScheme.copyWith(
        primary: c.primary,
        secondary: c.primary,
        surface: c.surface,
        error: c.danger,
        onSurface: c.text,
      ),
      dividerColor: c.border,
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: c.primary,
        selectionColor: c.primaryBg,
        selectionHandleColor: c.primary,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: c.primary,
        thumbColor: c.primary,
        inactiveTrackColor: c.border,
      ),
      // --- تفعيل خط Poppins على كامل التطبيق مع ألوان الثيم ---
      textTheme: GoogleFonts.poppinsTextTheme(base.textTheme).apply(
        bodyColor: c.text,
        displayColor: c.text,
      ),
      // ---------------------------------------------------------
      splashFactory: InkRipple.splashFactory,
    );
  }
}

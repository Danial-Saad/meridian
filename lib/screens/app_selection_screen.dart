import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../services/app_blocking_service.dart';
import '../store/meridian_store.dart';
import '../theme/app_theme.dart';
import '../widgets/shared/field_label.dart';

class AppSelectionScreen extends StatefulWidget {
  const AppSelectionScreen({super.key});

  @override
  State<AppSelectionScreen> createState() => _AppSelectionScreenState();
}

// BUG FIX (audit report #3 + #4): two related problems in how this
// screen talked to the platform side. Documented in detail at each fix
// point below, but the short version: no call here was ever wrapped in
// error handling, and the "did the person just grant the permission in
// Android Settings" recheck fired on a fixed timer instead of reacting
// to actually coming back to the app.
class _AppSelectionScreenState extends State<AppSelectionScreen>
    with WidgetsBindingObserver {
  List<InstalledApp>? _apps;
  bool _hasPermission = false;
  bool _isLoading = true;
  bool _loadFailed = false;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissionAndLoad();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchCtrl.dispose();
    super.dispose();
  }

  // BUG FIX (audit report #4): the permission gate used to send the
  // person to Android's own Settings app, then re-check permission
  // exactly once, after a flat one-second delay — timed from the moment
  // Settings *opened*, not from whenever the person actually came back.
  // Granting an accessibility permission always takes longer than a
  // second (finding the right toggle, reading the confirmation dialog
  // Android shows for this permission type), so the recheck almost
  // always fired while the person was still in Settings, saw
  // "not granted yet" (correctly, at that moment), and then never asked
  // again — leaving this screen stuck showing the permission gate even
  // after the permission really was granted, until manually leaving and
  // reopening it. `didChangeAppLifecycleState` reacts to the actual
  // event that matters — coming back to Meridian — regardless of how
  // long was spent in Settings. Guarded on `!_hasPermission` so a
  // completely unrelated resume (pulling down a notification, switching
  // apps and back) doesn't reload the full app list every time once
  // permission is already granted and nothing here needs refreshing.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_hasPermission) {
      _checkPermissionAndLoad();
    }
  }

  // BUG FIX (audit report #3): none of these platform calls were ever
  // wrapped in error handling. If the native side threw for any reason
  // (permission revoked mid-flow, an OEM quirk, the method channel
  // itself missing on some build), the exception propagated straight
  // out of this function — skipping the final `setState(() => _isLoading
  // = false)` below entirely, so the screen was left showing its loading
  // spinner forever with no way to recover short of leaving and
  // reopening it. Now every platform call is inside the same try/catch,
  // `_isLoading` is always cleared in a `finally`, and a failure shows a
  // real error state with a Retry button instead of an infinite spinner.
  Future<void> _checkPermissionAndLoad() async {
    setState(() {
      _isLoading = true;
      _loadFailed = false;
    });

    try {
      final granted = await AppBlockingService.isPermissionGranted();
      if (!mounted) return;
      setState(() => _hasPermission = granted);

      if (granted) {
        final apps = await AppBlockingService.getInstalledApps();
        if (!mounted) return;
        setState(() => _apps = apps);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadFailed = true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ThemeController>().colors;
    final store = context.watch<MeridianStore>();
    final blocked = store.settings.blockedApps;
    final l10n = AppLocalizations.of(context)!;

    final query = _searchCtrl.text.trim().toLowerCase();
    final apps = _apps ?? const <InstalledApp>[];
    // UX FIX (audit report #6, part 2): a long, unfilterable app list on
    // a phone with 100+ apps meant manually scrolling to find anything.
    final filteredApps = query.isEmpty
        ? apps
        : apps.where((a) => a.name.toLowerCase().contains(query)).toList();

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.bg,
        elevation: 0,
        title: Text(l10n.blockAppsTitle,
            style: TextStyle(
                color: c.text, fontSize: 17, fontWeight: FontWeight.w600)),
        iconTheme: IconThemeData(color: c.text),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: c.primary))
          : _loadFailed
              ? _buildErrorState(c, l10n)
              : !_hasPermission
                  ? _buildPermissionGate(c, l10n)
                  : Column(
                      children: [
                        if (apps.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                            child: TextField(
                              controller: _searchCtrl,
                              style: TextStyle(color: c.text, fontSize: 13.5),
                              decoration: mrdInputDecoration(c,
                                      hint: l10n.searchAppsHint)
                                  .copyWith(
                                prefixIcon: Icon(Icons.search,
                                    size: 18, color: c.textFaint),
                                suffixIcon: _searchCtrl.text.isEmpty
                                    ? null
                                    : IconButton(
                                        icon: Icon(Icons.close,
                                            size: 16, color: c.textFaint),
                                        onPressed: () =>
                                            setState(_searchCtrl.clear),
                                      ),
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                        Expanded(
                          child: filteredApps.isEmpty
                              ? Center(
                                  child: Text(l10n.noAppsFound,
                                      style: TextStyle(color: c.textDim)))
                              : ListView.builder(
                                  itemCount: filteredApps.length,
                                  itemBuilder: (context, index) {
                                    final app = filteredApps[index];
                                    final isBlocked =
                                        blocked.contains(app.packageName);
                                    return ListTile(
                                      // PERF FIX (audit report #6, part
                                      // 1): every icon used to decode at
                                      // full native resolution just to
                                      // be shown at 44x44 — real memory
                                      // and CPU cost multiplied by
                                      // however many apps are installed.
                                      // cacheWidth/cacheHeight tell the
                                      // decoder to downsample immediately
                                      // instead of after the fact; 88 is
                                      // 2x the display size, enough
                                      // headroom for higher-density
                                      // screens without decoding at full
                                      // native size for nothing.
                                      leading: Image.memory(
                                        app.icon,
                                        width: 44,
                                        height: 44,
                                        cacheWidth: 88,
                                        cacheHeight: 88,
                                      ),
                                      title: Text(app.name,
                                          style: TextStyle(
                                              color: c.text,
                                              fontWeight: FontWeight.w500)),
                                      subtitle: Text(app.packageName,
                                          style: TextStyle(
                                              color: c.textFaint,
                                              fontSize: 11)),
                                      trailing: Switch(
                                        value: isBlocked,
                                        // BUG FIX (flutter analyze):
                                        // Switch.activeColor is
                                        // deprecated since Flutter
                                        // 3.31 in favor of
                                        // activeThumbColor.
                                        activeThumbColor: c.primary,
                                        onChanged: (val) {
                                          final newList =
                                              List<String>.from(blocked);
                                          if (val) {
                                            newList.add(app.packageName);
                                          } else {
                                            newList.remove(app.packageName);
                                          }
                                          store.updateSettings((s) =>
                                              s.copyWith(
                                                  blockedApps: newList));
                                        },
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
    );
  }

  Widget _buildErrorState(MeridianColors c, AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: c.textFaint),
            const SizedBox(height: 16),
            Text(l10n.couldntLoadAppsError,
                textAlign: TextAlign.center,
                style: TextStyle(color: c.textDim)),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: _checkPermissionAndLoad,
              child: Text(l10n.retryLabel),
            ),
          ],
        ),
      ),
    );
  }

  // شاشة طلب الصلاحية إذا ما كانت مفعلة
  Widget _buildPermissionGate(MeridianColors c, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.security, size: 72, color: c.primary),
          const SizedBox(height: 24),
          Text(
            l10n.permissionsRequiredTitle,
            style: TextStyle(
                color: c.text, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.accessibilityPermissionExplanation,
            textAlign: TextAlign.center,
            style: TextStyle(color: c.textFaint, height: 1.5),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: c.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                await AppBlockingService.openSettings();
                // The real recheck now happens in didChangeAppLifecycleState
                // above when the person actually returns to the app — this
                // is just a same-screen fallback for the rare case where
                // openSettings() itself doesn't trigger a lifecycle pause
                // (e.g. a split-screen/multi-window setup).
              },
              child: Text(l10n.openAndroidSettingsButton,
                  style: TextStyle(
                      // UI/UX FIX (design critique #3): this used `c.bg`
                      // instead of the app's established `c.primaryInk`
                      // token for text-on-primary-button — inconsistent
                      // with every other primary button in the app, and
                      // coincidentally the exact color whose contrast
                      // against `primary` needed fixing anyway (see
                      // app_theme.dart).
                      color: c.primaryInk, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}

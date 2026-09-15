import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../l10n/app_localizations.dart'; // استيراد ملفات الترجمة

import '../models/domain.dart';
import '../services/notification_service.dart';
import '../store/backup.dart';
import '../store/meridian_store.dart';
import '../store/seed.dart';
import '../theme/app_theme.dart';
import '../utils/format_utils.dart';
import '../widgets/shared/confirm_dialog.dart';
import '../widgets/shared/field_label.dart';
import '../widgets/shared/mrd_bidi_text_field.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String? _importError;
  late final TextEditingController _nameCtrl;

  @override
  void initState() {
    super.initState();
    // read (not watch): only need the value once to seed the controller —
    // the field itself is now the source of truth for what's on screen
    // while the user is typing.
    final initialName = context.read<MeridianStore>().settings.userName ?? '';
    _nameCtrl = TextEditingController(text: initialName);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleExport(BuildContext context, MeridianStore store) async {
    try {
      final json = await backupToJsonString(store.rawData);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/${backupFileName()}');
      await file.writeAsString(json);
      await Share.shareXFiles([XFile(file.path)], text: 'Meridian backup');
      if (context.mounted) {
        store.notify(ToastKind.success, AppLocalizations.of(context)!.backupReadyToast);
      }
    } catch (_) {
      if (context.mounted) {
        store.notify(ToastKind.error, AppLocalizations.of(context)!.backupCreateErrorToast);
      }
    }
  }

  String _backupErrorMessage(AppLocalizations l10n, BackupImportError reason) {
    switch (reason) {
      case BackupImportError.invalidJson:
        return l10n.backupErrorInvalidJson;
      case BackupImportError.notABackup:
        return l10n.backupErrorNotABackup;
      case BackupImportError.wrongApp:
        return l10n.backupErrorWrongApp;
      case BackupImportError.missingData:
        return l10n.backupErrorMissingData;
      case BackupImportError.corruptData:
        return l10n.backupErrorCorruptData;
    }
  }

  Future<void> _handleImport(BuildContext context, MeridianStore store) async {
    setState(() => _importError = null);
    try {
      final result = await FilePicker.platform
          .pickFiles(type: FileType.custom, allowedExtensions: ['json']);
      if (result == null || result.files.single.path == null) return;
      final text = await File(result.files.single.path!).readAsString();
      final parsed = await parseBackupFile(text);
      if (!context.mounted) return;
      final l10n = AppLocalizations.of(context)!;
      if (!parsed.ok) {
        setState(() => _importError = _backupErrorMessage(l10n, parsed.reason!));
        return;
      }
      await showMrdConfirm(
        context,
        title: l10n.restoreBackupTitle,
        description: l10n.restoreBackupDescription,
        confirmLabel: l10n.restoreLabel,
        onConfirm: () {
          store.replaceAllData(parsed.data!);
          store.notify(ToastKind.success, l10n.backupRestoredToast);
        },
      );
    } catch (_) {
      setState(() => _importError = context.mounted
          ? AppLocalizations.of(context)!.couldntReadFileError
          : "Couldn't read that file.");
    }
  }

  Future<void> _handleNotificationsToggle(
      BuildContext context, MeridianStore store, bool enabled) async {
    store.updateSettings((s) => s.copyWith(notificationsEnabled: enabled));
    if (!enabled) return;
    final granted = await NotificationService.requestPermission();
    if (!granted && context.mounted) {
      store.notify(ToastKind.info, AppLocalizations.of(context)!.notificationsOffFocusToast);
    }
  }

  Future<void> _handleTaskRemindersToggle(
      BuildContext context, MeridianStore store, bool enabled) async {
    store.updateSettings((s) => s.copyWith(taskRemindersEnabled: enabled));
    if (!enabled) return;
    final granted = await NotificationService.requestPermission();
    if (!granted && context.mounted) {
      store.notify(ToastKind.info, AppLocalizations.of(context)!.notificationsOffTaskToast);
    }
    await NotificationService.requestExactAlarmPermissionIfNeeded();
  }

  Future<void> _handleHabitRemindersToggle(
      BuildContext context, MeridianStore store, bool enabled) async {
    store.updateSettings((s) => s.copyWith(habitRemindersEnabled: enabled));
    if (!enabled) return;
    final granted = await NotificationService.requestPermission();
    if (!granted && context.mounted) {
      store.notify(ToastKind.info, AppLocalizations.of(context)!.notificationsOffHabitToast);
    }
    await NotificationService.requestExactAlarmPermissionIfNeeded();
  }

  Future<void> _handleDailyPlanningToggle(
      BuildContext context, MeridianStore store, bool enabled) async {
    store.updateSettings(
        (s) => s.copyWith(dailyPlanningRemindersEnabled: enabled));
    if (!enabled) return;
    final granted = await NotificationService.requestPermission();
    if (!granted && context.mounted) {
      store.notify(ToastKind.info, AppLocalizations.of(context)!.notificationsOffDailyPlanningToast);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ThemeController>().colors;
    final themeController = context.watch<ThemeController>();
    final store = context.watch<MeridianStore>();
    final settings = store.settings;
    final l10n = AppLocalizations.of(context)!; // جلب نصوص الترجمة

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        Text(l10n.settings, // ترجمة عنوان الإعدادات
            style: TextStyle(
                fontSize: 24, fontWeight: FontWeight.w600, color: c.text)),
        const SizedBox(height: 4),
        Text(l10n.settingsSubtitle,
            style: TextStyle(fontSize: 13, color: c.textDim)),
        const SizedBox(height: 22),

        // --- قسم الملف الشخصي (الاسم) ---
        // UI/UX FIX: this used to be a full "PROFILE" section (uppercase
        // header + bordered card) for exactly one field. Reported as
        // unnecessary text/structure for a single setting — dropped the
        // section title (see `_Section.title` now being optional) and
        // shortened the field's own label from "Your name" to "Name."
        _Section(
          c: c,
          children: [
            _Row(
              c: c,
              label: l10n.nameLabel,
              description: l10n.yourNameDescription,
              isLast: true,
              child: MrdBidiTextField(
                controller: _nameCtrl,
                style: TextStyle(color: c.text, fontSize: 13.5),
                decoration: mrdInputDecoration(c, hint: l10n.yourNameHint),
                onChanged: (v) => store
                    .updateSettings((s) => s.copyWith(userName: v.trim())),
              ),
            ),
          ],
        ),
        // ------------------------------------

        // --- قسم اختيار اللغة المضاف حديثاً ---
        _Section(
          title: l10n.localization,
          c: c,
          children: [
            _Row(
              c: c,
              label: l10n.language,
              description: l10n.languageEffectImmediate,
              isLast: true,
              child: DropdownButtonHideUnderline(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: c.surface,
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: c.border),
                  ),
                  child: DropdownButton<String?>(
                    value: settings.languageCode,
                    isExpanded: true,
                    dropdownColor: c.surface,
                    icon: Icon(Icons.language, size: 18, color: c.textDim),
                    style: TextStyle(
                        color: c.text,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500),
                    items: [
                      DropdownMenuItem(
                          value: null, child: Text(l10n.systemDefault)),
                      const DropdownMenuItem(
                          value: 'en', child: Text('English')),
                      const DropdownMenuItem(
                          value: 'ar', child: Text('العربية')),
                      const DropdownMenuItem(
                          value: 'ru', child: Text('Русский')),
                    ],
                    onChanged: (val) {
                      store
                          .updateSettings((s) => s.copyWith(languageCode: val));
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
        // ------------------------------------

        _Section(
          title: l10n.appearanceTitle,
          c: c,
          children: [
            _Row(
              c: c,
              label: l10n.themeLabel,
              description: l10n.themeDescription,
              child: Wrap(spacing: 6, runSpacing: 6, children: [
                _toggleBtn(
                    c,
                    Icons.dark_mode,
                    l10n.darkLabel,
                    themeController.themeMode == ThemeMode.dark,
                    () => themeController.setThemeMode(ThemeMode.dark)),
                _toggleBtn(
                    c,
                    Icons.light_mode,
                    l10n.lightLabel,
                    themeController.themeMode == ThemeMode.light,
                    () => themeController.setThemeMode(ThemeMode.light)),
                _toggleBtn(
                    c,
                    Icons.laptop_mac,
                    l10n.systemLabel,
                    themeController.themeMode == ThemeMode.system,
                    () => themeController.setThemeMode(ThemeMode.system)),
              ]),
            ),
            _Row(
              c: c,
              label: l10n.timeFormatLabel,
              description: l10n.timeFormatDescription,
              child: Wrap(spacing: 6, children: [
                _toggleBtn(
                    c,
                    null,
                    l10n.format12h,
                    !settings.timeFormat24,
                    () => store.updateSettings(
                        (s) => s.copyWith(timeFormat24: false))),
                _toggleBtn(
                    c,
                    null,
                    l10n.format24h,
                    settings.timeFormat24,
                    () => store
                        .updateSettings((s) => s.copyWith(timeFormat24: true))),
              ]),
            ),
            _Row(
              c: c,
              label: l10n.weekStartsLabel,
              description: l10n.weekStartsDescription,
              isLast: true,
              child: Wrap(spacing: 6, children: [
                _toggleBtn(
                    c,
                    null,
                    l10n.sundayLabel,
                    settings.weekStart == 0,
                    () =>
                        store.updateSettings((s) => s.copyWith(weekStart: 0))),
                _toggleBtn(
                    c,
                    null,
                    l10n.mondayLabel,
                    settings.weekStart == 1,
                    () =>
                        store.updateSettings((s) => s.copyWith(weekStart: 1))),
              ]),
            ),
          ],
        ),
        _Section(
          title: l10n.focusMode, // استخدام الترجمة
          c: c,
          children: [
            _Row(
              c: c,
              label: l10n.focusDuration, // استخدام الترجمة
              description: l10n.pomodoroFocusDescription,
              child: _NumberStepper(
                value: settings.pomodoroFocus,
                min: 5,
                max: 180,
                step: 5,
                suffix: l10n.minUnit, // استخدام الترجمة
                onChanged: (v) =>
                    store.updateSettings((s) => s.copyWith(pomodoroFocus: v)),
              ),
            ),
            _Row(
              c: c,
              label: l10n.breakDuration, // استخدام الترجمة
              description: l10n.pomodoroBreakDescription,
              child: _NumberStepper(
                value: settings.pomodoroBreak,
                min: 1,
                max: 60,
                step: 1,
                suffix: l10n.minUnit, // استخدام الترجمة
                onChanged: (v) =>
                    store.updateSettings((s) => s.copyWith(pomodoroBreak: v)),
              ),
            ),
            _Row(
              c: c,
              label: l10n.focusNotificationsLabel,
              description: l10n.focusNotificationsDescription,
              isLast: true,
              child: Wrap(spacing: 6, children: [
                _toggleBtn(
                    c,
                    Icons.notifications_active_outlined,
                    l10n.onLabel,
                    settings.notificationsEnabled,
                    () => _handleNotificationsToggle(context, store, true)),
                _toggleBtn(
                    c,
                    Icons.notifications_off_outlined,
                    l10n.offLabel,
                    !settings.notificationsEnabled,
                    () => _handleNotificationsToggle(context, store, false)),
              ]),
            ),
          ],
        ),
        _Section(
          title: l10n.notifications, // استخدام الترجمة
          c: c,
          children: [
            _Row(
              c: c,
              label: l10n.taskReminders, // استخدام الترجمة
              description: l10n.taskRemindersSub, // استخدام الترجمة
              child: Wrap(spacing: 6, children: [
                _toggleBtn(
                    c,
                    Icons.notifications_active_outlined,
                    l10n.onLabel,
                    settings.taskRemindersEnabled,
                    () => _handleTaskRemindersToggle(context, store, true)),
                _toggleBtn(
                    c,
                    Icons.notifications_off_outlined,
                    l10n.offLabel,
                    !settings.taskRemindersEnabled,
                    () => _handleTaskRemindersToggle(context, store, false)),
              ]),
            ),
            _Row(
              c: c,
              label: l10n.habitReminders, // استخدام الترجمة
              description: l10n.habitRemindersDescription,
              child: Wrap(spacing: 6, children: [
                _toggleBtn(
                    c,
                    Icons.notifications_active_outlined,
                    l10n.onLabel,
                    settings.habitRemindersEnabled,
                    () => _handleHabitRemindersToggle(context, store, true)),
                _toggleBtn(
                    c,
                    Icons.notifications_off_outlined,
                    l10n.offLabel,
                    !settings.habitRemindersEnabled,
                    () => _handleHabitRemindersToggle(context, store, false)),
              ]),
            ),
            _Row(
              c: c,
              label: l10n.dailyPlanning, // استخدام الترجمة
              description: l10n.dailyPlanningSub, // استخدام الترجمة
              child: Wrap(spacing: 6, children: [
                _toggleBtn(
                    c,
                    Icons.notifications_active_outlined,
                    l10n.onLabel,
                    settings.dailyPlanningRemindersEnabled,
                    () => _handleDailyPlanningToggle(context, store, true)),
                _toggleBtn(
                    c,
                    Icons.notifications_off_outlined,
                    l10n.offLabel,
                    !settings.dailyPlanningRemindersEnabled,
                    () => _handleDailyPlanningToggle(context, store, false)),
              ]),
            ),
            _Row(
              c: c,
              label: l10n.morningReminderHourLabel,
              description: l10n.clock24hDescription,
              child: _NumberStepper(
                value: settings.dailyPlanningMorningHour,
                min: 0,
                max: 23,
                step: 1,
                suffix: l10n.hourUnit,
                onChanged: (v) => store.updateSettings(
                    (s) => s.copyWith(dailyPlanningMorningHour: v)),
              ),
            ),
            _Row(
              c: c,
              label: l10n.eveningReminderHourLabel,
              description: l10n.clock24hDescription,
              isLast: true,
              child: _NumberStepper(
                value: settings.dailyPlanningEveningHour,
                min: 0,
                max: 23,
                step: 1,
                suffix: l10n.hourUnit,
                onChanged: (v) => store.updateSettings(
                    (s) => s.copyWith(dailyPlanningEveningHour: v)),
              ),
            ),
          ],
        ),
        _Section(
          title: l10n.yourDataTitle,
          c: c,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.dataPrivacyText,
                    style: TextStyle(
                        fontSize: 12.5, color: c.textDim, height: 1.5),
                  ),
                  const SizedBox(height: 12),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    _dataActionBtn(c, Icons.download_outlined, l10n.exportBackupButton,
                        () => _handleExport(context, store)),
                    _dataActionBtn(c, Icons.upload_outlined, l10n.importBackupButton,
                        () => _handleImport(context, store)),
                    if (!store.hasAnyData)
                      _dataActionBtn(c, Icons.auto_awesome, l10n.loadExampleDataButton,
                          () => store.loadDemoData(seedData())),
                  ]),
                  if (_importError != null) ...[
                    const SizedBox(height: 10),
                    Row(children: [
                      Icon(Icons.error_outline, size: 13, color: c.danger),
                      const SizedBox(width: 6),
                      Expanded(
                          child: Text(_importError!,
                              style: TextStyle(fontSize: 12, color: c.danger))),
                    ]),
                  ],
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: c.border))),
              child: OutlinedButton.icon(
                onPressed: () => showMrdConfirm(
                  context,
                  title: l10n.resetAllDataTitle,
                  description: l10n.resetAllDataDescription,
                  confirmLabel: l10n.resetEverythingButton,
                  onConfirm: store.resetAllData,
                ),
                style: OutlinedButton.styleFrom(
                    foregroundColor: c.danger,
                    side: BorderSide(color: c.danger),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 11)),
                icon: const Icon(Icons.replay, size: 14),
                label: Text(l10n.resetAllDataButtonLabel,
                    style:
                        const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
        _Section(
          title: l10n.aboutTitle,
          c: c,
          children: [
            for (final row in [
              [l10n.versionLabel, '1.0.0 (Flutter port)'],
              [l10n.storageLabel, l10n.storageValue],
              [l10n.accountsLabel, l10n.accountsValue],
            ])
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: c.border))),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(row[0],
                          style: TextStyle(fontSize: 13, color: c.textDim)),
                      Text(row[1],
                          style: TextStyle(
                              fontSize: 12.5,
                              fontFamily: 'monospace',
                              color: c.text)),
                    ]),
              ),
          ],
        ),
      ],
    );
  }

  Widget _toggleBtn(MeridianColors c, IconData? icon, String label, bool active,
      VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: active ? c.primary : c.border),
          color: active ? c.primaryBg : c.surface,
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: active ? c.primary : c.textDim),
            const SizedBox(width: 6)
          ],
          Text(label,
              style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: active ? c.primary : c.textDim)),
        ]),
      ),
    );
  }

  Widget _dataActionBtn(
      MeridianColors c, IconData icon, String label, VoidCallback onTap) {
    return OutlinedButton.icon(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
          foregroundColor: c.text,
          side: BorderSide(color: c.border),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11)),
      icon: Icon(icon, size: 14),
      label: Text(label,
          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
    );
  }
}

class _Section extends StatelessWidget {
  // UI/UX FIX: title is now optional. A field reported as "too much
  // wrapper text for what's just one setting" — the whole "PROFILE"
  // section, for a single name field — gets folded down to the bordered
  // card alone, with no uppercase section label above it. Every other
  // section (Localization, Appearance, ...) still passes a title as
  // before and is unaffected.
  final String? title;
  final MeridianColors c;
  final List<Widget> children;
  const _Section({this.title, required this.c, required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(title!.toUpperCase(),
                style: TextStyle(
                    fontSize: 11.5,
                    letterSpacing: 0.6,
                    fontWeight: FontWeight.w600,
                    color: c.textFaint)),
            const SizedBox(height: 8),
          ],
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
                border: Border.all(color: c.border),
                borderRadius: BorderRadius.circular(16),
                color: c.surface),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final MeridianColors c;
  final String label;
  final String? description;
  final Widget child;
  final bool isLast;
  const _Row(
      {required this.c,
      required this.label,
      this.description,
      required this.child,
      this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
          border: isLast ? null : Border(bottom: BorderSide(color: c.border))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 13.5, fontWeight: FontWeight.w600, color: c.text)),
          if (description != null) ...[
            const SizedBox(height: 2),
            Text(description!,
                style: TextStyle(fontSize: 11.5, color: c.textFaint)),
          ],
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _NumberStepper extends StatelessWidget {
  final int value;
  final int min;
  final int max;
  final int step;
  final String suffix;
  final ValueChanged<int> onChanged;

  const _NumberStepper(
      {required this.value,
      required this.min,
      required this.max,
      required this.step,
      required this.suffix,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ThemeController>().colors;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      _stepBtn(c, '−', value <= min,
          () => onChanged(clampInt(value - step, min, max))),
      // UI FIX (reported: the two reminder-hour steppers — "8 h" and
      // "20 h" — didn't line up with each other). Centering the whole
      // "$value $suffix" string as one block meant the *digits* shifted
      // position depending on how many of them there were: "8 h" is 3
      // monospace characters, "20 h" is 4, so centering each as a block
      // put the "8" one character left of center but the "20" a digit
      // and a half left of center — different distances, so the numbers
      // (and the +/- buttons around them) never lined up between two
      // steppers with different digit counts. Splitting the number into
      // its own right-aligned sub-box, followed by the suffix at a fixed
      // gap, pins both the number's right edge and the suffix's left
      // edge to the same spot regardless of digit count — 1, 2, or 3
      // digits (this widget also renders up to "180" for focus-duration
      // minutes elsewhere on this screen).
      SizedBox(
        width: 70,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 36,
              child: Text('$value',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                      fontSize: 14,
                      fontFamily: 'monospace',
                      color: c.text)),
            ),
            const SizedBox(width: 4),
            Text(suffix,
                style: TextStyle(
                    fontSize: 14, fontFamily: 'monospace', color: c.text)),
          ],
        ),
      ),
      _stepBtn(c, '+', value >= max,
          () => onChanged(clampInt(value + step, min, max))),
    ]);
  }

  Widget _stepBtn(
      MeridianColors c, String symbol, bool disabled, VoidCallback onTap) {
    return Opacity(
      opacity: disabled ? 0.4 : 1,
      child: InkWell(
        onTap: disabled ? null : onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: c.border),
              color: c.surface),
          child: Text(symbol, style: TextStyle(fontSize: 16, color: c.text)),
        ),
      ),
    );
  }
}

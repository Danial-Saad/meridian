import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/domain.dart';
import '../l10n/app_localizations.dart';
import '../services/notification_service.dart'; // --- FEATURE 6 ---
import '../services/app_blocking_service.dart'; // خدمة حظر التطبيقات
import '../store/meridian_store.dart';
import '../theme/app_theme.dart';
import '../utils/format_utils.dart';
import '../widgets/shared/buttons.dart';
import '../widgets/shared/confirm_dialog.dart';
import '../widgets/shared/field_label.dart';
import 'app_selection_screen.dart'; // شاشة اختيار التطبيقات المحظورة

enum _Phase { focus, breakPhase }

class _Preset {
  final String id;
  final String label;
  final int focus;
  final int brk;
  const _Preset(this.id, this.label, this.focus, this.brk);
}

class FocusScreen extends StatefulWidget {
  final String? focusTaskId;
  final void Function(String id) setFocusTaskId;
  final bool isActive;
  final ValueChanged<bool> onSessionActiveChanged;

  const FocusScreen({
    super.key,
    required this.focusTaskId,
    required this.setFocusTaskId,
    required this.isActive,
    required this.onSessionActiveChanged,
  });

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen>
    with WidgetsBindingObserver {
  static const _presetOptions = [
    _Preset('25-5', '25 / 5', 25, 5),
    _Preset('50-10', '50 / 10', 50, 10),
  ];

  late _Preset _preset;
  late int _customFocus;
  late int _customBreak;
  _Phase _phase = _Phase.focus;
  bool _running = false;
  int _secondsLeft = 25 * 60;
  Timer? _timer;
  DateTime? _endAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final settings = context.read<MeridianStore>().settings;
    _customFocus = settings.pomodoroFocus;
    _customBreak = settings.pomodoroBreak;
    _preset = _presetOptions.first;
    _secondsLeft = _totalSeconds();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    AppBlockingService
        .endSession(); // حماية إضافية لإنهاء الحظر عند إغلاق الشاشة
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // The countdown is wall-clock based (_endAt), so it's always correct
    // in principle regardless of how long the app spent backgrounded —
    // but if Android suspends the isolate's timers while backgrounded
    // (common after a while, especially under battery optimization), the
    // periodic Timer that would normally self-correct every 250ms simply
    // doesn't fire until the app is foregrounded again. Force one
    // immediate reconciliation on resume instead of waiting up to 250ms
    // for the next natural tick, so the displayed time is never stale
    // even for a moment after coming back.
    if (state == AppLifecycleState.resumed && _running) {
      _tick(_totalSeconds());
    }
  }

  bool get _isCustom => _preset.id == 'custom';

  int _totalSeconds() {
    if (_phase == _Phase.focus) {
      return (_isCustom ? _customFocus : _preset.focus) * 60;
    }
    return (_isCustom ? _customBreak : _preset.brk) * 60;
  }

  List<Task> get _incomplete {
    final store = context.read<MeridianStore>();
    final list = store.todaysTasks
        .where((t) => t.status != TaskStatus.completed)
        .toList()
      ..sort((a, b) => a.start.compareTo(b.start));
    return list;
  }

  // BUG FIX (crash reported: tapping "Complete" threw a hard Flutter
  // assertion — "'package:flutter/src/material/dropdown.dart' ... There
  // should be exactly one item with [DropdownButton]'s value" — and took
  // the whole screen down to Flutter's red error page). Root cause: this
  // used to search `todaysTasks` (the *unfiltered* list, completed tasks
  // included) for `widget.focusTaskId`, while the Dropdown below builds
  // its `items` from `incomplete` (completed tasks excluded). The moment
  // `_complete()` marks the active task done, `widget.focusTaskId` still
  // points at it (nothing clears that selection), so this kept resolving
  // it as `activeTask` — and handing the Dropdown a `value` that no
  // longer existed anywhere in its own `items` list is exactly the
  // invariant that assertion enforces. Searching `incomplete` instead of
  // `todaysTasks` means a completed task can never be returned here, so
  // `activeTask` and the Dropdown's `items` are always sourced from the
  // same list — falls through to `incomplete.first` (or `null`, which
  // the Dropdown handles fine via its `hint`) exactly when the
  // previously-selected task stops being a valid choice, instead of
  // handing back a stale reference to it.
  Task? _activeTask(List<Task> incomplete) {
    if (widget.focusTaskId != null) {
      for (final t in incomplete) {
        if (t.id == widget.focusTaskId) return t;
      }
    }
    return incomplete.isNotEmpty ? incomplete.first : null;
  }

  void _resetForPhaseOrPreset() {
    AppBlockingService.endSession(); // إنهاء الحظر إذا تم تغيير الإعدادات
    _timer?.cancel();
    setState(() {
      _secondsLeft = _totalSeconds();
      _running = false;
    });
  }

  void _start() async {
    final total = _totalSeconds();
    _endAt = DateTime.now().add(Duration(seconds: _secondsLeft));
    setState(() => _running = true);
    widget.onSessionActiveChanged(true);
    _timer?.cancel();
    _timer =
        Timer.periodic(const Duration(milliseconds: 250), (_) => _tick(total));

    // -- تشغيل الحظر الفعلي في أندرويد --
    if (mounted) {
      final store = context.read<MeridianStore>();
      final settings = store.settings;
      if (settings.blockedApps.isNotEmpty && _phase == _Phase.focus) {
        final hasPerm = await AppBlockingService.isPermissionGranted();
        if (hasPerm) {
          await AppBlockingService.startSession(
              settings.blockedApps, (_secondsLeft / 60).ceil());
        }
      }
    }
  }

  void _tick(int totalSeconds) {
    if (_endAt == null) return;
    final remaining = _endAt!.difference(DateTime.now()).inMilliseconds / 1000;
    if (remaining <= 0) {
      AppBlockingService.endSession(); // إنهاء الحظر فور انتهاء الوقت الفعلي
      _timer?.cancel();
      final store = context.read<MeridianStore>();
      final active = _activeTask(_incomplete);
      final mins = (totalSeconds / 60).round();
      if (_phase == _Phase.focus) {
        if (active != null) store.logFocusSession(active.id, mins);
        final l10n = AppLocalizations.of(context)!;
        final taskTitle = active?.title ?? l10n.yourTaskFallback;
        store.notify(ToastKind.success, l10n.focusCompleteToast(mins, taskTitle));
        if (store.settings.notificationsEnabled && !widget.isActive) {
          NotificationService.show(
            title: l10n.focusCompleteNotifTitle,
            body: l10n.focusCompleteNotifBody(mins, taskTitle),
          );
        }
        setState(() {
          _phase = _Phase.breakPhase;
          _running = false;
          _secondsLeft = _totalSeconds();
        });
        widget.onSessionActiveChanged(false);
      } else {
        final l10n = AppLocalizations.of(context)!;
        store.notify(ToastKind.info, l10n.breakOverToast);
        if (store.settings.notificationsEnabled && !widget.isActive) {
          NotificationService.show(
            title: l10n.breakOverNotifTitle,
            body: l10n.breakOverNotifBody,
            type: MeridianNotificationType.breakComplete,
          );
        }
        setState(() {
          _phase = _Phase.focus;
          _running = false;
          _secondsLeft = _totalSeconds();
        });
        widget.onSessionActiveChanged(false);
      }
      return;
    }
    final next = remaining.ceil();
    if (widget.isActive) {
      if (next != _secondsLeft) setState(() => _secondsLeft = next);
    } else {
      _secondsLeft = next;
    }
  }

  void _pause() {
    AppBlockingService.endSession(); // إنهاء الحظر فور الإيقاف المؤقت
    _timer?.cancel();
    setState(() => _running = false);
    widget.onSessionActiveChanged(false);
  }

  void _reset() {
    AppBlockingService.endSession(); // إنهاء الحظر فور إعادة الضبط
    _timer?.cancel();
    setState(() {
      _running = false;
      _secondsLeft = _totalSeconds();
    });
    widget.onSessionActiveChanged(false);
  }

  // Every other destructive action in this app (delete task/habit, reset
  // all data) confirms first — resetting an in-progress session used to
  // be the one exception, silently zeroing out real elapsed time with no
  // warning. Skips the dialog when there's genuinely nothing to lose yet
  // (a fresh, untouched timer) so it doesn't nag on the common case of
  // resetting before ever starting.
  void _confirmReset() {
    if (_secondsLeft == _totalSeconds()) {
      _reset();
      return;
    }
    final l10n = AppLocalizations.of(context)!;
    showMrdConfirm(
      context,
      title: l10n.resetSessionTitle,
      description: l10n.resetSessionDesc,
      confirmLabel: l10n.resetButtonLabel,
      onConfirm: _reset,
    );
  }

  void _skip() {
    // BUG FIX: skipping used to discard whatever time had already elapsed
    // in the current focus phase with no record of it at all — unlike
    // _complete(), which correctly credits partial time. 20 real minutes
    // of focus work could vanish from the stats just because the person
    // tapped "Skip" instead of "Complete" once the task was done early.
    if (_phase == _Phase.focus) {
      final total = _totalSeconds();
      final elapsedMin = ((total - _secondsLeft) / 60).round();
      if (elapsedMin > 0) {
        final store = context.read<MeridianStore>();
        final active = _activeTask(_incomplete);
        store.logFocusSession(active?.id, elapsedMin);
      }
    }
    AppBlockingService.endSession(); // إنهاء الحظر فور التخطي
    _timer?.cancel();
    setState(() {
      _phase = _phase == _Phase.focus ? _Phase.breakPhase : _Phase.focus;
      _running = false;
      _secondsLeft = _totalSeconds();
    });
    widget.onSessionActiveChanged(false);
  }

  void _complete(Task? active) {
    AppBlockingService.endSession(); // إنهاء الحظر فور استكمال المهمة يدوياً
    final store = context.read<MeridianStore>();
    if (active != null) {
      final total = _totalSeconds();
      final elapsedMin = ((total - _secondsLeft) / 60).round();
      if (_phase == _Phase.focus && elapsedMin > 0) {
        store.logFocusSession(active.id, elapsedMin);
      }
      store.toggleTaskComplete(active.id);
    }
    _timer?.cancel();
    setState(() => _running = false);
    widget.onSessionActiveChanged(false);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ThemeController>().colors;
    final store = context.watch<MeridianStore>();
    final settings = store.settings;
    final incomplete = _incomplete;
    final activeTask = _activeTask(incomplete);
    final l10n = AppLocalizations.of(context)!;

    final presets = [
      ..._presetOptions,
      _Preset(
          'custom', l10n.customPresetLabel, settings.pomodoroFocus, settings.pomodoroBreak),
    ];

    final totalSeconds = _totalSeconds();
    final mins = _secondsLeft ~/ 60;
    final secs = _secondsLeft % 60;
    final progress = totalSeconds > 0 ? 1 - (_secondsLeft / totalSeconds) : 0.0;
    final phaseColor = _phase == _Phase.focus ? c.primary : c.success;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      children: [
        Text(l10n.focusMode,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.w600, color: c.text)),
        const SizedBox(height: 4),
        Text(
            _phase == _Phase.focus
                ? l10n.focusSubtitleFocus
                : l10n.focusSubtitleBreak,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: c.textDim)),
        const SizedBox(height: 20),
        if (!_running) ...[
          // --- ميزة اختيار التطبيقات المحظورة ---
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.block, color: c.textDim),
            title: Text(l10n.blockDistractingAppsTitle,
                style: TextStyle(color: c.text, fontSize: 14)),
            subtitle: Text(l10n.appsSelectedCount(settings.blockedApps.length),
                style: TextStyle(color: c.textFaint, fontSize: 12)),
            trailing: Icon(Icons.chevron_right, color: c.textDim),
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const AppSelectionScreen())),
          ),
          const SizedBox(height: 20),
          // -------------------------------------

          FieldLabel(l10n.workingOnLabel, c: c),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: c.border)),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: activeTask?.id,
                dropdownColor: c.surface,
                hint: Text(l10n.noTasksFreeSession,
                    style: TextStyle(fontSize: 13.5, color: c.textFaint)),
                style: TextStyle(fontSize: 14, color: c.text),
                items: incomplete
                    .map((t) => DropdownMenuItem(
                        value: t.id,
                        child: Text(t.title, overflow: TextOverflow.ellipsis)))
                    .toList(),
                onChanged: (id) {
                  if (id != null) widget.setFocusTaskId(id);
                },
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
        Center(
          child: SizedBox(
            width: 250,
            height: 250,
            child: Stack(alignment: Alignment.center, children: [
              CustomPaint(
                size: const Size(250, 250),
                painter: _RingPainter(
                    progress: progress,
                    trackColor: c.border,
                    color: phaseColor),
              ),
              Column(mainAxisSize: MainAxisSize.min, children: [
                Text(
                  _phase == _Phase.focus ? l10n.focusPhaseLabel : l10n.breakPhaseLabel,
                  style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 1,
                      fontWeight: FontWeight.w600,
                      color: phaseColor),
                ),
                const SizedBox(height: 6),
                Text('${pad2(mins)}:${pad2(secs)}',
                    style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w600,
                        color: c.text,
                        fontFamily: 'monospace')),
                const SizedBox(height: 6),
                SizedBox(
                  width: 170,
                  child: Text(activeTask?.title ?? l10n.freeSessionLabel,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12.5, color: c.textDim)),
                ),
              ]),
            ]),
          ),
        ),
        const SizedBox(height: 26),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          alignment: WrapAlignment.center,
          children: [
            if (!_running)
              MrdIconButton(
                  onTap: _start,
                  icon: Icons.play_arrow,
                  label: _secondsLeft == totalSeconds ? l10n.startButtonLabel : l10n.resumeButtonLabel,
                  primary: true)
            else
              MrdIconButton(onTap: _pause, icon: Icons.pause, label: l10n.pauseButtonLabel),
            // UX FIX (clarified: applies only while the timer is actively
            // running) — Reset and Skip are still useful, just not while
            // a session is counting down: the person asked for exactly
            // two buttons while running — Pause and Complete — and to
            // get Reset/Skip back once it's paused (or hasn't started
            // yet). Hidden here rather than removed.
            if (!_running) ...[
              MrdIconButton(onTap: _confirmReset, icon: Icons.replay, label: l10n.resetButtonLabel),
              MrdIconButton(onTap: _skip, icon: Icons.skip_next, label: l10n.skipButtonLabel),
            ],
            if (_phase == _Phase.focus)
              MrdIconButton(
                  onTap:
                      activeTask == null ? null : () => _complete(activeTask),
                  icon: Icons.check,
                  label: l10n.completeButtonLabel,
                  success: true),
          ],
        ),
        // UX FIX (reported: duration controls stayed visible and
        // tappable while a session was actively running) — tapping a
        // preset mid-session silently resets the running timer via
        // `_resetForPhaseOrPreset()`, which is exactly the kind of
        // surprising, easy-to-mis-tap behavior this screen already
        // avoids elsewhere: the "Working on" task picker and the
        // app-blocking row above are both already hidden with the same
        // `if (!_running)` guard. Presets and the custom duration fields
        // just didn't get that same treatment. Choosing a duration only
        // makes sense before a session starts, so wrapping them here
        // matches the pattern already established above.
        if (!_running) ...[
          const SizedBox(height: 28),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: presets.map((p) {
              final active = _preset.id == p.id;
              return InkWell(
                onTap: () {
                  setState(() => _preset = p);
                  _resetForPhaseOrPreset();
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: active ? c.primary : c.border),
                    color: active ? c.primaryBg : Colors.transparent,
                  ),
                  child: Text(p.label,
                      style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: active ? c.primary : c.textDim)),
                ),
              );
            }).toList(),
          ),
          if (_isCustom) ...[
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _customField(l10n.focusFieldLabel, _customFocus, c, (v) {
                  setState(() => _customFocus = v);
                  _resetForPhaseOrPreset();
                }, min: 5, max: 180),
                const SizedBox(width: 20),
                _customField(l10n.breakFieldLabel, _customBreak, c, (v) {
                  setState(() => _customBreak = v);
                  _resetForPhaseOrPreset();
                }, min: 1, max: 60),
              ],
            ),
          ],
        ],
      ],
    );
  }

  Widget _customField(
      String label, int value, MeridianColors c, ValueChanged<int> onChanged,
      {required int min, required int max}) {
    final l10n = AppLocalizations.of(context)!;
    // BUG FIX: previously accepted any positive number with no upper
    // bound at all (99999 minutes was valid input) — inconsistent with
    // Settings' own pomodoro sliders, which cap focus at 180 min and
    // break at 60. Clamps silently to the same range rather than
    // rejecting with an error message, since there isn't room for one
    // next to this compact inline field.
    int clamp(int n) => n < min ? min : (n > max ? max : n);
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Text('$label ', style: TextStyle(fontSize: 12.5, color: c.textDim)),
      SizedBox(
        width: 52,
        child: TextFormField(
          initialValue: '$value',
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12.5, color: c.text),
          decoration: InputDecoration(
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            filled: true,
            fillColor: c.surface,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: c.border)),
          ),
          onFieldSubmitted: (v) => onChanged(clamp(int.tryParse(v) ?? value)),
          onChanged: (v) {
            final n = int.tryParse(v);
            if (n != null && n > 0) onChanged(clamp(n));
          },
        ),
      ),
      Text(' ${l10n.minUnit}', style: TextStyle(fontSize: 12.5, color: c.textDim)),
    ]);
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color color;
  _RingPainter(
      {required this.progress, required this.trackColor, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    canvas.drawCircle(
        center,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 8
          ..color = trackColor);
    final sweep = 2 * math.pi * progress.clamp(0.0, 1.0);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress || old.color != color;
}

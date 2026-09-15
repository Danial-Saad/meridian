import 'package:flutter/widgets.dart';

/// Requests focus on [node] exactly when the enclosing modal route's
/// entrance animation finishes, instead of guessing a fixed delay.
///
/// Call from `didChangeDependencies()` — not `initState()`, since
/// `ModalRoute.of(context)` isn't reliably available that early — and
/// guard the call site so it only attaches once per widget lifetime.
///
/// BUG FIX (reported: the keyboard felt very slow to appear when
/// opening the New Task / New Habit sheets — "بطيئة كتير"). An earlier
/// fix for a *different* problem — `autofocus: true` fighting the
/// bottom sheet's own slide-up entrance animation, which read as janky,
/// two motions at once — replaced it with a flat
/// `Future.delayed(milliseconds: 300)` guess before requesting focus.
/// That guess was deliberately *longer* than the sheet's real ~250ms
/// entrance animation so it would never overlap — but the safety
/// margin itself is exactly the extra lag that got reported here.
/// Listening for the real `AnimationStatus.completed` event fires focus
/// the moment the sheet is actually done settling: no earlier (still
/// avoids the original two-animations-at-once jank) and never later
/// than necessary (no guessed padding on top of the real animation).
void requestFocusOnRouteSettled(
  BuildContext context,
  FocusNode node, {
  required bool Function() mounted,
}) {
  final anim = ModalRoute.of(context)?.animation;
  if (anim == null || anim.status == AnimationStatus.completed) {
    // No route animation to wait on (or it already finished — e.g. a
    // hot-reload re-entry). Next frame is as good as it gets.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted() && node.canRequestFocus) node.requestFocus();
    });
    return;
  }
  void listener(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      anim.removeStatusListener(listener);
      if (mounted() && node.canRequestFocus) node.requestFocus();
    }
  }

  anim.addStatusListener(listener);
}

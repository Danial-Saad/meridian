import 'package:flutter/material.dart';
import '../../utils/bidi_utils.dart';

/// A drop-in replacement for [TextField], for any field that holds
/// free-form natural-language text that might be Arabic, English, or a
/// mix of both in the same sentence — e.g. "انتهاء اول 3 دروس من كورس AI
/// agents". See bidi_utils.dart for why this needs to exist at all.
///
/// This re-detects the base direction from the field's own content
/// (falling back to the hint text while the field is empty, so an Arabic
/// placeholder still reads right-to-left instead of defaulting to LTR
/// just because nothing's been typed yet) and only rebuilds when the
/// detected direction actually changes, not on every keystroke.
/// `TextAlign.start` — already `TextField`'s own default, left unset here
/// on purpose — then resolves to the correct visual side on its own.
/// Nothing here ever hardcodes `textAlign` or `textDirection` to a fixed
/// value; that's the whole point.
///
/// What this does NOT change: the underlying [TextEditingController] and
/// its `text`/`selection` are exactly what a plain `TextField` would use.
/// Caret movement, selection, copy/paste, and backspace/delete inside
/// mixed-direction text are handled by Flutter's own text-layout engine
/// once it has the correct base `textDirection` — none of that logic is
/// reimplemented or touched here.
///
/// Do NOT use this for:
/// - URL fields — URLs must stay LTR regardless of surrounding content.
///   Pass `textDirection: TextDirection.ltr` to a plain `TextField`
///   instead (see the Link field in task_modal.dart or the URL field in
///   resource_modal.dart for the pattern).
/// - Numeric-only fields — leave those as a plain `TextField`/
///   `TextFormField`. Bidi detection on a field that only ever contains
///   digits is pure overhead with no behavioral benefit.
class MrdBidiTextField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final TextStyle? style;
  final InputDecoration? decoration;
  final int? maxLines;
  final TextInputType? keyboardType;
  final TextAlign? textAlign;
  final ValueChanged<String>? onChanged;

  const MrdBidiTextField({
    super.key,
    required this.controller,
    this.focusNode,
    this.style,
    this.decoration,
    this.maxLines = 1,
    this.keyboardType,
    this.textAlign,
    this.onChanged,
  });

  @override
  State<MrdBidiTextField> createState() => _MrdBidiTextFieldState();
}

class _MrdBidiTextFieldState extends State<MrdBidiTextField> {
  late TextDirection _direction;

  @override
  void initState() {
    super.initState();
    // Computed synchronously so editing an existing task/habit/resource
    // with Arabic text already in it renders correctly-aligned on the
    // very first frame — never a flash of the wrong direction.
    _direction = _detect();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void didUpdateWidget(covariant MrdBidiTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onTextChanged);
      widget.controller.addListener(_onTextChanged);
      _onTextChanged();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  TextDirection _detect() {
    final text = widget.controller.text;
    final source = text.isNotEmpty ? text : (widget.decoration?.hintText ?? '');
    // BUG FIX (audit report #5): detectTextDirection's own fallback
    // parameter defaults to TextDirection.ltr — correct as a library-
    // level default, but wrong to leave unset here specifically. A
    // genuinely empty field (no text yet, and no hint — or a hint with
    // no strongly-directional characters) used to always start
    // left-aligned regardless of what language the app itself is
    // currently in. In an Arabic session, that's a real, visible
    // mismatch against every other RTL element already on screen, for
    // exactly as long as the field stays empty. Falling back to the
    // ambient `Directionality` — the same direction the rest of this
    // screen is already using — instead of a hardcoded constant fixes
    // that without needing to duplicate any locale-checking logic here.
    return detectTextDirection(source, fallback: Directionality.of(context));
  }

  void _onTextChanged() {
    final next = _detect();
    // Guarded so typing doesn't trigger a rebuild on every keystroke —
    // only when the base direction actually flips.
    if (next != _direction) setState(() => _direction = next);
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      style: widget.style,
      decoration: widget.decoration,
      maxLines: widget.maxLines,
      keyboardType: widget.keyboardType,
      textAlign: widget.textAlign ?? TextAlign.start,
      onChanged: widget.onChanged,
      textDirection: _direction,
    );
  }
}

import 'dart:ui' show TextDirection;

/// True for a Unicode code point in a right-to-left script block (Hebrew,
/// Arabic, and their related/presentation-form blocks — Syriac, Thaana,
/// NKo, Samaritan, Mandaic, and Arabic Extended-A all sit contiguously
/// between Hebrew and Arabic Presentation Forms-A, so one range covers
/// them without needing to enumerate each block separately).
bool isRtlCodePoint(int rune) {
  return (rune >= 0x0591 && rune <= 0x08FF) ||
      (rune >= 0xFB1D && rune <= 0xFDFF) || // Hebrew + Arabic presentation forms A
      (rune >= 0xFE70 && rune <= 0xFEFF); // Arabic presentation forms B
}

/// True for a Unicode code point with strong left-to-right directionality.
/// This app's two real-world scripts are Latin (English) and Arabic, but a
/// few more common LTR blocks are included so the heuristic degrades
/// sensibly for names/words in other languages too, rather than treating
/// them as direction-neutral by accident.
bool isLtrCodePoint(int rune) {
  return (rune >= 0x0041 && rune <= 0x005A) || // A-Z
      (rune >= 0x0061 && rune <= 0x007A) || // a-z
      (rune >= 0x00C0 && rune <= 0x02AF) || // Latin Extended
      (rune >= 0x0370 && rune <= 0x058F) || // Greek, Cyrillic, Armenian
      (rune >= 0x3040 && rune <= 0x30FF) || // Hiragana, Katakana
      (rune >= 0x4E00 && rune <= 0x9FFF); // CJK unified ideographs
}

/// Detects the paragraph base direction for possibly-mixed-language text
/// using the "first strong character" heuristic — the same approach
/// behind HTML's `dir="auto"` and the `intl` package's
/// `Bidi.estimateDirectionOfText`. Digits, punctuation, whitespace,
/// symbols, and emoji are direction-neutral and skipped; the first
/// character that *is* strongly directional decides the base direction
/// for the whole field.
///
/// This intentionally does NOT count/weigh characters to find a
/// "majority" direction — first-strong is what every mainstream
/// implementation of this exact problem uses, because it's stable
/// (doesn't change classification based on what happens to appear later
/// in the string) and matches what people already expect from every other
/// bidi-aware app.
///
/// Why this needs to exist at all: Flutter's text layout already
/// implements the Unicode bidirectional algorithm correctly *within* a
/// paragraph — mixed-direction runs shape and order correctly once laid
/// out. What it does NOT do on its own is pick the right *base* direction
/// for that paragraph; without an explicit `textDirection`, a `TextField`
/// inherits the ambient `Directionality` (LTR in this app, since there's
/// no RTL locale configured), regardless of what's actually typed. A
/// field full of Arabic then ends up anchored to the left edge instead of
/// the right, which is the bug this file exists to fix — by detecting the
/// right base direction per field, dynamically, instead of hardcoding one
/// direction for every field (wrong for Arabic-dominant text) or the
/// other (wrong for English-dominant text).
TextDirection detectTextDirection(String text, {TextDirection fallback = TextDirection.ltr}) {
  for (final rune in text.runes) {
    if (isRtlCodePoint(rune)) return TextDirection.rtl;
    if (isLtrCodePoint(rune)) return TextDirection.ltr;
  }
  return fallback;
}

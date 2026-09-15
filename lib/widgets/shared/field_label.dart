import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class FieldLabel extends StatelessWidget {
  final String text;
  final MeridianColors c;
  final EdgeInsets? margin;

  const FieldLabel(this.text, {super.key, required this.c, this.margin});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin ?? const EdgeInsets.only(bottom: 6),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 11.5,
          color: c.textFaint,
          letterSpacing: 0.6,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

InputDecoration mrdInputDecoration(MeridianColors c, {String? hint}) {
  return InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: c.textFaint, fontSize: 13.5),
    filled: true,
    fillColor: c.surface,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: c.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: c.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: c.primary, width: 1.5),
    ),
  );
}

import 'package:flutter/material.dart';
import '../../models/domain.dart';
import '../../theme/app_theme.dart';

class MrdToast extends StatelessWidget {
  final ToastState toast;
  final MeridianColors c;

  const MrdToast({super.key, required this.toast, required this.c});

  @override
  Widget build(BuildContext context) {
    final color = toast.kind == ToastKind.success
        ? c.success
        : toast.kind == ToastKind.info
            ? c.textDim
            : c.danger;
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 26),
        child: Material(
          color: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 380),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: c.border),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 30, offset: const Offset(0, 8))],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle, boxShadow: [
                    BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 8),
                  ]),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(toast.text, style: TextStyle(fontSize: 13.5, color: c.text)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

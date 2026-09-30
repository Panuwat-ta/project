import 'package:flutter/material.dart';

/// Centers page content and caps its readable width on wider windows.
class AdaptiveContent extends StatelessWidget {
  const AdaptiveContent({
    super.key,
    required this.child,
    required this.maxWidth,
    this.alignment = Alignment.topCenter,
  });

  final Widget child;
  final double maxWidth;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: SizedBox(width: double.infinity, child: child),
      ),
    );
  }
}

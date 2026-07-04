import 'package:flutter/material.dart';

/// The FAFO brand wordmark, rendered with the second **F mirrored** (stem on
/// the right, arms pointing left) to match the app logo.
///
/// Pass the full [style] you want the word drawn in (font, size, color,
/// shadows). The mirrored F reuses that style but with its shadow x-offsets
/// negated, so — after the horizontal flip — its extrusion still falls in the
/// same direction as the other letters.
class FafoWordmark extends StatelessWidget {
  const FafoWordmark({super.key, required this.style});

  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    // Flip mirrors the letter horizontally; pre-negate the shadow dx so the
    // drop shadow lands on the same side as the un-flipped letters.
    final mirroredStyle = style.copyWith(
      shadows: style.shadows
          ?.map(
            (s) => Shadow(
              color: s.color,
              blurRadius: s.blurRadius,
              offset: Offset(-s.offset.dx, s.offset.dy),
            ),
          )
          .toList(),
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text('FA', style: style),
        // Transform is paint-only, so the letter still lays out (and reports
        // its baseline) as a normal 'F' — only its pixels are mirrored.
        Transform.flip(flipX: true, child: Text('F', style: mirroredStyle)),
        Text('O', style: style),
      ],
    );
  }
}

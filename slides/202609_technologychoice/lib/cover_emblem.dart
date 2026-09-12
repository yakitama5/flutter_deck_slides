// Extracted from the equivalent classes in
// `slides/20260912_oso/lib/widgets.dart`.
import 'package:flutter/material.dart';

/// Emblem embossed on the closed picture book.
///
/// The cover carries no title: the talk opens on a book the audience is meant
/// to recognise as a book, and the title is read aloud instead of printed.
class StorybookCoverEmblem extends StatelessWidget {
  const StorybookCoverEmblem({required this.accentColor, super.key});

  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 560,
      child: Stack(
        alignment: Alignment.center,
        children: [
          for (final alignment in const <Alignment>[
            Alignment.topLeft,
            Alignment.topRight,
            Alignment.bottomLeft,
            Alignment.bottomRight,
          ])
            Align(
              alignment: alignment,
              child: Icon(
                Icons.spa_rounded,
                size: 52,
                color: accentColor.withValues(alpha: 0.62),
              ),
            ),
          _CoverRing(
            diameter: 476,
            width: 6,
            color: accentColor.withValues(alpha: 0.9),
          ),
          _CoverRing(
            diameter: 408,
            width: 2,
            color: accentColor.withValues(alpha: 0.45),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_stories_rounded, size: 192, color: accentColor),
              const SizedBox(height: 30),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < 3; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 9),
                      child: Icon(
                        Icons.circle,
                        size: 14,
                        color: accentColor.withValues(alpha: 0.75),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CoverRing extends StatelessWidget {
  const _CoverRing({
    required this.diameter,
    required this.width,
    required this.color,
  });

  final double diameter;
  final double width;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: width),
      ),
    );
  }
}

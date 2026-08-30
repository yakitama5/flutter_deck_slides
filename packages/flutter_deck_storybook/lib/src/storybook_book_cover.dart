import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'storybook_book_cover_transition.dart';

/// A closed, storybook-like cover for the first and last slide of a deck.
///
/// The cover deliberately has no slide content area. It can therefore be used
/// as a real book boundary: the page-turn transition can cover the last page
/// completely and leave the viewer looking at a closed book.
class StorybookBookCover extends StatelessWidget {
  /// Creates a front or back cover.
  const StorybookBookCover({
    this.title,
    this.subtitle,
    this.child,
    this.coverColor = const Color(0xFF3E302A),
    this.accentColor = const Color(0xFFE7B86A),
    this.backCover = false,
    super.key,
  }) : assert(title == null || child == null);

  /// Title embossed on a front cover.
  final String? title;

  /// Small text shown below [title].
  final String? subtitle;

  /// Optional custom cover artwork. When set, [title] and [subtitle] are not
  /// rendered.
  final Widget? child;

  /// Main color of the cover.
  final Color coverColor;

  /// Color used for the cover border and embossed details.
  final Color accentColor;

  /// Whether this is the final back cover rather than the opening front cover.
  final bool backCover;

  @override
  Widget build(BuildContext context) {
    final coverContent = child ?? _buildDefaultContent();
    final transition = StorybookBookCoverTransitionScope.maybeOf(context);
    final motionValues = transition == null
        ? StorybookBookCoverMotionValues(
            hingeAlignment: backCover
                ? Alignment.centerRight
                : Alignment.centerLeft,
            rotationY: 0,
            cameraScale: 0.74,
            cameraOffset: Offset.zero,
          )
        : StorybookBookCoverMotionValues.forCover(
            motion: transition.motion,
            progress: transition.progress,
            backCover: backCover,
          );
    final panel = _buildPanel(coverContent);
    final showOuterSurface = math.cos(motionValues.rotationY) >= 0;
    // A rigid board has one visible face at a time. Choosing the face at the
    // edge-on instant avoids stacking two opaque rectangles and lets the same
    // transform carry the outer and inner surfaces through the turn.
    final rigidPanel = Transform(
      key: const ValueKey('storybook-book-rigid-cover-panel'),
      alignment: motionValues.hingeAlignment,
      transform: Matrix4.identity()
        // Keep the rigid board dimensional without allowing the
        // half-turn's depth to become an unintended camera zoom.
        ..setEntry(3, 2, 0.00045)
        ..rotateY(motionValues.rotationY),
      child: showOuterSurface || transition == null
          ? panel
          : _buildInnerPanel(),
    );

    return Stack(
      key: ValueKey(
        backCover ? 'storybook-book-back-cover' : 'storybook-book-front-cover',
      ),
      fit: StackFit.expand,
      children: [
        if (transition == null)
          const Positioned.fill(
            child: StorybookBookTabletop(
              key: ValueKey('storybook-book-tabletop'),
            ),
          )
        else if (transition.includeTabletop)
          Positioned.fill(
            child: StorybookBookTabletop(
              key: ValueKey(
                transition.motion == StorybookBookCoverMotion.opening
                    ? 'storybook-book-opening-cover-tabletop'
                    : 'storybook-book-closing-cover-tabletop',
              ),
            ),
          ),
        Positioned.fill(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final cameraOffset = Offset(
                motionValues.cameraOffset.dx * constraints.maxWidth,
                motionValues.cameraOffset.dy * constraints.maxHeight,
              );
              return Transform.translate(
                key: const ValueKey('storybook-book-camera-position'),
                offset: cameraOffset,
                child: Transform.scale(
                  key: const ValueKey('storybook-book-camera-scale'),
                  alignment: Alignment.center,
                  scale: motionValues.cameraScale,
                  child: Center(
                    child: FractionallySizedBox(
                      // The board is deliberately pulled back at rest. The
                      // camera move, rather than an opacity change, brings it
                      // closer while the rigid cover leaves the spine.
                      widthFactor: motionValues.sceneWidthFactor,
                      heightFactor: motionValues.sceneHeightFactor,
                      child: rigidPanel,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPanel(Widget coverContent) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: coverColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.78),
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            // Keep the board's shadow compact while it is rotating. A large
            // blurred shadow becomes a dark triangular band at the free edge
            // of a near-edge-on cover and reads like a fade or a black frame.
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(
              painter: _StorybookBookCoverPainter(
                accentColor: accentColor,
                backCover: backCover,
              ),
            ),
            Center(
              child: FittedBox(fit: BoxFit.scaleDown, child: coverContent),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInnerPanel() {
    return DecoratedBox(
      key: const ValueKey('storybook-book-rigid-cover-inner-panel'),
      decoration: BoxDecoration(
        color: const Color(0xFFE8D6B9),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.34),
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: CustomPaint(
        painter: _StorybookBookCoverInnerPainter(
          accentColor: accentColor,
          backCover: backCover,
        ),
      ),
    );
  }

  Widget _buildDefaultContent() {
    if (backCover) {
      return Icon(
        Icons.auto_stories_rounded,
        size: 120,
        color: accentColor.withValues(alpha: 0.68),
      );
    }

    final titleText = title;
    if (titleText == null) {
      return Icon(Icons.auto_stories_rounded, size: 120, color: accentColor);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 72, vertical: 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_stories_rounded, size: 104, color: accentColor),
          const SizedBox(height: 28),
          Text(
            titleText,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: accentColor,
              fontSize: 64,
              height: 1.12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
          if (subtitle case final text?) ...[
            const SizedBox(height: 18),
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: accentColor.withValues(alpha: 0.82),
                fontSize: 26,
                height: 1.45,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The persistent tabletop behind a book cover.
///
/// Boundary transitions paint this separately from the cover board so the
/// table never disappears through an opacity fade while paper sheets turn.
class StorybookBookTabletop extends StatelessWidget {
  const StorybookBookTabletop({super.key});

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFF75523E),
      child: CustomPaint(painter: _StorybookTabletopPainter()),
    );
  }
}

/// Adds a tabletop over the outer margin of an opaque page route.
///
/// FlutterDeck slide templates may paint their own background around the page
/// before the transition builder gets to draw. This frame keeps that route
/// background from becoming a dark rectangle while leaving the paper itself
/// and a small shadow band untouched.
class StorybookBookTabletopFrame extends StatelessWidget {
  const StorybookBookTabletopFrame({
    required this.child,
    // FlutterDeck's blank-slide content has 16px layout padding before the
    // StorybookPage's default 28px outer padding.
    this.pagePadding = const EdgeInsets.all(44),
    super.key,
  });

  final Widget child;
  final EdgeInsets pagePadding;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = math.max(
          0.0,
          constraints.maxWidth - pagePadding.horizontal,
        );
        final height = math.max(
          0.0,
          constraints.maxHeight - pagePadding.vertical,
        );
        final pageRect = Rect.fromLTWH(
          pagePadding.left,
          pagePadding.top,
          width,
          height,
        );

        return Stack(
          fit: StackFit.expand,
          children: [
            child,
            Positioned.fill(
              child: CustomPaint(
                painter: _StorybookTabletopOutsidePanelPainter(
                  pageRect,
                  inflateAmount: 0,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StorybookTabletopPainter extends CustomPainter {
  const _StorybookTabletopPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF9A7453), Color(0xFF5B4032)],
        ).createShader(bounds),
    );

    final grainPaint = Paint()
      ..color = const Color(0x260F0906)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.0, size.shortestSide / 420);
    for (var index = -2; index < 13; index++) {
      final y = size.height * (index / 10);
      final path = Path()..moveTo(0, y);
      path.cubicTo(
        size.width * 0.22,
        y + size.height * 0.018,
        size.width * 0.46,
        y - size.height * 0.014,
        size.width * 0.70,
        y + size.height * 0.010,
      );
      path.cubicTo(
        size.width * 0.84,
        y + size.height * 0.022,
        size.width * 0.94,
        y - size.height * 0.018,
        size.width,
        y,
      );
      canvas.drawPath(path, grainPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _StorybookTabletopPainter oldDelegate) => false;
}

/// Restores the tabletop around a cover's slide-owned Material background.
///
/// A route transition can put the cover's [Scaffold] above a sibling tabletop
/// layer. Painting only the four regions outside the board keeps that opaque
/// route background from becoming a black frame without covering the paper
/// bundle hidden below the rigid cover.
class _StorybookTabletopOutsidePanelPainter extends CustomPainter {
  const _StorybookTabletopOutsidePanelPainter(
    this.panelRect, {
    this.inflateAmount = 8,
  });

  final Rect panelRect;
  final double inflateAmount;

  @override
  void paint(Canvas canvas, Size size) {
    final tablePainter = const _StorybookTabletopPainter();
    final bounds = Offset.zero & size;
    final panel = panelRect.inflate(inflateAmount);
    final regions = [
      Rect.fromLTRB(bounds.left, bounds.top, bounds.right, panel.top),
      Rect.fromLTRB(bounds.left, panel.bottom, bounds.right, bounds.bottom),
      Rect.fromLTRB(bounds.left, panel.top, panel.left, panel.bottom),
      Rect.fromLTRB(panel.right, panel.top, bounds.right, panel.bottom),
    ];

    for (final region in regions) {
      if (region.isEmpty) continue;
      canvas
        ..save()
        ..clipRect(region)
        ..clipRect(bounds);
      tablePainter.paint(canvas, size);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(
    covariant _StorybookTabletopOutsidePanelPainter oldDelegate,
  ) {
    return panelRect != oldDelegate.panelRect ||
        inflateAmount != oldDelegate.inflateAmount;
  }
}

class _StorybookBookCoverPainter extends CustomPainter {
  const _StorybookBookCoverPainter({
    required this.accentColor,
    required this.backCover,
  });

  final Color accentColor;
  final bool backCover;

  @override
  void paint(Canvas canvas, Size size) {
    final borderPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.42)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final inset = size.shortestSide * 0.045;
    final border = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        inset,
        inset,
        size.width - inset * 2,
        size.height - inset * 2,
      ),
      Radius.circular(size.shortestSide * 0.032),
    );
    canvas.drawRRect(border, borderPaint);

    final spineWidth = size.width * 0.032;
    final spineGradient = LinearGradient(
      colors: [
        Colors.black.withValues(alpha: 0.22),
        accentColor.withValues(alpha: 0.16),
        Colors.transparent,
      ],
    ).createShader(Rect.fromLTWH(0, 0, spineWidth * 2.4, size.height));
    canvas.drawRect(
      Rect.fromLTWH(
        backCover ? size.width - spineWidth : 0,
        0,
        spineWidth,
        size.height,
      ),
      Paint()..shader = spineGradient,
    );

    final ornamentPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.52)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.0, size.shortestSide / 420)
      ..strokeCap = StrokeCap.round;
    final center = size.center(Offset.zero);
    final ornamentRadius = size.shortestSide * 0.22;
    canvas.drawCircle(center, ornamentRadius, ornamentPaint);
    canvas.drawCircle(center, ornamentRadius * 0.82, ornamentPaint);

    // A closed book has a visible block of pages on the free edge. The lines
    // stay subtle so the cover remains the dominant final frame.
    if (!backCover) {
      final pagePaint = Paint()
        ..color = const Color(0xFFFFF7E6).withValues(alpha: 0.72)
        ..strokeWidth = math.max(1.0, size.shortestSide / 500);
      final pageStart = size.width * 0.965;
      for (var index = 0; index < 7; index++) {
        final y = size.height * (0.39 + index * 0.038);
        canvas.drawLine(
          Offset(pageStart, y),
          Offset(size.width, y + size.height * 0.012),
          pagePaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _StorybookBookCoverPainter oldDelegate) {
    return accentColor != oldDelegate.accentColor ||
        backCover != oldDelegate.backCover;
  }
}

class _StorybookBookCoverInnerPainter extends CustomPainter {
  const _StorybookBookCoverInnerPainter({
    required this.accentColor,
    required this.backCover,
  });

  final Color accentColor;
  final bool backCover;

  @override
  void paint(Canvas canvas, Size size) {
    final inset = size.shortestSide * 0.045;
    final border = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        inset,
        inset,
        size.width - inset * 2,
        size.height - inset * 2,
      ),
      Radius.circular(size.shortestSide * 0.032),
    );
    canvas.drawRRect(
      border,
      Paint()
        ..color = accentColor.withValues(alpha: 0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    final spineWidth = size.width * 0.032;
    final spineLeft = backCover ? size.width - spineWidth : 0.0;
    canvas.drawRect(
      Rect.fromLTWH(spineLeft, 0, spineWidth, size.height),
      Paint()..color = Colors.black.withValues(alpha: 0.08),
    );
  }

  @override
  bool shouldRepaint(covariant _StorybookBookCoverInnerPainter oldDelegate) {
    return accentColor != oldDelegate.accentColor ||
        backCover != oldDelegate.backCover;
  }
}

import 'package:flutter/material.dart';

/// The deep forest green of the picture book cover.
///
/// The presentation slides are seeded from it so that the storybook and the
/// talk that follows read as one piece rather than two decks glued together.
const osoSeedColor = Color(0xFF31533E);

/// The gold foil of the book cover, carried into the scheme as the tertiary
/// role. [ColorScheme.fromSeed] cannot derive a readable foreground for a
/// colour it did not pick, so the tertiary group is spelled out here.
const osoAccentColor = Color(0xFFE7C978);
const _osoOnAccentColor = Color(0xFF3A2E12);
const _osoAccentContainerColor = Color(0xFFF7E7BE);
const _osoOnAccentContainerColor = Color(0xFF4A3A18);

/// Slides are composed against a fixed canvas and then scaled to the viewport.
///
/// The alternative, laying out against whatever size the window happens to be,
/// turns every font size into a guess. This deck is projected in a large room,
/// so the type has to be reliably big at any window size.
const osoCanvasSize = Size(1920, 1080);

/// Material's type scale is tuned for a phone at arm's length. The deck is read
/// from the back of a room, so the whole scale is enlarged once here instead of
/// sprinkling font sizes across the slides.
const _osoFontSizeFactor = 2.2;

/// The rounded face the talk is set in, bundled under assets/fonts so it never
/// depends on the venue network. Kiwi Maru ships only 300/400/500, so the bold
/// weights in the slides resolve to Medium; the hierarchy is carried by size
/// and colour rather than by weight.
const _osoFontFamily = 'Kiwi Maru';

final osoColorScheme = ColorScheme.fromSeed(
  seedColor: osoSeedColor,
  tertiary: osoAccentColor,
  onTertiary: _osoOnAccentColor,
  tertiaryContainer: _osoAccentContainerColor,
  onTertiaryContainer: _osoOnAccentContainerColor,
);

final osoTheme = _buildOsoTheme(fontFamily: _osoFontFamily);

/// The same theme in the platform face.
///
/// The two 「ご清聴ありがとうございました」 slides belong to the picture book rather
/// than to the talk, so they keep the face the book is set in.
final osoEndingTheme = _buildOsoTheme();

ThemeData _buildOsoTheme({String? fontFamily}) {
  final base = ThemeData(colorScheme: osoColorScheme);
  // A raw ThemeData carries only colours in its text theme: MaterialApp merges
  // the type geometry in at localization time, and this theme replaces that.
  // Pinning the geometry restores the font sizes and, as a bonus, keeps the
  // fixed canvas laying out identically whatever locale the browser reports.
  final textTheme = Typography.englishLike2021
      .merge(base.textTheme)
      .apply(fontSizeFactor: _osoFontSizeFactor, fontFamily: fontFamily);

  return base.copyWith(
    textTheme: textTheme,
    iconTheme: IconThemeData(size: 48, color: osoColorScheme.primary),
    cardTheme: const CardThemeData(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(36)),
      ),
    ),
    chipTheme: ChipThemeData(
      labelStyle: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    ),
  );
}

/// Lays a slide out against [osoCanvasSize] and scales the result to fit.
///
/// Letterbox gutters are painted with the surface colour rather than black, so
/// a window that is not 16:9 reads as margin instead of a broken slide.
class OsoCanvas extends StatelessWidget {
  const OsoCanvas({
    required this.child,
    this.backgroundColor,
    this.theme,
    super.key,
  });

  final Widget child;

  /// Colour of the letterbox gutters. Defaults to the scheme surface; a
  /// full-bleed slide passes its own so the gutters do not frame it in white.
  final Color? backgroundColor;

  /// Defaults to [osoTheme]. The book's ending slides pass [osoEndingTheme].
  final ThemeData? theme;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: theme ?? osoTheme,
      child: ColoredBox(
        color: backgroundColor ?? osoColorScheme.surface,
        child: Center(
          child: FittedBox(
            child: SizedBox.fromSize(size: osoCanvasSize, child: child),
          ),
        ),
      ),
    );
  }
}

/// Soft forest shapes behind a slide body.
///
/// The presentation half of the deck follows a picture book, and bare white
/// slides fall off a cliff after it. These shapes stay pale enough to leave
/// body text at full contrast while keeping the woodland mood.
class OsoBackdrop extends StatelessWidget {
  const OsoBackdrop({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: _OsoBackdropPainter(Theme.of(context).colorScheme),
          ),
        ),
        child,
      ],
    );
  }
}

class _OsoBackdropPainter extends CustomPainter {
  const _OsoBackdropPainter(this.colors);

  final ColorScheme colors;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    canvas
      ..drawCircle(
        Offset(w * 0.94, -h * 0.16),
        h * 0.52,
        Paint()..color = colors.primaryContainer.withValues(alpha: 0.42),
      )
      ..drawCircle(
        Offset(-w * 0.04, h * 1.08),
        h * 0.44,
        Paint()..color = colors.tertiaryContainer.withValues(alpha: 0.55),
      );

    final leafPaint = Paint()..color = colors.primary.withValues(alpha: 0.07);
    _drawLeaf(canvas, Offset(w * 0.86, h * 0.15), h * 0.26, -0.5, leafPaint);
    _drawLeaf(canvas, Offset(w * 0.96, h * 0.34), h * 0.18, 0.35, leafPaint);
    _drawLeaf(canvas, Offset(w * 0.05, h * 0.88), h * 0.20, 2.4, leafPaint);
  }

  /// Draws a leaf as two mirrored curves meeting at the tip and the stem.
  void _drawLeaf(
    Canvas canvas,
    Offset center,
    double length,
    double rotation,
    Paint paint,
  ) {
    final width = length * 0.52;
    final path = Path()
      ..moveTo(0, -length / 2)
      ..quadraticBezierTo(width, 0, 0, length / 2)
      ..quadraticBezierTo(-width, 0, 0, -length / 2)
      ..close();

    canvas
      ..save()
      ..translate(center.dx, center.dy)
      ..rotate(rotation)
      ..drawPath(path, paint)
      ..restore();
  }

  @override
  bool shouldRepaint(_OsoBackdropPainter oldDelegate) =>
      oldDelegate.colors != colors;
}

/// The shared frame for every non-storybook slide: a section label, a title,
/// an optional lead-in line, and the slide body.
class OsoMaterialSlide extends StatelessWidget {
  const OsoMaterialSlide({
    required this.eyebrow,
    required this.title,
    required this.child,
    this.subtitle,
    super.key,
  });

  final String eyebrow;
  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return OsoCanvas(
      child: Builder(
        builder: (context) {
          final theme = Theme.of(context);
          final colors = theme.colorScheme;

          return OsoBackdrop(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(88, 68, 88, 60),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _EyebrowPill(label: eyebrow),
                      const Spacer(),
                      Icon(
                        Icons.auto_stories_outlined,
                        size: 30,
                        color: colors.outline,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'リスくんと ひとつのどんぐり',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: colors.outline,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 26),
                  Text(
                    title,
                    style: theme.textTheme.displaySmall?.copyWith(
                      color: colors.onSurface,
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                      letterSpacing: -1,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 14),
                    Text(
                      subtitle!,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                  ],
                  const SizedBox(height: 40),
                  Expanded(child: child),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _EyebrowPill extends StatelessWidget {
  const _EyebrowPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 26, 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.eco_rounded, size: 30, color: colors.onPrimaryContainer),
            const SizedBox(width: 12),
            Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: colors.onPrimaryContainer,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

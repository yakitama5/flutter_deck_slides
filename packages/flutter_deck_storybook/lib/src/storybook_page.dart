import 'package:flutter/material.dart';

import 'storybook_reveal.dart';

/// Overrides the area surrounding a [StorybookPage] while it is part of a
/// larger book scene.
///
/// Normal pages keep their configured [StorybookPage.coverColor]. Boundary
/// transitions use a transparent outer color so the persistent tabletop below
/// the page remains visible while a cover or paper bundle moves above it.
class StorybookPageBackgroundScope extends InheritedWidget {
  const StorybookPageBackgroundScope({
    required this.outerColor,
    required super.child,
    super.key,
  });

  final Color outerColor;

  static StorybookPageBackgroundScope? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<StorybookPageBackgroundScope>();
  }

  @override
  bool updateShouldNotify(StorybookPageBackgroundScope oldWidget) {
    return outerColor != oldWidget.outerColor;
  }
}

/// A paper-like page surface for storybook-style slide decks.
class StorybookPage extends StatelessWidget {
  /// Creates a storybook page.
  const StorybookPage({
    required this.child,
    this.pageNumber,
    this.totalPages,
    this.paperColor = const Color(0xFFFFFCF3),
    this.coverColor = const Color(0xFF3E302A),
    this.accentColor = const Color(0xFF9B5D3D),
    this.inkColor = const Color(0xFF302620),
    this.outerPadding = const EdgeInsets.all(28),
    this.contentPadding = const EdgeInsets.fromLTRB(72, 56, 72, 64),
    this.designSize = const Size(1200, 675),
    this.borderRadius = 24,
    this.showPageNumber = true,
    super.key,
  }) : assert(pageNumber == null || pageNumber > 0),
       assert(totalPages == null || totalPages > 0),
       assert(
         pageNumber == null || totalPages == null || pageNumber <= totalPages,
       ),
       assert(borderRadius >= 0);

  /// The content displayed on the page.
  final Widget child;

  /// The current one-based page number.
  final int? pageNumber;

  /// The total number of pages.
  final int? totalPages;

  /// The page's paper color.
  final Color paperColor;

  /// The color visible around the paper page.
  final Color coverColor;

  /// The color used for the spine and page number.
  final Color accentColor;

  /// The default foreground color inherited by [child].
  final Color inkColor;

  /// Space between the slide edge and the paper page.
  final EdgeInsetsGeometry outerPadding;

  /// Space around [child] inside the paper page.
  final EdgeInsetsGeometry contentPadding;

  /// The logical canvas used for [child] before it is scaled to fit the page.
  final Size designSize;

  /// Corner radius of the paper page.
  final double borderRadius;

  /// Whether to display [pageNumber] at the bottom of the page.
  final bool showPageNumber;

  String? get _pageLabel {
    final current = pageNumber;
    if (current == null) return null;

    final total = totalPages;
    return total == null ? '$current' : '$current / $total';
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);
    final pageLabel = _pageLabel;
    final reveal = StorybookRevealScope.maybeOf(context);
    final backgroundColor =
        StorybookPageBackgroundScope.maybeOf(context)?.outerColor ?? coverColor;

    return ColoredBox(
      color: backgroundColor,
      child: Padding(
        padding: outerPadding,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: radius,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.28),
                blurRadius: 30,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: radius,
            child: Stack(
              fit: StackFit.expand,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: paperColor,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        paperColor,
                        Color.lerp(paperColor, accentColor, 0.035)!,
                      ],
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: 16,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withValues(alpha: 0.16),
                          accentColor.withValues(alpha: 0.10),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                StorybookInkReveal(
                  key: const ValueKey('storybook-ink-reveal'),
                  sketchProgress: reveal?.sketchProgress ?? 1,
                  paintProgress: reveal?.paintProgress ?? 1,
                  revealOrigin:
                      reveal?.revealOrigin ?? const Alignment(0, 0.25),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Padding(
                        padding: contentPadding,
                        child: FittedBox(
                          fit: BoxFit.contain,
                          child: SizedBox.fromSize(
                            size: designSize,
                            child: DefaultTextStyle.merge(
                              style: TextStyle(color: inkColor),
                              child: IconTheme.merge(
                                data: IconThemeData(color: accentColor),
                                child: child,
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (showPageNumber && pageLabel != null)
                        Positioned(
                          right: 36,
                          bottom: 24,
                          child: Semantics(
                            label: 'ページ $pageLabel',
                            child: ExcludeSemantics(
                              child: Text(
                                pageLabel,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      color: accentColor.withValues(
                                        alpha: 0.78,
                                      ),
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

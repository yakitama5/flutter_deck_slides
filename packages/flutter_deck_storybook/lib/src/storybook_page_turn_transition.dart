import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_deck/flutter_deck.dart';

import 'storybook_book_cover.dart';
import 'storybook_book_cover_transition.dart';
import 'storybook_page_curl.dart';
import 'storybook_page.dart';
import 'storybook_reveal.dart';
import 'storybook_sound_effects.dart';

enum _PageTurnDirection { forward, backward }

enum _BookBoundaryTransition { opening, closing }

/// Converts the one boundary timeline into the paper handoff phase.
///
/// The rigid cover owns the first beat of the shot. The paper bundle and the
/// destination page then use this same continuous phase after the cover has
/// passed its edge-on position; keeping the mapping here prevents a full-page
/// white rectangle from appearing underneath the cover before the handoff.
double _bookBoundaryPaperProgress(double progress) {
  final normalized = progress.clamp(0.0, 1.0);
  final handoff = ((normalized - 0.52) / 0.48).clamp(0.0, 1.0);
  return Curves.easeInOutCubic.transform(handoff);
}

/// A page-turn transition for [FlutterDeckApp].
///
/// Reuse a single instance as the deck's global transition. The instance keeps
/// track of the current slide number so that forward navigation turns the
/// current sheet away while previous navigation covers it with the prior sheet.
class StorybookPageTurnTransitionBuilder extends FlutterDeckTransitionBuilder {
  /// Page-turn duration measured from the supplied reference video.
  static const referenceTurnDuration = Duration(milliseconds: 1700);

  /// Creates a storybook page-turn transition builder.
  StorybookPageTurnTransitionBuilder({
    this.perspective = 0.00008,
    this.maxRotation = math.pi,
    this.pageFlex = 0.56,
    this.pageTwist = 0.035,
    this.meshColumns = 40,
    this.meshRows = 16,
    this.turnSoundCueProgress = 0.42,
    this.reverseOnPrevious = true,
    this.usePerspective = true,
    this.enableInkReveal = true,
    this.inkRevealDuration = const Duration(milliseconds: 2750),
    this.inkRevealOrigin = const Alignment(0, 0.25),
    this.enableBookOpening = false,
    this.enableBookClosing = false,
    this.openingTargetSlideNumber = 2,
    this.closingTargetSlideNumber,
    this.bookPageCount = 5,
    this.soundEffects,
  }) : assert(perspective > 0),
       assert(maxRotation > 0 && maxRotation <= math.pi),
       assert(pageFlex >= 0 && pageFlex <= math.pi / 2),
       assert(pageTwist >= 0 && pageTwist <= math.pi / 3),
       assert(meshColumns >= 8 && meshColumns <= 64),
       assert(meshRows >= 2 && meshRows <= 24),
       assert(turnSoundCueProgress >= 0 && turnSoundCueProgress <= 1),
       assert(inkRevealDuration > Duration.zero),
       assert(openingTargetSlideNumber >= 2),
       assert(closingTargetSlideNumber == null || closingTargetSlideNumber > 1),
       assert(bookPageCount >= 2 && bookPageCount <= 8);

  /// Perspective applied to the page transform.
  final double perspective;

  /// Maximum Y-axis rotation in radians.
  ///
  /// Values above 90 degrees expose the separately painted white paper back.
  final double maxRotation;

  /// Strength of the horizontal grip ridge and bend while the paper turns.
  final double pageFlex;

  /// Phase-changing twist between the top and bottom edges.
  final double pageTwist;

  /// Horizontal subdivisions used by the paper mesh.
  final int meshColumns;

  /// Vertical subdivisions used by the paper mesh.
  final int meshRows;

  /// Raw route progress at which the paper-turn sound starts.
  ///
  /// The sheet spends the opening beat shifting into a horizontal grip ridge,
  /// so playing the sound at route progress zero makes it audibly lead the
  /// paper. The default starts it just as that ridge becomes visible.
  final double turnSoundCueProgress;

  /// Whether previous navigation should cover the current page with the
  /// previous sheet instead of using the forward turn animation.
  final bool reverseOnPrevious;

  /// Whether to use the perspective-based 3D transition.
  ///
  /// The full slide is treated as one sheet and rotates around a vertical edge.
  /// This is enabled by default on every platform, including web. Pass `false`
  /// to use a slide-and-crossfade fallback on a problematic renderer.
  final bool usePerspective;

  /// Whether a blank page should develop from pencil lines into full color.
  ///
  /// The reveal starts after the incoming page has finished turning. It only
  /// affects [StorybookPage] content; the paper surface remains visible.
  final bool enableInkReveal;

  /// Duration of the blank-paper, pencil, and watercolor reveal sequence.
  ///
  /// The default timing follows the supplied Bayonetta Origins reference:
  /// roughly 300 ms of blank paper, 900 ms of underdrawing, and 1.7 seconds of
  /// overlapping watercolor bloom.
  final Duration inkRevealDuration;

  /// Point from which the watercolor bloom spreads across the page.
  final Alignment inkRevealOrigin;

  /// Whether the first transition from a front cover should open a book.
  ///
  /// The cover is expected to be slide 1 and the first real page to be slide 2
  /// (or [openingTargetSlideNumber]). It is disabled by default so existing
  /// decks that do not add boundary-cover slides keep their current behavior.
  final bool enableBookOpening;

  /// Whether the transition into the final cover should close the book.
  ///
  /// The final cover is the last slide unless [closingTargetSlideNumber] is
  /// supplied explicitly.
  final bool enableBookClosing;

  /// Slide number at which the opening animation ends.
  final int openingTargetSlideNumber;

  /// Optional slide number at which the closing animation ends.
  ///
  /// When null, the last slide in the current router is used.
  final int? closingTargetSlideNumber;

  /// Number of staggered paper sheets used by the book boundary animations.
  final int bookPageCount;

  /// Optional page-turn and drawing audio cues.
  ///
  /// Pass [StorybookSoundEffects] to use the bundled sounds. Leaving this null
  /// keeps the deck silent. Audio is also skipped when reduced motion is on.
  final StorybookSoundEffectPlayer? soundEffects;

  int? _lastSlideNumber;
  _PageTurnDirection _direction = _PageTurnDirection.forward;
  Widget? _settledChild;

  @override
  Widget build(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final deckProvider =
        (reverseOnPrevious || enableBookOpening || enableBookClosing)
        ? context.dependOnInheritedWidgetOfExactType<FlutterDeckProvider>()
        : null;
    final slideNumber = deckProvider?.flutterDeck.slideNumber;
    final slideCount = deckProvider?.flutterDeck.router.slides.length;

    if (deckProvider != null && slideNumber != null) {
      _updateDirection(slideNumber);
    }

    final boundary = _boundaryTransition(
      slideNumber: slideNumber,
      slideCount: slideCount,
    );
    final boundaryBackCover = boundary == null
        ? false
        : _boundaryUsesBackCover(boundary);

    final boundaryOutgoingChild = _settledChild;
    if (animation.status == AnimationStatus.completed &&
        secondaryAnimation.status == AnimationStatus.dismissed &&
        boundary != _BookBoundaryTransition.opening) {
      _settledChild = child;
    }

    if (!usePerspective &&
        !(MediaQuery.maybeOf(context)?.disableAnimations ?? false)) {
      return _StorybookPlanarPageTurnTransition(
        animation: animation,
        secondaryAnimation: secondaryAnimation,
        direction: _direction,
        child: _StorybookInkSequence(
          animation: animation,
          secondaryAnimation: secondaryAnimation,
          enabled:
              enableInkReveal &&
              _direction == _PageTurnDirection.forward &&
              boundary != _BookBoundaryTransition.closing,
          duration: inkRevealDuration,
          revealOrigin: inkRevealOrigin,
          turnSoundCueProgress: turnSoundCueProgress,
          soundEffects: soundEffects,
          child: child,
        ),
      );
    }

    return _StorybookPageTurnTransition(
      animation: animation,
      secondaryAnimation: secondaryAnimation,
      direction: _direction,
      perspective: perspective,
      maxRotation: maxRotation,
      pageFlex: pageFlex,
      pageTwist: pageTwist,
      meshColumns: meshColumns,
      meshRows: meshRows,
      enableInkReveal: enableInkReveal,
      inkRevealDuration: inkRevealDuration,
      inkRevealOrigin: inkRevealOrigin,
      boundary: boundary,
      boundaryBackCover: boundaryBackCover,
      boundaryOutgoingChild: boundaryOutgoingChild,
      bookPageCount: bookPageCount,
      turnSoundCueProgress: turnSoundCueProgress,
      soundEffects: soundEffects,
      child: child,
    );
  }

  void _updateDirection(int targetSlideNumber) {
    final previousSlideNumber = _lastSlideNumber;

    if (previousSlideNumber != null &&
        previousSlideNumber != targetSlideNumber) {
      _direction = targetSlideNumber > previousSlideNumber
          ? _PageTurnDirection.forward
          : _PageTurnDirection.backward;
    }

    _lastSlideNumber = targetSlideNumber;
  }

  _BookBoundaryTransition? _boundaryTransition({
    required int? slideNumber,
    required int? slideCount,
  }) {
    if (slideNumber == null) {
      return null;
    }

    final closingSlideNumber = closingTargetSlideNumber ?? slideCount;
    if (_direction == _PageTurnDirection.forward) {
      if (enableBookOpening && slideNumber == openingTargetSlideNumber) {
        return _BookBoundaryTransition.opening;
      }

      if (enableBookClosing &&
          closingSlideNumber != null &&
          slideNumber == closingSlideNumber) {
        return _BookBoundaryTransition.closing;
      }
    } else {
      if (enableBookOpening && slideNumber == openingTargetSlideNumber - 1) {
        return _BookBoundaryTransition.closing;
      }

      if (enableBookClosing &&
          closingSlideNumber != null &&
          slideNumber == closingSlideNumber - 1) {
        return _BookBoundaryTransition.opening;
      }
    }

    return null;
  }

  bool _boundaryUsesBackCover(_BookBoundaryTransition boundary) {
    return boundary == _BookBoundaryTransition.opening
        ? _direction == _PageTurnDirection.backward
        : _direction == _PageTurnDirection.forward;
  }
}

class _StorybookPlanarPageTurnTransition extends StatelessWidget {
  const _StorybookPlanarPageTurnTransition({
    required this.animation,
    required this.secondaryAnimation,
    required this.direction,
    required this.child,
  });

  final Animation<double> animation;
  final Animation<double> secondaryAnimation;
  final _PageTurnDirection direction;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final directionSign = direction == _PageTurnDirection.forward ? 1.0 : -1.0;
    final incomingPosition = animation.drive(
      Tween<Offset>(
        begin: Offset(directionSign * 0.12, 0),
        end: Offset.zero,
      ).chain(CurveTween(curve: Curves.easeOutCubic)),
    );
    final outgoingPosition = secondaryAnimation.drive(
      Tween<Offset>(
        begin: Offset.zero,
        end: Offset(-directionSign * 0.08, 0),
      ).chain(CurveTween(curve: Curves.easeInCubic)),
    );
    final incomingOpacity = animation.drive(CurveTween(curve: Curves.easeOut));
    final outgoingOpacity = ReverseAnimation(secondaryAnimation)
        .drive(CurveTween(curve: Curves.easeIn));

    return FadeTransition(
      key: const ValueKey('storybook-page-turn-planar'),
      opacity: outgoingOpacity,
      child: SlideTransition(
        position: outgoingPosition,
        child: FadeTransition(
          opacity: incomingOpacity,
          child: SlideTransition(position: incomingPosition, child: child),
        ),
      ),
    );
  }
}

class _StorybookPageTurnTransition extends StatelessWidget {
  const _StorybookPageTurnTransition({
    required this.animation,
    required this.secondaryAnimation,
    required this.direction,
    required this.perspective,
    required this.maxRotation,
    required this.pageFlex,
    required this.pageTwist,
    required this.meshColumns,
    required this.meshRows,
    required this.enableInkReveal,
    required this.inkRevealDuration,
    required this.inkRevealOrigin,
    required this.boundary,
    required this.boundaryBackCover,
    required this.boundaryOutgoingChild,
    required this.bookPageCount,
    required this.turnSoundCueProgress,
    required this.soundEffects,
    required this.child,
  });

  final Animation<double> animation;
  final Animation<double> secondaryAnimation;
  final _PageTurnDirection direction;
  final double perspective;
  final double maxRotation;
  final double pageFlex;
  final double pageTwist;
  final int meshColumns;
  final int meshRows;
  final bool enableInkReveal;
  final Duration inkRevealDuration;
  final Alignment inkRevealOrigin;
  final _BookBoundaryTransition? boundary;
  final bool boundaryBackCover;
  final Widget? boundaryOutgoingChild;
  final int bookPageCount;
  final double turnSoundCueProgress;
  final StorybookSoundEffectPlayer? soundEffects;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
      return FadeTransition(
        key: const ValueKey('storybook-page-turn-fade'),
        opacity: animation.drive(CurveTween(curve: Curves.easeOut)),
        child: child,
      );
    }

    return AnimatedBuilder(
      animation: Listenable.merge([animation, secondaryAnimation]),
      child: _StorybookInkSequence(
        animation: animation,
        secondaryAnimation: secondaryAnimation,
        enabled:
            enableInkReveal &&
            direction == _PageTurnDirection.forward &&
            boundary != _BookBoundaryTransition.closing,
        duration: inkRevealDuration,
        revealOrigin: inkRevealOrigin,
        turnSoundCueProgress: turnSoundCueProgress,
        soundEffects: soundEffects,
        child: child,
      ),
      builder: (context, page) {
        final rawIncoming = animation.value.clamp(0.0, 1.0);
        final rawOutgoing = secondaryAnimation.value.clamp(0.0, 1.0);

        if (boundary case final boundaryTransition?) {
          return _buildBookBoundaryTransition(
            context: context,
            boundary: boundaryTransition,
            page: page!,
            incoming: rawIncoming,
            outgoing: rawOutgoing,
          );
        }

        if (direction == _PageTurnDirection.forward) {
          // The reference spends most of the first half shifting and raising
          // a horizontal grip ridge. The broad turn accelerates only after the
          // ridge is readable, producing the late hand-driven page flick.
          final incoming = Curves.easeInCubic.transform(rawIncoming);
          final outgoing = Curves.easeInCubic.transform(rawOutgoing);
          return _buildForwardTurn(
            page: page!,
            incoming: incoming,
            outgoing: outgoing,
          );
        }

        // A previous page is not the forward peel played backwards. It arrives
        // above the current page, crosses it, then decelerates as it settles.
        final incoming = Curves.easeInOutCubic.transform(rawIncoming);
        final outgoing = Curves.easeInOutCubic.transform(rawOutgoing);
        return _buildBackwardCover(
          page: page!,
          incoming: incoming,
          outgoing: outgoing,
        );
      },
    );
  }

  Widget _buildBookBoundaryTransition({
    required BuildContext context,
    required _BookBoundaryTransition boundary,
    required Widget page,
    required double incoming,
    required double outgoing,
  }) {
    final isBoundaryOutgoingRoute = ModalRoute.of(context)?.isCurrent == false;
    final boundaryPage = _StorybookBookBoundaryPageScene(
      key: const ValueKey('storybook-book-boundary-page-scene'),
      motion: boundary == _BookBoundaryTransition.opening
          ? StorybookBookCoverMotion.opening
          : StorybookBookCoverMotion.closing,
      backCover: boundaryBackCover,
      progress: incoming,
      child: StorybookPageBackgroundScope(
        outerColor: Colors.transparent,
        child: _StorybookBoundarySlide(child: page),
      ),
    );
    final boundaryPaperProgress = _bookBoundaryPaperProgress(incoming);
    final turnsOutWithPrimary =
        animation.status == AnimationStatus.reverse && animation.value < 1;
    final turnsOutWithSecondary =
        secondaryAnimation.status == AnimationStatus.forward &&
        secondaryAnimation.value > 0;
    final isTurningOut = turnsOutWithPrimary || turnsOutWithSecondary;
    switch (boundary) {
      case _BookBoundaryTransition.opening:
        if (isBoundaryOutgoingRoute || isTurningOut) {
          if (boundaryOutgoingChild != null) {
            // The incoming route owns the visible boundary scene. Keeping the
            // outgoing route empty prevents its Scaffold background from
            // competing with the table and rigid cover above it.
            return const SizedBox.expand();
          }
          return _StorybookBookOpeningSheets(
            progress: outgoing,
            pageCount: bookPageCount,
            backCover: boundaryBackCover,
            perspective: perspective,
            maxRotation: maxRotation,
            flex: pageFlex,
            twist: pageTwist,
            columns: meshColumns,
            rows: meshRows,
            child: page,
          );
        }

        if (boundaryOutgoingChild != null) {
          return Stack(
            fit: StackFit.expand,
            children: [
              _StorybookBookOpeningSheets(
                progress: incoming,
                pageCount: bookPageCount,
                backCover: boundaryBackCover,
                perspective: perspective,
                maxRotation: maxRotation,
                flex: pageFlex,
                twist: pageTwist,
                columns: meshColumns,
                rows: meshRows,
                includeTabletop: true,
                child: boundaryOutgoingChild!,
              ),
              StorybookCurlReveal(
                clipKey: const ValueKey('storybook-book-opening-reveal'),
                progress: boundaryPaperProgress,
                direction: boundaryBackCover
                    ? StorybookPageCurlDirection.backward
                    : StorybookPageCurlDirection.forward,
                motion: StorybookPageCurlMotion.turnAway,
                perspective: perspective,
                maxRotation: maxRotation,
                flex: pageFlex,
                twist: pageTwist,
                columns: meshColumns,
                rows: meshRows,
                shadowFactor: 0,
                // The reveal starts on the same delayed paper phase as the
                // blank sheets below the rigid cover. There is no child swap:
                // the clip grows continuously from an empty silhouette.
                child: boundaryPage,
              ),
            ],
          );
        }

        return Stack(
          fit: StackFit.expand,
          children: [
            const Positioned.fill(
              child: StorybookBookTabletop(
                key: ValueKey('storybook-book-opening-scene-tabletop'),
              ),
            ),
            StorybookCurlReveal(
              clipKey: const ValueKey('storybook-book-opening-reveal'),
              progress: boundaryPaperProgress,
              direction: StorybookPageCurlDirection.forward,
              motion: StorybookPageCurlMotion.turnAway,
              perspective: perspective,
              maxRotation: maxRotation,
              flex: pageFlex,
              twist: pageTwist,
              columns: meshColumns,
              rows: meshRows,
              shadowFactor: 0,
              // Keep the route-owned outer background transparent even when
              // the outgoing route has not produced a settled child yet. The
              // tabletop must remain visible through the reveal silhouette;
              // otherwise the route's dark cover color appears as a black
              // border during the first opening frames.
              child: boundaryPage,
            ),
          ],
        );
      case _BookBoundaryTransition.closing:
        if (isBoundaryOutgoingRoute) {
          // The outgoing route owns the opaque scene during closing. Keep the
          // real page above the paper bed so the bed cannot white-out the page
          // before the first sheet has moved. The incoming route is painted
          // above this stack and contributes only the sheet silhouettes and
          // rigid cover; remounting the page there would reuse FlutterDeck's
          // framework-owned GlobalKeys.
          return Stack(
            fit: StackFit.expand,
            children: [
              const Positioned.fill(
                child: StorybookBookTabletop(
                  key: ValueKey('storybook-book-closing-underlay-tabletop'),
                ),
              ),
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _StorybookBookSheetsScene(
                    key: const ValueKey(
                      'storybook-book-closing-underlay-paper-scene',
                    ),
                    motion: StorybookBookCoverMotion.closing,
                    backCover: boundaryBackCover,
                    progress: outgoing,
                    child: const _StorybookBookPaperBed(
                      key: ValueKey('storybook-book-closing-paper-bed'),
                    ),
                  ),
                ),
              ),
              _StorybookBookBoundaryPageScene(
                key: const ValueKey('storybook-book-closing-underlay-page'),
                motion: StorybookBookCoverMotion.closing,
                backCover: boundaryBackCover,
                progress: outgoing,
                child: StorybookPageBackgroundScope(
                  outerColor: Colors.transparent,
                  child: _StorybookBoundarySlide(child: page),
                ),
              ),
            ],
          );
        }

        return Stack(
          fit: StackFit.expand,
          children: [
            // The outgoing route below owns the tabletop, paper bed, and real
            // page. Keeping this route transparent outside the moving sheets
            // and cover lets that page remain visible until it is physically
            // covered. Reintroduce the opaque scene only at the terminal frame
            // after the outgoing route has been removed.
            if (incoming >= 1)
              const Positioned.fill(
                child: StorybookBookTabletop(
                  key: ValueKey('storybook-book-closing-scene-tabletop'),
                ),
              ),
            if (incoming >= 1)
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _StorybookBookSheetsScene(
                    key: const ValueKey(
                      'storybook-book-closing-paper-bed-scene',
                    ),
                    motion: StorybookBookCoverMotion.closing,
                    backCover: boundaryBackCover,
                    progress: incoming,
                    child: const _StorybookBookPaperBed(
                      key: ValueKey('storybook-book-closing-paper-bed'),
                    ),
                  ),
                ),
              ),
            _StorybookBookClosingSheets(
              progress: incoming,
              pageCount: bookPageCount,
              backCover: boundaryBackCover,
              perspective: perspective,
              maxRotation: maxRotation,
              flex: pageFlex,
              twist: pageTwist,
              columns: meshColumns,
              rows: meshRows,
              child: page,
            ),
          ],
        );
    }
  }

  Widget _buildForwardTurn({
    required Widget page,
    required double incoming,
    required double outgoing,
  }) {
    final turnsOutWithPrimary =
        animation.status == AnimationStatus.reverse && animation.value < 1;
    final turnsOutWithSecondary =
        secondaryAnimation.status == AnimationStatus.forward &&
        secondaryAnimation.value > 0;
    final isTurningOut = turnsOutWithPrimary || turnsOutWithSecondary;

    if (!isTurningOut) {
      // The next route is flat below the old sheet. Reveal only the area that
      // the old sheet has physically uncovered.
      final revealProgress =
          secondaryAnimation.status == AnimationStatus.reverse
          ? 1 - outgoing
          : incoming;

      return StorybookCurlReveal(
        clipKey: const ValueKey('storybook-page-turn-incoming-reveal'),
        progress: revealProgress,
        direction: StorybookPageCurlDirection.forward,
        motion: StorybookPageCurlMotion.turnAway,
        perspective: perspective,
        maxRotation: maxRotation,
        flex: pageFlex,
        twist: pageTwist,
        columns: meshColumns,
        rows: meshRows,
        child: page,
      );
    }

    final turnProgress = turnsOutWithPrimary ? 1 - incoming : outgoing;
    return StorybookCurlSheet(
      key: const ValueKey('storybook-page-turn-outgoing-sheet'),
      progress: turnProgress,
      direction: StorybookPageCurlDirection.forward,
      motion: StorybookPageCurlMotion.turnAway,
      perspective: perspective,
      maxRotation: maxRotation,
      flex: pageFlex,
      twist: pageTwist,
      columns: meshColumns,
      rows: meshRows,
      child: page,
    );
  }

  Widget _buildBackwardCover({
    required Widget page,
    required double incoming,
    required double outgoing,
  }) {
    // FlutterDeck changes slides with GoRouter.go, so both route animations
    // move forward even when the logical slide number decreases. The new
    // previous page is therefore identified by its primary animation and
    // drawn as a sheet travelling from edge-on to flat. The physical binding
    // remains at the left edge: the previous sheet unfolds from that binding
    // and covers the current page towards the right. GoRouter keeps the
    // outgoing route painted above it, so that route is clipped by the same
    // silhouette below to make the incoming sheet visually cover it.
    final isReplacementCover =
        animation.status != AnimationStatus.reverse &&
        animation.value < 1 &&
        secondaryAnimation.status == AnimationStatus.dismissed;
    final isReplacementUnderlay =
        animation.status == AnimationStatus.completed &&
        secondaryAnimation.status == AnimationStatus.forward;

    if (isReplacementCover) {
      return StorybookCurlSheet(
        key: const ValueKey('storybook-page-cover-incoming-sheet'),
        progress: 1 - incoming,
        direction: StorybookPageCurlDirection.forward,
        motion: StorybookPageCurlMotion.coverPrevious,
        perspective: perspective,
        maxRotation: maxRotation,
        flex: pageFlex,
        twist: pageTwist,
        columns: meshColumns,
        rows: meshRows,
        child: page,
      );
    }

    if (isReplacementUnderlay) {
      return StorybookCurlReveal(
        clipKey: const ValueKey('storybook-page-cover-current-page'),
        progress: 1 - outgoing,
        direction: StorybookPageCurlDirection.forward,
        motion: StorybookPageCurlMotion.coverPrevious,
        perspective: perspective,
        maxRotation: maxRotation,
        flex: pageFlex,
        twist: pageTwist,
        columns: meshColumns,
        rows: meshRows,
        child: page,
      );
    }

    // Also support a real Navigator.pop. In that lifecycle, the previous route
    // is painted below the current route, so the current route must be clipped
    // out along the exact silhouette of the covering sheet.
    final isPoppedCurrentPage =
        animation.status == AnimationStatus.reverse && animation.value < 1;
    final isPoppedPreviousPage =
        secondaryAnimation.status == AnimationStatus.reverse &&
        secondaryAnimation.value > 0;

    if (isPoppedPreviousPage) {
      return StorybookCurlSheet(
        key: const ValueKey('storybook-page-cover-incoming-sheet'),
        progress: outgoing,
        direction: StorybookPageCurlDirection.forward,
        motion: StorybookPageCurlMotion.coverPrevious,
        perspective: perspective,
        maxRotation: maxRotation,
        flex: pageFlex,
        twist: pageTwist,
        columns: meshColumns,
        rows: meshRows,
        child: page,
      );
    }

    if (isPoppedCurrentPage) {
      return StorybookCurlReveal(
        clipKey: const ValueKey('storybook-page-cover-current-page'),
        progress: incoming,
        direction: StorybookPageCurlDirection.forward,
        motion: StorybookPageCurlMotion.coverPrevious,
        perspective: perspective,
        maxRotation: maxRotation,
        flex: pageFlex,
        twist: pageTwist,
        columns: meshColumns,
        rows: meshRows,
        child: page,
      );
    }

    return page;
  }
}

class _StorybookBookOpeningSheets extends StatelessWidget {
  const _StorybookBookOpeningSheets({
    required this.progress,
    required this.pageCount,
    required this.backCover,
    required this.perspective,
    required this.maxRotation,
    required this.flex,
    required this.twist,
    required this.columns,
    required this.rows,
    required this.child,
    this.includeTabletop = true,
  });

  final double progress;
  final int pageCount;
  final bool backCover;
  final double perspective;
  final double maxRotation;
  final double flex;
  final double twist;
  final int columns;
  final int rows;
  final Widget child;
  final bool includeTabletop;

  @override
  Widget build(BuildContext context) {
    final openingProgress = _bookBoundaryPaperProgress(progress);
    final pageDirection = backCover
        ? StorybookPageCurlDirection.backward
        : StorybookPageCurlDirection.forward;

    return Stack(
      fit: StackFit.expand,
      children: [
        if (includeTabletop)
          Positioned.fill(
            child: StorybookBookTabletop(
              key: ValueKey('storybook-book-opening-tabletop'),
            ),
          ),
        Positioned.fill(
          child: _StorybookBookSheetsScene(
            key: const ValueKey('storybook-book-opening-paper-bed-scene'),
            motion: StorybookBookCoverMotion.opening,
            backCover: backCover,
            progress: progress,
            child: const _StorybookBookPaperBed(),
          ),
        ),
        Positioned.fill(
          child: StorybookCurlReveal(
            clipKey: const ValueKey('storybook-book-opening-paper-reveal'),
            progress: openingProgress,
            direction: pageDirection,
            motion: StorybookPageCurlMotion.turnAway,
            perspective: perspective,
            maxRotation: maxRotation,
            flex: flex,
            twist: twist,
            columns: columns,
            rows: rows,
            shadowFactor: 0,
            child: _StorybookBookSheetsScene(
              key: const ValueKey('storybook-book-opening-paper-scene'),
              motion: StorybookBookCoverMotion.opening,
              backCover: backCover,
              progress: progress,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  for (var index = 0; index < pageCount; index++)
                    StorybookCurlSheet(
                      key: ValueKey('storybook-book-opening-sheet-$index'),
                      progress: _staggeredProgress(openingProgress, index),
                      direction: pageDirection,
                      motion: StorybookPageCurlMotion.turnAway,
                      perspective: perspective,
                      maxRotation: maxRotation,
                      flex: flex,
                      twist: twist,
                      columns: columns,
                      rows: rows,
                      paperOnly: true,
                      child: const _StorybookBookPaperLeaf(),
                    ),
                ],
              ),
            ),
          ),
        ),
        if (progress < 1)
          StorybookBookCoverTransitionScope(
            key: const ValueKey('storybook-book-opening-cover'),
            motion: StorybookBookCoverMotion.opening,
            progress: progress,
            // The opening scene owns its tabletop as a sibling below the bed;
            // letting StorybookBookCover paint a full-screen tabletop here
            // would hide the paper bed as soon as the rigid board turns
            // edge-on.
            includeTabletop: false,
            child: _StorybookBoundarySlide(child: child),
          ),
      ],
    );
  }

  double _staggeredProgress(double value, int index) {
    final delay = 0.055 * (index + 1);
    final localProgress = ((value - delay) / (1 - delay)).clamp(0.0, 1.0);
    return Curves.easeInCubic.transform(localProgress);
  }
}

class _StorybookBookClosingSheets extends StatelessWidget {
  const _StorybookBookClosingSheets({
    required this.progress,
    required this.pageCount,
    required this.backCover,
    required this.perspective,
    required this.maxRotation,
    required this.flex,
    required this.twist,
    required this.columns,
    required this.rows,
    required this.child,
  });

  final double progress;
  final int pageCount;
  final bool backCover;
  final double perspective;
  final double maxRotation;
  final double flex;
  final double twist;
  final int columns;
  final int rows;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final closingProgress = Curves.easeOutCubic.transform(progress);
    final pageDirection = backCover
        ? StorybookPageCurlDirection.backward
        : StorybookPageCurlDirection.forward;

    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _StorybookBookSheetsScene(
              key: const ValueKey('storybook-book-closing-paper-scene'),
              motion: StorybookBookCoverMotion.closing,
              backCover: backCover,
              progress: progress,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  for (var index = 0; index < pageCount; index++)
                    StorybookCurlSheet(
                      key: ValueKey('storybook-book-closing-sheet-$index'),
                      progress: _staggeredProgress(closingProgress, index),
                      direction: pageDirection,
                      motion: StorybookPageCurlMotion.coverPrevious,
                      perspective: perspective,
                      maxRotation: maxRotation,
                      flex: flex,
                      twist: twist,
                      columns: columns,
                      rows: rows,
                      paperOnly: true,
                      child: const _StorybookBookPaperLeaf(),
                    ),
                ],
              ),
            ),
          ),
        ),
        StorybookBookCoverTransitionScope(
          key: const ValueKey('storybook-book-closing-cover'),
          motion: StorybookBookCoverMotion.closing,
          progress: progress,
          includeTabletop: false,
          child: _StorybookBoundarySlide(child: child),
        ),
      ],
    );
  }

  double _staggeredProgress(double value, int index) {
    final delay = 0.055 * (pageCount - index);
    final localProgress = ((value - delay) / (1 - delay)).clamp(0.0, 1.0);
    return 1 - Curves.easeOutCubic.transform(localProgress);
  }
}

class _StorybookBookPaperLeaf extends StatelessWidget {
  const _StorybookBookPaperLeaf();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        color: Color(0xFFFFFDF8),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFEFB), Color(0xFFF4EBDD)],
        ),
      ),
    );
  }
}

/// The persistent block of paper below a boundary cover.
///
/// Curling sheets are layered above this surface, but the bed itself remains
/// in the same camera scene from the first frame. It is hidden by the opaque
/// cover at rest and closes the visual gap while the cover is edge-on.
class _StorybookBookPaperBed extends StatelessWidget {
  const _StorybookBookPaperBed({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF8),
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFEFB), Color(0xFFF0E7D8)],
        ),
        border: Border.all(
          color: const Color(0xFFB69A76).withValues(alpha: 0.28),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
    );
  }
}

/// Places the blank paper bundle in the same camera scene as the rigid cover.
/// The tabletop remains outside this transform, so it stays visible around the
/// book for the whole boundary animation.
class _StorybookBookSheetsScene extends StatelessWidget {
  const _StorybookBookSheetsScene({
    required this.motion,
    required this.backCover,
    required this.progress,
    required this.child,
    super.key,
  });

  final StorybookBookCoverMotion motion;
  final bool backCover;
  final double progress;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final values = StorybookBookCoverMotionValues.forCover(
      motion: motion,
      progress: progress,
      backCover: backCover,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final cameraOffset = Offset(
          values.cameraOffset.dx * constraints.maxWidth,
          values.cameraOffset.dy * constraints.maxHeight,
        );
        return Transform.translate(
          offset: cameraOffset,
          child: Transform.scale(
            alignment: Alignment.center,
            scale: values.cameraScale,
            child: Center(
              child: FractionallySizedBox(
                widthFactor: values.sceneWidthFactor,
                heightFactor: values.sceneHeightFactor,
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Keeps a real route page in the same camera move as the boundary artwork.
///
/// The normal FlutterDeck route is full-screen, while the cover and paper
/// bundle are intentionally smaller at rest. Scaling the incoming/outgoing
/// route here makes those two coordinate systems meet at scale 1.0 instead of
/// popping from a pulled-back book scene into an unrelated full-screen page.
class _StorybookBookBoundaryPageScene extends StatelessWidget {
  const _StorybookBookBoundaryPageScene({
    required this.motion,
    required this.backCover,
    required this.progress,
    required this.child,
    super.key,
  });

  final StorybookBookCoverMotion motion;
  final bool backCover;
  final double progress;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final values = StorybookBookCoverMotionValues.forCover(
      motion: motion,
      progress: progress,
      backCover: backCover,
    );

    // FractionalTranslation keeps the route child out of a LayoutBuilder
    // callback. The boundary route can swap a StatefulWidget while Flutter is
    // laying out the navigator; making this paint-only avoids detaching its
    // render subtree mid-layout while preserving the same normalized camera
    // position.
    return FractionalTranslation(
      key: const ValueKey('storybook-book-boundary-page-position'),
      translation: values.cameraOffset,
      child: Transform.scale(
        key: const ValueKey('storybook-book-boundary-page-scale'),
        alignment: Alignment.center,
        scale: values.cameraScale,
        child: Center(
          child: FractionallySizedBox(
            widthFactor: values.sceneWidthFactor,
            heightFactor: values.sceneHeightFactor,
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Makes the route child transparent around its book artwork.
///
/// A FlutterDeck slide normally owns a Material [Scaffold] background. At a
/// book boundary that background would sit above the neighbouring route and
/// hide the table and outgoing page through the transparent parts of the
/// cover scene. This local theme override changes only the boundary child; it
/// does not alter the deck's normal page background.
class _StorybookBoundarySlide extends StatelessWidget {
  const _StorybookBoundarySlide({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final deckTheme = FlutterDeckTheme.of(context);
    return Theme(
      data: Theme.of(context)
          .copyWith(scaffoldBackgroundColor: Colors.transparent),
      child: FlutterDeckTheme(
        data: deckTheme.copyWith(
          slideTheme: deckTheme.slideTheme.copyWith(
            backgroundColor: Colors.transparent,
          ),
        ),
        child: child,
      ),
    );
  }
}

class _StorybookInkSequence extends StatefulWidget {
  const _StorybookInkSequence({
    required this.animation,
    required this.secondaryAnimation,
    required this.enabled,
    required this.duration,
    required this.revealOrigin,
    required this.turnSoundCueProgress,
    required this.soundEffects,
    required this.child,
  });

  final Animation<double> animation;
  final Animation<double> secondaryAnimation;
  final bool enabled;
  final Duration duration;
  final Alignment revealOrigin;
  final double turnSoundCueProgress;
  final StorybookSoundEffectPlayer? soundEffects;
  final Widget child;

  @override
  State<_StorybookInkSequence> createState() => _StorybookInkSequenceState();
}

class _StorybookInkSequenceState extends State<_StorybookInkSequence>
    with SingleTickerProviderStateMixin {
  static const _drawingCueStart = 0.11;

  late final AnimationController _controller;
  var _shouldReveal = false;
  var _incomingTransitionObserved = false;
  var _turnCuePlayed = false;
  var _drawingCuePlayed = false;
  var _reverseTurnCuePlayed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
      value: 1,
    );
    _controller.addListener(_handleRevealTick);
    widget.animation.addListener(_handlePrimaryTick);
    widget.animation.addStatusListener(_handlePrimaryStatus);
    widget.secondaryAnimation.addStatusListener(_handleSecondaryStatus);
    unawaited(widget.soundEffects?.preload());
    _beginIncomingTransition();
    _maybePlayTurnCue();
  }

  @override
  void didUpdateWidget(covariant _StorybookInkSequence oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.animation != widget.animation) {
      oldWidget.animation.removeListener(_handlePrimaryTick);
      oldWidget.animation.removeStatusListener(_handlePrimaryStatus);
      widget.animation.addListener(_handlePrimaryTick);
      widget.animation.addStatusListener(_handlePrimaryStatus);
      _incomingTransitionObserved = false;
      _turnCuePlayed = false;
      _reverseTurnCuePlayed = false;
    }
    if (oldWidget.secondaryAnimation != widget.secondaryAnimation) {
      oldWidget.secondaryAnimation.removeStatusListener(_handleSecondaryStatus);
      widget.secondaryAnimation.addStatusListener(_handleSecondaryStatus);
    }
    if (oldWidget.duration != widget.duration) {
      _controller.duration = widget.duration;
    }
    if (oldWidget.enabled != widget.enabled && !widget.enabled) {
      _shouldReveal = false;
      _controller.value = 1;
      unawaited(widget.soundEffects?.stopDrawing());
    } else if (oldWidget.enabled != widget.enabled) {
      _incomingTransitionObserved = false;
    }
    if (oldWidget.soundEffects != widget.soundEffects) {
      unawaited(oldWidget.soundEffects?.stopDrawing());
      unawaited(widget.soundEffects?.preload());
    }

    _beginIncomingTransition();
  }

  void _handlePrimaryTick() {
    _beginIncomingTransition();
    _maybePlayTurnCue();
  }

  void _beginIncomingTransition() {
    if (_incomingTransitionObserved ||
        widget.animation.value >= 1 ||
        widget.animation.status == AnimationStatus.reverse) {
      return;
    }

    _incomingTransitionObserved = true;
    _turnCuePlayed = false;
    _drawingCuePlayed = false;

    if (!widget.enabled) return;

    _shouldReveal = true;
    _controller.value = 0;
  }

  void _maybePlayTurnCue() {
    if (widget.animation.status == AnimationStatus.reverse) {
      if (_reverseTurnCuePlayed ||
          widget.animation.value > 1 - widget.turnSoundCueProgress) {
        return;
      }

      _reverseTurnCuePlayed = true;
      unawaited(widget.soundEffects?.playPageTurn());
      return;
    }

    if (!_incomingTransitionObserved ||
        _turnCuePlayed ||
        widget.animation.value < widget.turnSoundCueProgress) {
      return;
    }

    _turnCuePlayed = true;
    unawaited(widget.soundEffects?.playPageTurn());
  }

  void _handleRevealTick() {
    if (_drawingCuePlayed ||
        !_shouldReveal ||
        _controller.value < _drawingCueStart) {
      return;
    }

    _drawingCuePlayed = true;
    unawaited(widget.soundEffects?.playDrawing());
  }

  void _handlePrimaryStatus(AnimationStatus status) {
    if (status == AnimationStatus.forward) {
      _reverseTurnCuePlayed = false;
      _beginIncomingTransition();
      _maybePlayTurnCue();
    } else if (status == AnimationStatus.completed) {
      _reverseTurnCuePlayed = false;
      if (_shouldReveal) _controller.forward();
    } else if (status == AnimationStatus.reverse) {
      _reverseTurnCuePlayed = false;
      _maybePlayTurnCue();
      _controller.stop();
      unawaited(widget.soundEffects?.stopDrawing());
    }
  }

  void _handleSecondaryStatus(AnimationStatus status) {
    if (status != AnimationStatus.forward) return;

    unawaited(widget.soundEffects?.stopDrawing());
    if (_controller.isCompleted) return;

    _shouldReveal = false;
    _controller.value = 1;
  }

  @override
  void dispose() {
    widget.animation.removeListener(_handlePrimaryTick);
    widget.animation.removeStatusListener(_handlePrimaryStatus);
    widget.secondaryAnimation.removeStatusListener(_handleSecondaryStatus);
    _controller.removeListener(_handleRevealTick);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, page) {
        final sketchProgress = const Interval(
          0.11,
          0.45,
          curve: Curves.easeOutCubic,
        ).transform(_controller.value);
        final paintProgress = const Interval(
          0.36,
          1,
          curve: Curves.easeInOutCubic,
        ).transform(_controller.value);

        return StorybookRevealScope(
          sketchProgress: sketchProgress,
          paintProgress: paintProgress,
          revealOrigin: widget.revealOrigin,
          child: page!,
        );
      },
    );
  }
}

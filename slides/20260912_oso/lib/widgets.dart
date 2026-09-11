import 'package:flutter/material.dart';
import 'package:flutter_deck/flutter_deck.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'theme.dart';

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

/// Speaker introduction: portrait and contact QR on the left, identity on the
/// right. The three facts below the name are icon-led rows rather than cards,
/// so the eye lands on the name first.
class OsoProfileBody extends StatelessWidget {
  const OsoProfileBody({super.key});

  static const avatarAssetPath = 'assets/profile/avatar.png';
  static const xProfileUrl = 'https://x.com/yakuran1';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Expanded(flex: 4, child: _ProfileIdentityColumn()),
        const SizedBox(width: 56),
        Expanded(
          flex: 6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '竹原 靖治',
                style: theme.textTheme.displaySmall?.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 20),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.secondaryContainer,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 12,
                  ),
                  child: Text(
                    'やくらん / @yakuran1',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: colors.onSecondaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 52),
              const _ProfileFactRow(
                icon: Icons.business_rounded,
                label: 'ピープルソフトウェア株式会社',
              ),
              const SizedBox(height: 30),
              const _ProfileFactRow(
                icon: Icons.location_on_rounded,
                label: 'Okayama, Japan',
              ),
              const SizedBox(height: 30),
              const _ProfileFactRow(
                icon: Icons.terminal_rounded,
                label: 'Flutter / Dart',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileIdentityColumn extends StatelessWidget {
  const _ProfileIdentityColumn();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 336,
          height: 336,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colors.primaryContainer,
            border: Border.all(color: colors.primary, width: 8),
          ),
          child: ClipOval(
            child: Image.asset(
              OsoProfileBody.avatarAssetPath,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.high,
              errorBuilder: (context, error, stackTrace) => Icon(
                Icons.person_rounded,
                size: 176,
                color: colors.onPrimaryContainer,
              ),
            ),
          ),
        ),
        const SizedBox(height: 44),
        Card.filled(
          color: colors.surfaceContainerLowest,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                QrImageView(
                  data: OsoProfileBody.xProfileUrl,
                  size: 196,
                  padding: EdgeInsets.zero,
                  backgroundColor: Colors.white,
                ),
                const SizedBox(height: 14),
                Text(
                  'X (Twitter)',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileFactRow extends StatelessWidget {
  const _ProfileFactRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Row(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: colors.primaryContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(icon, size: 40, color: colors.onPrimaryContainer),
        ),
        const SizedBox(width: 26),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.titleLarge?.copyWith(
              color: colors.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

/// One of the two things the picture book is trying to say.
///
/// The number, the tinted ground and the oversized watermark give each message
/// a face of its own; the arrow between them carries the reading order.
class OsoMessageCard extends StatelessWidget {
  const OsoMessageCard({
    required this.number,
    required this.icon,
    required this.headline,
    required this.body,
    required this.color,
    required this.onColor,
    super.key,
  });

  final String number;
  final IconData icon;
  final String headline;
  final String body;
  final Color color;
  final Color onColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card.filled(
      color: color,
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: -60,
            bottom: -48,
            child: Icon(
              icon,
              size: 348,
              color: onColor.withValues(alpha: 0.15),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: onColor.withValues(alpha: 0.14),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, size: 48, color: onColor),
                    ),
                    const SizedBox(width: 24),
                    Text(
                      number,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: onColor.withValues(alpha: 0.6),
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 48),
                Text(
                  headline,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: onColor,
                    fontWeight: FontWeight.w800,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 26),
                Text(
                  body,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: onColor.withValues(alpha: 0.88),
                    height: 1.55,
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The arrow that turns two cards into a sequence.
class OsoFlowArrow extends StatelessWidget {
  const OsoFlowArrow({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: 92,
      height: 92,
      decoration: BoxDecoration(color: colors.tertiary, shape: BoxShape.circle),
      child: Icon(
        Icons.arrow_forward_rounded,
        size: 52,
        color: colors.onTertiary,
      ),
    );
  }
}

/// Holds its child's space from the first step and fades it in on [step].
///
/// Reserving the space up front matters: the cards are laid out by a Row, and
/// letting them appear would re-flow everything already on screen.
class OsoStepReveal extends StatelessWidget {
  const OsoStepReveal({
    required this.step,
    required this.child,
    this.from = const Offset(0.1, 0),
    super.key,
  });

  /// The slide step at which the child becomes visible.
  final int step;

  /// Where the child travels from, as a fraction of its own size.
  final Offset from;

  final Widget child;

  static const _duration = Duration(milliseconds: 420);

  @override
  Widget build(BuildContext context) {
    return FlutterDeckSlideStepsBuilder(
      builder: (context, stepNumber) {
        final shown = stepNumber >= step;

        return AnimatedSlide(
          offset: shown ? Offset.zero : from,
          duration: _duration,
          curve: Curves.easeOutCubic,
          child: AnimatedOpacity(
            opacity: shown ? 1 : 0,
            duration: _duration,
            curve: Curves.easeOut,
            child: child,
          ),
        );
      },
    );
  }
}

/// One step of the speaker's own history, drawn as a stage of a growing tree.
///
/// [heightFactor] is what makes the row read as growth: the cards get taller
/// from left to right, and the colour roles climb with them so the last stage
/// lands on the full primary.
class OsoGrowthStage extends StatelessWidget {
  const OsoGrowthStage({
    required this.number,
    required this.icon,
    required this.title,
    required this.body,
    required this.color,
    required this.onColor,
    required this.heightFactor,
    required this.leafCount,
    required this.step,
    super.key,
  });

  final String number;
  final IconData icon;
  final String title;
  final String body;
  final Color color;
  final Color onColor;
  final double heightFactor;
  final int leafCount;

  /// The slide step this stage appears on. [OsoGrowthRow] reads it.
  final int step;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    // The parent row stretches every stage to the full body height; taking a
    // fraction of it here is what makes the stages climb from left to right.
    return FractionallySizedBox(
      heightFactor: heightFactor,
      alignment: Alignment.bottomCenter,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < leafCount; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    Icons.eco_rounded,
                    size: 26 + i * 4,
                    color: colors.primary.withValues(alpha: 0.3 + i * 0.14),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Expanded(
            child: Card.filled(
              color: color,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 26, 28, 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Icon(icon, size: 52, color: onColor),
                        Text(
                          number,
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: onColor.withValues(alpha: 0.55),
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: onColor,
                        fontWeight: FontWeight.w800,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      body,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: onColor.withValues(alpha: 0.86),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The soil the growth stages stand on, plus the chevrons between them.
class OsoGrowthRow extends StatelessWidget {
  const OsoGrowthRow({required this.stages, super.key});

  final List<OsoGrowthStage> stages;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Stack(
      children: [
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            height: 16,
            decoration: BoxDecoration(
              color: colors.tertiary.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 26),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < stages.length; i++) ...[
                // The chevron belongs to the stage it points at, so it arrives
                // on the same step rather than dangling at an empty gap.
                if (i > 0)
                  SizedBox(
                    width: 44,
                    child: OsoStepReveal(
                      step: stages[i].step,
                      child: Align(
                        alignment: const Alignment(0, 0.62),
                        child: Icon(
                          Icons.chevron_right_rounded,
                          size: 60,
                          color: colors.primary.withValues(alpha: 0.85),
                        ),
                      ),
                    ),
                  ),
                Expanded(
                  child: OsoStepReveal(
                    step: stages[i].step,
                    // The stages grow out of the soil line, so they rise into
                    // place instead of sliding in from the side.
                    from: const Offset(0, 0.08),
                    child: stages[i],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// The closing ask, kept to one sentence so it survives being read at a glance.
class OsoTakeawayBody extends StatelessWidget {
  const OsoTakeawayBody({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 5,
          child: Card.filled(
            color: colors.primaryContainer,
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                Positioned(
                  right: -76,
                  bottom: -76,
                  child: Icon(
                    Icons.park_rounded,
                    size: 380,
                    color: colors.onPrimaryContainer.withValues(alpha: 0.1),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(48),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.park_rounded,
                        size: 108,
                        color: colors.onPrimaryContainer,
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'まず、\nやってみる。',
                        style: theme.textTheme.displaySmall?.copyWith(
                          color: colors.onPrimaryContainer,
                          fontWeight: FontWeight.w900,
                          height: 1.25,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 30),
                      Container(
                        width: 132,
                        height: 8,
                        decoration: BoxDecoration(
                          color: colors.tertiary,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      const SizedBox(height: 30),
                      Text(
                        'あなたの「一粒」を、大切に。',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: colors.onPrimaryContainer,
                          fontWeight: FontWeight.w700,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 40),
        const Expanded(
          flex: 6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _TakeawayBeat(
                  number: '01',
                  icon: Icons.touch_app_rounded,
                  title: 'まず、やってみる',
                  body: '些細なきっかけでも、ひとまず手を動かす。',
                ),
              ),
              SizedBox(height: 20),
              Expanded(
                child: _TakeawayBeat(
                  number: '02',
                  icon: Icons.favorite_rounded,
                  title: '「おもしろい」を大事に',
                  body: 'その感動が、次の一歩の原動力になる。',
                ),
              ),
              SizedBox(height: 20),
              Expanded(
                child: _TakeawayBeat(
                  number: '03',
                  icon: Icons.volunteer_activism_rounded,
                  title: '次の誰かへ、手渡す',
                  body: 'いつか誰かに渡せる、一粒になっていく。',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TakeawayBeat extends StatelessWidget {
  const _TakeawayBeat({
    required this.number,
    required this.icon,
    required this.title,
    required this.body,
  });

  final String number;
  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card.filled(
      color: colors.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 20, 36, 20),
        child: Row(
          children: [
            Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                color: colors.secondaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: colors.onSecondaryContainer),
            ),
            const SizedBox(width: 28),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: colors.onSurface,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    body,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: colors.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Text(
              number,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: colors.outlineVariant,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Sponsor slide: the photo takes the top of the canvas edge to edge, and the
/// pitch underneath is one line the room can read without stopping the talk.
class OsoCompanySlide extends StatelessWidget {
  const OsoCompanySlide({super.key});

  static const imageAssetPath = 'assets/company/people_software.png';

  /// Aspect ratio of [imageAssetPath] (1904x510). The band is sized from it so
  /// the banner lands edge to edge with none of its lettering cropped off.
  static const _bannerAspectRatio = 1904 / 510;

  @override
  Widget build(BuildContext context) {
    return OsoCanvas(
      child: Builder(
        builder: (context) {
          final theme = Theme.of(context);
          final colors = theme.colorScheme;

          return Column(
            // Without this the text block shrink-wraps and centres itself under
            // the full-bleed photo instead of sharing the deck's left margin.
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: double.infinity,
                height: osoCanvasSize.width / _bannerAspectRatio,
                child: Image.asset(
                  imageAssetPath,
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (context, error, stackTrace) => ColoredBox(
                    color: colors.primaryContainer,
                    child: Icon(
                      Icons.apartment_rounded,
                      size: 200,
                      color: colors.onPrimaryContainer,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ColoredBox(
                  color: colors.surface,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(88, 44, 88, 52),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: colors.primaryContainer,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 26,
                              vertical: 12,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.business_rounded,
                                  size: 32,
                                  color: colors.onPrimaryContainer,
                                ),
                                const SizedBox(width: 14),
                                Text(
                                  'ピープルソフトウェア株式会社',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: colors.onPrimaryContainer,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                        Text(
                          'ちいさなキッカケが、\nたくさん見つかる会社です。',
                          style: theme.textTheme.displaySmall?.copyWith(
                            color: colors.onSurface,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(height: 22),
                        Text(
                          'あなたの「どんぐり」も、きっとここで見つかります。',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: colors.onSurfaceVariant,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// The real closing slide. It mirrors the book so the talk ends where it began.
class OsoFinalThanksSlide extends StatelessWidget {
  const OsoFinalThanksSlide({super.key});

  static const message = 'ご清聴ありがとうございました！';

  @override
  Widget build(BuildContext context) {
    return OsoCanvas(
      backgroundColor: osoSeedColor,
      theme: osoEndingTheme,
      child: Builder(
        builder: (context) {
          final theme = Theme.of(context);

          return ColoredBox(
            color: osoSeedColor,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < 5; i++)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Icon(
                            Icons.spa_rounded,
                            size: 44,
                            color: osoAccentColor.withValues(alpha: 0.7),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 56),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.displayMedium?.copyWith(
                      color: osoAccentColor,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 56),
                  Container(
                    width: 220,
                    height: 8,
                    decoration: BoxDecoration(
                      color: osoAccentColor.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// A single tinted panel with an icon and a caption, used where a slide needs
/// a visual anchor rather than another block of text.
class OsoIconPanel extends StatelessWidget {
  const OsoIconPanel({
    required this.icon,
    required this.label,
    required this.color,
    required this.iconColor,
    super.key,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Card.filled(
      color: color,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 168, color: iconColor),
            const SizedBox(height: 28),
            Text(
              label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: iconColor,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A headline card for slides that lead with a single statement.
class OsoStatementCard extends StatelessWidget {
  const OsoStatementCard({
    required this.icon,
    required this.title,
    required this.body,
    super.key,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card.filled(
      color: colors.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(52),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 96, color: colors.onPrimaryContainer),
            const SizedBox(height: 36),
            Text(
              title,
              style: theme.textTheme.headlineLarge?.copyWith(
                color: colors.onPrimaryContainer,
                fontWeight: FontWeight.w800,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              body,
              style: theme.textTheme.titleLarge?.copyWith(
                color: colors.onPrimaryContainer,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

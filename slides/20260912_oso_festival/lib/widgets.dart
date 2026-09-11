import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/link.dart';

import 'pages.dart';
import 'theme.dart';

/// Like the original OSO book, every page is just its full illustration.
class StoryArtwork extends StatelessWidget {
  const StoryArtwork({required this.page, super.key});
  final FestivalPage page;

  @override
  Widget build(BuildContext context) => Image.asset(
    page.asset,
    fit: BoxFit.contain,
    filterQuality: FilterQuality.high,
    semanticLabel: page.title,
  );
}

class EventPage extends StatelessWidget {
  const EventPage({super.key});

  static const bannerAsset = 'assets/event/banner.png';

  @override
  Widget build(BuildContext context) => OsoMaterialSlide(
    eyebrow: '中四国初の FLUTTERKAIGI MINI',
    title: '来週、岡山で開催します',
    child: Builder(
      builder: (context) {
        final theme = Theme.of(context);
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(36),
                    child: Image.asset(
                      bannerAsset,
                      semanticLabel: 'FlutterKaigi mini #6 @Okayama 岡山開催',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    '知らない人も、知っている人も。\n「おもしろい」が見つかる場所。',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 40),
            const Expanded(
              child: OsoStatementCard(
                icon: Icons.diversity_3_rounded,
                title: 'FlutterKaigi と\n地域コミュニティ',
                body: 'いっしょにひらく\nFlutterの技術イベント。',
              ),
            ),
          ],
        );
      },
    ),
  );
}

class InvitationPage extends StatelessWidget {
  const InvitationPage({super.key});

  @override
  Widget build(BuildContext context) => const OsoMaterialSlide(
    eyebrow: 'まだまだ、ちいさな はじまり',
    title: 'このお話を、ハッピーエンドに。',
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 6,
          child: OsoStatementCard(
            icon: Icons.celebration_rounded,
            title: 'ぜひ、ご参加ください。\nお友だちも一緒に。',
            body: '聞くだけでも、話してみても。\n小さな「おもしろい」が芽を出す。',
          ),
        ),
        SizedBox(width: 40),
        Expanded(flex: 4, child: EventQrCard()),
      ],
    ),
  );
}

/// Uses the same generated QR approach as the original OSO profile slide.
class EventQrCard extends StatelessWidget {
  const EventQrCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Card.filled(
      color: colors.surfaceContainerLowest,
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '参加のお申し込み',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: colors.onSurface,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 24),
            QrImageView(
              data: eventUrl,
              size: 350,
              padding: const EdgeInsets.all(20),
              backgroundColor: Colors.white,
              semanticsLabel: 'FlutterKaigi mini 岡山の参加申し込みQRコード',
            ),
            const SizedBox(height: 24),
            Link(
              uri: Uri.parse(eventUrl),
              target: LinkTarget.blank,
              builder: (context, followLink) => InkWell(
                onTap: followLink,
                child: Text(
                  eventUrl,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colors.primary,
                    decoration: TextDecoration.underline,
                    height: 1.4,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Copied from 20260912_oso/lib/widgets.dart to preserve its exact card styling.
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

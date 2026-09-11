import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/link.dart';

import 'pages.dart';

const forestGreen = Color(0xFF31533E);
const bookGold = Color(0xFFE7C978);
const paperCream = Color(0xFFFFFDF5);
const storyInk = Color(0xFF543B21);

final festivalTheme = ThemeData(
  fontFamily: 'Kiwi Maru',
  scaffoldBackgroundColor: paperCream,
  colorScheme: ColorScheme.fromSeed(seedColor: forestGreen),
);

class StoryArtwork extends StatelessWidget {
  const StoryArtwork({required this.page, super.key});
  final FestivalPage page;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      Image.asset(
        page.asset,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        semanticLabel: page.embeddedTitle ? festivalTitle : null,
      ),
      if (page.titleLayout)
        Positioned(
          top: 360,
          left: 760,
          right: 80,
          child: Text(
            page.caption,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Kiwi Maru',
              fontSize: 72,
              fontWeight: FontWeight.w500,
              height: 1.65,
              color: storyInk,
              shadows: [Shadow(color: paperCream, blurRadius: 18)],
            ),
          ),
        ),
      if (!page.titleLayout && !page.embeddedTitle)
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(48, 55, 48, 27),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x00FFFDF5), Color(0xEFFFFDF5), paperCream],
                stops: [0, 0.42, 1],
              ),
            ),
            child: Text(
              page.caption,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Kiwi Maru',
                fontSize: 52,
                height: 1.4,
                fontWeight: FontWeight.w500,
                color: storyInk,
              ),
            ),
          ),
        ),
    ],
  );
}

/// A real optional asset slot. Missing media shows finished fallback content;
/// adding the documented filenames activates them on the next build.
class OptionalEventImage extends StatefulWidget {
  const OptionalEventImage({
    required this.asset,
    required this.fallback,
    super.key,
  });
  final String asset;
  final Widget fallback;
  @override
  State<OptionalEventImage> createState() => _OptionalEventImageState();
}

class _OptionalEventImageState extends State<OptionalEventImage> {
  late final Future<AssetManifest> _manifest =
      AssetManifest.loadFromAssetBundle(rootBundle);
  @override
  Widget build(BuildContext context) => FutureBuilder<AssetManifest>(
    future: _manifest,
    builder: (context, snapshot) {
      if (!(snapshot.data?.listAssets().contains(widget.asset) ?? false)) {
        return widget.fallback;
      }
      return Image.asset(
        widget.asset,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => widget.fallback,
      );
    },
  );
}

class EventPage extends StatelessWidget {
  const EventPage({super.key});
  @override
  Widget build(BuildContext context) => ColoredBox(
    color: paperCream,
    child: Padding(
      padding: const EdgeInsets.all(100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ここからは、わたしたちの おはなし。',
            style: TextStyle(fontSize: 38, color: storyInk),
          ),
          const SizedBox(height: 35),
          const Text(
            eventTiming,
            style: TextStyle(fontSize: 62, color: forestGreen),
          ),
          const Text(
            'FlutterKaigi mini 岡山',
            style: TextStyle(
              fontSize: 84,
              fontWeight: FontWeight.w500,
              color: forestGreen,
            ),
          ),
          const SizedBox(height: 42),
          Expanded(
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'みんなの おかげで、\nひらけることに なりました。',
                    style: TextStyle(
                      fontSize: 48,
                      height: 1.8,
                      color: storyInk,
                    ),
                  ),
                ),
                const SizedBox(width: 72),
                Expanded(
                  child: OptionalEventImage(
                    asset: 'assets/event/banner.png',
                    fallback: Image.asset(
                      'assets/story/06_ready.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class InvitationPage extends StatelessWidget {
  const InvitationPage({super.key});
  @override
  Widget build(BuildContext context) => ColoredBox(
    color: paperCream,
    child: Padding(
      padding: const EdgeInsets.all(100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'まだまだ、ちいさな はじまり。',
            style: TextStyle(fontSize: 44, color: storyInk),
          ),
          const SizedBox(height: 28),
          const Text(
            'いっしょに、大きくしていこう。',
            style: TextStyle(
              fontSize: 76,
              color: forestGreen,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 54),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'あそびに 来てください。\nだれかを 誘ってください。',
                        style: TextStyle(
                          fontSize: 49,
                          height: 1.9,
                          color: storyInk,
                        ),
                      ),
                      const SizedBox(height: 40),
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Image.asset(
                            'assets/story/07_gathering.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 80),
                const SizedBox.square(
                  dimension: 420,
                  child: ColoredBox(
                    color: Colors.white,
                    child: Padding(
                      padding: EdgeInsets.all(28),
                      child: OptionalEventImage(
                        asset: 'assets/event/qr.png',
                        fallback: Center(
                          child: Text(
                            '参加の\nお申し込み',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 48,
                              height: 1.7,
                              color: forestGreen,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          const Text(
            'FlutterKaigi mini 岡山',
            style: TextStyle(fontSize: 36, color: forestGreen),
          ),
          Link(
            uri: Uri.parse(eventUrl),
            target: LinkTarget.blank,
            builder: (context, followLink) => InkWell(
              onTap: followLink,
              child: const Text(
                eventUrl,
                style: TextStyle(
                  fontSize: 38,
                  color: forestGreen,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

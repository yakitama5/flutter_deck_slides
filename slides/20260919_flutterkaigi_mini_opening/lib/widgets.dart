import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/link.dart';

import 'pages.dart';
import 'theme.dart';

class OpeningSlide extends StatelessWidget {
  const OpeningSlide({required this.page, super.key});
  final OpeningPage page;

  @override
  Widget build(BuildContext context) {
    final dark =
        page.kind == OpeningKind.cover || page.kind == OpeningKind.handoff;
    return SlideCanvas(
      child: DecoratedBox(
        decoration: BoxDecoration(color: dark ? miniNavy : paper),
        child: Stack(
          children: [
            if (!dark)
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SizedBox(
                  height: 10,
                  child: DecoratedBox(
                    decoration: BoxDecoration(gradient: warmGradient),
                  ),
                ),
              ),
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(64, 54, 64, 94),
                child: switch (page.kind) {
                  OpeningKind.cover => const _Cover(),
                  OpeningKind.about => const _About(),
                  OpeningKind.event => const _Event(),
                  OpeningKind.tickets => const _Tickets(),
                  OpeningKind.volunteer => const _Volunteer(),
                  OpeningKind.mini => const _Mini(),
                  OpeningKind.timeline => const _Timeline(),
                  OpeningKind.timelineLater => const _Timeline(later: true),
                  OpeningKind.handoff => const _Handoff(),
                },
              ),
            ),
            Positioned(
              left: 64,
              right: 64,
              bottom: 30,
              child: Row(
                children: [
                  Text(
                    'FlutterKaigi mini #6 @Okayama',
                    style: TextStyle(
                      fontSize: 18,
                      color: dark ? Colors.white70 : muted,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${(openingPages.indexOf(page) + 1).toString().padLeft(2, '0')} / ${openingPages.length.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      fontSize: 18,
                      color: dark ? Colors.white70 : muted,
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
}

class _Heading extends StatelessWidget {
  const _Heading(this.title, {this.kicker});
  final String title;
  final String? kicker;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (kicker != null) ...[
        Text(
          kicker!,
          style: const TextStyle(
            fontSize: 20,
            letterSpacing: 2,
            color: miniTeal,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
      ],
      Text(
        title,
        style: const TextStyle(
          fontSize: 58,
          height: 1.2,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );
}

class _GradientText extends StatelessWidget {
  const _GradientText(this.text, {required this.style});
  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) => ShaderMask(
    shaderCallback: (bounds) => warmGradient.createShader(bounds),
    blendMode: BlendMode.srcIn,
    child: Text(text, style: style.copyWith(color: Colors.white)),
  );
}

class _Cover extends StatelessWidget {
  const _Cover();

  @override
  Widget build(BuildContext context) => DefaultTextStyle.merge(
    style: const TextStyle(color: Colors.white),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              decoration: BoxDecoration(
                gradient: freshGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                '岡山開催',
                style: TextStyle(
                  fontSize: 27,
                  color: miniNavy,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Spacer(),
            const Text(
              '2026.09.19  SAT',
              style: TextStyle(fontSize: 26, letterSpacing: 2),
            ),
          ],
        ),
        const Spacer(),
        const Text(
          'FlutterKaigi',
          style: TextStyle(
            fontSize: 116,
            height: 1.1,
            fontWeight: FontWeight.w900,
            letterSpacing: -3,
          ),
        ),
        const SizedBox(height: 8),
        const _GradientText(
          'mini #6 @Okayama',
          style: TextStyle(
            fontSize: 99,
            height: 1.25,
            fontWeight: FontWeight.w900,
            letterSpacing: -2,
          ),
        ),
        const SizedBox(height: 36),
        Container(
          width: 110,
          height: 6,
          decoration: const BoxDecoration(gradient: freshGradient),
        ),
        const SizedBox(height: 26),
        const Text(
          'OPENING',
          style: TextStyle(
            fontSize: 26,
            letterSpacing: 5,
            color: miniTurquoise,
          ),
        ),
        const Spacer(),
        const Row(
          children: [
            Icon(Icons.location_on_outlined, size: 28, color: miniTurquoise),
            SizedBox(width: 10),
            Text('能楽堂ホール tenjin9', style: TextStyle(fontSize: 28)),
            Spacer(),
            Text('FlutterKaigi × 岡山.Flutter', style: TextStyle(fontSize: 26)),
          ],
        ),
      ],
    ),
  );
}

class _About extends StatelessWidget {
  const _About();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const _Heading('FlutterKaigiとは', kicker: 'ABOUT FLUTTERKAIGI'),
      const SizedBox(height: 40),
      Expanded(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 14),
                  const Text(
                    'Flutter好きと\n語って、楽しむ\nカンファレンス',
                    style: TextStyle(
                      fontSize: 49,
                      height: 1.45,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  const _ConceptCard(
                    icon: Icons.code_rounded,
                    title: '知見を持ち寄る',
                    detail: 'セッションから発見を',
                  ),
                  const SizedBox(height: 18),
                  const _ConceptCard(
                    icon: Icons.forum_outlined,
                    title: '好きで盛り上がる',
                    detail: '仲間と語り、熱を分かち合う',
                  ),
                ],
              ),
            ),
            const SizedBox(width: 44),
            Expanded(
              flex: 8,
              child: _PhotoCard(
                asset: 'assets/images/kaigi-2025-hall.jpg',
                label: 'FlutterKaigi 2025',
                semanticsLabel: 'FlutterKaigi 2025 の会場風景',
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _ConceptCard extends StatelessWidget {
  const _ConceptCard({
    required this.icon,
    required this.title,
    required this.detail,
  });
  final IconData icon;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Icon(icon, size: 40, color: miniTeal),
          const SizedBox(width: 22),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(detail, style: const TextStyle(fontSize: 20, color: muted)),
            ],
          ),
        ],
      ),
    ),
  );
}

class _PhotoCard extends StatelessWidget {
  const _PhotoCard({
    required this.asset,
    required this.label,
    required this.semanticsLabel,
  });
  final String asset;
  final String label;
  final String semanticsLabel;

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(asset, fit: BoxFit.cover, semanticLabel: semanticsLabel),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Color(0xA6082B55)],
              stops: [.6, 1],
            ),
          ),
        ),
        Positioned(
          left: 30,
          bottom: 26,
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    ),
  );
}

class _Event extends StatelessWidget {
  const _Event();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const _Heading('FlutterKaigi 2026', kicker: 'THIS YEAR'),
      const SizedBox(height: 38),
      Expanded(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    color: mint,
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.calendar_month_outlined,
                                size: 28,
                                color: miniTeal,
                              ),
                              SizedBox(width: 12),
                              Text(
                                '2026年 10月',
                                style: TextStyle(fontSize: 25, color: miniTeal),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              for (final day in ['29', '30']) ...[
                                if (day == '30') ...[
                                  const SizedBox(width: 24),
                                  const Icon(
                                    Icons.east_rounded,
                                    size: 36,
                                    color: miniTeal,
                                  ),
                                  const SizedBox(width: 24),
                                ],
                                Text(
                                  day,
                                  style: const TextStyle(
                                    fontSize: 88,
                                    height: 1.1,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Text(
                                  day == '29' ? 'THU' : 'FRI',
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: Card(
                      clipBehavior: Clip.antiAlias,
                      child: DecoratedBox(
                        decoration: const BoxDecoration(
                          gradient: kaigi2026Gradient,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(34),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'THEME',
                                style: TextStyle(
                                  fontSize: 20,
                                  letterSpacing: 2,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'Assemble',
                                style: TextStyle(
                                  fontSize: 76,
                                  height: 1.2,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                '会って、話して、熱くなる。',
                                style: TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 28),
            Expanded(
              flex: 5,
              child: Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: Image.asset(
                        'assets/images/hamamatsucho-main-hall.jpg',
                        fit: BoxFit.cover,
                        semanticLabel: '浜松町コンベンションホールのメインホール 公式会場写真',
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(30, 24, 30, 26),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 25,
                                color: miniTeal,
                              ),
                              SizedBox(width: 8),
                              Text(
                                '東京',
                                style: TextStyle(fontSize: 22, color: miniTeal),
                              ),
                            ],
                          ),
                          SizedBox(height: 10),
                          Text(
                            '浜松町\nコンベンションホール',
                            style: TextStyle(
                              fontSize: 38,
                              height: 1.3,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 14),
                          Text(
                            '写真：会場公式サイト（レイアウト例）',
                            style: TextStyle(fontSize: 17, color: muted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _Tickets extends StatelessWidget {
  const _Tickets();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const _Heading('チケットのご案内', kicker: 'JOIN FLUTTERKAIGI 2026'),
      const SizedBox(height: 42),
      Expanded(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(38),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(25),
                              decoration: BoxDecoration(
                                color: mint,
                                borderRadius: BorderRadius.circular(26),
                              ),
                              child: const Icon(
                                Icons.confirmation_number_outlined,
                                size: 62,
                                color: miniTeal,
                              ),
                            ),
                            const SizedBox(width: 40),
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '一般チケット',
                                  style: TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: 16),
                                Text.rich(
                                  TextSpan(
                                    children: [
                                      TextSpan(
                                        text: '¥12,000',
                                        style: TextStyle(
                                          fontSize: 78,
                                          fontWeight: FontWeight.w700,
                                          height: 1,
                                        ),
                                      ),
                                      TextSpan(
                                        text: '  税抜',
                                        style: TextStyle(
                                          fontSize: 24,
                                          color: muted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: Card(
                      color: mint,
                      child: Padding(
                        padding: const EdgeInsets.all(38),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(25),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(26),
                              ),
                              child: const Icon(
                                Icons.school_outlined,
                                size: 62,
                                color: miniTeal,
                              ),
                            ),
                            const SizedBox(width: 40),
                            const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '学生向け',
                                  style: TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  '参加無料',
                                  style: TextStyle(
                                    fontSize: 58,
                                    fontWeight: FontWeight.w700,
                                    color: miniTeal,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'スカラシップの詳細は公式サイトへ',
                                  style: TextStyle(fontSize: 23, color: muted),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 28),
            const SizedBox(
              width: 410,
              child: _QrCard(
                url: ticketsUrl,
                title: 'チケットはこちら',
                label: 'Luma で詳細・購入',
                caption: '学生枠はページ内の案内から',
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _Volunteer extends StatelessWidget {
  const _Volunteer();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const _Heading('ボランティアスタッフ募集中', kicker: 'JOIN THE TEAM'),
      const SizedBox(height: 30),
      Expanded(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Preserve the complete group photo, including the people at both edges.
            SizedBox(
              width: 812,
              child: Card(
                clipBehavior: Clip.antiAlias,
                child: Image.asset(
                  'assets/images/volunteer-team.jpg',
                  fit: BoxFit.contain,
                  cacheWidth: 2000,
                  semanticLabel: '飲食店の前で集まったメンバーの集合写真',
                ),
              ),
            ),
            const SizedBox(width: 32),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '一緒につくる\nFlutterKaigi',
                    style: TextStyle(
                      fontSize: 44,
                      height: 1.3,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    '2026 当日ボランティア',
                    style: TextStyle(fontSize: 24, color: muted),
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: Card(
                      color: mint,
                      child: Padding(
                        padding: const EdgeInsets.all(26),
                        child: Row(
                          children: [
                            Semantics(
                              label: 'ボランティア募集要項のQRコード',
                              image: true,
                              child: QrImageView(
                                data: volunteerUrl,
                                size: 254,
                                padding: const EdgeInsets.all(18),
                                backgroundColor: Colors.white,
                                errorCorrectionLevel: QrErrorCorrectLevel.M,
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '一緒に\n楽しもう！',
                                    style: TextStyle(
                                      fontSize: 31,
                                      height: 1.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  _TextLink(url: volunteerUrl, label: '募集の詳細'),
                                ],
                              ),
                            ),
                          ],
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
    ],
  );
}

class _QrCard extends StatelessWidget {
  const _QrCard({
    required this.url,
    required this.title,
    required this.label,
    required this.caption,
  });
  final String url;
  final String title;
  final String label;
  final String caption;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 28),
          Semantics(
            label: '$label のQRコード',
            image: true,
            child: QrImageView(
              data: url,
              size: 302,
              padding: const EdgeInsets.all(18),
              backgroundColor: Colors.white,
              errorCorrectionLevel: QrErrorCorrectLevel.M,
            ),
          ),
          const SizedBox(height: 26),
          _TextLink(url: url, label: label),
          const SizedBox(height: 16),
          Text(
            caption,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 19, color: muted),
          ),
        ],
      ),
    ),
  );
}

class _TextLink extends StatelessWidget {
  const _TextLink({required this.url, required this.label, this.white = false});
  final String url;
  final String label;
  final bool white;

  @override
  Widget build(BuildContext context) => Link(
    uri: Uri.parse(url),
    target: LinkTarget.blank,
    builder: (context, followLink) => TextButton(
      onPressed: followLink,
      style: TextButton.styleFrom(
        foregroundColor: white ? Colors.white : miniTeal,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        textStyle: const TextStyle(
          fontFamily: 'Noto Sans JP',
          fontSize: 21,
          fontWeight: FontWeight.w700,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          const SizedBox(width: 10),
          const Icon(Icons.open_in_new_rounded, size: 21),
        ],
      ),
    ),
  );
}

class _Mini extends StatelessWidget {
  const _Mini();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const _Heading('FlutterKaigi miniとは', kicker: 'LOCAL COMMUNITY'),
      const SizedBox(height: 38),
      const Text(
        'もっと気軽に地域でつながる',
        style: TextStyle(fontSize: 48, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 16),
      const Text(
        '全国のコミュニティと開く Flutter のミニイベント',
        style: TextStyle(fontSize: 28, color: muted),
      ),
      const SizedBox(height: 34),
      Expanded(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: miniNavy,
              clipBehavior: Clip.antiAlias,
              child: Image.asset(
                'assets/images/mini-okayama.png',
                width: 850,
                fit: BoxFit.contain,
                semanticLabel: 'FlutterKaigi mini #6 @Okayama の公式イベントビジュアル',
              ),
            ),
            const SizedBox(width: 28),
            Expanded(
              child: Card(
                color: mint,
                child: Padding(
                  padding: const EdgeInsets.all(34),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '共催',
                        style: TextStyle(fontSize: 24, color: muted),
                      ),
                      const Spacer(),
                      const Text(
                        'FlutterKaigi',
                        style: TextStyle(
                          fontSize: 41,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Text(
                        '×',
                        style: TextStyle(fontSize: 30, color: miniTeal),
                      ),
                      const Text(
                        '岡山.Flutter',
                        style: TextStyle(
                          fontSize: 47,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _Timeline extends StatelessWidget {
  const _Timeline({this.later = false});
  final bool later;

  @override
  Widget build(BuildContext context) {
    final entries = later ? scheduleLater : scheduleFirst;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Heading(
          later ? '今日のタイムライン  後半' : '今日のタイムライン  前半',
          kicker: 'TODAY’S PROGRAM',
        ),
        const SizedBox(height: 28),
        if (!later) ...[
          const _ScheduleStrip(
            children: [
              _ShortSchedule('14:00', 'オープニング'),
              _ShortSchedule('14:10', '協賛のご紹介'),
            ],
          ),
          const SizedBox(height: 16),
        ],
        Expanded(
          child: Column(
            children: [
              for (var i = 0; i < entries.length; i++) ...[
                if (i > 0) const SizedBox(height: 14),
                if (later && i == 2) ...[
                  const _ScheduleStrip(
                    children: [
                      _ShortSchedule('15:20–15:40', '休憩'),
                      _ShortSchedule('15:40–16:00', 'クイズイベント'),
                    ],
                  ),
                  const SizedBox(height: 14),
                ],
                Expanded(child: _TalkCard(entry: entries[i])),
              ],
            ],
          ),
        ),
        if (later) ...[
          const SizedBox(height: 16),
          const Row(
            children: [
              Text(
                '16:25 アンケート  /  16:30 クロージング・写真撮影  /  17:00 完全撤収',
                style: TextStyle(fontSize: 21, color: muted),
              ),
            ],
          ),
        ],
        const SizedBox(height: 12),
        Row(
          children: [
            const Text(
              '当日の進行により時間は前後します',
              style: TextStyle(fontSize: 18, color: muted),
            ),
            const Spacer(),
            _TextLink(url: miniUrl, label: 'connpass'),
          ],
        ),
      ],
    );
  }
}

class _TalkCard extends StatelessWidget {
  const _TalkCard({required this.entry});
  final ScheduleEntry entry;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 222,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.category,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: miniTeal,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  entry.time,
                  style: const TextStyle(
                    fontSize: 27,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Container(width: 3, height: 64, color: miniTurquoise),
          const SizedBox(width: 28),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.title,
                  style: const TextStyle(
                    fontSize: 27,
                    height: 1.25,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  entry.speaker,
                  style: const TextStyle(fontSize: 22, color: miniTeal),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _ScheduleStrip extends StatelessWidget {
  const _ScheduleStrip({required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: mint,
      borderRadius: BorderRadius.circular(20),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
    child: Row(
      children: [for (final child in children) Expanded(child: child)],
    ),
  );
}

class _ShortSchedule extends StatelessWidget {
  const _ShortSchedule(this.time, this.label);
  final String time;
  final String label;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text(
        time,
        style: const TextStyle(
          fontSize: 25,
          fontWeight: FontWeight.w700,
          color: miniTeal,
        ),
      ),
      const SizedBox(width: 22),
      Text(
        label,
        style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w500),
      ),
    ],
  );
}

class _Handoff extends StatelessWidget {
  const _Handoff();

  @override
  Widget build(BuildContext context) => DefaultTextStyle.merge(
    style: const TextStyle(color: Colors.white),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'LET’S GET STARTED',
          style: TextStyle(
            fontSize: 24,
            letterSpacing: 4,
            color: miniTurquoise,
          ),
        ),
        const Spacer(),
        const Text(
          'Over to you,',
          style: TextStyle(
            fontSize: 106,
            height: 1.15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),
        const _GradientText(
          '岡山.Flutter!',
          style: TextStyle(
            fontSize: 128,
            height: 1.3,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 34),
        Container(
          width: 120,
          height: 6,
          decoration: const BoxDecoration(gradient: freshGradient),
        ),
        const Spacer(),
        Row(
          children: [
            const Text(
              'Enjoy Flutter. Enjoy Okayama.',
              style: TextStyle(fontSize: 31),
            ),
            const Spacer(),
            _TextLink(url: communityUrl, label: '岡山.Flutter', white: true),
          ],
        ),
      ],
    ),
  );
}

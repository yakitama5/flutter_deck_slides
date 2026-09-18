import 'speaker_notes.dart';

/// Slide copy, presentation timing, and sources for the five-minute opening.
enum OpeningKind {
  cover,
  about,
  event,
  tickets,
  volunteer,
  mini,
  timeline,
  timelineLater,
  handoff,
}

class OpeningPage {
  const OpeningPage({
    required this.kind,
    required this.route,
    required this.title,
    required this.seconds,
    required this.notes,
    required this.sources,
  });

  final OpeningKind kind;
  final String route;
  final String title;
  final int seconds;
  final String notes;
  final List<String> sources;
}

const eventUrl = 'https://2026.flutterkaigi.jp/';
const ticketsUrl = 'https://luma.com/flutterkaigi2026?locale=ja';
const volunteerUrl =
    'https://medium.com/flutterkaigi/'
    'flutterkaigi-2026-day-of-volunteer-staff-recruitment-9f31ddbad09e';
const miniUrl = 'https://flutterkaigi.connpass.com/event/401279/';
const communityUrl = 'https://okayama-dot-flutter.connpass.com/';

/// A confirmed talk in the official event schedule.
class ScheduleEntry {
  const ScheduleEntry({
    required this.time,
    required this.title,
    required this.speaker,
    required this.category,
  });

  final String time;
  final String title;
  final String speaker;
  final String category;
}

const scheduleFirst = <ScheduleEntry>[
  ScheduleEntry(
    time: '14:15–14:40',
    title: 'Flutter × ヘルスケア 〜 ネイティブコード０への挑戦 〜',
    speaker: 'フナモト さん',
    category: 'SESSION',
  ),
  ScheduleEntry(
    time: '14:40–14:50',
    title: 'ダイヤが欲しかっただけなのに、なぜかFlutterを書いています。',
    speaker: 'はりねずみ さん',
    category: 'LT',
  ),
  ScheduleEntry(
    time: '14:50–15:00',
    title: 'Flutter初学者が知っておくべき◯個のこと',
    speaker: 'よわよわエンジニア さん',
    category: 'LT',
  ),
];

const scheduleLater = <ScheduleEntry>[
  ScheduleEntry(
    time: '15:00–15:10',
    title: 'FlutterとiOS 27とiPhone Duo',
    speaker: 'kishisuke さん',
    category: 'LT',
  ),
  ScheduleEntry(
    time: '15:10–15:20',
    title: 'そのFlutterコード、なぜ書いた？',
    speaker: 'yakuran さん',
    category: 'LT',
  ),
  ScheduleEntry(
    time: '16:00–16:25',
    title: '開発を高速化。AIコーディングエージェントとCodeRabbitでループエンジニアリング',
    speaker: 'アツシ@CodeRabbit さん',
    category: 'SESSION',
  ),
];

const openingPages = <OpeningPage>[
  OpeningPage(
    kind: OpeningKind.cover,
    route: '/cover',
    title: 'FlutterKaigi mini #6 @Okayama',
    seconds: 15,
    notes: SpeakerNotes.cover,
    sources: ['確認日: 2026-09-17', miniUrl],
  ),
  OpeningPage(
    kind: OpeningKind.about,
    route: '/about',
    title: 'FlutterKaigiとは',
    seconds: 40,
    notes: SpeakerNotes.about,
    sources: [
      '確認日: 2026-09-17',
      'https://docs.flutterkaigi.jp/',
      'https://flutterkaigi.connpass.com/',
      '写真: FlutterKaigi 2025 公式アルバム https://photos.app.goo.gl/D6VmWbVwtYhqaZWH8',
    ],
  ),
  OpeningPage(
    kind: OpeningKind.event,
    route: '/event',
    title: 'FlutterKaigi 2026',
    seconds: 45,
    notes: SpeakerNotes.event,
    sources: [
      '確認日: 2026-09-17',
      eventUrl,
      ticketsUrl,
      '会場写真: 浜松町コンベンションホール 公式フォトギャラリー（メインホールのレイアウト例） https://www.hmc.conventionhall.jp/facility/#photo',
    ],
  ),
  OpeningPage(
    kind: OpeningKind.tickets,
    route: '/tickets',
    title: 'チケットのご案内',
    seconds: 40,
    notes: SpeakerNotes.tickets,
    sources: ['確認日: 2026-09-17', ticketsUrl, eventUrl],
  ),
  OpeningPage(
    kind: OpeningKind.volunteer,
    route: '/volunteer',
    title: 'ボランティアスタッフ募集中',
    seconds: 40,
    notes: SpeakerNotes.volunteer,
    sources: [
      '確認日: 2026-09-17',
      eventUrl,
      volunteerUrl,
      '写真: ユーザー提供 /Users/yakuran/Downloads/IMG_0936.jpg',
    ],
  ),
  OpeningPage(
    kind: OpeningKind.mini,
    route: '/mini',
    title: 'FlutterKaigi miniとは',
    seconds: 45,
    notes: SpeakerNotes.mini,
    sources: [
      '確認日: 2026-09-17',
      miniUrl,
      communityUrl,
      'イベント表紙: ユーザー提供 FlutterKaigi mini #6 @Okayama 画像',
    ],
  ),
  OpeningPage(
    kind: OpeningKind.timeline,
    route: '/timeline',
    title: '今日のタイムライン · 前半',
    seconds: 30,
    notes: SpeakerNotes.timeline,
    sources: ['確認日: 2026-09-17（公式connpass本文をブラウザで確認）', miniUrl],
  ),
  OpeningPage(
    kind: OpeningKind.timelineLater,
    route: '/timeline-later',
    title: '今日のタイムライン · 後半',
    seconds: 25,
    notes: SpeakerNotes.timelineLater,
    sources: ['確認日: 2026-09-17（公式connpass本文をブラウザで確認）', miniUrl],
  ),
  OpeningPage(
    kind: OpeningKind.handoff,
    route: '/handoff',
    title: 'Over to you, 岡山.Flutter!',
    seconds: 20,
    notes: SpeakerNotes.handoff,
    sources: ['確認日: 2026-09-17', miniUrl, communityUrl],
  ),
];

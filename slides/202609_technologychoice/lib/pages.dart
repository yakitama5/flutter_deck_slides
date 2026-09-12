import 'package:flutter/widgets.dart';

import 'speaker_notes.dart';

const bookTitle = 'リスくんと ぴったりのかご';

enum PageKind {
  frontCover,
  story,
  backCover,
  bridge,
  exam,
  architecture,
  melos,
  learning,
  record,
  review,
  takeaway,
}

class ChoicePage {
  const ChoicePage({
    required this.route,
    required this.title,
    required this.seconds,
    required this.notes,
    required this.kind,
    this.asset,
    this.revealOrigin = const Alignment(0, 0.25),
  });

  final String route;
  final String title;
  final int seconds;
  final String notes;
  final PageKind kind;
  final String? asset;
  final Alignment revealOrigin;

  bool get isBook =>
      kind == PageKind.frontCover ||
      kind == PageKind.story ||
      kind == PageKind.backCover;
}

const choicePages = <ChoicePage>[
  ChoicePage(
    route: '/front-cover',
    title: bookTitle,
    seconds: 10,
    notes: SpeakerNotes.cover,
    kind: PageKind.frontCover,
  ),
  ChoicePage(
    route: '/story/trend',
    title: 'もりで はやっている かご',
    seconds: 18,
    notes: SpeakerNotes.trend,
    kind: PageKind.story,
    asset: 'assets/story/01_trend.png',
    revealOrigin: Alignment(0.3, 0.2),
  ),
  ChoicePage(
    route: '/story/everyone',
    title: 'みんなが つかっている',
    seconds: 18,
    notes: SpeakerNotes.everyone,
    kind: PageKind.story,
    asset: 'assets/story/02_everyone.png',
    revealOrigin: Alignment(-0.3, 0.2),
  ),
  ChoicePage(
    route: '/story/copy',
    title: 'ぼくも これにしよう',
    seconds: 18,
    notes: SpeakerNotes.copy,
    kind: PageKind.story,
    asset: 'assets/story/03_copy.png',
  ),
  ChoicePage(
    route: '/story/trouble',
    title: 'おおきすぎて つかえない',
    seconds: 24,
    notes: SpeakerNotes.trouble,
    kind: PageKind.story,
    asset: 'assets/story/04_trouble.png',
  ),
  ChoicePage(
    route: '/story/owl',
    title: 'フクロウはかせ',
    seconds: 16,
    notes: SpeakerNotes.owl,
    kind: PageKind.story,
    asset: 'assets/story/05_owl.png',
  ),
  ChoicePage(
    route: '/story/why',
    title: 'みんな そうだから',
    seconds: 22,
    notes: SpeakerNotes.why,
    kind: PageKind.story,
    asset: 'assets/story/06_why.png',
    revealOrigin: Alignment(-0.2, 0.2),
  ),
  ChoicePage(
    route: '/story/purpose',
    title: 'なにを はこびたいのかな',
    seconds: 28,
    notes: SpeakerNotes.purpose,
    kind: PageKind.story,
    asset: 'assets/story/07_purpose.png',
  ),
  ChoicePage(
    route: '/story/choose',
    title: 'じぶんで ためして えらぶ',
    seconds: 24,
    notes: SpeakerNotes.choose,
    kind: PageKind.story,
    asset: 'assets/story/08_choose.png',
  ),
  ChoicePage(
    route: '/story/works',
    title: 'はこべた とりだせた',
    seconds: 20,
    notes: SpeakerNotes.works,
    kind: PageKind.story,
    asset: 'assets/story/09_works.png',
    revealOrigin: Alignment(0.3, 0.2),
  ),
  ChoicePage(
    route: '/story/reason',
    title: 'ぼくの りゆう',
    seconds: 22,
    notes: SpeakerNotes.reason,
    kind: PageKind.story,
    asset: 'assets/story/10_reason.png',
  ),
  ChoicePage(
    route: '/back-cover',
    title: 'おしまい',
    seconds: 5,
    notes: SpeakerNotes.back,
    kind: PageKind.backCover,
  ),
  ChoicePage(
    route: '/talk/bridge',
    title: '技術選定に 自分の理由を',
    seconds: 30,
    notes: SpeakerNotes.bridge,
    kind: PageKind.bridge,
  ),
  ChoicePage(
    route: '/talk/exam',
    title: 'なぜそうしたか を書いた',
    seconds: 35,
    notes: SpeakerNotes.exam,
    kind: PageKind.exam,
    asset: 'assets/evidence/search_results_light.png',
  ),
  ChoicePage(
    route: '/talk/architecture',
    title: '制御しやすい構造を選んだ',
    seconds: 55,
    notes: SpeakerNotes.architecture,
    kind: PageKind.architecture,
  ),
  ChoicePage(
    route: '/talk/melos',
    title: '同じMelosでも 選択が変わる',
    seconds: 55,
    notes: SpeakerNotes.melos,
    kind: PageKind.melos,
  ),
  ChoicePage(
    route: '/talk/learning',
    title: 'やってみたかった も理由になる',
    seconds: 40,
    notes: SpeakerNotes.learning,
    kind: PageKind.learning,
  ),
  ChoicePage(
    route: '/talk/record',
    title: '選ばなかった理由も残す',
    seconds: 55,
    notes: SpeakerNotes.record,
    kind: PageKind.record,
  ),
  ChoicePage(
    route: '/talk/review',
    title: '条件が変わったら 理由も見直す',
    seconds: 50,
    notes: SpeakerNotes.review,
    kind: PageKind.review,
  ),
  ChoicePage(
    route: '/talk/takeaway',
    title: '自分の言葉で 選べる状態に',
    seconds: 55,
    notes: SpeakerNotes.takeaway,
    kind: PageKind.takeaway,
  ),
];

String timestamp(int seconds) =>
    '${(seconds ~/ 60).toString().padLeft(2, '0')}:'
    '${(seconds % 60).toString().padLeft(2, '0')}';

/// Notes and rehearsal schedule share the same order as the rendered deck.
String timedNotes(ChoicePage page) {
  final start = choicePages
      .takeWhile((p) => p != page)
      .fold<int>(0, (sum, p) => sum + p.seconds);
  return '${timestamp(start)}–${timestamp(start + page.seconds)} '
      '（${page.seconds}秒・場面転換込み）\n\n${page.notes}';
}

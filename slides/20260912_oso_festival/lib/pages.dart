import 'package:flutter/widgets.dart';

import 'speaker_notes.dart';

const festivalTitle = 'リスくんと もりのちいさなおまつり';
const eventUrl = 'https://flutterkaigi.connpass.com/event/401279/';
// Relative wording is deliberately tied to the OSO talk, not today's clock.
const eventTiming = '来週、岡山で。';

class FestivalPage {
  const FestivalPage(
    this.slug,
    this.caption,
    this.asset,
    this.notes, {
    this.titleLayout = false,
    this.embeddedTitle = false,
    this.revealOrigin = const Alignment(0, 0.25),
  });
  final String slug;
  final String caption;
  final String asset;
  final String notes;
  final bool titleLayout;
  final bool embeddedTitle;
  final Alignment revealOrigin;
}

const festivalPages = [
  FestivalPage(
    'title',
    'リスくんと\nもりのちいさなおまつり',
    'assets/story/01_cover.png',
    FestivalNotes.title,
    embeddedTitle: true,
  ),
  FestivalPage(
    'idea',
    'この もりで、おまつりを。',
    'assets/story/02_idea.png',
    FestivalNotes.idea,
    revealOrigin: Alignment(-0.46, 0.35),
  ),
  FestivalPage(
    'alone',
    'あれも、これも。……あれれ？',
    'assets/story/03_alone.png',
    FestivalNotes.alone,
    revealOrigin: Alignment(0.2, 0.1),
  ),
  FestivalPage(
    'friends',
    '「いっしょに やろう！」',
    'assets/story/04_friends.png',
    FestivalNotes.friends,
  ),
  FestivalPage(
    'preparation',
    'それぞれの できることを。',
    'assets/story/05_preparation.png',
    FestivalNotes.preparation,
  ),
  FestivalPage(
    'ready',
    'ちいさな おまつりが、かたちに。',
    'assets/story/06_ready.png',
    FestivalNotes.ready,
  ),
  FestivalPage(
    'gathering',
    'あつまると、もっと たのしい。',
    'assets/story/07_gathering.png',
    FestivalNotes.gathering,
  ),
  FestivalPage(
    'unfinished',
    'でも、これはまだ\nとちゅうの おはなし。',
    'assets/story/02_idea.png',
    FestivalNotes.unfinished,
    titleLayout: true,
  ),
];

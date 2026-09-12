import 'package:flutter/widgets.dart';

import 'speaker_notes.dart';

const festivalTitle = 'リスくんと もりのちいさなおまつり';
const eventUrl = 'https://flutterkaigi.connpass.com/event/401279/';
const eventDate = '2026年9月19日（土）';
const eventTime = '14:00〜17:00';
const eventVenue = '能楽堂ホール tenjin9';
const eventAddress = '〒700-0814 岡山県岡山市北区天神町9-24';

class FestivalPage {
  const FestivalPage(
    this.slug,
    this.title,
    this.asset,
    this.notes, {
    this.revealOrigin = const Alignment(0, 0.25),
  });
  final String slug;
  final String title;
  final String asset;
  final String notes;
  final Alignment revealOrigin;
}

const festivalPages = [
  FestivalPage(
    'title',
    'リスくんと\nもりのちいさなおまつり',
    'assets/story/01_cover.png',
    FestivalNotes.title,
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
  ),
];

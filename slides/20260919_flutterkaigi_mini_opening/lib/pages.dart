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
    notes: '''みなさん、こんにちは。FlutterKaigi mini、岡山へようこそ！
今日はご参加いただき、ありがとうございます。最初にFlutterKaigi運営から、私たちの活動と、今日の流れを5分ほどでご紹介します。''',
    sources: ['確認日: 2026-09-17', miniUrl],
  ),
  OpeningPage(
    kind: OpeningKind.about,
    route: '/about',
    title: 'FlutterKaigiとは',
    seconds: 40,
    notes: '''まず、FlutterKaigiについてです。FlutterやDartの知見を共有し、エンジニア同士が交流する、日本の技術カンファレンスです。Flutterエンジニアの有志による実行委員会が運営しています。

発表から新しい技術や開発の工夫を知る楽しさ。そして、Flutterが好きな仲間と、つくったものや試してみたことを語って盛り上がる楽しさ。そんな楽しさが詰まった場所です。「それ、面白いね！」と話しているうちに、周りの熱を感じて、自分も何かつくりたくなる。今日のminiでも、そんなワクワクをみんなで分かち合えたらうれしいです。''',
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
    notes: '''今年のFlutterKaigiは、10月29日、木曜日と、30日、金曜日の2日間です。会場は東京の浜松町コンベンションホールです。

テーマは「会って、話して、熱くなる。Assemble」。今年はFlutterNinjasと合流して、国内外のFlutterエンジニアが集まるイベントになります。

セッションを聞いて終わりではなく、その場で気になったことを話したり、開発の経験を交換したり、会場だからこそ生まれるつながりを楽しんでいただきたいと思っています。今日、岡山で出会ったみなさんと、秋には浜松町でもお会いできるとうれしいです。詳しいプログラムは公式サイトでご覧いただけます。''',
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
    notes: '''チケットは現在販売中です。一般チケットは税抜き1万2,000円です。参加を考えている方は、こちらのQRコードから販売ページをご確認ください。

学生のみなさんには、無料で参加できるスカラシップ制度があります。利用条件や申し込み方法がありますので、販売ページから制度の詳細をご覧ください。

また、FlutterKaigiを応援してくださる方向けに、税抜き1万5,000円からの個人スポンサーチケットも用意しています。どのチケットが自分に合うか、ぜひ一度チェックしてみてください。周りに興味のありそうな方がいれば、開催情報を共有してもらえるとうれしいです。''',
    sources: ['確認日: 2026-09-17', ticketsUrl, eventUrl],
  ),
  OpeningPage(
    kind: OpeningKind.volunteer,
    route: '/volunteer',
    title: 'ボランティアスタッフ募集中',
    seconds: 40,
    notes: '''そして、今年のFlutterKaigiを一緒につくる当日ボランティアスタッフを募集しています。

参加者として楽しむことに加えて、イベントを支える側にも興味がある、運営の人たちと関わってみたい。そんな方に、ぜひ知っていただきたい募集です。みんなで集まる場を、一緒につくっていけたらと思っています。

募集の詳しい内容や応募方法は、こちらのQRコードから公式の案内をご覧ください。まずは内容を読んで、自分に合いそうか見てもらえれば大丈夫です。少し気になったという方は、今日のFlutterKaigi運営にも、ぜひ声をかけてください。''',
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
    notes: '''ここからは、今日のFlutterKaigi miniについてです。miniは、年に一度のカンファレンスだけでなく、年間を通して、いろいろな地域で集まることを目指しているミニイベントです。

今回は第6回。岡山.Flutterのみなさんとの共催で、ここ、能楽堂ホールtenjin9で開催します。今日は能舞台の上で発表を聞ける、ちょっと特別な機会でもあります。

Flutterを普段の仕事で使っている方も、趣味で触っている方も、これから始めたい方も、学生のみなさんも歓迎です。詳しいかどうかを気にせず、気になったことを話してみてください。セッションやLT、休憩の時間を通して、この地域でFlutterの話ができる仲間と出会ってもらえたらうれしいです。''',
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
    notes: '''今日の前半の流れです。このあと協賛のご紹介を挟み、14時15分からフナモトさんの、Flutterとヘルスケアのセッションです。

14時40分からは、はりねずみさんの「ダイヤが欲しかっただけなのに、なぜかFlutterを書いています。」。続いて、よわよわエンジニアさんの、Flutter初学者が知っておくべきことについてのLTです。

【進行確認用・読み上げ不要】
13:30 開場
14:00–14:10 オープニング（会場案内 / FlutterKaigi 並びに FlutterKaigi mini について・運営）
14:10–14:15 協賛のご紹介
14:15–14:40 Flutter × ヘルスケア 〜 ネイティブコード０への挑戦 〜 / フナモト さん
14:40–14:50 ダイヤが欲しかっただけなのに、なぜかFlutterを書いています。 / はりねずみ さん
14:50–15:00 Flutter初学者が知っておくべき◯個のこと / よわよわエンジニア さん''',
    sources: ['確認日: 2026-09-17（公式connpass本文をブラウザで確認）', miniUrl],
  ),
  OpeningPage(
    kind: OpeningKind.timelineLater,
    route: '/timeline-later',
    title: '今日のタイムライン · 後半',
    seconds: 25,
    notes: '''続いて、kishisukeさんのFlutterとiOS 27とiPhone Duo、yakuranの「そのFlutterコード、なぜ書いた？」です。

休憩後はクイズイベント、16時からはアツシ@CodeRabbitさんの、AIコーディングエージェントとCodeRabbitのセッションです。最後にアンケートと写真撮影を行い、17時に完全撤収します。

【進行確認用・読み上げ不要】
15:00–15:10 FlutterとiOS 27とiPhone Duo / kishisuke さん
15:10–15:20 そのFlutterコード、なぜ書いた？ / yakuran さん
15:20–15:40 休憩
15:40–16:00 クイズイベント（FlutterKaigi / 岡山.Flutter / Flutterに関するクイズ・運営）
16:00–16:25 開発を高速化。AIコーディングエージェントとCodeRabbitでループエンジニアリング / アツシ@CodeRabbit さん
16:25–16:30 アンケートタイム
16:30– クロージング・写真撮影（運営）
17:00 完全撤収''',
    sources: ['確認日: 2026-09-17（公式connpass本文をブラウザで確認）', miniUrl],
  ),
  OpeningPage(
    kind: OpeningKind.handoff,
    route: '/handoff',
    title: 'Over to you, 岡山.Flutter!',
    seconds: 20,
    notes: '''FlutterKaigiからのご紹介は以上です。ここからの進行は、地元コミュニティの岡山.Flutterのみなさんにお渡しします。

今日はFlutterをきっかけに、たくさん話して、新しいつながりをつくってもらえたらうれしいです。それでは、岡山.Flutterのみなさん、よろしくお願いします！''',
    sources: ['確認日: 2026-09-17', miniUrl, communityUrl],
  ),
];

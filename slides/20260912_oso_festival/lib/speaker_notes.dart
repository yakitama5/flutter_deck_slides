/// 『リスくんと もりのちいさなおまつり』の発表用スピーカーノート。
///
/// 表紙と2場面で、おまつりの思いつきから現実の参加案内へつなぐ続編です。
abstract final class FestivalNotes {
  // 01: 外側の表紙
  static const frontCover = '''
ひとつの どんぐりから 広がった、リスくんの もり。
今日は、その つづきの お話です。
''';

  // 02: タイトル表紙
  static const title = '''
『リスくんと もりのちいさなおまつり』
''';

  // 03 / 本文01: おまつりを思いつく
  static const idea = '''
ある あさ、リスくんは 思いつきました。

「この もりで、なにか おまつりを したい！」
''';

  // 04 / 本文02: みんなを待つ
  static const ready = '''
ちいさな おまつりの 準備が できました。

「みんな、来てくれるかな〜。」
''';

  // 05: 絵本の裏表紙
  static const backCover = '''
この お話の つづきは、みんなが 集まってから。
''';

  // 06: 絵本から現実の FlutterKaigi mini 岡山へ
  static const event = '''
実は、私たちも岡山で、みんなの「おもしろい」が集まる場所を準備しています。
来週、FlutterKaigi mini が岡山で開かれます。

Flutterを知らない方向けの説明になりますが、FlutterKaigi miniとは、日本最大級のFlutterカンファレンスである「FlutterKaigi」とコラボした地方のコミュニティで開かれるFlutterの技術イベントです。
今回、いろんな方のご協力もあり、中四国初となる miniイベントを岡山で開けることになりました。

Flutterを知らない人も知ってる人も、「おもしろい」が見つけられる場所です。
詳しくは、こちらを ご覧ください。
https://flutterkaigi.connpass.com/event/401279/
''';

  // 07: 参加と継続を呼びかける
  static const invitation = '''
ですが、まだまだ参加人数が多いとは言えません。
「リスくんとひとつのどんぐり」でもお話しした小さなきっかけが見つかる場所だとおもうので、ぜひ あそびに 来てください。
お友だちも 誘ってもらえると うれしいです。
聞くだけでも、話してみても、誰かの 一言から「おもしろい」が 芽を出すかもしれません。

今回の絵本をハッピーエンドにするため、みなさんにもぜひご参加いただけると幸いです。
connpassから参加できますので、ぜひご検討ください！
https://flutterkaigi.connpass.com/event/401279/

画面には開催日時と会場も表示しています。
2026年9月19日（土）14:00〜17:00、能楽堂ホール tenjin9（〒700-0814 岡山県岡山市北区天神町9-24）です。
''';

  static const all = <String>[
    frontCover,
    title,
    idea,
    ready,
    backCover,
    event,
    invitation,
  ];
}

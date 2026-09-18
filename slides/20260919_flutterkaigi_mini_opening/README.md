# FlutterKaigi mini #6 @Okayama — オープニング

2026年9月19日の FlutterKaigi mini #6 向けに、FlutterKaigi運営が約5分で案内する FlutterDeck 資料です。イベント紹介から岡山.Flutterへの進行引き継ぎまで、9枚・合計300秒で構成しています。

## 起動

リポジトリルートで依存関係を取得してから、このパッケージで起動します。Flutterのバージョンはルートの `mise.toml` に従います。

```sh
mise x -- flutter pub get
cd slides/20260919_flutterkaigi_mini_opening
mise x -- flutter run -d chrome
```

発表原稿は [`lib/speaker_notes.dart`](lib/speaker_notes.dart)、スライドごとの目安時間と出典は `lib/pages.dart` にまとめています。原稿はFlutterDeckの発表者ノートにも表示されます。タイムラインの「進行確認用」は読み上げ時間に含めません。

## 構成

| スライド | 目安 |
| --- | ---: |
| FlutterKaigi mini #6 @Okayama | 15秒 |
| FlutterKaigiとは | 40秒 |
| FlutterKaigi 2026 | 45秒 |
| チケットのご案内 | 40秒 |
| ボランティアスタッフ募集中 | 40秒 |
| FlutterKaigi miniとは | 45秒 |
| 今日のタイムライン · 前半 | 30秒 |
| 今日のタイムライン · 後半 | 25秒 |
| Over to you, 岡山.Flutter! | 20秒 |
| **合計** | **300秒** |

## デザイン

Materialを基調に、短い見出し、画像、Card、QRコードで案内します。配色はユーザー提供の FlutterKaigi mini #6 @Okayama の表紙に合わせています。

| 用途 | 色 |
| --- | --- |
| 基調・濃色背景 | `#082B55` |
| 暖色アクセント・グラデーション始点 | `#FF7163` |
| 暖色アクセント・グラデーション終点 | `#FFEA70` |
| 補助アクセント | `#20D3BD` |

紺色を軸に、コーラルから黄色へのグラデーションとターコイズを使います。本文は白系の背景とCardで読みやすくし、文字量を抑えて詳しい説明を発表者ノートに記載します。単独のFlutterKaigiロゴと2026メインビジュアルは使用しません。FlutterKaigi 2026 の紹介は開催日・テーマ・会場のCardで構成し、浜松町コンベンションホールの公式写真を添えています。

THIS YEARのTHEMEカードのみ、2026メインビジュアルに合わせた左上から右下へのグラデーション（`#FF0055` → `#6200EA` → `#001155`）を使います。中間の紫は40〜60%の範囲で固定し、文字は白で表示します。

## 事実確認と出典

確認日: **2026-09-17**。資料の紹介文は、次の公式情報をもとに発表用に再構成しています。

| 内容 | 出典・確認範囲 |
| --- | --- |
| FlutterKaigiの目的 | [公式ドキュメント](https://docs.flutterkaigi.jp/)・[公式connpass](https://flutterkaigi.connpass.com/)。Flutter / Dartの知見共有とエンジニア間の交流 |
| 2026年の開催日・会場・テーマ | [2026公式サイト](https://2026.flutterkaigi.jp/)。10月29〜30日、浜松町コンベンションホール、Assemble |
| 2026年の会場写真 | [浜松町コンベンションホール公式フォトギャラリー](https://www.hmc.conventionhall.jp/facility/#photo)。メインホールの実写（会場レイアウト例） |
| チケット・FlutterNinjasとの合流 | [公式Luma](https://luma.com/flutterkaigi2026?locale=ja)。一般12,000円（税抜）、個人スポンサー15,000円〜（税抜）、学生は無料制度の案内あり |
| 当日ボランティア募集 | [公式サイトのお知らせ](https://2026.flutterkaigi.jp/)・[公式募集記事](https://medium.com/flutterkaigi/flutterkaigi-2026-day-of-volunteer-staff-recruitment-9f31ddbad09e)。募集告知の掲載とリンク先を確認 |
| miniの趣旨・岡山開催・タイムライン | [今回の公式connpass](https://flutterkaigi.connpass.com/event/401279/)。2026-09-17にブラウザで最新本文を確認。第6回、岡山.Flutter共催、能楽堂ホールtenjin9、登壇者・発表タイトル・各時刻 |
| 岡山.Flutter | [コミュニティ公式connpass](https://okayama-dot-flutter.connpass.com/) |

### 確認範囲の制約

- ボランティア募集は公式サイトからの告知リンクを確認できましたが、Medium本文は取得できませんでした。応募条件、締切、特典、費用支給などは資料で断定せず、公式募集記事へ案内します。
- 学生の無料参加には制度の条件があります。一般チケットの購入と同じ手続きで無条件に参加できるとは扱いません。
- チケットの料金・販売状況、学生制度、ボランティア募集、当日のタイムラインは、登壇前に公式ページで再確認してください。変更があれば画面の表示と `lib/speaker_notes.dart` のノートと `lib/pages.dart` の出典を合わせて更新します。

miniの表紙にはユーザー提供のイベント画像を参照し、mini紹介スライドでも同画像を使用します。ボランティア募集にはユーザー提供の集合写真 `IMG_0936.jpg` を使用します。

## 検証とWebビルド

このパッケージのディレクトリで実行します。

```sh
mise x -- flutter analyze --no-pub
mise x -- flutter test --no-pub --dart-define=RENDER_SLIDES=true
mise x -- flutter build web --no-pub
```

テストでは全9枚を16:9・ノートPC・縦長スマートフォンの画面サイズで描画し、
画像の読み込み完了、レイアウト例外、キーボードでの往復操作を確認します。
`RENDER_SLIDES=true` を指定すると `build/previews/01.png`〜`09.png` も生成します。
縦長画面では16:9の資料を全体表示するため、発表時は横向き・全画面表示を推奨します。

イベント画像・写真・フォントは同梱しています。素材の出典は [assets/README.md](assets/README.md) に記載しています。

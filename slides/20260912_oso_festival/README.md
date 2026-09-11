# リスくんと もりのちいさなおまつり

『リスくんと ひとつのどんぐり』の続編です。リスくんが思いついた小さなおまつりを、うさぎさん・くまさん・はりねずみさんと準備していく12枚のFlutterDeckです。絵本パートは共通のStorybook演出、イベント案内パートは通常のスライド遷移で表示します。

## スライドの順序と画面テキスト

外側の前カバー、本文8枚、後ろカバー、イベント案内、参加案内の順です。

| No. | キー | 画面テキスト・内容 |
| ---: | --- | --- |
| 1 | `frontCover` | `リスくんと\nもりのちいさなおまつり`（前カバー） |
| 2 | `title` | `リスくんと\nもりのちいさなおまつり` |
| 3 | `idea` | `この もりで、おまつりを。` |
| 4 | `alone` | `あれも、これも。……あれれ？` |
| 5 | `friends` | `「いっしょに やろう！」` |
| 6 | `preparation` | `それぞれの できることを。` |
| 7 | `ready` | `ちいさな おまつりが、かたちに。` |
| 8 | `gathering` | `あつまると、もっと たのしい。` |
| 9 | `unfinished` | `でも、これはまだ\nとちゅうの おはなし。`（本文背景に前カバー絵を再使用） |
| 10 | `backCover` | 絵本の後ろカバー。画面に本文テキストは載せず、Deckタイトルは `つづきは、わたしたちの もりで。` |
| 11 | `event` | `ここからは、わたしたちの おはなし。`／`来週、岡山で。`／`FlutterKaigi mini 岡山`／`みんなの おかげで、\nひらけることに なりました。` |
| 12 | `invitation` | `まだまだ、ちいさな はじまり。`／`いっしょに、大きくしていこう。`／`あそびに 来てください。\nだれかを 誘ってください。`／`FlutterKaigi mini 岡山`／`https://flutterkaigi.connpass.com/event/401279/` |

## スピーカーノート

ノートは、前作の一粒から続く物語として始まり、ひとりの思いつき、仲間との準備、リスくんが思い描いたおまつり、そして「まだ途中のお話」へ進みます。後ろカバーで現実の話へ切り替え、FlutterKaigi mini 岡山への案内と、みんなで次のきっかけを育てる呼びかけで終わります。集まる場面はリスくんの想像上の物語として扱い、現実のイベントが開催済みだとは説明しません。

全文は [`lib/speaker_notes.dart`](lib/speaker_notes.dart) を参照してください。

## 起動

リポジトリのルートで依存関係を取得し、Melosの選択画面でこのパッケージを選びます。

```sh
dart pub get
dart run melos run dev
```

選択後は Chrome で `slides/20260912_oso_festival` が起動します。Web成果物を確認するときは、ルートで `dart run tool/build_web.dart` を実行します。

## QRコードとイベントバナー

`pubspec.yaml` は `assets/event/` 全体を登録しています。次のファイルを配置すると、再ビルド時に画面へ差し込まれます。

- `assets/event/qr.png`: 正方形のQRコード。12枚目の参加案内に表示します。四辺の白い余白を残してください。
- `assets/event/banner.png`: イベントバナー。11枚目に縦横比を保って表示します。

未配置の場合も発表できるよう、QR欄は「参加のお申し込み」、バナー欄は `assets/story/06_ready.png` にフォールバックします。ファイルを追加・差し替えした後は `dart pub get` と再ビルド（開発中は再起動）を行ってください。

## 参照原画と流用

前作の原画は [`../20260912_oso/assets/risukun_hitotsu_no_donguri/`](../20260912_oso/assets/risukun_hitotsu_no_donguri/) を参照しています。新デッキで使う対応は次のとおりです。

| 新デッキの画像 | 参照・扱い |
| --- | --- |
| `assets/story/02_idea.png` | 前作 `06_page06.png` を無加工コピー |
| `assets/story/04_friends.png` | 前作 `07_page07.png` のうさぎ原画を無加工コピー |
| `assets/story/07_gathering.png` | 前作 `08_page08.png` を無加工コピー |
| `assets/story/01_cover.png` | 新規作成。`title` の表紙絵として使用 |
| `assets/story/03_alone.png` | 新規作成 |
| `assets/story/05_preparation.png` | 新規作成 |
| `assets/story/06_ready.png` | 新規作成。イベントバナー未配置時のフォールバックにも使用 |
| `unfinished` | `assets/story/01_cover.png` を明るい表紙背景として再使用 |

参加案内の左側にも `07_gathering.png` を挿絵として再使用しています。

## 差分方針

- 前作 [`slides/20260912_oso`](../20260912_oso/) のコード・画像・設定は変更しません。
- ページめくり、紙面リビール、前後カバーの開閉、効果音は共通パッケージ `flutter_deck_storybook` の演出を同じ方針で使用します。
- 構成は12枚（前カバー + 本文8枚 + 後ろカバー + `event` + `invitation`）に固定します。

イベントページはアクセス時のbot対策で本文を確認できないため、具体的な日時・会場は記載していません。発表時点の文脈に合わせて、画面の時期表現はユーザー指定どおり `来週、岡山で。` に固定しています。案内先は [FlutterKaigi mini 岡山のページ](https://flutterkaigi.connpass.com/event/401279/) です。

### 画風の固定基準

最優先のアンカーは [`cover_master.png`](../2026_oso_risukun_hitotsu_no_donguri/generation/refs/cover_master.png) と [`page01_master.png`](../2026_oso_risukun_hitotsu_no_donguri/generation/refs/page01_master.png) です。前者でリスくんの顔・体型・黒い目・巻いたしっぽ・赤いバンダナと森の色を固定し、後者でうさぎさんの顔と青いバンダナを固定しています。共同作業と完成場面は前作 `08_page08.png` の広場・くまさん・はりねずみさんを補助参照にしました。

内蔵 image_gen に渡した4点分のプロンプトと参照順は [`refs/image_prompts.json`](refs/image_prompts.json)、採用画像の由来とSHA-256は [`refs/asset_manifest.json`](refs/asset_manifest.json) に保存しています。参照原画は元の場所に残し、重複した refs 画像は追加していません。

表示は1920×1080の16:9、文字は前作同梱のKiwi Maruです。画像内への新しい文字の焼き込みはありません。画面テキストは `lib/pages.dart`、案内レイアウトは `lib/widgets.dart` で編集できます。

## 確認用プレビュー

![全12枚の表示一覧](refs/slide_preview.jpg)

## 追加・修正ファイル

- ルート `pubspec.yaml`: 新デッキをworkspaceへ登録
- ルート `README.md`: 新デッキへの入口
- このディレクトリの `pubspec.yaml` / `analysis_options.yaml` / `web/index.html`: アプリ定義
- `lib/main.dart`: 12枚の並びと共通演出
- `lib/pages.dart`: 本文テキスト・画像・案内URL
- `lib/speaker_notes.dart`: 全12枚の読み上げ草案
- `lib/widgets.dart`: 絵と文字の配置、QR/バナー領域
- `assets/story/`: 画像7点（新規4点、無加工流用3点）
- `assets/fonts/`: 前作から引き継いだKiwi Maru 2種
- `assets/event/README.md`: QR・バナーの挿入手順
- `refs/image_prompts.json` / `asset_manifest.json` / `slide_preview.jpg`: 参照記録と確認用画像
- `test/deck_test.dart`: 全ページ移動と画像差し込みの確認
- `README.md`: 構成と運用方法

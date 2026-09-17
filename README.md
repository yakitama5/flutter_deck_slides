# flutter_deck_slides

[flutter_deck](https://pub.dev/packages/flutter_deck) で作成するスライド資料を、
Pub Workspace + [melos](https://melos.invertase.dev/) で複数管理する monorepo です。

FlutterKaigi mini #6 @Okayamaの[オープニング資料](slides/20260919_flutterkaigi_mini_opening/README.md)を
`slides/20260919_flutterkaigi_mini_opening` に追加しています。
miniイベントの紺色と暖色アクセント、MaterialのCardを使った全9枚・約5分の資料です。

詳細な設計・意思決定の経緯は [docs/IMPLEMENTATION_PLAN.md](docs/IMPLEMENTATION_PLAN.md) を参照してください。

FlutterKaigi mini 向けの [だしゅまる3Dデモ](slides/20260919_flutterkaigi_mini/README.md) を
`slides/20260919_flutterkaigi_mini` に追加しています。FlutterSceneで描画し、
歩行・ジャンプ・バイバイ・まばたきを再生できます。GLBと生成ソースは暗号化して管理し、
[モデルの復元手順](docs/private-assets.md)に沿って準備するとWeb / macOSで起動できます。

同イベントのLT「そのFlutterコード、なぜ書いた？」は、
[構成と起動方法](slides/20260919_flutterkaigi_mini_lt/README.md)・
[読み上げ原稿](slides/20260919_flutterkaigi_mini_lt/SCRIPT.md)から確認できます。
Noto Sans JPとイベントカラーの濃紺を基調にしたMaterialテーマで、全17場面に3Dだしゅまるのデモと演出を組み込んでいます。

技術選定の絵本LT「リスくんと ぴったりのかご」は、
[スライド](https://yakitama5.github.io/flutter_deck_slides/202609_technologychoice/)と
[読み上げ原稿・時間配分](slides/202609_technologychoice/SCRIPT.md)から確認できます。

選定理由を章ごとに紹介するスライド版「技術選定に 自分の理由を」も追加しています。
[スライド](https://yakitama5.github.io/flutter_deck_slides/202609_technologychoice_reasons/)では、
青と紫の紙面に、配色・画面幅・Slangの動くFlutterサンプルを並べています。
[構成と起動方法](slides/202609_technologychoice_reasons/README.md)・
[読み上げ原稿](slides/202609_technologychoice_reasons/SCRIPT.md)を参照してください。

## ディレクトリ構成

```
slides/<yyyymm>_<event>/   各スライド資料(Flutter アプリ, Web 専用)
packages/<name>/           スライド間で共有する共通パッケージ(必要になったら追加)
tool/                       melos scripts から呼び出す Dart 製の補助スクリプト
```

## セットアップ

このリポジトリでは Flutter SDK のバージョン管理に [mise](https://mise.jdx.dev/) を使用します(FVM は使いません)。

```sh
mise install       # mise.toml にピンされた Flutter SDK を導入
dart pub get       # ワークスペース全パッケージの依存解決(ルートに 1 つの pubspec.lock)
```

`mise install` 後、`flutter` / `dart` コマンドが使えることを確認してください。

だしゅまるを含むテストやビルドの前には、[非公開アセットの復元](docs/private-assets.md)が必要です。

```sh
mise x -- flutter doctor
```

IDE(VS Code / Android Studio)の Flutter SDK パスは、以下で取得したパスを設定してください。

```sh
mise where flutter
```

## コマンド一覧(すべてリポジトリルートから実行)

melos は `dev_dependencies` に含まれているため `dart run melos <command>` で実行します。

| コマンド | 内容 |
|---|---|
| `dart run melos run dev` | スライドを選択して Chrome で起動(発表・確認はすべて Web) |
| `dart run melos run build:web` | 全スライドを web ビルド(`slides/<name>/build/web` に出力) |
| `dart run melos run analyze` | 全パッケージを `dart analyze` |
| `dart run melos run format` | 全パッケージを `dart format` でチェック |
| `dart run melos run test` | `test/` を持つパッケージのみ `flutter test` |
| `dart run melos run create:slide -- <yyyymm>_<event>` | 新規スライドの雛形を作成 |

`dart pub global activate melos` 済みであれば `melos <command>`(`dart run` 省略)でも同様に実行できます。

## 新規スライドの作り方

```sh
dart run melos run create:slide -- 202609_flutterkaigi
```

- ディレクトリ名は `<yyyymm>_<event>`(例: `202609_flutterkaigi`)
- パッケージ名は Dart の識別子制約(数字始まり不可)により `<event>_<yyyymm>`(例: `flutterkaigi_202609`)に自動変換されます
- 実行すると以下が自動で行われます
  1. `flutter create --platforms=web` でプロジェクト生成
  2. `pubspec.yaml` に `resolution: workspace` と `flutter_deck` / `flutter_deck_web_client` を設定
  3. `flutter_deck` の絵本風雛形(表紙・本文・結びの3ページ)で `lib/main.dart` を置換
  4. `analysis_options.yaml` をルート共通設定への include に置換
  5. ルート `pubspec.yaml` の `workspace:` リストへ追記(Pub Workspace は glob 非対応のため)
  6. `dart pub get` で bootstrap

## 絵本風ページめくりテンプレート

`slides/example` と新規作成されるスライドには、共通パッケージ
`packages/flutter_deck_storybook` が組み込まれています。

- `StorybookPageTurnTransitionBuilder`: 16:9のスライド全体を1枚の紙として扱い、40×16の両面三角形メッシュで紙面を曲げます。進む時は右端の横中央へ手を掛けたような横長の隆起を作り、その隆起を内側へ走らせてから加速します。90度を越えた面は絵を反転せず、白い紙裏として描きます。戻る時は旧ページを逆向きに剥がさず、別の時間曲線で前ページを上層から被せ、減速しながら平らに戻します。`enableBookOpening` / `enableBookClosing` を有効にすると、先頭の前カバーから複数枚をパラパラめくって本文へ入り、末尾の後ろカバーで本を閉じられます
- `StorybookBookCover`: 本文ページとは別の前カバー・後ろカバーを描画します。本文の薄紙メッシュとは分けた厚紙の平面回転で、開始時は本を少し引いて表示し、終了時はテーブルを含む全体へ引いて着地します。後ろカバーを最後のスライドに置くと、閉じた本を最終フレームとして残せます
- `StorybookPage`: 紙色、表紙色、アクセント色、余白、ページ番号を変更できる絵本風のページ枠。ページがめくれた後は、白紙の上にセピア色の下描きが現れ、中央下寄りから水彩・インクがにじむように完成絵を描き出します
- `StorybookSoundEffects`: ページ回転には乾いた紙音、線画が現れ始める位置には鉛筆と筆の音を同期します。音量変更・一時ミュートが可能で、音声ファイルは共通パッケージ内に同梱されます
- 視差効果を減らす設定が有効な環境では、ページ回転をフェードへ自動的に切り替えます
- 3D描画に問題がある環境では、`usePerspective: false` でスライド＋クロスフェードへ明示的に切り替えられます

デッキ全体に適用する場合は、移動方向を追跡できるよう、同じトランジションインスタンスを再利用します。

```dart
final storybookSounds = StorybookSoundEffects();

final pageTurnTransition = FlutterDeckTransition.custom(
  duration: StorybookPageTurnTransitionBuilder.referenceTurnDuration,
  transitionBuilder: StorybookPageTurnTransitionBuilder(
    usePerspective: true,
    pageFlex: 0.56,
    pageTwist: 0.035,
    turnSoundCueProgress: 0.42,
    enableBookOpening: true,
    enableBookClosing: true,
    bookPageCount: 5,
    enableInkReveal: true,
    inkRevealDuration: Duration(milliseconds: 2750),
    inkRevealOrigin: Alignment(0, 0.25),
    soundEffects: storybookSounds,
  ),
);

FlutterDeckApp(
  configuration: FlutterDeckConfiguration(
    transition: pageTurnTransition,
  ),
  // ...
);
```

開始・終了の本演出を使う場合は、スライド一覧の先頭に前カバー、末尾に
`StorybookBookCover(backCover: true)` を置きます。`openingTargetSlideNumber` は既定値の
2で前カバー直後の本文ページを指し、終了先は既定で最後のスライドです。

Webの効果音は、ブラウザの自動再生制限に従い、矢印キーやタップなどのユーザー操作でページを移動した時に再生されます。音が不要なデッキは `soundEffects` を省略してください。`storybookSounds.enabled = false` で一時ミュートもできます。「視差効果を減らす」が有効な場合は演出と一緒に効果音も停止します。

16:9の完成画像を1枚の紙として使う場合は、`StorybookPage` の余白をなくして画像を全面に配置できます。

```dart
StorybookPage(
  outerPadding: EdgeInsets.zero,
  contentPadding: EdgeInsets.zero,
  borderRadius: 0,
  showPageNumber: false,
  child: Image.asset('assets/page.png', fit: BoxFit.cover),
)
```

## 発表方法(Presenter View)

各スライドは `flutter_deck_web_client` を使用しており、`localStorage` を介してブラウザのタブ間で状態が同期されます(サーバー不要)。

1. `dart run melos run dev` でスライドを選択して Chrome を起動
2. 同じブラウザで別タブを開き、同じ URL にアクセスすると presenter view として同期動作します

## 共通パッケージの追加

スライド間で共通化したいコード(テーマ、共通ウィジェットなど)が出てきたら `packages/` 配下に切り出します。

```sh
flutter create --template=package packages/<name>
```

1. 生成された `pubspec.yaml` に `resolution: workspace` を追加
2. ルート `pubspec.yaml` の `workspace:` リストに `packages/<name>` を追記
3. 利用したいスライド側の `pubspec.yaml` の `dependencies` に `<name>: any` を追加(ワークスペース内はパス解決されます)

## 重要な制約

- Pub Workspace は依存解決が単一の `pubspec.lock` に統合されるため、**flutter_deck のバージョンはワークスペース全体で 1 つに揃います**。過去のスライドを古いバージョンのまま凍結したい場合は、そのパッケージを `workspace:` リストから外して独立解決にする必要があります(詳細は実装計画ドキュメント参照)。

## CI / デプロイ

- `.github/workflows/ci.yaml`: push / PR で analyze・format・test・build を実行。Webに影響するPRではプレビュー成果物も作成
- `.github/workflows/deploy.yaml`: `main` への push で全スライドの本番用Web成果物を作成
- `.github/workflows/publish-pages.yaml`: ビルド成功後、本番と各PRの成果物をまとめてGitHub Pagesへ公開
  - 公開 URL: `https://yakitama5.github.io/flutter_deck_slides/<slide_name>/`
  - スライド一覧ページ: `https://yakitama5.github.io/flutter_deck_slides/`

### PRごとのWebプレビュー

同じリポジトリのブランチから `main` 向けにPRを作成すると、CI成功後に
PRの **View deployment**（環境名 `pr-<PR番号>`）からプレビューを開けます。
URLはPR更新後も同じです。公開ジョブのActions Summaryにもリンクを表示します。

```text
https://yakitama5.github.io/flutter_deck_slides/previews/pr-<PR番号>/
https://yakitama5.github.io/flutter_deck_slides/previews/pr-<PR番号>/<slide_name>/
```

- `slides/` 内の変更は該当スライドをプレビューします。`packages/`、ビルドツール、ワークフロー、依存設定の変更では全スライドを対象にします。
- Webに関係しないルートのドキュメントだけの変更ではプレビューを作りません。
- PRにコミットを追加すると再公開します。ビルド中や失敗時は直前に成功した表示が残るため、Deploymentに記録されたコミットを確認してください。
- PRをマージ／クローズするとプレビューを削除し、Deploymentを終了状態にします。本番と他のPRは維持します。
- forkからのPRはCIのみ実行し、プレビューの自動公開は対象外です。

公開先の設定はGitHub **Settings → Pages → Source: GitHub Actions** です。
追加のPATや外部ホスティングは不要で、ジョブごとに権限を限定した `GITHUB_TOKEN` を使用します。
公開専用の `gh-pages` ブランチに静的成果物を保持し、`main` には生成済みWebファイルを追加しません。
PRコードを実行するビルドと、`main` のコードだけを実行する公開処理を分離しています。

Pagesはサイト全体で1 GBまでのため、公開前に950 MBの上限を検証します。
CanvasKit専用のJSビルドでは、未使用のSkwasm・Wimpと描画エンジンのシンボルファイルを配信対象から外します。
Wasmを含むビルド、構成を判定できないビルド、旧オフラインキャッシュを使うビルドでは保持します。
容量超過時は不要なPRを閉じてから公開ジョブを再実行してください。
ビルド成果物のActions保存期間は7日ですが、一度公開したプレビューはPRを閉じるまで保持します。

復旧時は **Publish GitHub Pages → Run workflow** を使用できます。
`build_run_id` に成功した **CI** または **Build production web** の実行IDを指定すると再公開し、
空欄なら保存済みサイトの再公開と終了済みPRの削除を行います。初回は本番ビルドを先に公開します。

ローカルでも同じ公開パスを再現できます。両コマンドには同じ環境変数を渡してください。

```sh
export WEB_BASE_PATH=/flutter_deck_slides/previews/pr-123
export WEB_SLIDES=20260919_flutterkaigi_mini
export PR_NUMBER=123
dart run tool/build_web.dart
dart run tool/prepare_pages.dart
```

## 絵本LT「リスくんと もりのちいさなおまつり」

OSO懇親会向けの続編を `slides/20260912_oso_festival` に追加しています。
[構成・スピーカーノート・画像の由来・QR差し込み手順](slides/20260912_oso_festival/README.md)を参照してください。

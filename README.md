# flutter_deck_slides

[flutter_deck](https://pub.dev/packages/flutter_deck) で作成するスライド資料を、
Pub Workspace + [melos](https://melos.invertase.dev/) で複数管理する monorepo です。

詳細な設計・意思決定の経緯は [docs/IMPLEMENTATION_PLAN.md](docs/IMPLEMENTATION_PLAN.md) を参照してください。

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

- `.github/workflows/ci.yaml`: push / PR で analyze・format・test・build を実行
- `.github/workflows/deploy.yaml`: `main` への push で全スライドを web ビルドし、GitHub Pages へデプロイ
  - 公開 URL: `https://yakitama5.github.io/flutter_deck_slides/<slide_name>/`
  - スライド一覧ページ: `https://yakitama5.github.io/flutter_deck_slides/`

# flutter_deck スライド monorepo 構築 実装計画

作成日: 2026-07-06 / 対象リポジトリ: `yakitama5/flutter_deck_slides`

## 目的

`flutter_deck` で作成するスライド資料を **Pub Workspace + melos 7** の monorepo 構成で複数管理する。

- 各スライドは `slides/<name>` パッケージとして管理
- 共通コードは `packages/<name>` に配置
- Web でのプレゼンテーション(+ presenter view)に対応
- 起動・ビルド等のコマンドは melos scripts に集約し、ディレクトリ移動不要でルートから実行できるようにする
- Flutter SDK のバージョン管理は **mise** で行う(FVM は使わない)

## 決定事項(2026-07-06 ユーザー確認済み)

| 論点 | 決定 |
|---|---|
| スライド命名規則 | ディレクトリ名 `slides/<yyyymm>_<イベント名>`(例: `slides/202609_flutterkaigi`)。パッケージ名は数字始まり不可のため `<イベント名>_<yyyymm>`(例: `flutterkaigi_202609`)。`slides/example` のみ規則外のサンプルとして常設 |
| GitHub Pages | **初期構築に含める**(deploy.yaml + スライド一覧 index ページ生成まで)。リポジトリを public にすることが前提 |
| 対象プラットフォーム | **Web のみ**(`flutter create --platforms=web`)。発表・確認とも Chrome で行う。デスクトップ対応は必要になったら追加 |
| 共通テーマパッケージ | 初期構築では**作らない**。`packages/` は `.gitkeep` のみ。2 本目以降で共通化ニーズが見えたら切り出す |

## 現状と環境

| 項目 | 状態 |
|---|---|
| リポジトリ | `flutter create` 直後のテンプレートアプリがルートに存在。**git 未初期化** |
| mise | `2026.6.10` インストール済み。`flutter` プラグイン利用可 |
| Dart SDK | ルート pubspec は `^3.12.2`(現行 stable 相当) |
| melos | 最新は v7 系(7.3.x)。**melos.yaml は廃止され、設定はルート pubspec.yaml の `melos:` キーに集約** |
| Flutter stable | **3.44.4**(`mise ls-remote flutter` で確認済み、2026-07-06 時点) |
| flutter_deck | 最新 `0.29.0`。presenter view 用の `flutter_deck_web_client` は `0.4.0`(localStorage でタブ間同期、サーバー不要、Web 専用) |

## 最終ディレクトリ構成

```
flutter_deck_slides/
├── mise.toml                  # Flutter SDK バージョンピン(リポジトリ全体で共通)
├── pubspec.yaml               # ワークスペースルート(workspace: / melos: / dev_dependencies: melos)
├── pubspec.lock               # ルートに1つだけ生成される(各パッケージには作られない)
├── analysis_options.yaml      # 共通 lint 設定(各パッケージから include)
├── README.md
├── docs/
│   └── IMPLEMENTATION_PLAN.md # 本ドキュメント
├── tool/
│   └── create_slide.dart      # スライド雛形生成スクリプト(Phase 5)
├── slides/
│   └── example/               # 最初のサンプルスライド(Flutter app / web 有効)
│       ├── pubspec.yaml       #   resolution: workspace + flutter_deck 依存
│       ├── lib/main.dart      #   FlutterDeckApp
│       └── web/ ...
├── packages/                  # 共通パッケージ置き場(必要になったら追加。初期は .gitkeep のみ)
└── .github/
    └── workflows/
        ├── ci.yaml            # analyze / test / build
        └── deploy.yaml        # GitHub Pages デプロイ(任意フェーズ)
```

## 設計上の重要な注意点(先に合意しておくこと)

1. **Pub Workspace は依存解決が単一**
   ワークスペース内の全パッケージは 1 つの `pubspec.lock` に解決される。つまり **flutter_deck のバージョンはワークスペース全体で 1 バージョンに揃う**。「スライドごとにバージョン差異を許容」は「各 pubspec の制約(`^0.29.0` 等)が互いに互換な範囲で」のみ成立する。
   - 過去スライドを古い flutter_deck のまま凍結したい場合: そのパッケージから `resolution: workspace` を外し、ルートの `workspace:` リストからも除外して独立解決にする(独自 lockfile を持つ)。ただし melos の一括コマンド対象からは外れるため、専用スクリプト(`melos exec` ではなく `--directory` 指定の raw コマンド)で補う。
   - 基本方針は「全スライドを最新 flutter_deck に追従させる」を推奨。
2. **`workspace:` キーは glob 非対応**
   スライド追加のたびにルート pubspec.yaml へ手動追記が必要。→ Phase 5 の `create:slide` スクリプトで自動追記させる。
3. **melos scripts は Windows では cmd.exe、それ以外では sh で実行される**(公式ドキュメントで確認済み)
   → スクリプト文字列内の `$MELOS_PACKAGE_NAME` 等の `$` 展開は Windows で動かない。**環境変数や条件分岐が必要な処理はすべて `tool/*.dart` に書き、melos からは `dart run` で呼ぶ**。melos が子プロセスに渡す `MELOS_*` 環境変数は Dart 側で `Platform.environment` から読める。
4. **melos の対話的パッケージ選択(確認済み)**
   `packageFilters` 付きスクリプトは実行時に対象パッケージの選択プロンプトが出る。全パッケージ一括実行は `--no-select`。これを「スライドを選んで起動」の UX として利用する。

---

## Phase 0: 事前準備

1. `git init` + 初回コミット(以降のフェーズを差分管理できるように)
2. `.gitignore` を monorepo 向けに確認(`flutter create` 生成のものをベースに、ルート `pubspec.lock` はアプリのみのリポジトリなのでコミットする方針)
3. `.github/modernize/` は本プロジェクトと無関係の残骸のため削除候補(ユーザー確認のうえ)

## Phase 1: mise によるツールチェーン定義

1. ルートに `mise.toml` を作成:
   ```toml
   [tools]
   flutter = "3.44.4"   # 2026-07-06 時点の最新 stable。実装時に mise ls-remote flutter で再確認
   ```
   - Dart は Flutter SDK に同梱のものを使う(dart を別途ピンしない)
   - mise の flutter は `http:`/`vfox:` バックエンド提供のため **Windows でも動作する**(`mise ls-remote flutter` が本環境で動作することを確認済み)
2. `mise install` で SDK を導入し、`mise x -- flutter --version` で確認
3. README に「初回セットアップ = `mise install` → `dart pub get` → `dart run melos bootstrap`」を明記
4. IDE 向け注記: VS Code / Android Studio の Flutter SDK パスは mise の shims / installs 配下を指す設定が必要(`mise where flutter` で取得)

## Phase 2: ルートをワークスペース化(既存テンプレートの整理)

1. ルートの Flutter アプリ一式を削除:
   `lib/`, `test/`, `android/`, `ios/`, `linux/`, `macos/`, `windows/`, `web/`, `pubspec.lock`, `.metadata`, `flutter_deck_slides.iml`, `.idea/`(IDE 再生成に任せる)
2. ルート `pubspec.yaml` を全面置き換え:
   ```yaml
   name: flutter_deck_slides_workspace
   publish_to: none

   environment:
     sdk: ^3.12.2

   workspace:
     - slides/example

   dev_dependencies:
     melos: ^7.3.0

   melos:
     scripts:
       # Phase 4 で定義
   ```
3. ルート `analysis_options.yaml` は共通 lint として維持(`package:flutter_lints/flutter.yaml` include)

## Phase 3: 最初のスライドパッケージ作成 (`slides/example`)

1. `flutter create --platforms=web --project-name example_slide slides/example`
   - Web のみ有効化(決定事項参照)。android/ios 等のディレクトリは生成させない
   - 以降の実スライドは命名規則 `slides/<yyyymm>_<event>` / パッケージ名 `<event>_<yyyymm>` に従う
2. `slides/example/pubspec.yaml` を編集:
   ```yaml
   name: example_slide
   publish_to: none
   resolution: workspace        # ← ワークスペースメンバー宣言

   environment:
     sdk: ^3.12.2

   dependencies:
     flutter:
       sdk: flutter
     flutter_deck: ^0.29.0
     flutter_deck_web_client: ^0.4.0   # presenter view 用(localStorage同期・Web専用)

   dev_dependencies:
     flutter_test:
       sdk: flutter
     flutter_lints: ^6.0.0
   ```
3. `slides/example/analysis_options.yaml` → `include: ../../analysis_options.yaml`
4. `lib/main.dart` を flutter_deck の雛形に置き換え:
   ```dart
   void main() => runApp(const ExampleSlideApp());

   class ExampleSlideApp extends StatelessWidget {
     const ExampleSlideApp({super.key});

     @override
     Widget build(BuildContext context) {
       return FlutterDeckApp(
         client: FlutterDeckWebClient(), // web での presenter view 連携
         configuration: const FlutterDeckConfiguration(...),
         slides: const [TitleSlide(), ...],
       );
     }
   }
   ```
   - `client: FlutterDeckWebClient()` の API は公式 README で確認済み。presenter view は localStorage でタブ間同期されるため同一ブラウザの別タブで開く(具体的な開き方=デッキ内メニュー or URL は実装時に動作確認)
5. `dart pub get`(ルート)→ ルートに単一 `pubspec.lock` が生成されることを確認
6. `mise x -- flutter run -d chrome`(melos 経由)で表示確認

## Phase 4: melos scripts 定義(コマンド集約の中核)

ルート pubspec.yaml の `melos.scripts` に以下を定義する。**すべてリポジトリルートから実行**。

| コマンド | 内容 |
|---|---|
| `melos run dev` | スライドを選択して `flutter run -d chrome` 起動(選択プロンプト利用) |
| `melos run build:web` | 全スライドを `flutter build web`。`--base-href /flutter_deck_slides/<pkg>/` の付与はパッケージ名の変数展開が必要なため `tool/build_web.dart` に実装(cmd.exe の `$` 非展開対策) |
| `melos run analyze` | `melos exec -- dart analyze .` 全パッケージ |
| `melos run format` | `dart format` チェック/適用 |
| `melos run test` | test ディレクトリを持つパッケージのみ `flutter test` |
| `melos run create:slide -- <name>` | 新規スライド雛形生成(Phase 5) |

定義例:

```yaml
melos:
  scripts:
    dev:
      description: スライドを選択して Chrome で起動
      exec: flutter run -d chrome
      packageFilters:
        dependsOn: flutter_deck     # slides/** の実体的なフィルタ

    build:web:
      description: 全スライドを web ビルド(成果物は各 build/web)
      run: dart run tool/build_web.dart
      # ルートで1回実行。tool 側で slides/ 配下を列挙し、
      # flutter build web --base-href "/flutter_deck_slides/<pkg>/" を順次実行する。
      # exec + $MELOS_PACKAGE_NAME 方式は Windows(cmd.exe)で $ が展開されないため不採用。

    analyze:
      exec: dart analyze .

    test:
      exec: flutter test
      packageFilters:
        dirExists: test
```

実装時の検証ポイント:
- `packageFilters.dependsOn: flutter_deck` で slides のみ対象にできるか(共通パッケージが flutter_deck に依存するようになったら `scope` による命名ベースのフィルタに切替)

melos の起動方法: `dart run melos <cmd>`(dev_dependency 経由)を正とし、README には `dart pub global activate melos` で `melos` 直接起動も可と記載。

## Phase 5: スライド雛形生成スクリプト (`tool/create_slide.dart`)

`melos run create:slide -- 202609_flutterkaigi` で以下を自動化:

1. 引数を命名規則 `<yyyymm>_<event>` でバリデーションし、パッケージ名 `<event>_<yyyymm>` を導出
2. `flutter create --platforms=web --project-name <event>_<yyyymm> slides/<yyyymm>_<event>` を実行
3. 生成された pubspec.yaml に `resolution: workspace` / `flutter_deck` / `flutter_deck_web_client` を注入
4. `lib/main.dart` を flutter_deck テンプレート(タイトル+セクション+クロージングの 3 枚程度)に置換
5. `analysis_options.yaml` をルート include 形式に置換
6. **ルート pubspec.yaml の `workspace:` リストに `slides/<yyyymm>_<event>` を追記**(glob 非対応対策)
7. `dart pub get` を実行して bootstrap

テンプレート本体は `tool/templates/` 配下に置き、文字列置換(パッケージ名・タイトル)で生成する。

## Phase 6: 共通パッケージ運用 (`packages/`)

初期は空(`.gitkeep`)。共通化ニーズが出た時の手順をREADMEに記載:

1. `flutter create --template=package packages/<name>`(または `dart create -t package`)
2. `resolution: workspace` を付与し、ルート `workspace:` に追記
3. 利用側スライドは `dependencies: <name>:`(バージョン指定なし or any。ワークスペース内はパス解決される)
4. 想定例: `slide_theme`(共通テーマ/フォント)、`slide_widgets`(共通ウィジェット)、`slide_lints`(lint 共有)

## Phase 7: CI / GitHub Pages(初期構築に含める)

前提: リポジトリを GitHub に public で作成し、Pages のソースを GitHub Actions に設定する。

1. `ci.yaml`: push/PR で実行
   - `jdx/mise-action@v2` で mise.toml どおりの Flutter を導入
   - `dart pub get` → `dart run melos run analyze --no-select` → `dart run melos run test --no-select`
2. `deploy.yaml`: main への push で全スライドを web ビルドし GitHub Pages へ
   - 各スライドの `build/web` を `dist/<package_name>/` に集約し、`dist/index.html`(スライド一覧のリンクページ)を生成して `actions/deploy-pages` でデプロイ
   - URL 設計: `https://yakitama5.github.io/flutter_deck_slides/<slide_name>/`(Phase 4 の `--base-href` と一致させる)

## Phase 8: README 整備

- セットアップ手順(mise install → dart pub get → melos bootstrap)
- コマンド一覧(Phase 4 の表)
- 新規スライドの作り方(create:slide)
- 発表方法(web での presenter view の開き方)
- 共通パッケージ追加手順

---

## 動作確認チェックリスト(実装完了の定義)

- [x] `mise install` だけで Flutter SDK が入り、`flutter --version` が通る(3.44.4 / Dart 3.12.2 を確認)
- [x] ルート `dart pub get` で全パッケージが解決され、lockfile がルートに 1 つだけ生成される(`slides/example` に pubspec.lock / pubspec_overrides.yaml が生成されないことも確認)
- [x] `dart run melos run dev` でスライド選択 → Chrome で example スライドが表示される(コンパイル・デバッグ接続まで確認。`packageFilters.dependsOn: flutter_deck` が 1 パッケージに正しく絞り込まれることも確認)
- [ ] presenter view が別タブ/ウィンドウで動作する(API 実装・ビルド成功までは確認済みだが、実ブラウザでの複数タブ目視確認は未実施 — ユーザー側でのスポットチェック推奨)
- [x] `dart run melos run build:web --no-select` で `slides/example/build/web` が生成される(`--base-href /flutter_deck_slides/example/` の注入も確認)
- [x] `dart run melos run analyze` / `format` / `test` がルートから成功する
- [x] `dart run melos run create:slide -- 202609_testevent` で新スライドが生成され、workspace 追記まで自動で行われる(確認後に削除)
- [x] 一連の作業中、一度も `cd` を要求されない

## 調査済み事項(2026-07-06 確認)

1. **presenter view API**: `FlutterDeckApp(client: FlutterDeckWebClient(), ...)` で有効化。`flutter_deck_web_client 0.4.0`。localStorage によるタブ間同期のためサーバー不要・Web 専用(本構成の「Web のみ」方針と合致。`flutter_deck_ws_client`/`ws_server` は不要)
2. **melos scripts の実行シェル**: Windows は cmd.exe、他は sh(公式ドキュメント)。`$VAR` 展開に依存する exec スクリプトは書かない → `tool/*.dart` に集約
3. **選択プロンプト**: `packageFilters` 付きスクリプトは実行時にパッケージ選択プロンプトが出る。`--no-select` で全対象一括実行(公式ドキュメント)
4. **mise × Windows**: flutter は `http:`/`vfox:` バックエンド提供で Windows 対応。本環境で `mise ls-remote flutter` の動作を確認済み
5. **最新 stable Flutter**: 3.44.4(実装時に再確認して mise.toml に固定)

## 実装時に判明した追加事項

1. **`FlutterDeckSlide` の route に `/` を使うとクラッシュする**: flutter_deck は `/` をルートリダイレクト専用に予約しており、スライド自体の route に `/` を割り当てると `A redirect-only route must redirect to location different from itself` で実行時エラーになる。公式 example でも最初のスライドは `/intro` を使用しているため、本構成でも `tool/templates/main.dart.template` / `slides/example` の最初のスライドは `route: '/intro'` とした
2. `packageFilters.dependsOn: flutter_deck` によるスライド限定フィルタは想定通り動作(`analyze`/`test`/`dev` すべてで `example_slide` のみが対象になることを確認)
3. `flutter_deck 0.29.0` × `flutter_deck_web_client 0.4.0` は `dart pub get` が問題なく通り、依存制約の互換性に問題なし
4. `melos run <script> --no-select` は `packageFilters` で対象パッケージが 0 件だと `NoPackageFoundScriptException` で失敗する。そのため `slides/example` には最小限のスモークテスト(`test/widget_test.dart`)を追加し、`melos run test` が CI で常に成功するようにした

## 未実施(ユーザー側でのスポットチェック推奨)

1. presenter view の実ブラウザでの複数タブ間同期の目視確認(API 実装とビルド成功までは確認済み)
2. GitHub Pages への実デプロイ確認(ワークフロー定義まで実装。実際のリポジトリ public 化・Pages 有効化は未実施)

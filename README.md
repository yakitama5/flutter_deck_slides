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
  3. `flutter_deck` の雛形(タイトル・セクション・クロージングの3枚)で `lib/main.dart` を置換
  4. `analysis_options.yaml` をルート共通設定への include に置換
  5. ルート `pubspec.yaml` の `workspace:` リストへ追記(Pub Workspace は glob 非対応のため)
  6. `dart pub get` で bootstrap

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

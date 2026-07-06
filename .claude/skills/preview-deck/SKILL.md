---
name: preview-deck
description: スライドをChromeでプレビュー起動する。presenter view(発表者ビュー)の使い方もここ。「スライドを見たい」「起動して」「発表者ビューを試したい」と言われたときに使用。
---

# スライドのプレビュー・presenter view

## 起動

リポジトリルートから(`cd` 不要):

```
dart run melos run dev
```

- flutter_deck に依存するパッケージ(= 各スライド)の選択プロンプトが出るので対象を選ぶ。
- 特定のデッキを直接起動したい場合はパッケージ名でフィルタできる:
  `dart run melos exec --scope=<パッケージ名> -- flutter run -d chrome`
  (パッケージ名は `<イベント名>_<yyyymm>` 形式。例: `example_slide`)
- ホットリロードは起動したターミナルで `r`、ホットリスタートは `R`。

## 操作方法(ブラウザ内)

- スライド送り: →/↓/Space、戻り: ←/↑
- 画面下部のツールバーからスライド一覧ドロワー・マーカー・テーマ切替などにアクセスできる。

## presenter view(発表者ビュー)

- 同一オリジンの**別タブ**でアプリを開き、ツールバーから presenter view を開くと、localStorage 経由でタブ間同期される(サーバ不要)。
- speaker notes は各スライドの `FlutterDeckSlideConfiguration(speakerNotes: '...')` に書いたものが表示される。
- 実ブラウザでのタブ間同期は目視確認が必要(ヘッドレスでは検証できない)。

## トラブルシューティング

- 起動時に `A redirect-only route must redirect to location different from itself` でクラッシュ
  → いずれかのスライドが `route: '/'` を使っている。`/intro` 等に変更する。
- `NoPackageFoundScriptException` → packageFilters にマッチするパッケージが0件。対象スライドの pubspec に flutter_deck 依存があるか確認。

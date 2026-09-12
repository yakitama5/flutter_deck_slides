# 技術選定に 自分の理由を

コーディング試験の技術選定メモと振り返りをもとにした、約11分のスライド資料です。
既存の絵本LTの解説部分を土台に、青と紫、紙の質感、Kiwi Maruを使う独立したスライド版にしました。
章ごとに「選んだもの → 自分の理由 → 引き受けたこと」を並べ、UIの選定理由には動くFlutterサンプルを添えています。

- [読み上げ原稿・時間配分](SCRIPT.md)
- [スライドの文章・発表者ノート](lib/pages.dart)
- [公開予定URL（mainへのマージ・デプロイ後）](https://yakitama5.github.io/flutter_deck_slides/202609_technologychoice_reasons/)
- [元の絵本LT](../202609_technologychoice/README.md)

全22枚。本編は表紙から結びまでの20枚・660秒で、参照資料と付録は質疑用です。
時間配分には場面転換とデモ操作を含みます。自動送りは行わず、リハーサルで調整してください。

## 構成

| 時間 | 章 | 選定理由 |
| --- | --- | --- |
| 00:00–01:05 | 導入 | コーディング試験で何をアピールしたかったか |
| 01:05–02:45 | 01 設計を選ぶ | オニオンアーキテクチャ、layer first、Pub Workspace |
| 02:45–04:10 | 02 開発環境を選ぶ | mise、Git worktree、Swift Package Manager |
| 04:10–05:50 | 03 品質の守り方を選ぶ | ハーネス、altive_lints、テストとCIの役割 |
| 05:50–08:50 | 04 UIを選ぶ | Material 3、幅によるレイアウト、Slang |
| 08:50–11:00 | 05 判断を振り返る | 過剰だった設計、見積もり、迷いと次の選択 |
| 時間外 | 参照資料・付録 | Flavor、GitHub Flow、CSpell、CodeRabbit |

## 動くサンプル

サンプルは、選定理由を発表中に確かめるための小さな再構成です。
試験アプリ全体やそのパッケージを埋め込んだものではありません。

| サンプル | 操作と、実際に使う仕組み | 元アプリとの関係 |
| --- | --- | --- |
| テーマ | Seedの青・紫とLight・Darkを変更。Flutterの`ColorScheme.fromSeed`から配色を生成する | 元アプリのColorSchemeによる配色方針を再構成。OSのDynamic Colorそのものは実演しない |
| レスポンシブ | 390・720・1024 dpでナビゲーションを切り替える。利用可能幅とFlutter標準のレイアウトAPIで判断する | 元アプリのcompact / medium / expandedとBar / Rail切り替えを再構成 |
| 多言語化 | 日本語・英語と0・1・2件を切り替える。実際の`slang` / `slang_flutter`とYAMLからの生成コードを使う | 検索案内などは元アプリの文言を参照。複数形の件数UIと資料専用ラベルはサンプル用に追加 |

デモの操作はローカルの状態だけで完結し、GitHub APIや元アプリの永続化には接続しません。
SlangのEnumや数に応じた表現は選定時に評価した能力です。この資料では、説明用に加えた件数UIで`1 repository found`と`2 repositories found`も実演します。元アプリに同じ複数形の件数UIがあるとは扱いません。

## 原稿の根拠

参照リビジョンは`57d9662dcdbfe1a93e6bb0b4706bfa778db8ba05`です。

本人の判断と感想は、[技術選定メモ](https://github.com/yakitama5/material_github_searcher/blob/57d9662dcdbfe1a93e6bb0b4706bfa778db8ba05/docs/technical-decisions.md)と
[振り返り](https://github.com/yakitama5/material_github_searcher/blob/57d9662dcdbfe1a93e6bb0b4706bfa778db8ba05/docs/retrospective.md)をもとに要約しました。
実装方針は本人の感想と区別し、スライドの出典表示とノートで明示しています。
本人が書いた参照資料自体は編集していません。

| スライド | 主な根拠 |
| --- | --- |
| 03 アピールしたかったこと | `docs/retrospective.md:10–21` |
| 05 オニオンアーキテクチャ | `docs/technical-decisions.md:36–67`、`docs/ARCHITECTURE.md:57–67,120–143` |
| 06 Pub Workspace | `docs/technical-decisions.md:69–74`、`docs/ARCHITECTURE.md:69–83` |
| 08 開発環境 | `docs/technical-decisions.md:76–122` |
| 09 SPM | `docs/technical-decisions.md:89–98` |
| 11 ハーネス | `docs/retrospective.md:23–37`、`docs/technical-decisions.md:28–34` |
| 12 品質の守り方 | `docs/technical-decisions.md:168–217`、`docs/testing.md:8–21,113–119`、`README.md:166` |
| 14 Material 3 | `docs/technical-decisions.md:243–256`、`docs/design.md:17–38` |
| 15 レスポンシブ | `docs/design.md:72–120`、`apps/app/lib/src/navigation/adaptive_app_shell.dart:49–71` |
| 16 Slang | `docs/technical-decisions.md:230–241`、`apps/app/assets/i18n/repositorySearch_ja.i18n.yaml`など |
| 18 過剰だった設計 | `docs/retrospective.md:39–54` |
| 19 迷いを残す | `docs/technical-decisions.md:1–18,176–184`、`docs/retrospective.md:29–37` |
| 20 次の選択への提案 | `docs/retrospective.md:56–62`をもとにした発表用の提案 |
| 22 付録 | `docs/technical-decisions.md:124–207` |

実装資料：[アーキテクチャ](https://github.com/yakitama5/material_github_searcher/blob/57d9662dcdbfe1a93e6bb0b4706bfa778db8ba05/docs/ARCHITECTURE.md)、
[デザイン方針](https://github.com/yakitama5/material_github_searcher/blob/57d9662dcdbfe1a93e6bb0b4706bfa778db8ba05/docs/design.md)、
[テスト方針](https://github.com/yakitama5/material_github_searcher/blob/57d9662dcdbfe1a93e6bb0b4706bfa778db8ba05/docs/testing.md)、
[README](https://github.com/yakitama5/material_github_searcher/blob/57d9662dcdbfe1a93e6bb0b4706bfa778db8ba05/README.md)。

次の区別を原稿でも維持しています。

- Melosは試験アプリでは見送り。条件次第で再検討する立場。
- `altive_lints`は採用済み。`very_good_analysis`は検討中。
- Flutter公式AIルールは未導入。Serenaへの集約は実施済みではなく検討中。
- Golden TestとPatrolはローカル実行。CIで全部を自動実行したという説明はしない。
- SPMへの懸念は選定した当時の見立て。現在の対応率や実測の改善数値は扱わない。
- デザインは当初の最優先事項ではなく、振り返りにも作り込みの心残りがある。

## 起動

リポジトリルート`flutter_deck_slides/`で実行します。

```sh
mise install
mise exec -- dart pub get
mise exec -- dart run melos exec --scope=technologychoice_reasons_202609 -- flutter run -d chrome
```

右矢印で次へ、左矢印で前へ移動します。画面下のツールバーから発表者ビューを開くと、
選定の根拠やデモ手順を含むノートを確認できます。
サンプルはクリック、またはTabで操作部へ移動してEnter・Spaceで操作できます。
左右キーはスライド移動に使います。各サンプルの「リセット」で初期状態へ戻せます。

この資料だけをWebビルドする場合は、次を使います。

```sh
mise exec -- dart run melos exec --scope=technologychoice_reasons_202609 -- flutter build web --base-href=/flutter_deck_slides/202609_technologychoice_reasons/
```

## 原稿の編集

`lib/pages.dart`の`reasonPages`が文章・順序・時間・発表者ノートの元データです。
ノートと`SCRIPT.md`には原文の出典、採用状況の注意点、デモ操作の順番を記載しています。
文章や秒数を変更した際は、`SCRIPT.md`の時間配分と本文も同期してください。

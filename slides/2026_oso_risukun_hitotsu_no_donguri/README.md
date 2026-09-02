# リスくんと ひとつのどんぐり — 画像生成

Issue #28 の絵本画像ワークフローです。表紙と page01 は既に確定した
canonical reference として扱い、page02〜page11 の各ページについて、構図の異なる
`a` / `b` / `c` の3候補を生成します。生成側と評価側を分け、評価が合格ラインに
届かなければ最大 `--max-retries` 回まで評価結果をプロンプトへ戻して再生成します。

## セットアップ

Python 3.10 以上が必要です。APIモードを使う場合だけ `OPENAI_API_KEY` が必要です。

```sh
cd slides/2026_oso_risukun_hitotsu_no_donguri
python3 -m venv .venv
.venv/bin/python -m pip install -r generation/requirements.txt
export OPENAI_API_KEY='...'
```

APIキーはファイルへ保存せず、環境変数から読み込みます。

## サブスク内蔵ImageGenで放置生成（APIキーなし）

Codexのサブスク利用枠で生成する場合は、PythonからAPIを呼ばず、Codex内蔵の
ImageGenを1ジョブずつ使います。ローカル側にはプロンプト、参照画像の役割、試行番号、
生成済みPNG、レビュー状態を保存します。`generation/output/` はGit管理外です。

まず次のページのジョブを作ります。`--next-page` は、前ページの生成結果を参照画像に
反映してから次のページを準備します。

```sh
python3 generation/scripts/imagegen_queue.py prepare --next-page
python3 generation/scripts/imagegen_queue.py status
python3 generation/scripts/imagegen_queue.py next
```

バックグラウンドで動かすCodexタスクは、`generation/output/BUILTIN_IMAGEGEN_WORKER.md` を
読み、表示された `.md` ジョブを順番に処理します。各ジョブでは `$imagegen` を使い、
生成されたPNGをジョブ内の `record` コマンドでローカルへ取り込みます。1ページの
`a` / `b` / `c` が揃うと、次ページへ進む前にコンタクトシートを作ります。API SDKや
`OPENAI_API_KEY` は使いません。

生成完了後は、次のコマンドで人間レビュー対象だけを確認します。

```sh
python3 generation/scripts/imagegen_queue.py review
python3 generation/scripts/imagegen_queue.py adopt --page page05 --variant b
```

レビューで修正したい候補だけ、同じキューへ追加できます。過去の試行は
`generation/output/<page>/attempts/` に残ります。

```sh
python3 generation/scripts/imagegen_queue.py revise \
  --page page05 --variant b \
  --note 'リスくんをもう少し右へ寄せ、木のスケール感を維持する'
```

キュー全体の進捗は `status`、次に処理するジョブは `next` で確認できます。キューを
作り直さずに再開できるため、利用枠やツールの一時的な失敗で中断しても、完了済みの
候補を重複生成しません。

参照画像は `generation/refs/` に置きます。現在の canonical の優先順位は次の通りです。

1. `cover_master.png` — 主人公・画風・森のスケール・明るさ
2. `page01_master.png` — 主人公とうさぎさん、近景でのキャラサイズ
3. `page02_ref_a.png` / `page02_ref_b.png` — page02 の補助的な構図・連続性
4. 直前ページで最も高評価だった候補 — 色とキャラクターの連続性

page01 のマスターをうさぎさんの参照にも使うため、別の `rabbit_ref.png` は必須では
ありません。参照画像は構図のコピーには使いません。

## コマンド

リポジトリルートから実行する場合は、次のようにスクリプトへのパスを読み替えてください。

```sh
python generation/scripts/generate_storybook.py
python generation/scripts/generate_storybook.py --page page05
python generation/scripts/generate_storybook.py --page page05 --variant b
python generation/scripts/generate_storybook.py --quality medium
python generation/scripts/generate_storybook.py --max-retries 2
python generation/scripts/generate_storybook.py --dry-run
```

追加オプション:

```sh
# 既存候補を明示的に作り直す
python generation/scripts/generate_storybook.py --page page05 --regenerate

# ロック済みの表紙・page01を明示的に再生成する
python generation/scripts/generate_storybook.py --page page01 --regenerate-locked

# ページ範囲を指定する（両端を含む）
python generation/scripts/generate_storybook.py --from-page page03 --to-page page06

# 保守的な見積額を超える実行を開始しない
python generation/scripts/generate_storybook.py --page page05 --max-cost-usd 1.50

# 人間が確認した候補を最終アセットへコピーする
python generation/scripts/generate_storybook.py --page page05 --variant b --adopt

# Pillow導入後、3候補を横並びに再生成する
python generation/scripts/make_contact_sheet.py --page page05
```

通常実行ではロック済みの `cover` / `page01` を再生成しません。`--regenerate-locked`
を付けた場合だけ対象にできます。`--adopt` は候補を
`assets/risukun_hitotsu_no_donguri/<page>.png` へコピーします。既存ファイルの置換は
`--force-adopt` が必要です。

`--dry-run` は APIキーや OpenAI SDKを要求せず、設定・ページ選択・参照画像・構図を
検証して表示します。

## 生成物と再開

ページごとに次のファイルを `generation/output/<page>/` へ保存します。

- `variant_a.png`, `variant_b.png`, `variant_c.png` — 必ず残す候補画像
- `evaluation.json` — 各試行のスコア、critique、推奨候補、3案の構図比較
- `contact_sheet.png` — 3案を横並びにした確認用画像
- `state.json` — 進行中・失敗・再試行可能な状態

候補・状態・評価ファイルはローカル生成物なので `.gitignore` 対象です。APIエラーは
ページ全体を中断せず、`state.json` に記録して次回実行で再開できます。画像生成後の
vision評価でも、次の候補生成に使う具体的な `revision_instruction` を保存します。

3案が揃った後は `gpt-5.6-sol` で構図の類似度を比較し、似すぎている場合は残りの
試行回数の範囲で低評価側を再生成します。`recommended_variant` は機械的な提案に
すぎず、最終採用は `--adopt` を実行する人が contact sheet を見て判断します。

設定と状態保存のテストは、追加依存なしで実行できます。

```sh
python -m unittest discover -s generation/scripts -p 'test_*.py'
```

## 仕様ファイル

- `generation/prompts/global_style.md` — キャラクター、画風、スケール、禁止事項
- `generation/prompts/storyboard.yaml` — cover / page01 / page02〜page11 の全ページと3構図
- `generation/scripts/generate_storybook.py` — `gpt-image-2` edit + vision評価ループ
- `generation/scripts/imagegen_queue.py` — サブスク内蔵ImageGen用のローカルキュー
- `generation/scripts/make_contact_sheet.py` — 候補の横並び画像生成
- `generation/requirements.txt` — OpenAI SDK、Pillow、PyYAML、Pydantic

画像内へ絵本文字を生成するのは禁止です。本文は後でFlutterスライド側に正確に重ねます。

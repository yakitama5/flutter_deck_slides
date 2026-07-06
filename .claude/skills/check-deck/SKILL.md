---
name: check-deck
description: コミット・PR前の品質チェック一式(analyze / format / test / webビルド)。「チェックして」「コミット前の確認」「CIが通るか確認」と言われたとき、およびスライド編集作業の締めに使用。
---

# コミット前チェック

リポジトリルートから以下を順に実行し、すべて成功させる:

```
dart run melos run analyze --no-select
dart run melos run format --no-select
dart run melos run test --no-select
```

pubspec・`tool/` 配下・CI設定を変更した場合は web ビルドも確認:

```
dart run melos run build:web --no-select
```

## 失敗時の対処

- **format で失敗**(`Changed <file>` が出る): チェック専用コマンドなので差分は自動適用されない。
  `dart format <対象ファイルかディレクトリ>` で適用してから再実行する。
- **test で `NoPackageFoundScriptException`**: `dirExists: test` フィルタにマッチするパッケージが0件。
  スライドから `test/` を削除しないこと。最低限のスモークテスト(`pumpWidget` するだけ)を必ず残す。
- **analyze で未使用import等**: スライド分割・削除時に残りがち。素直に修正する。

## CI との対応

`.github/workflows/ci.yaml` が push/PR で同じコマンド列を実行するため、
ローカルでこの一式が通れば CI も通る(Flutter バージョンも mise.toml で同一)。

## コミット時の注意

- 新スライド追加時はルート `pubspec.yaml` の `workspace:` 追記が含まれているか確認。
- `build/`, `dist/`, `pubspec_overrides.yaml` は gitignore 済み。ステージに紛れていたら異常なので調査する。
- lockfile はルートの `pubspec.lock` 1つだけが正。パッケージ配下に lockfile ができていたら削除する。

# だしゅまるの非公開アセット

モデルの公開元をFlutterKaigi側で管理するため、このリポジトリではGLBと生成ソースの平文をGit管理から外す。
ローカルでは元のパスを使い、CIでは暗号化バンドルを復元してからFlutterのテスト・ビルドを実行する。

## 保管するもの

`slides/20260919_flutterkaigi_mini/` 配下の次の5ファイルをまとめる。

- `assets/models/dashmaru.glb`
- `assets/models/dashmaru_manifest.json`
- `tool/build_dashmaru.py`
- `tool/dashmaru_expressions.py`
- `tool/dashmaru_materials.py`

暗号化バンドルは `.private-assets/dashmaru.tar.gz.gpg`、GitHub Actionsのrepository secretは
`DASHMARU_ASSET_PASSPHRASE`。参考画像、検証コード、Flutterアプリはこのバンドルに含めない。

GitHub Secretsは1件48KBまでのため、約11.6MBのGLBを直接登録せず、AES-256で暗号化した
バンドルをGitに置き、復号鍵をSecretsで渡す。[GitHub公式の大きなSecretsの扱い](https://docs.github.com/en/actions/how-tos/write-workflows/choose-what-workflows-do/use-secrets#storing-large-secrets)に沿う構成。

`.gitignore`への移行は過去のコミットを削除しない。また、公開Webデモには描画用の変換済み
`.fsceneb` が配信される。この構成は今後のチェックアウトとビルド時の原本管理を切り替えるもの。

## ローカルで復元する

GPGをインストールする（macOSは `brew install gnupg`）。パスフレーズは管理者から安全な経路で受け取り、
Git管理対象外の `.private-assets/dashmaru.passphrase` に保存して所有者のみ読める権限にする。
今回の移行環境ではこのファイルを作成済み。GitHub Secretsから値を読み戻すことはできないので、別途保管する。

リポジトリルートから実行する。

```sh
chmod 600 .private-assets/dashmaru.passphrase
python3 tool/private_assets.py restore --passphrase-file .private-assets/dashmaru.passphrase
flutter pub get
```

`DASHMARU_ASSET_PASSPHRASE` 環境変数が設定済みなら `--passphrase-file` は省略できる。
復元済みで内容が同じ場合は何も上書きしない。ローカルに異なる内容がある場合は停止するため、
編集を保存してから、意図的に置き換える場合だけ `restore --force` を使用する。

復号失敗や不正なアーカイブでは、既存ファイルを書き換えない。
アーカイブ内の5つの固定パス、通常ファイルであること、サイズを検証し、リンクや想定外のパスを拒否する。

## モデルを更新するとき

復元したソースを編集してから、リポジトリルートで実行する。

```sh
python3 slides/20260919_flutterkaigi_mini/tool/build_dashmaru.py
python3 slides/20260919_flutterkaigi_mini/tool/check_dashmaru.py
python3 tool/private_assets.py pack --passphrase-file .private-assets/dashmaru.passphrase
git add .private-assets/dashmaru.tar.gz.gpg
```

`pack` は暗号化後にもう一度復号し、5ファイルの内容が一致したことを確かめてからバンドルを置き換える。
Git差分には平文のモデルや生成ソースが出ないため、モデルの変更内容と検証結果をPRに記載し、プレビューで確認する。
バンドルだけを更新したPRも、依存する資料を取りこぼさないよう全資料のプレビューを作成する。

新しいリポジトリや復号鍵の変更時には、同じパスフレーズをrepository secretへ登録する。
値をコマンド引数に書かず、標準入力を使う。

```sh
gh secret set DASHMARU_ASSET_PASSPHRASE < .private-assets/dashmaru.passphrase
```

## CIとデプロイ

- 通常の同一リポジトリ内PRとmainのCIは、Secretsを復元ステップの環境変数にだけ渡す。
  復号鍵が未登録・不一致なら処理を停止する。
- 本番の `Build production web` も同じ復元を行い、従来どおりGitHub Pagesへ公開する。
- forkやDependabotのPRにはSecretsが渡らないため、全パッケージの解析・フォーマット確認と、
  Flutter Sceneに依存しないパッケージのテストを実行する。モデル依存テスト・モデル検証・プレビューは省略し、
  その範囲をActionsのジョブサマリーに表示する。
- FlutterのビルドフックはGLBがない場合に停止する。モデルが欠けたWeb成果物を公開しない。
- 検証用 `check_dashmaru.py`・`check_dashmaru_surfaces.py` は引き続きGit管理する。

復元処理は実モデルを使わない合成データでも検証できる。

```sh
python3 -m unittest discover -s tool -p 'test_private_assets.py'
```

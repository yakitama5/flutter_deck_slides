---
name: create-deck
description: 新しいスライド資料(デッキ)をこのmonorepoに追加する。「新しいスライドを作りたい」「登壇資料を追加」「○○イベント用の資料を作成」と言われたときに使用。
---

# 新規スライド資料の作成

## 手順

1. ディレクトリ名を決める。命名規則は `<yyyymm>_<イベント名>`(イベント名は英小文字始まり、英小文字+数字のみ)。
   - 例: `202609_flutterkaigi`
   - yyyymm は開催年月。ユーザーから聞いていなければ確認する。
2. リポジトリルートで生成コマンドを実行する(`cd` 不要):

   ```
   dart run melos run create:slide -- <yyyymm>_<イベント名>
   ```

3. これだけで以下がすべて自動で行われる(手作業でファイルを作らないこと):
   - `flutter create --platforms=web` によるプロジェクト生成(`slides/<yyyymm>_<イベント名>/`)
   - パッケージ名は `<イベント名>_<yyyymm>` に変換される(Dartパッケージ名は数字始まり不可のため)
   - pubspec.yaml の書き換え(`resolution: workspace`、flutter_deck ^0.29.0、flutter_deck_web_client ^0.4.0)
   - `lib/main.dart` を雛形テンプレート(`tool/templates/main.dart.template`)から生成
   - `analysis_options.yaml` をルート共通設定への include に置換
   - ルート `pubspec.yaml` の `workspace:` への追記
   - ルートでの `dart pub get`

4. 生成後の確認:

   ```
   dart run melos run analyze --no-select
   dart run melos run test --no-select
   ```

## 注意

- ルート `pubspec.yaml` の `workspace:` は glob 非対応。スクリプトを使わず手動で作った場合は追記を忘れずに。
- 生成直後の main.dart はタイトル・セクション・Thank you の3枚構成。内容の作り込みは `write-slides` スキルを参照。
- スライドの route に `/` は使用禁止(flutter_deck が内部予約しており実行時クラッシュする)。雛形は `/intro` 始まり。

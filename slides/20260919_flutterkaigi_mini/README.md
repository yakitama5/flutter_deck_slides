# FlutterKaigi mini — だしゅまると Flutter Scene

2026-09-19 FlutterKaigi mini 向けに育てていく、だしゅまるの3Dデモです。
Flutter / Dart と `flutter_scene 0.23.0` でモデルを描画し、GLB内の
`Walk`・`Jump`・`Wave`・`Blink` アニメーションを再生します。

[公開デモ](https://yakitama5.github.io/flutter_deck_slides/20260919_flutterkaigi_mini/)
は、`main` へのマージ後に既存のGitHub Pagesワークフローで更新されます。

## 起動

リポジトリで指定している Flutter 3.47.1 / Dart 3.13.1 を使います。

```sh
# リポジトリルート
mise install
flutter pub get
cd slides/20260919_flutterkaigi_mini
flutter run -d chrome
```

macOS でも起動できます。Flutter GPU の有効化設定は同梱済みです。

```sh
flutter run -d macos
```

WebはFlutterSceneに内蔵されたWebGL2バックエンド、macOSはFlutter GPU / Impellerで描画します。
初回はビルドフックでモデルの事前変換とシェーダーのコンパイルが走ります。
参考画像フォルダはアセット探索対象から外しており、配布物へ混入しません。

## 操作

- 「歩く」「ジャンプ」「手を振る」「まばたき」で動きを切り替えます。
- 再生・一時停止、再生速度の変更ができます。
- ドラッグで視点を回転し、スクロールで拡大・縮小します。
- 正面・横・後ろの視点と、自動回転を使って立体を確認できます。
- リセットで初期状態に戻ります。

## モデルと参考資料

- `assets/models/dashmaru.glb`: 立体形状・6種類の材質・4種類の動きを内包するglTF 2.0モデル。
- `tool/build_dashmaru.py`: モデルの編集可能なソース。Python標準ライブラリだけで再生成できます。
- `assets/models/dashmaru_manifest.json`: モデルサイズ、三角形数、クリップ一覧。
- `assets/dashmaru/`: ユーザー提供の参考資料。既存のgitignore設定を維持しています。

公式キャラクター「だしゅまる」を、提供された三面図と8方向の3Dモデリング画像を
照合して、このデモ用に立体化したものです。公式配布の3Dモデルではありません。
キャラクターの権利は元の権利者に帰属します。

立ち姿・顔の比率は `だしゅまる画像/sanmen.png`、胴体の厚み・三枚の羽先・尾・
円錐形のくちばしは `3080388 3Dモデリング/` を基準にしました。
ぬいぐるみ写真は丸みの補助資料にしています。

基本色は三面図の `#C8FCFE` / `#68D8FB` / `#634936` / `#E83568` / 白 / 黒です。
GLBの材質には線形色へ変換して格納するため、実描画では照明による陰影が加わります。
顔、胸、雪の黒い境界線と色面も、胴体・帽子の曲面に沿うメッシュです。

モデル座標はY軸が上、Z軸の正方向が正面、足裏がほぼY=0、高さ3.04です。
FlutterSceneの読み込み時の座標変換に合わせ、アプリではZ軸の負方向から正面を見ます。

## 再生成と検証

```sh
# このディレクトリで実行
python3 tool/build_dashmaru.py
python3 tool/check_dashmaru.py
flutter analyze
flutter build web
```

モデルを変更したらアプリを再起動して、ビルドフックの変換を反映させてください。
GLBはBlender等のglTF対応モデラーでも読み込めます。

歩行はその場の歩行ループ、ジャンプは溜め・離陸・着地、手振りは片翼を持ち上げる
バイバイ、まばたきは目だけが閉じる二回の瞬きです。
全クリップが関節・目・胴体の初期値を含み、動作切り替え時に前のポーズを持ち越しません。

再現可能な静止フレーム確認にはURLクエリを利用できます。

```text
?motion=walk&time=0.3&camera=three-quarter
?motion=jump&time=0.7&camera=front
?motion=wave&time=1.0&camera=front
?motion=blink&time=0.561&camera=front
```

`time` は秒で、その時刻へ移動して一時停止します。
描画比較と動作確認の記録は `docs/verification.md` にまとめます。

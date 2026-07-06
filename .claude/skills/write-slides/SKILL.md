---
name: write-slides
description: flutter_deck でスライドページを追加・編集するときのAPIパターン集。「スライドを追加」「ページを増やす」「コードを載せたい」「箇条書きを段階表示したい」などスライド内容の作り込み全般で使用。
---

# スライドページの作成・編集(flutter_deck 0.29.0)

各スライドは `FlutterDeckApp` の `slides:` リストに `FlutterDeckSlide` を追加していく。
編集対象は `slides/<デッキ名>/lib/main.dart`(規模が大きくなったら `lib/slides/` に1ページ1ファイルで分割し、公式exampleと同様に構成してよい)。

## 絶対に守ること

- **route に `/` を使わない**。flutter_deck が内部でリダイレクト専用に予約しており、実行時に
  `A redirect-only route must redirect to location different from itself` でクラッシュする。最初のスライドは `/intro` などにする。
- route はスライドごとに一意のケバブケース(例: `/agenda`, `/section-1`)。
- 編集後は `dart format <対象ファイル>` を必ず実行(CIのformatチェックが `--set-exit-if-changed` のため)。

## スライドテンプレート(用途別)

```dart
// タイトルスライド
FlutterDeckSlide.title(title: 'タイトル', subtitle: 'サブタイトル', configuration: ...)

// 自由レイアウト(最頻出)
FlutterDeckSlide.blank(builder: (context) => ..., configuration: ...)

// 大きな数字・キーワードの強調
FlutterDeckSlide.bigFact(title: '100%', subtitle: '説明', configuration: ...)

// 引用
FlutterDeckSlide.quote(quote: '引用文', attribution: '出典', configuration: ...)

// 画像全面
FlutterDeckSlide.image(imageBuilder: (context) => Image.asset('...'), label: 'キャプション', configuration: ...)

// 左右2分割
FlutterDeckSlide.split(leftBuilder: (context) => ..., rightBuilder: (context) => ..., configuration: ...)

// ヘッダー/フッター等も含め完全カスタム
FlutterDeckSlide.custom(builder: (context) => ..., configuration: ...)
```

## FlutterDeckSlideConfiguration の主要オプション

```dart
FlutterDeckSlideConfiguration(
  route: '/my-slide',        // 必須・一意
  title: 'ナビ表示名',        // 省略可(ドロワーに表示)
  steps: 3,                  // 段階表示のステップ数
  speakerNotes: '発表メモ',   // presenter view に表示される
  hidden: true,              // 発表から除外
  header: FlutterDeckHeaderConfiguration(showHeader: false),
  footer: FlutterDeckFooterConfiguration(showFooter: false),
  transition: FlutterDeckTransition.fade(),
)
```

## よく使うウィジェット

```dart
// 箇条書き(useSteps: true で1項目ずつ表示。configuration.steps と項目数を合わせる)
FlutterDeckBulletList(useSteps: true, items: const ['項目1', '項目2', '項目3'])

// コードハイライト
FlutterDeckCodeHighlight(
  code: '...',
  fileName: 'main.dart',
  language: 'dart',
)

// steps に応じた出し分け
FlutterDeckSlideStepsBuilder(
  builder: (context, stepNumber) => stepNumber > 1 ? WidgetA() : WidgetB(),
)
```

## テーマ・スタイル

- `FlutterDeckApp(lightTheme: FlutterDeckThemeData.light(), darkTheme: FlutterDeckThemeData.dark(), themeMode: ...)`
- スライド内では `FlutterDeckTheme.of(context).textTheme.title` などでテキストスタイルを取得。

## 参考実装

pubキャッシュ内の公式exampleに全テンプレートの実例がある:
`%LOCALAPPDATA%\Pub\Cache\hosted\pub.dev\flutter_deck-0.29.0\example\lib\slides\`(Windowsの場合。パスは環境による)
(steps_slide.dart, code_highlight_slide.dart, theming_slide.dart など)

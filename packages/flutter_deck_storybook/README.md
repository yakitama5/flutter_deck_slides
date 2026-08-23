# flutter_deck_storybook

`flutter_deck` 向けの絵本風ページと、左右の移動方向に追従するページめくりトランジションです。ネイティブでは3D回転、Webではソフトウェア描画でも安定するスライド＋クロスフェードを使用します。

```dart
final pageTurnTransition = FlutterDeckTransition.custom(
  transitionBuilder: StorybookPageTurnTransitionBuilder(),
);

FlutterDeckApp(
  configuration: FlutterDeckConfiguration(
    transition: pageTurnTransition,
  ),
  slides: [
    FlutterDeckSlide.blank(
      configuration: const FlutterDeckSlideConfiguration(route: '/page-1'),
      builder: (_) => const StorybookPage(
        pageNumber: 1,
        totalPages: 3,
        child: Center(child: Text('むかしむかし…')),
      ),
    ),
  ],
);
```

`StorybookPageTurnTransitionBuilder` は移動方向を覚えるため、デッキ全体で同じインスタンスを再利用してください。Webでも3D回転を使いたい場合は `usePerspective: true` を指定できます。OS・ブラウザで「視差効果を減らす」が有効な場合は、自動的にフェードへ切り替わります。

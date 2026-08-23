# flutter_deck_storybook

`flutter_deck` 向けの絵本風ページと、左右の移動方向に追従するページめくりトランジションです。16:9のスライド全体を1枚の紙として扱い、Web・ネイティブとも片側の端を支点に3D回転します。

```dart
final pageTurnTransition = FlutterDeckTransition.custom(
  transitionBuilder: StorybookPageTurnTransitionBuilder(usePerspective: true),
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

`StorybookPageTurnTransitionBuilder` は移動方向を覚えるため、デッキ全体で同じインスタンスを再利用してください。3D回転はWebを含む全プラットフォームで標準です。描画に問題がある環境だけ `usePerspective: false` を指定すると、スライド＋クロスフェードへ切り替えられます。OS・ブラウザで「視差効果を減らす」が有効な場合は、自動的にフェードへ切り替わります。

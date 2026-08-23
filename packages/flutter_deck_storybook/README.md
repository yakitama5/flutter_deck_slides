# flutter_deck_storybook

`flutter_deck` 向けの絵本風ページと、左右の移動方向に追従するページめくりトランジションです。16:9のスライド全体を1枚の紙として扱い、Web・ネイティブとも片側の端を支点に3D回転します。ページが平らになった後は白紙を短く見せ、薄い下描き、中央下寄りから広がる水彩・インクの順で完成絵を描き出します。

```dart
final pageTurnTransition = FlutterDeckTransition.custom(
  transitionBuilder: StorybookPageTurnTransitionBuilder(
    usePerspective: true,
    enableInkReveal: true,
    inkRevealDuration: Duration(milliseconds: 2750),
    inkRevealOrigin: Alignment(0, 0.25),
  ),
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

`StorybookPageTurnTransitionBuilder` は移動方向を覚えるため、デッキ全体で同じインスタンスを再利用してください。インク表現は `StorybookPage` のコンテンツへ適用され、紙面・綴じ目・影は先に表示されます。`enableInkReveal: false` で描画演出のみ無効化できます。

3D回転はWebを含む全プラットフォームで標準です。描画に問題がある環境だけ `usePerspective: false` を指定すると、スライド＋クロスフェードへ切り替えられます。OS・ブラウザで「視差効果を減らす」が有効な場合は、ページめくりと描画演出をフェードへ切り替えます。

16:9画像をページ全面に使う場合は、`outerPadding` と `contentPadding` を `EdgeInsets.zero`、`borderRadius` を `0` にすると、画像全体を1枚の紙としてめくれます。

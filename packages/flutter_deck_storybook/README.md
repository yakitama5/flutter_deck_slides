# flutter_deck_storybook

`flutter_deck` 向けの絵本風ページと、左右の移動方向に追従するページめくりトランジションです。16:9のスライド全体を1枚の紙として扱い、スナップショットを三角形メッシュへ貼って、紙面の曲率・上下の小さなねじれ・移動する照り返し・白紙へ落ちる影をWeb・ネイティブで描画します。ページが平らになった後は白紙を短く見せ、薄い下描き、中央下寄りから広がる水彩・インクの順で完成絵を描き出します。必要に応じて、紙をめくる音と鉛筆・筆で描く音も同期できます。

```dart
final storybookSounds = StorybookSoundEffects(
  pageTurnVolume: 0.64,
  drawingVolume: 0.58,
);

final pageTurnTransition = FlutterDeckTransition.custom(
  duration: const Duration(milliseconds: 1000),
  transitionBuilder: StorybookPageTurnTransitionBuilder(
    usePerspective: true,
    pageFlex: 0.34,
    pageTwist: 0.045,
    enableInkReveal: true,
    inkRevealDuration: Duration(milliseconds: 2750),
    inkRevealOrigin: Alignment(0, 0.25),
    soundEffects: storybookSounds,
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

`StorybookSoundEffects` は、めくり始めに約0.65秒の紙音、下描きが現れ始める位置に約2.48秒の鉛筆・筆音を合わせます。音声は自作の生成素材で、外部通信は行いません。`enabled = false` で一時ミュートでき、不要なら `soundEffects` を省略すると音声機能自体を使いません。所有する `State` の `dispose` では `StorybookSoundEffects.dispose()` を呼んでください。Webではブラウザの自動再生制限により、URLを開いただけでは鳴らず、矢印キー・タップなどユーザー操作でページを移動した時から再生されます。

3D回転はWebを含む全プラットフォームで標準です。描画に問題がある環境だけ `usePerspective: false` を指定すると、スライド＋クロスフェードへ切り替えられます。OS・ブラウザで「視差効果を減らす」が有効な場合は、ページめくりと描画演出をフェードへ切り替え、効果音も鳴らしません。

16:9画像をページ全面に使う場合は、`outerPadding` と `contentPadding` を `EdgeInsets.zero`、`borderRadius` を `0` にすると、画像全体を1枚の紙としてめくれます。

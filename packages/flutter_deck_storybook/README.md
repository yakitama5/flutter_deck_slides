# flutter_deck_storybook

`flutter_deck` 向けの絵本風ページと、移動方向に応じて物理動作を切り替えるページトランジションです。16:9のスライド全体を1枚の紙として扱い、スナップショットを両面三角形メッシュへ貼って変形します。進む時は右端の横中央へ手を掛けたような横長の隆起を作り、内側へ伝えてから後半で加速します。90度を越えた面は白い紙裏として表面とは別に描画します。戻る時は旧ページを剥がさず、別の時間曲線で前ページを上層から影付きで被せ、減速しながら平らに戻します。ページが平らになった後は白紙を短く見せ、薄い下描き、中央下寄りから広がる水彩・インクの順で完成絵を描き出します。必要に応じて、紙をめくる音と鉛筆・筆で描く音も同期できます。

```dart
final storybookSounds = StorybookSoundEffects(
  pageTurnVolume: 0.64,
  drawingVolume: 0.58,
);

final pageTurnTransition = FlutterDeckTransition.custom(
  duration: StorybookPageTurnTransitionBuilder.referenceTurnDuration,
  transitionBuilder: StorybookPageTurnTransitionBuilder(
    usePerspective: true,
    pageFlex: 0.56,
    pageTwist: 0.035,
    turnSoundCueProgress: 0.42,
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

`StorybookPageTurnTransitionBuilder` は移動方向を覚えるため、デッキ全体で同じインスタンスを再利用してください。`referenceTurnDuration` は参照動画を0.1秒刻みで測った約1.7秒の紙めくり時間です。インク表現は `StorybookPage` のコンテンツへ適用され、紙面・綴じ目・影は先に表示されます。`enableInkReveal: false` で描画演出のみ無効化できます。

`StorybookSoundEffects` は、横向きの隆起が見え始める約0.71秒後に約0.65秒の紙音、下描きが現れ始める位置に約2.48秒の鉛筆・筆音を合わせます。紙音の開始位置は `turnSoundCueProgress` で調整できます。音声は自作の生成素材で、外部通信は行いません。`enabled = false` で一時ミュートでき、不要なら `soundEffects` を省略すると音声機能自体を使いません。所有する `State` の `dispose` では `StorybookSoundEffects.dispose()` を呼んでください。Webではブラウザの自動再生制限により、URLを開いただけでは鳴らず、矢印キー・タップなどユーザー操作でページを移動した時から再生されます。

3D回転はWebを含む全プラットフォームで標準です。描画に問題がある環境だけ `usePerspective: false` を指定すると、スライド＋クロスフェードへ切り替えられます。OS・ブラウザで「視差効果を減らす」が有効な場合は、ページめくりと描画演出をフェードへ切り替え、効果音も鳴らしません。

16:9画像をページ全面に使う場合は、`outerPadding` と `contentPadding` を `EdgeInsets.zero`、`borderRadius` を `0` にすると、画像全体を1枚の紙としてめくれます。

下描きだけを画像内の注目点から円形に広げたいページには、`circularSketchReveal` を指定できます。`origin` は、`BoxFit.contain` で表示された実画像領域を基準にした `Alignment` です。画像の上下や左右に余白が入る場合も、`artworkAspectRatio` から表示領域を解決します。省略したページは従来の全面下描き、時間、効果音をそのまま使用します。

```dart
StorybookPage(
  outerPadding: EdgeInsets.zero,
  contentPadding: EdgeInsets.zero,
  borderRadius: 0,
  circularSketchReveal: const StorybookCircularSketchReveal(
    origin: Alignment(0.35, -0.2),
    artworkAspectRatio: 1408 / 752,
    initialRadiusFraction: 0.055,
    softEdgeFraction: 0.025,
  ),
  child: Image.asset('assets/story.png', fit: BoxFit.contain),
)
```

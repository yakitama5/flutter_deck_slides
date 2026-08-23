import 'package:flutter/material.dart';
import 'package:flutter_deck_storybook/flutter_deck_storybook.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('StorybookPage renders its content and page label', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: StorybookPage(
          pageNumber: 1,
          totalPages: 3,
          child: Center(child: Text('ものがたり')),
        ),
      ),
    );

    expect(find.text('ものがたり'), findsOneWidget);
    expect(find.text('1 / 3'), findsOneWidget);
  });

  testWidgets('page-turn transition produces a finite 3D transform', (
    tester,
  ) async {
    final animation = AnimationController(vsync: tester, value: 0.5);
    final secondaryAnimation = AnimationController(vsync: tester);
    addTearDown(animation.dispose);
    addTearDown(secondaryAnimation.dispose);

    final transitionBuilder = StorybookPageTurnTransitionBuilder(
      reverseOnPrevious: false,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => transitionBuilder.build(
            context,
            animation,
            secondaryAnimation,
            const ColoredBox(key: Key('page'), color: Colors.white),
          ),
        ),
      ),
    );

    final transform = tester.widget<Transform>(find.byType(Transform));

    expect(find.byKey(const Key('page')), findsOneWidget);
    expect(
      transform.transform.storage.every((value) => value.isFinite),
      isTrue,
    );
  });

  testWidgets('page-turn transition provides a planar web fallback', (
    tester,
  ) async {
    final animation = AnimationController(vsync: tester, value: 0.5);
    final secondaryAnimation = AnimationController(vsync: tester);
    addTearDown(animation.dispose);
    addTearDown(secondaryAnimation.dispose);

    final transitionBuilder = StorybookPageTurnTransitionBuilder(
      reverseOnPrevious: false,
      usePerspective: false,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => transitionBuilder.build(
            context,
            animation,
            secondaryAnimation,
            const ColoredBox(key: Key('page'), color: Colors.white),
          ),
        ),
      ),
    );

    final planarTransition = find.byKey(
      const ValueKey('storybook-page-turn-planar'),
    );

    expect(planarTransition, findsOneWidget);
    expect(
      find.descendant(
        of: planarTransition,
        matching: find.byType(SlideTransition),
      ),
      findsNWidgets(2),
    );
    expect(
      find.descendant(of: planarTransition, matching: find.byType(Transform)),
      findsNothing,
    );
  });

  testWidgets('page-turn transition falls back to a fade for reduced motion', (
    tester,
  ) async {
    final animation = AnimationController(vsync: tester, value: 1);
    final secondaryAnimation = AnimationController(vsync: tester);
    addTearDown(animation.dispose);
    addTearDown(secondaryAnimation.dispose);

    final transitionBuilder = StorybookPageTurnTransitionBuilder(
      reverseOnPrevious: false,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Builder(
            builder: (context) => transitionBuilder.build(
              context,
              animation,
              secondaryAnimation,
              const SizedBox(),
            ),
          ),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('storybook-page-turn-fade')),
      findsOneWidget,
    );
    expect(find.byType(Transform), findsNothing);
  });
}

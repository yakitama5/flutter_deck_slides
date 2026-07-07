import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_deck/flutter_deck.dart';

/// `stepNumber >= revealAt` になったら `child` を入場アニメーション付きで表示する共通ラッパー。
///
/// `stepNumber < revealAt` の間は `SizedBox.shrink()` を返す（逆送りで自然に消える）。
class StepReveal extends StatelessWidget {
  const StepReveal({
    required this.revealAt,
    required this.child,
    super.key,
    this.delay = Duration.zero,
  });

  /// この値以上の stepNumber で表示する。
  final int revealAt;

  final Widget child;

  /// 同一ステップ内で複数要素を時間差で入場させたい場合の遅延。
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    return FlutterDeckSlideStepsBuilder(
      builder: (context, stepNumber) {
        if (stepNumber < revealAt) return const SizedBox.shrink();

        return child
            .animate(delay: delay)
            .fadeIn(duration: 400.ms, curve: Curves.easeOutCubic)
            .slideY(
              begin: 0.15,
              end: 0,
              duration: 400.ms,
              curve: Curves.easeOutCubic,
            );
      },
    );
  }
}

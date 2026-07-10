import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_deck/flutter_deck.dart';

import '../speaker_notes.dart';
import '../theme.dart';
import '../widgets/content_card.dart';
import '../widgets/slide_headline.dart';

FlutterDeckSlide buildS10RetrospectiveSlide() {
  return FlutterDeckSlide.blank(
    configuration: const FlutterDeckSlideConfiguration(
      route: '/retrospective',
      title: '振り返り',
      steps: 4,
      speakerNotes: SpeakerNotes.retrospective,
    ),
    builder: (context) => const _RetrospectiveContent(),
  );
}

class _RetrospectiveContent extends StatelessWidget {
  const _RetrospectiveContent();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.googleGreen.withValues(alpha: 0.05),
                  AppColors.googleBlue.withValues(alpha: 0.06),
                ],
              ),
            ),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SlideHeadline(text: '振り返り'),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  '1ヶ月運用して見えたリアルな知見',
                  style: FlutterDeckTheme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(width: 12),
                const _MonthBadge(),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              flex: 5,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _RevealColumn(revealAt: 1, child: _GoodColumn()),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: _RevealColumn(revealAt: 2, child: _StruggleColumn()),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              flex: 4,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _RevealColumn(
                      revealAt: 3,
                      child: _MemberQuote(
                        name: '作業者A',
                        quote:
                            '他の人のQAの内容も含めてレビューしてくれるのがとてもいい。要件漏れにきづけたので、ここはすごくよかった！',
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: _RevealColumn(
                      revealAt: 4,
                      child: _MemberQuote(
                        name: '作業者B',
                        quote:
                            'BacklogやSlackの内容も加味してレビューしてもらえるので、見逃していたポイントに気づける',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MonthBadge extends StatelessWidget {
  const _MonthBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.notebookLm,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            '運用1ヶ月目',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scale(
          begin: const Offset(1, 1),
          end: const Offset(1.06, 1.06),
          duration: 1200.ms,
          curve: Curves.easeInOut,
        );
  }
}

class _RevealColumn extends StatelessWidget {
  const _RevealColumn({required this.revealAt, required this.child});

  final int revealAt;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FlutterDeckSlideStepsBuilder(
      builder: (context, stepNumber) {
        if (stepNumber < revealAt) return const SizedBox.shrink();

        return child
            .animate()
            .fadeIn(duration: 400.ms)
            .slideX(begin: 0.2, end: 0, curve: Curves.easeOutCubic);
      },
    );
  }
}

class _GoodColumn extends StatelessWidget {
  const _GoodColumn();

  @override
  Widget build(BuildContext context) {
    return ContentCard(
      color: AppColors.googleGreen.withValues(alpha: 0.06),
      borderColor: AppColors.googleGreen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.thumb_up, color: AppColors.googleGreen, size: 40)
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .moveY(
                begin: 0,
                end: -6,
                duration: 900.ms,
                curve: Curves.easeInOut,
              ),
          const SizedBox(height: 16),
          const Text(
            '良かったこと',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 26),
          ),
          const SizedBox(height: 12),
          const Text('無変更日はコスト0の冪等性。', style: TextStyle(fontSize: 22)),
          const Text(
            'インフォグラフィックや画像生成で認識齟齬が減少。',
            style: TextStyle(fontSize: 22),
          ),
          const Text('動画・音声解説で短時間にすっと理解できる。', style: TextStyle(fontSize: 22)),
        ],
      ),
    );
  }
}

class _StruggleColumn extends StatelessWidget {
  const _StruggleColumn();

  @override
  Widget build(BuildContext context) {
    return ContentCard(
      color: AppColors.googleYellow.withValues(alpha: 0.08),
      borderColor: AppColors.googleYellow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
                Icons.warning_amber,
                color: AppColors.googleYellow,
                size: 40,
              )
              .animate(onPlay: (c) => c.repeat())
              .shake(hz: 2, duration: 1600.ms, curve: Curves.easeInOut),
          const SizedBox(height: 16),
          const Text(
            'ハマりどころ',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 26),
          ),
          const SizedBox(height: 12),
          const Text(
            '現プランはAPI連携不可、手動アップロードのみ。',
            style: TextStyle(fontSize: 22),
          ),
          const Text(
            'Drive参照は1度50ファイル上限で地味に時間がかかる。',
            style: TextStyle(fontSize: 22),
          ),
        ],
      ),
    );
  }
}

class _MemberQuote extends StatelessWidget {
  const _MemberQuote({required this.name, required this.quote});

  final String name;
  final String quote;

  @override
  Widget build(BuildContext context) {
    return ContentCard(
      color: AppColors.googleBlue.withValues(alpha: 0.06),
      borderColor: AppColors.googleBlue,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            radius: 26,
            backgroundColor: AppColors.googleBlue,
            child: Icon(Icons.person, color: Colors.white, size: 28),
          ).animate().scale(
            begin: const Offset(0.3, 0.3),
            end: const Offset(1, 1),
            curve: Curves.elasticOut,
            duration: 600.ms,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: AppColors.googleBlue,
                  ),
                ),
                const SizedBox(height: 6),
                Text('「$quote」', style: const TextStyle(fontSize: 21)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

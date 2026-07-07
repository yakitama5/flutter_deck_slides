import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_deck/flutter_deck.dart';

import '../speaker_notes.dart';
import '../theme.dart';
import '../widgets/content_card.dart';
import '../widgets/service_node.dart';
import '../widgets/slide_headline.dart';

FlutterDeckSlide buildS07KeySafetySlide() {
  return FlutterDeckSlide.blank(
    configuration: const FlutterDeckSlideConfiguration(
      route: '/key-safety',
      title: 'キモ①安全設計',
      steps: 3,
      speakerNotes: SpeakerNotes.keySafety,
    ),
    builder: (context) => const _KeySafetyContent(),
  );
}

class _KeySafetyContent extends StatelessWidget {
  const _KeySafetyContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SlideHeadline(
          text: '技術のキモ① — AIにxlsxを直接読ませない',
          accentColor: AppColors.googleRed,
        ),
        const SizedBox(height: 32),
        Expanded(
          child: FlutterDeckSlideStepsBuilder(
            builder: (context, stepNumber) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (stepNumber >= 1) _NgLane(greyedOut: stepNumber >= 2),
                  const SizedBox(height: 40),
                  if (stepNumber >= 3)
                    _OkLane()
                        .animate()
                        .fadeIn(duration: 400.ms)
                        .slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic),
                  if (stepNumber >= 3) const SizedBox(height: 24),
                  if (stepNumber >= 3)
                    Center(
                      child: ContentCard(
                        color: AppColors.googleGreen.withValues(alpha: 0.08),
                        borderColor: AppColors.googleGreen,
                        child: Text(
                          'AIに渡す情報と、できる操作の両方を事前に絞る',
                          style: FlutterDeckTheme.of(context).textTheme.title
                              .copyWith(color: AppColors.googleGreen),
                        ),
                      ).animate(delay: 200.ms).fadeIn(),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _NgLane extends StatelessWidget {
  const _NgLane({required this.greyedOut});

  final bool greyedOut;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: greyedOut ? 0.3 : 1.0,
      duration: 400.ms,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const ServiceNode(
                label: 'xlsx',
                icon: Icons.grid_on,
                color: AppColors.excel,
                width: 170,
              ),
              SizedBox(
                width: 130,
                child: Column(
                  children: [
                    const Text(
                      '直接',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 22),
                    ),
                    _buildBlinkingEdge(animate: !greyedOut),
                  ],
                ),
              ),
              _buildClaudeNode(shaking: !greyedOut),
            ],
          ),
          if (greyedOut)
            const Icon(Icons.block, color: AppColors.googleRed, size: 140)
                .animate()
                .scale(
                  begin: const Offset(3, 3),
                  end: const Offset(1, 1),
                  curve: Curves.easeOutExpo,
                  duration: 500.ms,
                )
                .fadeIn(duration: 200.ms),
        ],
      ),
    );
  }

  Widget _buildBlinkingEdge({required bool animate}) {
    const bar = SizedBox(
      height: 4,
      child: ColoredBox(color: AppColors.googleRed),
    );
    if (!animate) return bar;

    return bar
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .fade(begin: 1, end: 0.2, duration: 500.ms);
  }

  Widget _buildClaudeNode({required bool shaking}) {
    const node = ServiceNode(
      label: 'Claude',
      icon: Icons.smart_toy,
      color: AppColors.claude,
      width: 170,
    );
    if (!shaking) return node;

    return node
        .animate(onPlay: (c) => c.repeat())
        .shake(hz: 3, duration: 800.ms);
  }
}

class _OkLane extends StatelessWidget {
  const _OkLane();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        ServiceNode(
          label: 'xlsx',
          icon: Icons.grid_on,
          color: AppColors.excel,
          width: 160,
        ),
        Icon(Icons.arrow_forward, size: 32),
        ServiceNode(
          label: 'Python\nopenpyxl',
          icon: Icons.data_object,
          color: AppColors.googleYellow,
          width: 190,
        ),
        Icon(Icons.arrow_forward, size: 32),
        ServiceNode(
          label: 'プレーンテキスト',
          icon: Icons.notes,
          color: AppColors.googleGreen,
          width: 220,
        ),
        Icon(Icons.arrow_forward, size: 32),
        ServiceNode(
          label: 'Claude',
          sublabel: '🔒 読む/書くのみ',
          icon: Icons.smart_toy,
          color: AppColors.claude,
          width: 200,
        ),
      ],
    );
  }
}

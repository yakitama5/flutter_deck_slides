import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_deck/flutter_deck.dart';

import '../speaker_notes.dart';
import '../theme.dart';
import '../widgets/content_card.dart';
import '../widgets/drag_hint.dart';
import '../widgets/service_node.dart';
import '../widgets/slide_headline.dart';

FlutterDeckSlide buildS08KeyFreerideSlide() {
  return FlutterDeckSlide.blank(
    configuration: const FlutterDeckSlideConfiguration(
      route: '/key-freeride',
      title: 'キモ②相乗り連携',
      steps: 3,
      speakerNotes: SpeakerNotes.keyFreeride,
    ),
    builder: (context) => const _KeyFreerideContent(),
  );
}

class _KeyFreerideContent extends StatefulWidget {
  const _KeyFreerideContent();

  @override
  State<_KeyFreerideContent> createState() => _KeyFreerideContentState();
}

class _KeyFreerideContentState extends State<_KeyFreerideContent> {
  bool _synced = false;
  Timer? _autoFireTimer;

  @override
  void dispose() {
    _autoFireTimer?.cancel();
    super.dispose();
  }

  void _fireSync() {
    if (_synced) return;
    setState(() => _synced = true);
  }

  void _onStepChanged(int stepNumber) {
    if (stepNumber >= 2 && !_synced) {
      _autoFireTimer?.cancel();
      _autoFireTimer = Timer(600.ms, _fireSync);
    } else if (stepNumber < 2) {
      _autoFireTimer?.cancel();
      if (_synced) setState(() => _synced = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SlideHeadline(text: '技術のキモ② — NotebookLM連携は"相乗り"で開発ゼロ'),
        const SizedBox(height: 24),
        Expanded(
          child: FlutterDeckSlideStepsListener(
            listener: (context, stepNumber) => _onStepChanged(stepNumber),
            child: FlutterDeckSlideStepsBuilder(
              builder: (context, stepNumber) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (stepNumber >= 1)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          DragHint(
                            visible: stepNumber >= 1 && !_synced,
                            child: Draggable<String>(
                              data: 'spec',
                              feedback: const Material(
                                color: Colors.transparent,
                                child: ContentCard(
                                  color: Colors.white,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.description,
                                        color: AppColors.claude,
                                        size: 28,
                                      ),
                                      SizedBox(width: 10),
                                      Text(
                                        'spec.md',
                                        style: TextStyle(fontSize: 22),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              childWhenDragging: const Opacity(
                                opacity: 0.3,
                                child: _SpecFileCard(),
                              ),
                              child: const _SpecFileCard(),
                            ),
                          ).animate().fadeIn().scale(
                            begin: const Offset(0.6, 0.6),
                            end: const Offset(1, 1),
                          ),
                          Column(
                            children: [
                              Icon(
                                    _synced ? Icons.sync : Icons.arrow_forward,
                                    size: 40,
                                    color: AppColors.drive,
                                  )
                                  .animate(target: _synced ? 1 : 0)
                                  .rotate(duration: 900.ms),
                              const SizedBox(height: 8),
                              const Text(
                                'クラウド同期',
                                style: TextStyle(fontSize: 22),
                              ),
                            ],
                          ),
                          DragTarget<String>(
                            onAcceptWithDetails: (_) => _fireSync(),
                            builder: (context, candidateData, rejectedData) {
                              return ServiceNode(
                                label: 'Google Drive',
                                sublabel: '同期フォルダ',
                                icon: candidateData.isNotEmpty || _synced
                                    ? Icons.folder_open
                                    : Icons.folder,
                                color: AppColors.drive,
                                width: 210,
                              );
                            },
                          ).animate().fadeIn().scale(
                            begin: const Offset(0.6, 0.6),
                            end: const Offset(1, 1),
                          ),
                          Icon(
                            Icons.cloud,
                            size: 40,
                            color: AppColors.drive,
                          ).animate(delay: 100.ms).fadeIn(),
                          Stack(
                                alignment: Alignment.topCenter,
                                clipBehavior: Clip.none,
                                children: [
                                  ServiceNode(
                                        label: 'NotebookLM',
                                        icon: Icons.auto_stories,
                                        color: AppColors.notebookLm,
                                        width: 220,
                                      )
                                      .animate(target: _synced ? 1 : 0)
                                      .scale(
                                        begin: const Offset(1, 1),
                                        end: const Offset(1.1, 1.1),
                                        curve: Curves.easeOut,
                                      ),
                                  if (_synced)
                                    Positioned(
                                      top: -60,
                                      child:
                                          ContentCard(
                                                color: Colors.white,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 14,
                                                      vertical: 8,
                                                    ),
                                                child: const Text(
                                                  '記憶を更新しました',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 22,
                                                  ),
                                                ),
                                              )
                                              .animate()
                                              .scale(
                                                begin: const Offset(0.5, 0.5),
                                                end: const Offset(1, 1),
                                                curve: Curves.easeOutBack,
                                              )
                                              .fadeIn(),
                                    ),
                                ],
                              )
                              .animate(delay: 200.ms)
                              .fadeIn()
                              .scale(
                                begin: const Offset(0.6, 0.6),
                                end: const Offset(1, 1),
                              ),
                        ],
                      ),
                    if (_synced) ...[
                      const SizedBox(height: 24),
                      const ContentCard(
                        color: Colors.white,
                        child: Text(
                          '連携コード 0 行',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                            color: AppColors.googleGreen,
                          ),
                        ),
                      ).animate().fadeIn().slideY(begin: 0.2, end: 0),
                    ],
                    if (stepNumber >= 3) ...[
                      const SizedBox(height: 32),
                      ContentCard(
                        color: AppColors.googleBlue.withValues(alpha: 0.08),
                        borderColor: AppColors.googleBlue,
                        child: Text(
                          '作らないのが一番速い、保守コストもゼロ',
                          style: FlutterDeckTheme.of(context).textTheme.title,
                        ),
                      ).animate().fadeIn().slideY(begin: 0.2, end: 0),
                    ],
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _SpecFileCard extends StatelessWidget {
  const _SpecFileCard();

  @override
  Widget build(BuildContext context) {
    return const ContentCard(
      color: Colors.white,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.description, color: AppColors.claude, size: 28),
          SizedBox(width: 10),
          Text('spec.md', style: TextStyle(fontSize: 22)),
        ],
      ),
    );
  }
}

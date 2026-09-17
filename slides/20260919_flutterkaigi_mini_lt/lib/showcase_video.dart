import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

/// A click-to-play official demo, with no video requests before the first tap.
class ShowcaseVideo extends StatefulWidget {
  const ShowcaseVideo({
    required this.posterAsset,
    required this.title,
    required this.videoUrl,
    this.sourceUrl = 'https://fscene.dev/',
    this.isActive = true,
    this.controllerFactory,
    super.key,
  });

  final String posterAsset;
  final String title;
  final String videoUrl;
  final String sourceUrl;
  final bool isActive;

  @visibleForTesting
  final VideoPlayerController Function(Uri)? controllerFactory;

  @override
  State<ShowcaseVideo> createState() => _ShowcaseVideoState();
}

class _ShowcaseVideoState extends State<ShowcaseVideo> {
  VideoPlayerController? _controller;
  bool _loading = false;
  bool _failed = false;
  bool _tickerEnabled = true;

  bool get _active => widget.isActive && _tickerEnabled;

  @override
  void didUpdateWidget(ShowcaseVideo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.isActive || oldWidget.videoUrl != widget.videoUrl) _reset();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _tickerEnabled = TickerMode.valuesOf(context).enabled;
    if (!_active) _reset();
  }

  void _reset() {
    final controller = _controller;
    _controller = null;
    _loading = false;
    _failed = false;
    if (controller != null) unawaited(controller.dispose());
  }

  @override
  void dispose() {
    _reset();
    super.dispose();
  }

  bool _owns(VideoPlayerController controller) =>
      mounted && _active && identical(_controller, controller);

  Future<void> _start() async {
    if (!_active || _loading) return;
    _reset();
    final controller =
        widget.controllerFactory?.call(Uri.parse(widget.videoUrl)) ??
        VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
    setState(() {
      _controller = controller;
      _loading = true;
    });
    try {
      await controller.initialize().timeout(const Duration(seconds: 20));
      if (!_owns(controller)) return;
      // Official showcase clips are silent loops. Muting also allows playback
      // after asynchronous initialization on browsers with autoplay restrictions.
      await controller.setVolume(0);
      if (!_owns(controller)) return;
      await controller.setLooping(true);
      if (!_owns(controller)) return;
      await controller.play();
      if (_owns(controller)) setState(() => _loading = false);
    } catch (_) {
      if (!_owns(controller)) return;
      _reset();
      setState(() => _failed = true);
    }
  }

  Future<void> _togglePlayback() async {
    final controller = _controller;
    if (controller == null || !_owns(controller)) return;
    try {
      if (controller.value.isPlaying) {
        await controller.pause();
      } else {
        await controller.play();
      }
    } catch (_) {
      if (_owns(controller)) {
        _reset();
        setState(() => _failed = true);
      }
    }
  }

  Future<void> _openSource() async {
    final opened = await launchUrl(
      Uri.parse(widget.sourceUrl),
      mode: LaunchMode.externalApplication,
    );
    if (!opened && mounted) {
      ScaffoldMessenger.maybeOf(context)
          ?.showSnackBar(const SnackBar(content: Text('公式サイトを開けませんでした')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final controller = _controller;
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Material(
        color: colors.surfaceContainerHighest,
        child: Column(
          children: [
            Expanded(
              child: controller == null
                  ? _poster(colors)
                  : ValueListenableBuilder<VideoPlayerValue>(
                      valueListenable: controller,
                      builder: (context, value, _) {
                        if (value.hasError) {
                          return _poster(colors, failed: true);
                        }
                        if (_loading || !value.isInitialized) {
                          return Stack(
                            fit: StackFit.expand,
                            children: [
                              _posterImage(),
                              ColoredBox(
                                color: colors.scrim.withValues(alpha: 0.55),
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    semanticsLabel: '動画を読み込み中',
                                  ),
                                ),
                              ),
                            ],
                          );
                        }
                        return Stack(
                          fit: StackFit.expand,
                          children: [
                            ColoredBox(
                              color: colors.scrim,
                              child: Center(
                                child: AspectRatio(
                                  aspectRatio: value.aspectRatio,
                                  child: Semantics(
                                    label: '${widget.title}の動画',
                                    child: VideoPlayer(controller),
                                  ),
                                ),
                              ),
                            ),
                            if (value.isBuffering)
                              const Center(
                                child: CircularProgressIndicator(
                                  semanticsLabel: '動画を読み込み中',
                                ),
                              ),
                            Positioned(
                              left: 18,
                              bottom: 18,
                              child: FilledButton.icon(
                                onPressed: _active ? _togglePlayback : null,
                                icon: Icon(
                                  value.isPlaying
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                                ),
                                label: Text(value.isPlaying ? '一時停止' : '再生'),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 6, 16, 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: TextStyle(
                        color: colors.onSurface,
                        fontSize: 23,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _openSource,
                    icon: const Icon(Icons.open_in_new_rounded, size: 20),
                    label: const Text('公式サイト', style: TextStyle(fontSize: 20)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _posterImage() => Image.asset(
    widget.posterAsset,
    width: double.infinity,
    height: double.infinity,
    fit: BoxFit.cover,
    excludeFromSemantics: true,
    errorBuilder: (_, _, _) =>
        const Center(child: Icon(Icons.movie_outlined, size: 96)),
  );

  Widget _poster(ColorScheme colors, {bool failed = false}) {
    final hasFailed = failed || _failed;
    return Semantics(
      button: true,
      label: '${widget.title}の動画を${hasFailed ? '再読み込み' : '再生'}',
      child: InkWell(
        onTap: _active ? _start : null,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _posterImage(),
            ColoredBox(color: colors.scrim.withValues(alpha: 0.26)),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colors.primary,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(17),
                      child: Icon(
                        hasFailed ? Icons.refresh_rounded : Icons.play_arrow,
                        size: 66,
                        color: colors.onPrimary,
                      ),
                    ),
                  ),
                  if (hasFailed) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      color: colors.surface,
                      child: const Text(
                        '読み込めませんでした\n再試行するか 公式サイトで見る',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 23),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

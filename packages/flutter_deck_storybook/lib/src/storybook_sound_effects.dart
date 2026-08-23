import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Audio cues consumed by the storybook page-turn transition.
///
/// Implement this interface to supply a different audio engine or custom
/// sounds. The transition deliberately treats every method as best effort: an
/// unavailable or browser-blocked audio player must never stop navigation.
abstract interface class StorybookSoundEffectPlayer {
  /// Warms the short sound assets so the first page turn is not delayed.
  Future<void> preload();

  /// Plays the dry paper sound at the start of a page turn.
  Future<void> playPageTurn();

  /// Plays the pencil-and-brush sound when the sketch begins to appear.
  Future<void> playDrawing();

  /// Stops a drawing sound that is still playing when another page is opened.
  Future<void> stopDrawing();
}

/// Packaged paper and drawing sound effects for a storybook deck.
///
/// The bundled sounds are original, procedurally generated effects. They are
/// intentionally quiet so they can sit underneath a presentation voice. Set
/// [enabled] to `false` for a mute control, or omit this object from the
/// transition builder to ship a silent deck.
class StorybookSoundEffects implements StorybookSoundEffectPlayer {
  /// Creates the bundled storybook sound player.
  StorybookSoundEffects({
    bool enabled = true,
    this.pageTurnVolume = 0.64,
    this.drawingVolume = 0.58,
    this.onError,
  }) : assert(pageTurnVolume >= 0 && pageTurnVolume <= 1),
       assert(drawingVolume >= 0 && drawingVolume <= 1),
       // The public `enabled` name is preserved while the setter needs private
       // storage to stop active players when it changes.
       // ignore: prefer_initializing_formals
       _enabled = enabled {
    _pageTurnPlayer.audioCache = _audioCache;
    _drawingPlayer.audioCache = _audioCache;
  }

  static const _pageTurnFile = 'page-turn.mp3';
  static const _drawingFile = 'drawing-on-paper.mp3';

  final AudioCache _audioCache = AudioCache(
    prefix: 'packages/flutter_deck_storybook/assets/audio/',
  );
  final AudioPlayer _pageTurnPlayer = AudioPlayer();
  final AudioPlayer _drawingPlayer = AudioPlayer();

  /// Volume of the page-turn sound, from 0 to 1.
  final double pageTurnVolume;

  /// Volume of the pencil-and-brush sound, from 0 to 1.
  final double drawingVolume;

  /// Optional diagnostic hook for blocked or unavailable audio playback.
  ///
  /// Errors are swallowed after this callback because a sound failure should
  /// never interrupt the slide transition.
  final void Function(Object error, StackTrace stackTrace)? onError;

  Future<void>? _preloadFuture;
  var _enabled = true;
  var _disposed = false;
  var _playersPrepared = false;

  /// Whether future sound cues should be played.
  bool get enabled => _enabled;

  set enabled(bool value) {
    if (_enabled == value || _disposed) return;
    _enabled = value;
    if (!value) unawaited(_stopAll());
  }

  @override
  Future<void> preload() {
    if (!_enabled || _disposed) return Future<void>.value();
    return _preloadFuture ??= _guard(() async {
      await _audioCache.loadAll(const [_pageTurnFile, _drawingFile]);
      await Future.wait([
        _pageTurnPlayer.setReleaseMode(ReleaseMode.stop),
        _drawingPlayer.setReleaseMode(ReleaseMode.stop),
        _pageTurnPlayer.setVolume(pageTurnVolume),
        _drawingPlayer.setVolume(drawingVolume),
      ]);
      await Future.wait([
        _pageTurnPlayer.setSource(
          AssetSource(_pageTurnFile, mimeType: 'audio/mpeg'),
        ),
        _drawingPlayer.setSource(
          AssetSource(_drawingFile, mimeType: 'audio/mpeg'),
        ),
      ]);
      _playersPrepared = true;
    });
  }

  @override
  Future<void> playPageTurn() => _guard(() async {
    if (!_enabled || _disposed) return;

    await preload();
    if (!_enabled || _disposed) return;

    if (_playersPrepared) {
      await Future.wait([_pageTurnPlayer.stop(), _drawingPlayer.stop()]);
      await _pageTurnPlayer.resume();
    } else {
      await _pageTurnPlayer.play(
        AssetSource(_pageTurnFile, mimeType: 'audio/mpeg'),
        volume: pageTurnVolume,
      );
    }
  });

  @override
  Future<void> playDrawing() => _guard(() async {
    if (!_enabled || _disposed) return;

    await preload();
    if (!_enabled || _disposed) return;

    if (_playersPrepared) {
      await _drawingPlayer.stop();
      await _drawingPlayer.resume();
    } else {
      await _drawingPlayer.play(
        AssetSource(_drawingFile, mimeType: 'audio/mpeg'),
        volume: drawingVolume,
      );
    }
  });

  @override
  Future<void> stopDrawing() => _guard(_drawingPlayer.stop);

  /// Releases the two underlying audio players.
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await _guard(() async {
      await Future.wait([_pageTurnPlayer.dispose(), _drawingPlayer.dispose()]);
    });
  }

  Future<void> _stopAll() => _guard(() async {
    await Future.wait([_pageTurnPlayer.stop(), _drawingPlayer.stop()]);
  });

  Future<void> _guard(Future<void> Function() operation) async {
    try {
      await operation();
    } on Object catch (error, stackTrace) {
      if (onError case final callback?) {
        callback(error, stackTrace);
      } else if (kDebugMode) {
        debugPrint('Storybook sound effect unavailable: $error');
      }
    }
  }
}

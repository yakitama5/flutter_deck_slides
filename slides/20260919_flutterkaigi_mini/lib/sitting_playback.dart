import 'package:flutter_scene/scene.dart' as scene;

/// The Sit clip enters once, then repeats its authored seated section.
/// Its pose at 2.4 seconds matches the final pose, so the repeat stays seated.
abstract final class SittingPlayback {
  static const loopStart = 2.4;

  static double position(double time, double duration) {
    if (!time.isFinite || duration <= loopStart) return 0;
    if (time <= duration) return time.clamp(0, duration);
    return loopStart + (time - loopStart) % (duration - loopStart);
  }

  /// Advance the actual bound clip, retaining its pause and speed settings.
  static void advance(
    scene.AnimationClip clip,
    double deltaSeconds,
    double duration,
  ) {
    if (!clip.playing || deltaSeconds <= 0) return;
    clip.seek(
      position(
        clip.playbackTime + deltaSeconds * clip.playbackTimeScale,
        duration,
      ),
    );
  }
}

import 'dart:math' as math;

import 'package:flutter_scene/scene.dart' as scene;
import 'package:vector_math/vector_math.dart' as vm;

/// The four animations authored into the glTF model.
enum DashmaruMotion {
  walk('Walk', '歩く', 'てくてく、いっしょに。'),
  jump('Jump', 'ジャンプ', 'うれしくて、ぴょん。'),
  wave('Wave', '手を振る', 'またね、バイバイ！'),
  blink('Blink', 'まばたき', 'ぱちっ。ひとやすみ。');

  const DashmaruMotion(this.clipName, this.label, this.caption);
  final String clipName;
  final String label;
  final String caption;

  static DashmaruMotion parse(String? value) => values.firstWhere(
    (motion) => motion.clipName.toLowerCase() == value?.toLowerCase(),
    orElse: () => wave,
  );
}

/// Owns the retained Flutter Scene graph and its glTF animation clips.
///
/// glTF is Y-up / +Z-front. Flutter Scene converts the imported asset to its
/// left-handed coordinates, making -Z the front in the runtime scene.
class DashmaruScene {
  final scene.Scene sceneGraph = scene.Scene();
  final Map<DashmaruMotion, scene.AnimationClip> _clips = {};
  final Map<DashmaruMotion, double> durations = {};

  DashmaruMotion motion = DashmaruMotion.wave;
  bool playing = true;
  bool orbiting = false;
  double speed = 1;
  double yaw = 0;
  double elevation = 0.03;
  double distance = 12;

  Future<void> load({
    required DashmaruMotion initialMotion,
    double? initialTime,
    String? initialCamera,
  }) async {
    await scene.Scene.initializeStaticResources();
    final model = await scene.loadScene('assets/models/dashmaru.glb');
    sceneGraph.add(model);

    // Register every clip before playing so all share the authored bind pose.
    for (final motion in DashmaruMotion.values) {
      final animation = model.findAnimationByName(motion.clipName);
      if (animation == null) {
        throw StateError('3D モデルに ${motion.clipName} アニメーションがありません。');
      }
      _clips[motion] = model.createAnimationClip(animation)
        ..weight = 0
        ..loop = true;
      durations[motion] = animation.endTime;
    }

    // An even studio fill keeps the white belly and pink cheek faithful to the
    // reference palette, including the downward-facing part of the round body.
    sceneGraph.environmentSettings = scene.EnvironmentSettings(
      environment: scene.EnvironmentMap.constantDiffuse(vm.Vector3.all(0.85)),
      toneMapping: scene.ToneMappingMode.pbrNeutral,
      exposure: 1.0,
      environmentIntensity: 1.0,
      ambientOcclusionEnabled: true,
      ambientOcclusionIntensity: 0.35,
      ambientOcclusionHalfResolution: true,
    );
    sceneGraph.directionalLight = scene.DirectionalLight(
      direction: vm.Vector3(0.4, -1, 0.5),
      intensity: 1.35,
      castsShadow: true,
      shadowCascadeCount: 1,
      shadowMaxDistance: 16,
      shadowMapResolution: 1024,
      shadowSoftness: 0.11,
      shadowDepthBias: 0.003,
      shadowNormalBias: 0.008,
    );

    final plinth = scene.Node(
      name: 'Display plinth',
      mesh: scene.Mesh(
        scene.CylinderGeometry(
          topRadius: 1.65,
          bottomRadius: 1.65,
          height: 0.085,
          radialSegments: 96,
        ),
        scene.PhysicallyBasedMaterial()
          ..baseColorFactor = vm.Vector4(0.77, 0.87, 0.79, 1)
          ..metallicFactor = 0
          ..roughnessFactor = 0.92,
      ),
    )..position = vm.Vector3(0, -0.053, 0);
    sceneGraph.add(plinth);
    setCamera(initialCamera ?? 'front');
    selectMotion(initialMotion);
    if (initialTime != null) {
      _clips[motion]!.seek(initialTime);
      setPlaying(false);
      sceneGraph.update(0);
    }
  }

  void selectMotion(DashmaruMotion value) {
    for (final clip in _clips.values) {
      clip
        ..stop()
        ..weight = 0;
    }
    motion = value;
    playing = true;
    _clips[value]!
      ..weight = 1
      ..playbackTimeScale = speed
      ..replay();
  }

  void setPlaying(bool value) {
    playing = value;
    _clips[motion]?.playing = value;
  }

  void setSpeed(double value) {
    speed = value;
    _clips[motion]?.playbackTimeScale = value;
  }

  void setCamera(String preset) {
    orbiting = false;
    elevation = 0.03;
    yaw = switch (preset) {
      'side' => math.pi / 2,
      'back' => math.pi,
      'three-quarter' => -math.pi / 5,
      _ => 0,
    };
  }

  void reset() {
    distance = 12;
    setCamera('front');
    setSpeed(1);
    selectMotion(DashmaruMotion.wave);
  }

  void drag(double dx, double dy) {
    orbiting = false;
    yaw -= dx * 0.009;
    elevation = (elevation + dy * 0.004).clamp(-0.08, 0.65);
  }

  void zoom(double scrollDelta) {
    distance = (distance + scrollDelta * 0.012).clamp(9, 16);
  }

  void tick(Duration elapsed, double deltaSeconds) {
    final delta = math.min(deltaSeconds, 0.05);
    if (orbiting) yaw += delta * 0.35;
    // One explicit scene step avoids the renderer's implicit wall-clock tick.
    sceneGraph.update(delta);
  }

  scene.PerspectiveCamera camera(Duration elapsed) => scene.PerspectiveCamera(
    position: vm.Vector3(
      math.sin(yaw) * distance,
      1.5 + math.tan(elevation) * distance,
      -math.cos(yaw) * distance,
    ),
    target: vm.Vector3(0, 1.5, 0),
    fovRadiansY: 22 * math.pi / 180,
    fovNear: 0.1,
    fovFar: 30,
  );
}

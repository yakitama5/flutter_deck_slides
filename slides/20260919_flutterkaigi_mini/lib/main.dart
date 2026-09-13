import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_scene/scene.dart' as scene;

import 'dashmaru_scene.dart';

const _ink = Color(0xFF183E36);
const _green = Color(0xFF287757);
const _muted = Color(0xFF698179);
const _line = Color(0xFFE0E9E1);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DashmaruApp());
}

class DashmaruApp extends StatelessWidget {
  const DashmaruApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'だしゅまる 3D | FlutterKaigi mini',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFFF8F9F3),
      colorScheme: ColorScheme.fromSeed(
        seedColor: _green,
        surface: const Color(0xFFF8F9F3),
      ),
      fontFamily: 'sans-serif',
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: _ink),
        bodyLarge: TextStyle(color: _ink),
      ),
    ),
    home: const DashmaruViewer(),
  );
}

class DashmaruViewer extends StatefulWidget {
  const DashmaruViewer({super.key});

  @override
  State<DashmaruViewer> createState() => _DashmaruViewerState();
}

class _DashmaruViewerState extends State<DashmaruViewer> {
  final _world = DashmaruScene();
  bool _ready = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final query = Uri.base.queryParameters;
    try {
      await _world.load(
        initialMotion: DashmaruMotion.parse(query['motion']),
        initialTime: double.tryParse(query['time'] ?? ''),
        initialCamera: query['camera'],
      );
      if (mounted) setState(() => _ready = true);
    } catch (error, stack) {
      debugPrint('Dashmaru model loading failed: $error\n$stack');
      if (mounted) setState(() => _error = error);
    }
  }

  void _selectMotion(DashmaruMotion motion) {
    if (_ready) setState(() => _world.selectMotion(motion));
  }

  void _togglePlay() {
    if (_ready) setState(() => _world.setPlaying(!_world.playing));
  }

  void _reset() {
    if (_ready) setState(_world.reset);
  }

  @override
  Widget build(BuildContext context) => CallbackShortcuts(
    bindings: {
      const SingleActivator(LogicalKeyboardKey.digit1): () =>
          _selectMotion(DashmaruMotion.walk),
      const SingleActivator(LogicalKeyboardKey.digit2): () =>
          _selectMotion(DashmaruMotion.jump),
      const SingleActivator(LogicalKeyboardKey.digit3): () =>
          _selectMotion(DashmaruMotion.wave),
      const SingleActivator(LogicalKeyboardKey.digit4): () =>
          _selectMotion(DashmaruMotion.blink),
      const SingleActivator(LogicalKeyboardKey.digit5): () =>
          _selectMotion(DashmaruMotion.idle),
      const SingleActivator(LogicalKeyboardKey.space): _togglePlay,
      const SingleActivator(LogicalKeyboardKey.keyR): _reset,
    },
    child: Focus(
      autofocus: true,
      child: Scaffold(
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 760;
              final tight = constraints.maxHeight < 700;
              final content = Padding(
                padding: EdgeInsets.fromLTRB(
                  compact ? 20 : 40,
                  tight ? 18 : 28,
                  compact ? 20 : 40,
                  18,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _header(compact, tight),
                    SizedBox(height: tight ? 16 : 24),
                    Expanded(child: _stage(compact)),
                    const SizedBox(height: 18),
                    _motionControls(compact),
                    const SizedBox(height: 14),
                    _footer(compact),
                  ],
                ),
              );
              // Keep the 3D stage usable on short windows / landscape phones.
              return constraints.maxHeight < 600
                  ? SingleChildScrollView(
                      child: SizedBox(height: 700, child: content),
                    )
                  : content;
            },
          ),
        ),
      ),
    ),
  );

  Widget _header(bool compact, bool tight) => Row(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const FlutterLogo(size: 18),
                const SizedBox(width: 8),
                Text(
                  'FLUTTERKAIGI MINI  /  2026.09.19',
                  style: TextStyle(
                    fontSize: compact ? 10 : 11,
                    color: _green,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.6,
                  ),
                ),
              ],
            ),
            SizedBox(height: tight ? 8 : 12),
            Text(
              'だしゅまる、3Dになる。',
              style: TextStyle(
                fontSize: compact ? 29 : (tight ? 36 : 42),
                fontWeight: FontWeight.w800,
                color: _ink,
                letterSpacing: -1.5,
                height: 1.2,
              ),
            ),
            if (!tight) ...[
              const SizedBox(height: 8),
              const Text(
                'Flutter で描く、小さなともだち。',
                style: TextStyle(fontSize: 14, color: _muted),
              ),
            ],
          ],
        ),
      ),
      if (!compact)
        Padding(
          padding: const EdgeInsets.only(bottom: 3),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: _line),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 17, vertical: 10),
              child: Row(
                children: [
                  Icon(Icons.view_in_ar_rounded, size: 17, color: _green),
                  SizedBox(width: 8),
                  Text(
                    'Flutter Scene',
                    style: TextStyle(
                      color: _ink,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
    ],
  );

  Widget _stage(bool compact) => Container(
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(28),
      border: Border.all(color: _line),
      gradient: const RadialGradient(
        center: Alignment(0, -0.4),
        radius: 1.1,
        colors: [Color(0xFFFFFFFF), Color(0xFFEAF1E5)],
      ),
    ),
    child: Stack(
      children: [
        Positioned.fill(
          child: _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: SelectableText(
                      '3D モデルを読み込めませんでした。\n$_error',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : !_ready
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: _green, strokeWidth: 2),
                      SizedBox(height: 18),
                      Text('だしゅまるを呼んでいます…'),
                    ],
                  ),
                )
              : Semantics(
                  label: 'だしゅまるの3Dモデル。${_world.motion.label}のアニメーション。',
                  child: MouseRegion(
                    cursor: SystemMouseCursors.grab,
                    child: Listener(
                      onPointerSignal: (event) {
                        if (event is PointerScrollEvent) {
                          setState(() => _world.zoom(event.scrollDelta.dy));
                        }
                      },
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onPanUpdate: (details) => setState(
                          () => _world.drag(details.delta.dx, details.delta.dy),
                        ),
                        child: scene.SceneView(
                          _world.sceneGraph,
                          cameraBuilder: _world.camera,
                          onTick: _world.tick,
                        ),
                      ),
                    ),
                  ),
                ),
        ),
        Positioned(
          top: 22,
          left: 24,
          child: IgnorePointer(
            child: Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _ready ? _green : _muted,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _ready
                      ? (_world.playing
                            ? 'LIVE  /  ${_world.motion.label}'
                            : 'PAUSED')
                      : 'LOADING',
                  style: const TextStyle(
                    color: _green,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (!compact)
          const Positioned(
            top: 20,
            right: 24,
            child: IgnorePointer(
              child: Text(
                'ドラッグで回転 · スクロールでズーム',
                style: TextStyle(fontSize: 11, color: _muted),
              ),
            ),
          ),
        Positioned(
          bottom: 14,
          left: 16,
          right: 16,
          child: Row(
            children: [
              _cameraControls(compact),
              const Spacer(),
              _toolButton(
                icon: Icons.restart_alt_rounded,
                label: 'リセット',
                onPressed: _ready ? _reset : null,
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _cameraControls(bool compact) => DecoratedBox(
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.88),
      border: Border.all(color: _line),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Padding(
      padding: const EdgeInsets.all(3),
      child: Row(
        children: [
          for (final preset in [('front', '正面'), ('side', '横'), ('back', '後ろ')])
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: _ink,
                minimumSize: Size(compact ? 40 : 52, 36),
                padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 12),
                textStyle: const TextStyle(fontSize: 12),
              ),
              onPressed: _ready
                  ? () => setState(() => _world.setCamera(preset.$1))
                  : null,
              child: Text(preset.$2),
            ),
          const SizedBox(height: 18, child: VerticalDivider(width: 8)),
          IconButton(
            tooltip: '自動で回転',
            icon: Icon(
              Icons.threesixty_rounded,
              color: _world.orbiting ? _green : _muted,
              size: 21,
            ),
            isSelected: _world.orbiting,
            onPressed: _ready
                ? () => setState(() => _world.orbiting = !_world.orbiting)
                : null,
          ),
        ],
      ),
    ),
  );

  Widget _motionControls(bool compact) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = constraints.maxWidth < 520 ? 3 : 5;
      final spacing = compact ? 8.0 : 12.0;
      final width = (constraints.maxWidth - spacing * (columns - 1)) / columns;
      return Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: [
          for (final motion in DashmaruMotion.values)
            SizedBox(
              width: width,
              height: compact ? 89 : 132,
              child: Tooltip(
                message: '${motion.label}（キー ${motion.index + 1}）',
                child: _motionCard(motion, compact),
              ),
            ),
        ],
      );
    },
  );

  Widget _motionCard(DashmaruMotion motion, bool compact) {
    final active = _world.motion == motion;
    final icon = switch (motion) {
      DashmaruMotion.walk => Icons.directions_walk_rounded,
      DashmaruMotion.jump => Icons.arrow_upward_rounded,
      DashmaruMotion.wave => Icons.waving_hand_rounded,
      DashmaruMotion.blink => Icons.visibility_rounded,
      DashmaruMotion.idle => Icons.spa_rounded,
    };
    return Material(
      color: active ? _green : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: active ? _green : _line),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _ready ? () => _selectMotion(motion) : null,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 8 : 14,
            vertical: compact ? 15 : 18,
          ),
          child: Column(
            crossAxisAlignment: compact
                ? CrossAxisAlignment.center
                : CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: compact
                    ? MainAxisAlignment.center
                    : MainAxisAlignment.start,
                children: [
                  Icon(icon, size: 23, color: active ? Colors.white : _green),
                  if (!compact) ...[
                    const Spacer(),
                    Text(
                      '0${motion.index + 1}',
                      style: TextStyle(
                        color: active ? Colors.white60 : _muted,
                        fontSize: 10,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              Text(
                motion.label,
                style: TextStyle(
                  color: active ? Colors.white : _ink,
                  fontWeight: FontWeight.w700,
                  fontSize: compact ? 13 : 16,
                ),
              ),
              if (!compact) ...[
                const SizedBox(height: 5),
                Text(
                  motion.caption,
                  style: TextStyle(
                    color: active ? Colors.white70 : _muted,
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _footer(bool compact) => Row(
    children: [
      _toolButton(
        icon: _world.playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
        label: _world.playing ? '一時停止' : '再生',
        onPressed: _ready ? _togglePlay : null,
      ),
      const SizedBox(width: 12),
      DropdownButtonHideUnderline(
        child: DropdownButton<double>(
          value: _world.speed,
          borderRadius: BorderRadius.circular(12),
          isDense: true,
          style: const TextStyle(color: _ink, fontSize: 12),
          icon: const Icon(Icons.expand_more_rounded, size: 18, color: _muted),
          items: [
            for (final speed in [0.5, 1.0, 1.5])
              DropdownMenuItem(
                value: speed,
                child: Text('${speed.toStringAsFixed(1)}×'),
              ),
          ],
          onChanged: !_ready
              ? null
              : (value) => setState(() => _world.setSpeed(value!)),
        ),
      ),
      const Spacer(),
      Text(
        compact
            ? '© FlutterKaigi'
            : 'だしゅまる © FlutterKaigi  ·  3D fan recreation',
        style: const TextStyle(fontSize: 10, color: _muted),
      ),
    ],
  );

  Widget _toolButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
  }) => TextButton.icon(
    onPressed: onPressed,
    icon: Icon(icon, size: 19),
    label: Text(label),
    style: TextButton.styleFrom(
      foregroundColor: _ink,
      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      backgroundColor: Colors.white.withValues(alpha: 0.8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );
}

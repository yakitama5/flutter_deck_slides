// GitHub Pages 公開用に、各スライドの build/web を dist/<slide>/ に集約し、
// スライド一覧の dist/index.html を生成する。
// 前提: 事前に `dart run tool/build_web.dart` で全スライドをビルド済みであること。
// 実行: dart run tool/prepare_pages.dart
// build_web.dart と同じ WEB_BASE_PATH / WEB_SLIDES を設定すること。
// PR_NUMBER がある場合、一覧ページに PR プレビューであることを表示する。
import 'dart:convert';
import 'dart:io';

import 'web_build_options.dart';

void main() {
  try {
    _prepare(WebBuildOptions.fromEnvironment(Platform.environment));
  } on FormatException catch (error) {
    stderr.writeln('エラー: ${error.message}');
    exit(1);
  }
}

void _prepare(WebBuildOptions options) {
  final repoRoot = Directory.current;
  final slideDirs = options.slideDirectories(repoRoot);
  for (final dir in slideDirs) {
    if (!File('${dir.path}/build/web/index.html').existsSync()) {
      throw FormatException(
        '[${slideDirectoryName(dir)}] build/web/index.html が見つかりません。'
        '同じ WEB_SLIDES を指定して tool/build_web.dart を実行してください。',
      );
    }
  }

  final distDir = Directory('${repoRoot.path}/dist');
  if (distDir.existsSync()) {
    distDir.deleteSync(recursive: true);
  }
  distDir.createSync(recursive: true);

  final publishedSlides = <String>[];

  for (final dir in slideDirs) {
    final slideName = slideDirectoryName(dir);
    final buildWebDir = Directory('${dir.path}/build/web');

    final destDir = Directory('${distDir.path}/$slideName');
    _copyDirectory(
      buildWebDir,
      destDir,
      trimUnusedRenderers: _isCanvasKitOnly(buildWebDir),
    );
    publishedSlides.add(slideName);
    stdout.writeln('▸ [$slideName] dist/$slideName/ へコピーしました。');
  }

  File('${distDir.path}/index.html')
      .writeAsStringSync(_renderIndexHtml(publishedSlides, options));

  stdout.writeln('✔ dist/index.html を生成しました (${publishedSlides.length} スライド)。');
}

// Flutter copies every renderer into build/web, even for CanvasKit-only JS.
// Keep all resources for unknown/Wasm builds and older offline service workers.
bool _isCanvasKitOnly(Directory buildWebDir) {
  final bootstrap = File('${buildWebDir.path}/flutter_bootstrap.js');
  if (!bootstrap.existsSync()) return false;
  final worker = File('${buildWebDir.path}/flutter_service_worker.js');
  if (worker.existsSync() && worker.readAsStringSync().contains('RESOURCES')) {
    return false;
  }
  final match = RegExp(r'_flutter\.buildConfig\s*=\s*(\{[^\n]*\});')
      .firstMatch(bootstrap.readAsStringSync());
  if (match == null) return false;
  try {
    final config = jsonDecode(match.group(1)!);
    if (config is! Map || config['builds'] is! List) return false;
    var hasCanvasKit = false;
    for (final build in config['builds'] as List) {
      if (build is! Map) return false;
      if (build.isEmpty) continue; // Flutter's trailing placeholder.
      if (build['compileTarget'] != 'dart2js' ||
          build['renderer'] != 'canvaskit') {
        return false;
      }
      hasCanvasKit = true;
    }
    return hasCanvasKit;
  } on FormatException {
    return false;
  }
}

bool _isUnusedRendererFile(String path) {
  if (!path.startsWith('canvaskit/')) return false;
  if (path.endsWith('.symbols')) return true;
  return const {
    'canvaskit/skwasm.js',
    'canvaskit/skwasm.wasm',
    'canvaskit/skwasm_heavy.js',
    'canvaskit/skwasm_heavy.wasm',
    'canvaskit/wimp.js',
    'canvaskit/wimp.wasm',
  }.contains(path);
}

void _copyDirectory(
  Directory source,
  Directory destination, {
  bool trimUnusedRenderers = false,
  String relativePath = '',
}) {
  destination.createSync(recursive: true);
  for (final entity in source.listSync(followLinks: false)) {
    final name = entity.uri.pathSegments.where((s) => s.isNotEmpty).last;
    final newPath = '${destination.path}/$name';
    final relative = '$relativePath$name';
    if (entity is Directory) {
      _copyDirectory(
        entity,
        Directory(newPath),
        trimUnusedRenderers: trimUnusedRenderers,
        relativePath: '$relative/',
      );
    } else if (entity is File) {
      if (trimUnusedRenderers && _isUnusedRendererFile(relative)) continue;
      entity.copySync(newPath);
    }
  }
}

String _renderIndexHtml(List<String> slides, WebBuildOptions options) {
  const escape = HtmlEscape(HtmlEscapeMode.attribute);
  final number = options.pullRequestNumber;
  final title = number == null
      ? 'flutter_deck_slides'
      : 'PR #$number プレビュー | flutter_deck_slides';
  final previewNotice = number == null
      ? ''
      : '  <p>PR #$number の変更確認用プレビューです。PR を更新すると再公開され、終了すると削除されます。</p>\n';
  final items = slides
      .map(
        (s) =>
            '    <li><a href="${escape.convert(options.slideBaseHref(s))}">${escape.convert(s)}</a></li>',
      )
      .join('\n');

  return '''
<!doctype html>
<html lang="ja">
<head>
  <meta charset="utf-8" />
  <title>$title</title>
  <meta name="viewport" content="width=device-width, initial-scale=1" />
</head>
<body>
  <h1>$title</h1>
$previewNotice  <ul>
$items
  </ul>
</body>
</html>
''';
}

// GitHub Pages 公開用に、各スライドの build/web を dist/<slide>/ に集約し、
// スライド一覧の dist/index.html を生成する。
// 前提: 事前に `dart run tool/build_web.dart` で全スライドをビルド済みであること。
// 実行: dart run tool/prepare_pages.dart
import 'dart:io';

const _basePath = '/flutter_deck_slides';

void main() {
  final repoRoot = Directory.current;
  final slidesDir = Directory('${repoRoot.path}/slides');
  final distDir = Directory('${repoRoot.path}/dist');

  if (!slidesDir.existsSync()) {
    stderr.writeln('エラー: slides/ ディレクトリが見つかりません。リポジトリルートで実行してください。');
    exit(1);
  }

  if (distDir.existsSync()) {
    distDir.deleteSync(recursive: true);
  }
  distDir.createSync(recursive: true);

  final slideDirs = slidesDir
      .listSync()
      .whereType<Directory>()
      .where((d) => File('${d.path}/pubspec.yaml').existsSync())
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  final publishedSlides = <String>[];

  for (final dir in slideDirs) {
    final slideName = dir.uri.pathSegments.where((s) => s.isNotEmpty).last;
    final buildWebDir = Directory('${dir.path}/build/web');

    if (!buildWebDir.existsSync()) {
      stderr.writeln('警告: [$slideName] build/web が見つかりません。先に tool/build_web.dart を実行してください。スキップします。');
      continue;
    }

    final destDir = Directory('${distDir.path}/$slideName');
    _copyDirectory(buildWebDir, destDir);
    publishedSlides.add(slideName);
    stdout.writeln('▸ [$slideName] dist/$slideName/ へコピーしました。');
  }

  File('${distDir.path}/index.html').writeAsStringSync(
    _renderIndexHtml(publishedSlides),
  );

  stdout.writeln('✔ dist/index.html を生成しました (${publishedSlides.length} スライド)。');
}

void _copyDirectory(Directory source, Directory destination) {
  destination.createSync(recursive: true);
  for (final entity in source.listSync(recursive: false)) {
    final newPath = '${destination.path}/${entity.uri.pathSegments.where((s) => s.isNotEmpty).last}';
    if (entity is Directory) {
      _copyDirectory(entity, Directory(newPath));
    } else if (entity is File) {
      entity.copySync(newPath);
    }
  }
}

String _renderIndexHtml(List<String> slides) {
  final items = slides
      .map((s) => '    <li><a href="$_basePath/$s/">$s</a></li>')
      .join('\n');

  return '''
<!doctype html>
<html lang="ja">
<head>
  <meta charset="utf-8" />
  <title>flutter_deck_slides</title>
  <meta name="viewport" content="width=device-width, initial-scale=1" />
</head>
<body>
  <h1>flutter_deck_slides</h1>
  <ul>
$items
  </ul>
</body>
</html>
''';
}

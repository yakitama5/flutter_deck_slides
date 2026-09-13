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
    _copyDirectory(buildWebDir, destDir);
    publishedSlides.add(slideName);
    stdout.writeln('▸ [$slideName] dist/$slideName/ へコピーしました。');
  }

  File('${distDir.path}/index.html')
      .writeAsStringSync(_renderIndexHtml(publishedSlides, options));

  stdout.writeln('✔ dist/index.html を生成しました (${publishedSlides.length} スライド)。');
}

void _copyDirectory(Directory source, Directory destination) {
  destination.createSync(recursive: true);
  for (final entity in source.listSync(followLinks: false)) {
    final newPath =
        '${destination.path}/${entity.uri.pathSegments.where((s) => s.isNotEmpty).last}';
    if (entity is Directory) {
      _copyDirectory(entity, Directory(newPath));
    } else if (entity is File) {
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

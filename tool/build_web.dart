// 全スライドを web ビルドするスクリプト。
// 実行: dart run tool/build_web.dart
// (melos 経由: melos run build:web)
//
// melos の exec スクリプトは Windows では cmd.exe 上で実行され `$VAR` 展開が
// 効かないため、base-href にパッケージ名を埋め込む処理は Dart 側で行う。
//
// リポジトリルートから実行すること。
// WEB_BASE_PATH: 公開パス。WEB_SLIDES: 対象名（改行またはカンマ区切り、空なら全件）。
import 'dart:io';

import 'web_build_options.dart';

void main() {
  try {
    _build(WebBuildOptions.fromEnvironment(Platform.environment));
  } on FormatException catch (error) {
    stderr.writeln('エラー: ${error.message}');
    exit(1);
  }
}

void _build(WebBuildOptions options) {
  final slideDirs = options.slideDirectories(Directory.current);

  if (slideDirs.isEmpty) {
    stdout.writeln('ビルド対象のスライドがありません。');
    return;
  }

  var failureCount = 0;

  for (final dir in slideDirs) {
    final slideName = slideDirectoryName(dir);
    final baseHref = options.slideBaseHref(slideName);

    stdout.writeln('▸ [$slideName] flutter build web --base-href $baseHref');
    final result = Process.runSync(
      'flutter',
      ['build', 'web', '--base-href', baseHref],
      workingDirectory: dir.path,
      runInShell: true,
    );
    stdout.write(result.stdout);
    stderr.write(result.stderr);

    if (result.exitCode != 0) {
      stderr.writeln('✘ [$slideName] ビルドに失敗しました。');
      failureCount++;
    } else {
      stdout.writeln('✔ [$slideName] ${dir.path}/build/web');
    }
  }

  if (failureCount > 0) {
    stderr.writeln('$failureCount 件のスライドでビルドが失敗しました。');
    exit(1);
  }
}

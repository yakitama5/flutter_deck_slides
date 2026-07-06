// 全スライドを web ビルドするスクリプト。
// 実行: dart run tool/build_web.dart
// (melos 経由: melos run build:web)
//
// melos の exec スクリプトは Windows では cmd.exe 上で実行され `$VAR` 展開が
// 効かないため、base-href にパッケージ名を埋め込む処理は Dart 側で行う。
//
// リポジトリルートから実行すること。
import 'dart:io';

const _basePath = '/flutter_deck_slides';

void main() {
  final repoRoot = Directory.current;
  final slidesDir = Directory('${repoRoot.path}/slides');

  if (!slidesDir.existsSync()) {
    stderr.writeln('エラー: slides/ ディレクトリが見つかりません。リポジトリルートで実行してください。');
    exit(1);
  }

  final slideDirs = slidesDir
      .listSync()
      .whereType<Directory>()
      .where((d) => File('${d.path}/pubspec.yaml').existsSync())
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  if (slideDirs.isEmpty) {
    stdout.writeln('ビルド対象のスライドがありません。');
    return;
  }

  var failureCount = 0;

  for (final dir in slideDirs) {
    final slideName = dir.uri.pathSegments.where((s) => s.isNotEmpty).last;
    final baseHref = '$_basePath/$slideName/';

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

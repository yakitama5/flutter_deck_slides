// 新規スライド雛形を作成するスクリプト。
// 実行: dart run tool/create_slide.dart <yyyymm>_<event>
// (melos 経由: melos run create:slide -- <yyyymm>_<event>)
//
// リポジトリルートから実行すること。
import 'dart:io';

final _namePattern = RegExp(r'^(\d{6})_([a-z][a-z0-9]*)$');

const _flutterDeckVersion = '^0.29.0';
const _flutterDeckWebClientVersion = '^0.4.0';
const _flutterLintsVersion = '^6.0.0';

void main(List<String> arguments) {
  final rawName = arguments.isNotEmpty ? arguments.first : '';

  final match = _namePattern.firstMatch(rawName);
  if (match == null) {
    stderr.writeln(
      'エラー: スライド名は "<yyyymm>_<event>" 形式で指定してください '
      '(例: 202609_flutterkaigi)。渡された値: "$rawName"',
    );
    exit(1);
  }

  final yyyymm = match.group(1)!;
  final event = match.group(2)!;
  final dirName = '${yyyymm}_$event';
  final packageName = '${event}_$yyyymm';
  final className = _toPascalCase(event);

  final repoRoot = Directory.current;
  if (!File('${repoRoot.path}/pubspec.yaml').existsSync() ||
      !Directory('${repoRoot.path}/slides').existsSync()) {
    stderr.writeln('エラー: リポジトリルート(slides/ が存在する場所)で実行してください。');
    exit(1);
  }

  final slideDir = Directory('${repoRoot.path}/slides/$dirName');
  if (slideDir.existsSync()) {
    stderr.writeln('エラー: ${slideDir.path} は既に存在します。');
    exit(1);
  }

  stdout.writeln('▸ flutter create --platforms=web --project-name $packageName slides/$dirName');
  final createResult = Process.runSync(
    'flutter',
    [
      'create',
      '--platforms=web',
      '--project-name',
      packageName,
      'slides/$dirName',
    ],
    workingDirectory: repoRoot.path,
    runInShell: true,
  );
  stdout.write(createResult.stdout);
  stderr.write(createResult.stderr);
  if (createResult.exitCode != 0) {
    stderr.writeln('エラー: flutter create に失敗しました。');
    exit(createResult.exitCode);
  }

  _rewritePubspec(slideDir: slideDir, packageName: packageName);
  _rewriteMainDart(slideDir: slideDir, className: className, title: dirName);
  _rewriteAnalysisOptions(slideDir: slideDir);
  _appendWorkspaceEntry(repoRoot: repoRoot, dirName: dirName);

  stdout.writeln('▸ dart pub get');
  final pubGetResult = Process.runSync(
    'dart',
    ['pub', 'get'],
    workingDirectory: repoRoot.path,
    runInShell: true,
  );
  stdout.write(pubGetResult.stdout);
  stderr.write(pubGetResult.stderr);
  if (pubGetResult.exitCode != 0) {
    stderr.writeln('エラー: dart pub get に失敗しました。');
    exit(pubGetResult.exitCode);
  }

  stdout.writeln('');
  stdout.writeln('✔ slides/$dirName ($packageName) を作成しました。');
  stdout.writeln('  起動: dart run melos run dev');
}

void _rewritePubspec({required Directory slideDir, required String packageName}) {
  final pubspecFile = File('${slideDir.path}/pubspec.yaml');
  final content = '''
name: $packageName
description: "flutter_deck slide."
publish_to: 'none'
resolution: workspace

version: 1.0.0+1

environment:
  sdk: ^3.12.2

dependencies:
  flutter:
    sdk: flutter
  flutter_deck: $_flutterDeckVersion
  flutter_deck_web_client: $_flutterDeckWebClientVersion

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: $_flutterLintsVersion

flutter:
  uses-material-design: true
''';
  pubspecFile.writeAsStringSync(content);
}

void _rewriteMainDart({
  required Directory slideDir,
  required String className,
  required String title,
}) {
  final templateFile = File(
    '${Directory.current.path}/tool/templates/main.dart.template',
  );
  final template = templateFile.readAsStringSync();
  final rendered = template
      .replaceAll('{{CLASS_NAME}}', className)
      .replaceAll('{{TITLE}}', title);

  File('${slideDir.path}/lib/main.dart').writeAsStringSync(rendered);
}

void _rewriteAnalysisOptions({required Directory slideDir}) {
  File(
    '${slideDir.path}/analysis_options.yaml',
  ).writeAsStringSync("include: ../../analysis_options.yaml\n");
}

void _appendWorkspaceEntry({required Directory repoRoot, required String dirName}) {
  final rootPubspec = File('${repoRoot.path}/pubspec.yaml');
  final lines = rootPubspec.readAsLinesSync();
  final newEntry = '  - slides/$dirName';

  if (lines.contains(newEntry)) return;

  final workspaceIndex = lines.indexWhere((l) => l.trim() == 'workspace:');
  if (workspaceIndex == -1) {
    stderr.writeln('エラー: ルート pubspec.yaml に workspace: セクションが見つかりません。');
    exit(1);
  }

  var insertAt = workspaceIndex + 1;
  while (insertAt < lines.length && lines[insertAt].startsWith('  - ')) {
    insertAt++;
  }

  lines.insert(insertAt, newEntry);
  rootPubspec.writeAsStringSync('${lines.join('\n')}\n');
}

String _toPascalCase(String snakeCase) {
  return snakeCase
      .split('_')
      .where((part) => part.isNotEmpty)
      .map((part) => part[0].toUpperCase() + part.substring(1))
      .join();
}

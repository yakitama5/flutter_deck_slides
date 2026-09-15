// 標準ライブラリのみで公開パス・対象選択・集約処理を検証する。
// 実行: dart run tool/web_build_test.dart
import 'dart:io';

import 'web_build_options.dart';

void main() {
  final toolDir = File.fromUri(Platform.script).parent;
  final fixture = Directory.systemTemp.createTempSync('web-pages-test-');
  try {
    _checkOptions();
    for (final name in ['alpha', 'beta', 'gamma']) {
      _write(fixture, 'slides/$name/pubspec.yaml', 'name: $name\n');
      _write(fixture, 'slides/$name/build/web/index.html', '<h1>$name</h1>');
      _write(fixture, 'slides/$name/build/web/assets/model.glb', '$name model');
    }
    _write(fixture, 'slides/references/image.png', 'not a slide');
    _write(fixture, 'dist/old/index.html', 'previous deployment');

    final previewEnvironment = {
      'WEB_BASE_PATH': '/flutter_deck_slides/previews/pr-56/',
      'WEB_SLIDES': ' beta,alpha\r\n beta ',
      'PR_NUMBER': '56',
    };
    var result = _run(
      toolDir,
      fixture,
      'prepare_pages.dart',
      previewEnvironment,
    );
    _expect(
      result.exitCode == 0,
      'Preview preparation failed: ${result.stderr}',
    );
    final previewIndex = File('${fixture.path}/dist/index.html')
        .readAsStringSync();
    _expect(
      previewIndex.contains(
            'href="/flutter_deck_slides/previews/pr-56/alpha/"',
          ) &&
          previewIndex.contains(
            'href="/flutter_deck_slides/previews/pr-56/beta/"',
          ),
      'Preview links must stay within the PR prefix.',
    );
    _expect(previewIndex.contains('PR #56 プレビュー'), 'Preview label is missing.');
    _expect(
      !Directory('${fixture.path}/dist/gamma').existsSync(),
      'Unselected slide was copied.',
    );
    _expect(
      !Directory('${fixture.path}/dist/old').existsSync(),
      'Old output was not cleared.',
    );
    _expect(
      File('${fixture.path}/dist/beta/assets/model.glb').readAsStringSync() ==
          'beta model',
      'Nested model asset was not preserved.',
    );

    result = _run(toolDir, fixture, 'prepare_pages.dart', {});
    _expect(
      result.exitCode == 0,
      'Production preparation failed: ${result.stderr}',
    );
    final productionIndex = File('${fixture.path}/dist/index.html')
        .readAsStringSync();
    _expect(
      productionIndex.contains('href="/flutter_deck_slides/gamma/"'),
      'Default build must include every slide.',
    );
    _expect(
      !productionIndex.contains('プレビュー'),
      'Production index was marked as a preview.',
    );

    result = _run(toolDir, fixture, 'prepare_pages.dart', {
      'WEB_SLIDES': 'missing',
    });
    _expect(result.exitCode != 0, 'Unknown selected slide must fail.');
    _expect(
      File('${fixture.path}/dist/index.html').readAsStringSync() ==
          productionIndex,
      'Invalid selection must not remove the previous output.',
    );
    File('${fixture.path}/slides/beta/build/web/index.html').deleteSync();
    result = _run(toolDir, fixture, 'prepare_pages.dart', {
      'WEB_SLIDES': 'beta',
    });
    _expect(result.exitCode != 0, 'Missing selected build must fail.');
    _expect(
      File('${fixture.path}/dist/index.html').readAsStringSync() ==
          productionIndex,
      'Missing build must not remove the previous output.',
    );

    if (!Platform.isWindows) {
      _checkBuildArguments(toolDir, fixture, previewEnvironment);
    }
    _checkSdkAssetPruning(toolDir, Directory('${fixture.path}/sdk-assets'));
    stdout.writeln(
      'PASS: Web publication paths, selected slides, preview index, SDK asset pruning, assets, and failure handling.',
    );
  } finally {
    fixture.deleteSync(recursive: true);
  }
}

void _checkOptions() {
  _expect(
    WebBuildOptions.fromEnvironment({}).slideBaseHref('alpha') ==
        '/flutter_deck_slides/alpha/',
    'Default production prefix changed.',
  );
  _expect(
    WebBuildOptions.fromEnvironment({'WEB_BASE_PATH': '/'})
            .slideBaseHref('alpha') ==
        '/alpha/',
    'Root-level site must use a single leading slash.',
  );
  for (final environment in [
    {'WEB_BASE_PATH': '/previews/../main'},
    {'WEB_BASE_PATH': 'https://example.com'},
    {'WEB_BASE_PATH': '//example.com/path'},
    {'WEB_BASE_PATH': '/preview?query'},
    {'WEB_SLIDES': '../alpha'},
    {'PR_NUMBER': '0'},
    {'PR_NUMBER': '<script>'},
  ]) {
    var rejected = false;
    try {
      WebBuildOptions.fromEnvironment(environment);
    } on FormatException {
      rejected = true;
    }
    _expect(rejected, 'Invalid options were accepted: $environment');
  }
}

void _checkBuildArguments(
  Directory toolDir,
  Directory fixture,
  Map<String, String> previewEnvironment,
) {
  _write(
    fixture,
    'bin/flutter',
    '#!/bin/sh\nprintf "%s\\n" "\$PWD|\$*" >> "\$WEB_TEST_BUILD_LOG"\n',
  );
  final mode = Process.runSync('chmod', ['+x', '${fixture.path}/bin/flutter']);
  _expect(mode.exitCode == 0, 'Could not create fake Flutter executable.');
  final log = File('${fixture.path}/build-arguments.log');
  final result = _run(toolDir, fixture, 'build_web.dart', {
    ...previewEnvironment,
    'PATH': '${fixture.path}/bin:${Platform.environment['PATH'] ?? ''}',
    'WEB_TEST_BUILD_LOG': log.path,
  });
  _expect(result.exitCode == 0, 'Selected web build failed: ${result.stderr}');
  final calls = log.readAsLinesSync();
  _expect(
    calls.length == 2,
    'Flutter must build each selected slide exactly once.',
  );
  _expect(
    calls[0].endsWith(
          '/slides/alpha|build web --base-href /flutter_deck_slides/previews/pr-56/alpha/',
        ) &&
        calls[1].endsWith(
          '/slides/beta|build web --base-href /flutter_deck_slides/previews/pr-56/beta/',
        ),
    'Flutter build arguments do not match the selected slides and preview prefix: $calls',
  );
}

void _checkSdkAssetPruning(Directory toolDir, Directory fixture) {
  const jsBuild =
      '{"compileTarget":"dart2js","renderer":"canvaskit","mainJsPath":"main.dart.js"}';
  const wasmBuild =
      '{"compileTarget":"dart2wasm","renderer":"skwasm","mainWasmPath":"main.dart.wasm"}';
  const cases = <String, String?>{
    'js': '{"builds":[$jsBuild,{}]}',
    'js_only': '{"builds":[$jsBuild]}',
    'wasm': '{"builds":[$wasmBuild,$jsBuild,{}]}',
    'unknown': '{"builds":[{"compileTarget":"future","renderer":"unknown"}]}',
    'mixed_unknown': '{"builds":[$jsBuild,{"renderer":"unknown"}]}',
    'malformed': '{"builds":[invalid]}',
    'missing': null,
    'empty': '{"builds":[]}',
    'placeholder': '{"builds":[{}]}',
    'no_builds': '{}',
    'legacy_worker': '{"builds":[$jsBuild,{}]}',
  };
  const prunableAssets = [
    'canvaskit/canvaskit.js.symbols',
    'canvaskit/chromium/canvaskit.js.symbols',
    'canvaskit/webparagraph/canvaskit.js.symbols',
    'canvaskit/skwasm.js.symbols',
    'canvaskit/skwasm.js',
    'canvaskit/skwasm.wasm',
    'canvaskit/skwasm_heavy.js',
    'canvaskit/skwasm_heavy.wasm',
    'canvaskit/wimp.js',
    'canvaskit/wimp.wasm',
  ];
  const retainedAssets = [
    'canvaskit/canvaskit.js',
    'canvaskit/canvaskit.wasm',
    'canvaskit/chromium/canvaskit.js',
    'canvaskit/chromium/canvaskit.wasm',
    'canvaskit/webparagraph/canvaskit.js',
    'canvaskit/webparagraph/canvaskit.wasm',
    'canvaskit/unknown.wasm',
    'canvaskit/skwasm_future.wasm',
    'canvaskit/nested/skwasm.wasm',
    'assets/skwasm.wasm',
    'assets/application.symbols',
    'assets/model.glb',
  ];
  for (final entry in cases.entries) {
    final name = entry.key;
    final buildDir = 'slides/$name/build/web';
    _write(fixture, 'slides/$name/pubspec.yaml', 'name: $name\n');
    _write(fixture, '$buildDir/index.html', '<h1>$name</h1>');
    if (entry.value != null) {
      _write(
        fixture,
        '$buildDir/flutter_bootstrap.js',
        '// Loader code mentions skwasm even for a JS-only build.\n'
            '_flutter.buildConfig = ${entry.value};\n'
            '_flutter.loader.load();\n',
      );
    }
    _write(
      fixture,
      '$buildDir/flutter_service_worker.js',
      name == 'legacy_worker'
          ? 'const RESOURCES = {"canvaskit/skwasm.wasm": "hash"};\n'
          : 'self.addEventListener("install", () => self.skipWaiting());\n',
    );
    for (final asset in [...prunableAssets, ...retainedAssets]) {
      _write(fixture, '$buildDir/$asset', '$name/$asset');
    }
  }

  final result = _run(toolDir, fixture, 'prepare_pages.dart', {});
  _expect(
    result.exitCode == 0,
    'SDK asset preparation failed: ${result.stderr}',
  );
  for (final name in cases.keys) {
    final shouldPrune = name == 'js' || name == 'js_only';
    for (final asset in prunableAssets) {
      final output = File('${fixture.path}/dist/$name/$asset');
      _expect(
        output.existsSync() != shouldPrune,
        '$name: $asset must ${shouldPrune ? 'be omitted' : 'be retained'}.',
      );
      _expect(
        File('${fixture.path}/slides/$name/build/web/$asset').existsSync(),
        'Preparing Pages must not remove the original build asset: $name/$asset',
      );
    }
    for (final asset in retainedAssets) {
      final output = File('${fixture.path}/dist/$name/$asset');
      _expect(
        output.existsSync() && output.readAsStringSync() == '$name/$asset',
        '$name: required or unrelated asset was changed or omitted: $asset',
      );
    }
  }
}

ProcessResult _run(
  Directory toolDir,
  Directory fixture,
  String script,
  Map<String, String> environment,
) => Process.runSync(
  Platform.resolvedExecutable,
  ['${toolDir.path}/$script'],
  workingDirectory: fixture.path,
  environment: {
    ...Platform.environment,
    'WEB_BASE_PATH': '',
    'WEB_SLIDES': '',
    'PR_NUMBER': '',
    ...environment,
  },
);

void _write(Directory fixture, String path, String contents) {
  final file = File('${fixture.path}/$path');
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(contents);
}

void _expect(bool condition, String message) {
  if (!condition) throw StateError(message);
}

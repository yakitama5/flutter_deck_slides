import 'dart:io';

/// Web ビルドと Pages の一覧ページで共通の公開先・対象を使用する。
class WebBuildOptions {
  WebBuildOptions.fromEnvironment(Map<String, String> environment)
    : basePath = _parseBasePath(environment['WEB_BASE_PATH']),
      selectedSlides = _parseSlides(environment['WEB_SLIDES']),
      pullRequestNumber = _parsePullRequest(environment['PR_NUMBER']);

  final String basePath;
  final Set<String> selectedSlides;
  final int? pullRequestNumber;

  String slideBaseHref(String slideName) => '$basePath/$slideName/';

  List<Directory> slideDirectories(Directory repoRoot) {
    final slidesDir = Directory('${repoRoot.path}/slides');
    if (!slidesDir.existsSync()) {
      throw const FormatException('slides/ ディレクトリが見つかりません。リポジトリルートで実行してください。');
    }

    final slideDirs =
        slidesDir
            .listSync(followLinks: false)
            .whereType<Directory>()
            .where((dir) => File('${dir.path}/pubspec.yaml').existsSync())
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));
    final names = slideDirs.map(slideDirectoryName).toSet();
    final missing = selectedSlides.difference(names);
    if (missing.isNotEmpty) {
      throw FormatException('WEB_SLIDES の対象が見つかりません: ${missing.join(', ')}');
    }
    return slideDirs
        .where(
          (dir) =>
              selectedSlides.isEmpty ||
              selectedSlides.contains(slideDirectoryName(dir)),
        )
        .toList();
  }

  static String _parseBasePath(String? value) {
    final path = value?.trim().isNotEmpty == true
        ? value!.trim()
        : '/flutter_deck_slides';
    if (!path.startsWith('/') ||
        !RegExp(r'^/[A-Za-z0-9._~/-]*$').hasMatch(path) ||
        path.split('/').any((part) => part == '.' || part == '..') ||
        path.contains('//')) {
      throw const FormatException(
        'WEB_BASE_PATH は / で始まる公開パスにしてください（例: /flutter_deck_slides/previews/pr-56）。',
      );
    }
    return path.replaceFirst(RegExp(r'/$'), '');
  }

  static Set<String> _parseSlides(String? value) {
    final names = (value ?? '')
        .split(RegExp(r'[,\r\n]'))
        .map((name) => name.trim())
        .where((name) => name.isNotEmpty)
        .toSet();
    if (names.any((name) => !RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(name))) {
      throw const FormatException('WEB_SLIDES は slides/ 直下のディレクトリ名を指定してください。');
    }
    return names;
  }

  static int? _parsePullRequest(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final number = int.tryParse(value.trim());
    if (!RegExp(r'^[0-9]+$').hasMatch(value.trim()) ||
        number == null ||
        number <= 0) {
      throw const FormatException('PR_NUMBER は正の整数にしてください。');
    }
    return number;
  }
}

String slideDirectoryName(Directory directory) =>
    directory.uri.pathSegments.where((part) => part.isNotEmpty).last;

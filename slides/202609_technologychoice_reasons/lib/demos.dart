import 'package:flutter/material.dart';

import 'i18n/strings.g.dart';

const _blue = Color(0xFF4262C5);
const _purple = Color(0xFF7962B5);
const _ink = Color(0xFF292A47);

ThemeData _sampleTheme({Color seed = _blue, bool dark = false}) {
  final scheme = ColorScheme.fromSeed(
    seedColor: seed,
    brightness: dark ? Brightness.dark : Brightness.light,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: 'Kiwi Maru',
    textTheme: const TextTheme(
      headlineSmall: TextStyle(fontSize: 28, fontWeight: FontWeight.w600),
      titleLarge: TextStyle(fontSize: 25, fontWeight: FontWeight.w500),
      titleMedium: TextStyle(fontSize: 23, fontWeight: FontWeight.w500),
      titleSmall: TextStyle(fontSize: 21, fontWeight: FontWeight.w500),
      bodyLarge: TextStyle(fontSize: 23),
      bodyMedium: TextStyle(fontSize: 20),
      bodySmall: TextStyle(fontSize: 17),
      labelLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
      labelMedium: TextStyle(fontSize: 18),
      labelSmall: TextStyle(fontSize: 16),
    ),
    visualDensity: VisualDensity.standard,
    iconTheme: const IconThemeData(size: 26),
  );
}

/// A real Material 3 theme preview, independent of the deck's typography.
class ThemeChoiceDemo extends StatefulWidget {
  const ThemeChoiceDemo({super.key});

  @override
  State<ThemeChoiceDemo> createState() => _ThemeChoiceDemoState();
}

class _ThemeChoiceDemoState extends State<ThemeChoiceDemo> {
  bool _purpleSeed = false;
  bool _dark = false;
  bool _saved = false;

  void _reset() => setState(() {
    _purpleSeed = false;
    _dark = false;
    _saved = false;
  });

  @override
  Widget build(BuildContext context) => _DemoSurface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DemoHeader(label: '色から、UI 全体へ', onReset: _reset),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: SegmentedButton<bool>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(
                    value: false,
                    label: Text('青'),
                    icon: Icon(Icons.circle, color: _blue),
                  ),
                  ButtonSegment(
                    value: true,
                    label: Text('紫'),
                    icon: Icon(Icons.circle, color: _purple),
                  ),
                ],
                selected: {_purpleSeed},
                onSelectionChanged: (value) =>
                    setState(() => _purpleSeed = value.single),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: SegmentedButton<bool>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(
                    value: false,
                    label: Text('Light'),
                    icon: Icon(Icons.light_mode_outlined),
                  ),
                  ButtonSegment(
                    value: true,
                    label: Text('Dark'),
                    icon: Icon(Icons.dark_mode_outlined),
                  ),
                ],
                selected: {_dark},
                onSelectionChanged: (value) =>
                    setState(() => _dark = value.single),
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        Expanded(
          child: Theme(
            data: _sampleTheme(
              seed: _purpleSeed ? _purple : _blue,
              dark: _dark,
            ),
            child: Builder(
              builder: (context) {
                final colors = Theme.of(context).colorScheme;
                return Material(
                  key: const ValueKey('theme-preview'),
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(24),
                  clipBehavior: Clip.antiAlias,
                  child: Padding(
                    padding: const EdgeInsets.all(26),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: colors.primaryContainer,
                              foregroundColor: colors.onPrimaryContainer,
                              child: const Icon(Icons.code),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                'Repository Search',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ),
                            Icon(Icons.palette_outlined, color: colors.primary),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Card.filled(
                          margin: EdgeInsets.zero,
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'flutter / flutter',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium,
                                ),
                                const SizedBox(height: 6),
                                const Text('小さな工夫を、どの画面にも。'),
                                const SizedBox(height: 18),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.star_rounded,
                                      color: colors.primary,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 6),
                                    const Text('170k'),
                                    const Spacer(),
                                    FilledButton.icon(
                                      onPressed: () =>
                                          setState(() => _saved = !_saved),
                                      icon: Icon(
                                        _saved
                                            ? Icons.bookmark
                                            : Icons.bookmark_border,
                                      ),
                                      label: Text(_saved ? '保存済み' : '保存する'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            _ColorDot(color: colors.primary, label: 'primary'),
                            const SizedBox(width: 20),
                            _ColorDot(
                              color: colors.secondary,
                              label: 'secondary',
                            ),
                            const SizedBox(width: 20),
                            _ColorDot(
                              color: colors.tertiary,
                              label: 'tertiary',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 12),
        const _Caption('ColorScheme.fromSeed → カード・ボタン・背景に反映'),
      ],
    ),
  );
}

/// Uses the source application's width classes and navigation behavior.
/// The logical viewport is simulated; the whole preview is fitted to the slide.
class ResponsiveChoiceDemo extends StatefulWidget {
  const ResponsiveChoiceDemo({super.key});

  @override
  State<ResponsiveChoiceDemo> createState() => _ResponsiveChoiceDemoState();
}

class _ResponsiveChoiceDemoState extends State<ResponsiveChoiceDemo> {
  int _width = 390;
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) => _DemoSurface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DemoHeader(
          label: '幅が変わると、居場所が変わる',
          onReset: () => setState(() {
            _width = 390;
            _selectedIndex = 0;
          }),
        ),
        const SizedBox(height: 16),
        SegmentedButton<int>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(
              value: 390,
              label: Text('390 dp'),
              icon: Icon(Icons.smartphone),
            ),
            ButtonSegment(
              value: 720,
              label: Text('720 dp'),
              icon: Icon(Icons.tablet_mac),
            ),
            ButtonSegment(
              value: 1024,
              label: Text('1024 dp'),
              icon: Icon(Icons.tablet),
            ),
          ],
          selected: {_width},
          onSelectionChanged: (value) => setState(() => _width = value.single),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _Pill(
              label: _width < 600
                  ? 'compact'
                  : _width < 840
                  ? 'medium'
                  : 'expanded',
            ),
            const SizedBox(width: 12),
            Text(
              _width < 600
                  ? '下部ナビゲーション'
                  : _width < 840
                  ? 'アイコンのナビゲーション'
                  : 'ラベル付きナビゲーション',
              style: const TextStyle(fontSize: 21),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFFE8EAF5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: SizedBox(
                    width: _width.toDouble(),
                    height: 450,
                    child: MediaQuery(
                      data: MediaQuery.of(context).copyWith(
                        size: Size(_width.toDouble(), 450),
                        textScaler: TextScaler.noScaling,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: _AdaptivePreview(
                          selectedIndex: _selectedIndex,
                          onChanged: (index) =>
                              setState(() => _selectedIndex = index),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        const _Caption('仮想の利用可能幅で実行・全体を縮小表示／本文上限 840 dp'),
        const SizedBox(height: 3),
        const _Caption('compact < 600  ·  medium < 840  ·  expanded ≥ 840'),
      ],
    ),
  );
}

class _AdaptivePreview extends StatelessWidget {
  const _AdaptivePreview({
    required this.selectedIndex,
    required this.onChanged,
  });
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 600;
    final expanded = width >= 840;
    final body = Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 840),
        child: Padding(
          padding: EdgeInsets.all(compact ? 18 : 26),
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              Text(
                selectedIndex == 0 ? 'Repository Search' : 'Settings',
                style: TextStyle(
                  fontSize: compact ? 25 : 30,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 18),
              if (selectedIndex == 0) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.search),
                      SizedBox(width: 12),
                      Text('Flutter UI', style: TextStyle(fontSize: 24)),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                const _RepositoryLine(
                  name: 'flutter / flutter',
                  description: 'Beautiful apps, everywhere.',
                ),
                const SizedBox(height: 12),
                const _RepositoryLine(
                  name: 'dart-lang / sdk',
                  description: 'A language for every screen.',
                ),
              ] else ...[
                Card.filled(
                  child: Padding(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('アプリの設定', style: TextStyle(fontSize: 26)),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Icon(
                              Icons.palette_outlined,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'テーマ: Blue',
                              style: TextStyle(fontSize: 23),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Row(
                          children: [
                            Icon(Icons.language),
                            SizedBox(width: 12),
                            Text('言語: 日本語', style: TextStyle(fontSize: 23)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: compact
          ? body
          : Row(
              children: [
                NavigationRail(
                  key: const ValueKey('adaptive-rail'),
                  extended: expanded,
                  minExtendedWidth: 208,
                  selectedIndex: selectedIndex,
                  onDestinationSelected: onChanged,
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.search),
                      label: Text('検索'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.settings_outlined),
                      label: Text('設定'),
                    ),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(child: body),
              ],
            ),
      bottomNavigationBar: compact
          ? NavigationBar(
              key: const ValueKey('adaptive-bottom-nav'),
              height: 72,
              selectedIndex: selectedIndex,
              onDestinationSelected: onChanged,
              destinations: const [
                NavigationDestination(icon: Icon(Icons.search), label: '検索'),
                NavigationDestination(
                  icon: Icon(Icons.settings_outlined),
                  label: '設定',
                ),
              ],
            )
          : null,
    );
  }
}

/// Runs generated Slang translations with local instances, so changing the
/// sample language cannot alter the surrounding Japanese slide deck.
class LocalizationChoiceDemo extends StatefulWidget {
  const LocalizationChoiceDemo({super.key});

  @override
  State<LocalizationChoiceDemo> createState() => _LocalizationChoiceDemoState();
}

class _LocalizationChoiceDemoState extends State<LocalizationChoiceDemo> {
  AppLocale _locale = AppLocale.ja;
  int _count = 1;
  final _translations = {
    AppLocale.en: AppLocale.en.buildSync(),
    AppLocale.ja: AppLocale.ja.buildSync(),
  };

  @override
  Widget build(BuildContext context) {
    final strings = _translations[_locale]!;
    return _DemoSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _DemoHeader(
            label: '同じ UI に、違うことば',
            onReset: () => setState(() {
              _locale = AppLocale.ja;
              _count = 1;
            }),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SegmentedButton<AppLocale>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(value: AppLocale.ja, label: Text('日本語')),
                    ButtonSegment(value: AppLocale.en, label: Text('English')),
                  ],
                  selected: {_locale},
                  onSelectionChanged: (value) =>
                      setState(() => _locale = value.single),
                ),
              ),
              const SizedBox(width: 24),
              const Text('件数', style: TextStyle(fontSize: 23)),
              const SizedBox(width: 10),
              IconButton.outlined(
                tooltip: '件数を減らす',
                onPressed: _count > 0 ? () => setState(() => _count--) : null,
                icon: const Icon(Icons.remove),
              ),
              SizedBox(
                width: 44,
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    '$_count',
                    key: const ValueKey('result-count'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 27),
                  ),
                ),
              ),
              IconButton.outlined(
                tooltip: '件数を増やす',
                onPressed: _count < 5 ? () => setState(() => _count++) : null,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Expanded(
            child: Theme(
              data: _sampleTheme(seed: _purple),
              child: Builder(
                builder: (context) => Material(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(24),
                  child: Padding(
                    padding: const EdgeInsets.all(26),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                strings.search,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall,
                              ),
                            ),
                            Icon(
                              Icons.translate,
                              color: Theme.of(context).colorScheme.primary,
                              size: 30,
                            ),
                          ],
                        ),
                        const SizedBox(height: 26),
                        Semantics(
                          liveRegion: true,
                          child: Text(
                            strings.result(count: _count),
                            key: const ValueKey('translated-result'),
                            style: TextStyle(
                              fontSize: 27,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        if (_count == 0)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 28),
                            child: Text(
                              strings.empty,
                              style: const TextStyle(fontSize: 22),
                            ),
                          )
                        else
                          Card.filled(
                            margin: EdgeInsets.zero,
                            child: Padding(
                              padding: const EdgeInsets.all(22),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'flutter / flutter',
                                    style: TextStyle(
                                      fontSize: 25,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Row(
                                    children: [
                                      const Icon(Icons.bookmark, size: 23),
                                      const SizedBox(width: 8),
                                      Text(strings.saved),
                                      const Spacer(),
                                      Icon(
                                        Icons.open_in_new,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        const Spacer(),
                        const Text(
                          '※ 検索結果の件数と言語を試すための固定データ',
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const _Caption('Slang で YAML → 型付き Dart を生成した、小さな実装'),
        ],
      ),
    );
  }
}

class _DemoSurface extends StatelessWidget {
  const _DemoSurface({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => FittedBox(
    fit: BoxFit.contain,
    child: SizedBox(
      width: 760,
      height: 600,
      child: Theme(
        data: _sampleTheme(),
        child: Material(
          color: const Color(0xFFF0F1FA),
          borderRadius: BorderRadius.circular(28),
          clipBehavior: Clip.antiAlias,
          child: DefaultTextStyle(
            style: const TextStyle(
              fontFamily: 'Kiwi Maru',
              fontSize: 22,
              color: _ink,
            ),
            child: Padding(padding: const EdgeInsets.all(22), child: child),
          ),
        ),
      ),
    ),
  );
}

class _DemoHeader extends StatelessWidget {
  const _DemoHeader({required this.label, required this.onReset});
  final String label;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      const Icon(Icons.play_circle_outline, color: _purple, size: 28),
      const SizedBox(width: 10),
      Expanded(
        child: Text(
          label,
          style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w500),
        ),
      ),
      Tooltip(
        message: 'サンプルを最初の状態に戻す',
        child: TextButton.icon(
          onPressed: onReset,
          icon: const Icon(Icons.restart_alt, size: 22),
          label: const Text('リセット', style: TextStyle(fontSize: 20)),
        ),
      ),
    ],
  );
}

class _Caption extends StatelessWidget {
  const _Caption(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(fontSize: 17, color: Color(0xFF666680)),
  );
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: const Color(0xFFDEDAF2),
      borderRadius: BorderRadius.circular(30),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 7),
    child: Text(
      label,
      style: const TextStyle(color: Color(0xFF59438B), fontSize: 20),
    ),
  );
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({required this.color, required this.label});
  final Color color;
  final String label;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 8),
      Text(label, style: Theme.of(context).textTheme.bodySmall),
    ],
  );
}

class _RepositoryLine extends StatelessWidget {
  const _RepositoryLine({required this.name, required this.description});
  final String name;
  final String description;
  @override
  Widget build(BuildContext context) => Card.filled(
    margin: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 18),
          ),
        ],
      ),
    ),
  );
}

import 'package:flutter/material.dart';
import 'package:flutter_deck/flutter_deck.dart';

/// スライド左上に自前描画する見出し（headline + アクセント下線）。
class SlideHeadline extends StatelessWidget {
  const SlideHeadline({required this.text, super.key, this.accentColor});

  final String text;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final textTheme = FlutterDeckTheme.of(context).textTheme;
    final color = accentColor ?? Theme.of(context).colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(text, style: textTheme.header),
        const SizedBox(height: 8),
        Container(
          width: 64,
          height: 6,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';

/// MD3 調のカード。`Card` の代わりに使う共通コンテナ。
class ContentCard extends StatelessWidget {
  const ContentCard({
    required this.child,
    super.key,
    this.padding = const EdgeInsets.all(24),
    this.color,
    this.borderColor,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: borderColor ?? colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: child,
    );
  }
}

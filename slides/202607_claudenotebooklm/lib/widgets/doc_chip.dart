import 'package:flutter/material.dart';

/// 資料チップ（アイコン + ラベル）。Excel/Slack/Backlog 等の色分けに使う。
class DocChip extends StatelessWidget {
  const DocChip({
    required this.label,
    required this.icon,
    required this.color,
    super.key,
    this.sublabel,
  });

  final String label;
  final IconData icon;
  final Color color;
  final String? sublabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 28, color: color),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 22,
                ),
              ),
              if (sublabel != null)
                Text(
                  sublabel!,
                  style: TextStyle(
                    color: color.withValues(alpha: 0.8),
                    fontSize: 17,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

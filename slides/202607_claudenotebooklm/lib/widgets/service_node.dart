import 'package:flutter/material.dart';

/// サービスノード（丸角タイル + アイコン + 名前 + ブランド色）。構成図・全体像図で使用。
class ServiceNode extends StatelessWidget {
  const ServiceNode({
    required this.label,
    required this.icon,
    required this.color,
    super.key,
    this.sublabel,
    this.width = 220,
  });

  final String label;
  final String? sublabel;
  final IconData icon;
  final Color color;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: color,
            child: Icon(icon, color: Colors.white, size: 32),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
          if (sublabel != null) ...[
            const SizedBox(height: 4),
            Text(
              sublabel!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color.withValues(alpha: 0.85),
                fontSize: 18,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

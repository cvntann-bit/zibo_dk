import 'package:flutter/material.dart';

import '../theme.dart';

/// Henüz yapılmamış sekmeler — hangi adımda geleceğini gösterir (bkz. docs/admin_panel.md).
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({super.key, required this.step, required this.text});

  final String step;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(20),
        decoration: stickerDecoration(fill: kGoldPale),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Yakında · $step', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 8),
            Text(text, textAlign: TextAlign.center, style: const TextStyle(color: kInkSoft)),
          ],
        ),
      ),
    );
  }
}

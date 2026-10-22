import 'package:flutter/material.dart';

import 'sticker_style.dart';

/// Zibo'nun konuşma balonu — uygulamanın çıkartma (sticker) diliyle: krem dolgu, koyu çerçeve, ofsetli gölge.
/// İsteğe bağlı kalın [title] (ör. "Tanıştığıma memnun oldum, Ayşe!") + [text] (+ küçük [hint]).
class ZiboBubble extends StatelessWidget {
  const ZiboBubble({super.key, this.title, required this.text, this.hint});

  final String? title;
  final String text;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF7),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: kStickerOutline, width: 3),
        boxShadow: const [
          BoxShadow(color: kStickerOutline, offset: Offset(4, 4)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null) ...[
            Text(
              title!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF14110C),
                fontSize: 21,
                height: 1.3,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
          ],
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF14110C),
              fontSize: 19,
              height: 1.35,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (hint != null) ...[
            const SizedBox(height: 10),
            Text(
              hint!,
              style: const TextStyle(
                color: Color(0xFF7A6A52),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

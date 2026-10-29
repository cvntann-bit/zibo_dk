import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../theme.dart';

/// Son 100 yönetici işlemi (`adminLog`), en yenisi üstte.
class AdminLogScreen extends StatelessWidget {
  const AdminLogScreen({super.key});

  static String _fmt(DateTime t) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(t.day)}.${two(t.month)}.${t.year} ${two(t.hour)}:${two(t.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final query = FirebaseFirestore.instance.collection('adminLog').orderBy('at', descending: true).limit(100);
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: query.snapshots(),
      builder: (context, snap) {
        if (snap.hasError) return Center(child: Text('${snap.error}', style: const TextStyle(color: kBad)));
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snap.data!.docs;
        if (docs.isEmpty) return const Center(child: Text('Henüz işlem yok.'));
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            final d = docs[i].data();
            final at = (d['at'] as Timestamp?)?.toDate();
            return Container(
              padding: const EdgeInsets.all(14),
              decoration: stickerDecoration(borderWidth: 2, shadowOffset: const Offset(2, 2)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${d['action']} · ${d['target']}',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  Text(at == null ? 'yazılıyor…' : _fmt(at), style: const TextStyle(color: kInkSoft, fontSize: 12)),
                  const SizedBox(height: 6),
                  Text('${d['before']} → ${d['after']}', style: const TextStyle(fontSize: 13)),
                  if (d['note'] != null) Text('${d['note']}', style: const TextStyle(color: kInkSoft, fontSize: 13)),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

/// Her yönetici yazımı `adminLog/{id}` kaydıyla AYNI batch'te yapılır — kayıtsız
/// değişiklik olamaz (kayıt yazılamazsa değişiklik de yazılmaz).
void addAdminLog(
  WriteBatch batch, {
  required String action,
  required String target,
  required Map<String, Object?> before,
  required Map<String, Object?> after,
  String? note,
}) {
  batch.set(FirebaseFirestore.instance.collection('adminLog').doc(), {
    'at': FieldValue.serverTimestamp(),
    'action': action,
    'target': target,
    'before': before,
    'after': after,
    'note': ?note,
  });
}

import 'package:cloud_firestore/cloud_firestore.dart';

/// Her yönetici yazımı `adminLog/{id}` kaydıyla AYNI batch/transaction'da yapılır —
/// kayıtsız değişiklik olamaz (kayıt yazılamazsa değişiklik de yazılmaz).
DocumentReference<Map<String, dynamic>> newAdminLogRef() =>
    FirebaseFirestore.instance.collection('adminLog').doc();

Map<String, Object?> adminLogEntry({
  required String action,
  required String target,
  required Map<String, Object?> before,
  required Map<String, Object?> after,
  String? note,
}) {
  return {
    'at': FieldValue.serverTimestamp(),
    'action': action,
    'target': target,
    'before': before,
    'after': after,
    'note': ?note,
  };
}

void addAdminLog(
  WriteBatch batch, {
  required String action,
  required String target,
  required Map<String, Object?> before,
  required Map<String, Object?> after,
  String? note,
}) {
  batch.set(
    newAdminLogRef(),
    adminLogEntry(action: action, target: target, before: before, after: after, note: note),
  );
}

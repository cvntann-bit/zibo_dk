import 'dart:async';

import 'package:dijital_kanka/services/purchase_recorder.dart';
import 'package:dijital_kanka/services/purchase_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeReceiptService extends MockPurchaseService {
  _FakeReceiptService(this.controller);

  final StreamController<PurchaseReceipt> controller;

  @override
  Stream<PurchaseReceipt> get purchaseReceipts => controller.stream;
}

void main() {
  const receipt = PurchaseReceipt(
    productId: 'coins_100',
    purchaseToken: 'token-1',
    orderId: 'GPA.1',
  );

  late FakeFirebaseFirestore firestore;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    firestore = FakeFirebaseFirestore();
  });

  PurchaseRecorder recorder({String? uid = 'uid-1'}) => PurchaseRecorder(
    uid: uid,
    purchaseService: const MockPurchaseService(),
    firestore: firestore,
  );

  test('makbuzu token özetiyle pending olarak yazar', () async {
    await recorder().record(receipt);

    final hash = PurchaseRecorder.hashToken('token-1');
    final data = (await firestore
        .collection('purchaseRecords')
        .doc(hash)
        .get()).data()!;
    expect(hash, hasLength(64));
    expect(data['uid'], 'uid-1');
    expect(data['productId'], 'coins_100');
    expect(data['purchaseToken'], 'token-1');
    expect(data['orderId'], 'GPA.1');
    expect(data['status'], 'pending');
  });

  test('aynı makbuz ikinci kez yazılmaz (restore her açılışta oynatır)', () async {
    final first = recorder();
    await first.record(receipt);
    final ref = firestore
        .collection('purchaseRecords')
        .doc(PurchaseRecorder.hashToken('token-1'));
    await ref.update({'status': 'verified'});

    await recorder().record(receipt);

    expect((await ref.get()).data()!['status'], 'verified');
  });

  test('stream ile gelen makbuzu kaydeder', () async {
    final controller = StreamController<PurchaseReceipt>.broadcast();
    PurchaseRecorder(
      uid: 'uid-1',
      purchaseService: _FakeReceiptService(controller),
      firestore: firestore,
    );

    controller.add(receipt);
    await pumpEventQueue();

    final snap = await firestore.collection('purchaseRecords').get();
    expect(snap.docs, hasLength(1));
    await controller.close();
  });

  test('uid yoksa ya da token boşsa hiçbir şey yazmaz', () async {
    await recorder(uid: null).record(receipt);
    await recorder().record(
      const PurchaseReceipt(productId: 'coins_100', purchaseToken: ''),
    );

    final snap = await firestore.collection('purchaseRecords').get();
    expect(snap.docs, isEmpty);
  });
}

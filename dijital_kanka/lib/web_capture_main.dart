// Alternatif giriş noktası — YALNIZCA masaüstünde ekran görüntüsü almak içindir (Play Store görselleri,
// bkz. tool/store_capture_web.py). Normal `main.dart`'ı etkilemiyor, normal derlemeye dahil OLMUYOR.
//
// `main.dart`'tan farkı: Firebase/Appodeal/in_app_purchase GİBİ web'de uygulaması olmayan (veya gerçek
// hesaba/reklam ağına bağlanan) HİÇBİR şeyi başlatmaz; reklam ve ödeme için sahte (mock) servisler
// enjekte eder, `uid: null` ile saf-yerel moda düşer. Böylece gerçek kullanıcı verisine ve reklam
// hesabına (geçersiz trafik riski) dokunulmaz.
//
// Çalıştırma: flutter run -d web-server --web-port 8766 -t lib/web_capture_main.dart
import 'package:flutter/material.dart';

import 'main.dart' show DijitalKankaApp;
import 'services/ad_service.dart';
import 'services/purchase_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DijitalKankaApp(adService: MockAdService(), purchaseService: MockPurchaseService()));
}

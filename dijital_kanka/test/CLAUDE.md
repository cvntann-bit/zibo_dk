# `test/` — flutter_test kuralları ve tuzakları

Komut: `export PATH="$PATH:/c/flutter/bin" && flutter test` (`dijital_kanka/` içinde).
`flutter analyze` bu makinede ÇÖKÜYOR — kullanma.

Önceden belgelenmiş flake: "Zibo'ya dokununca söz değişir..." testi `audioplayers`/`home_widget`
platform-kanalı `MissingPluginException` sızıntısı — gerçek regresyon değil, ayrı bir görev.

## İki farklı "uygulamayı ayağa kaldır" yardımcısı — KARIŞTIRMA

- `const DijitalKankaApp()` pump'layan testler → **`_pumpPastOnboarding(tester, app)`** kullanmalı (gerçek `_AppStartupGate`'den geçer, önce isim girip Onboarding'i atlar).
- `_buildAppWithClock(() => clock)` → bare `MaterialApp(home: RootScreen())` kurar (Onboarding/`_AppStartupGate` YOK) → düz `pumpWidget` + `pumpAndSettle()`.
- `_buildAppWithClock` çıktısına `_pumpPastOnboarding` uygulamak `Bad state: No element` verir.

## `_buildAppWithClock()` provider listesi

`RootScreen`'in ihtiyaç duyduğu HER provider'ı içermeli (~35 provider). `main.dart`'a VEYA
`RootScreen`'in `context.read` ettiği kümeye yeni bir provider eklersen bu yardımcıyı GÜNCELLE —
yoksa `ProviderNotFoundException` / `Method not found` derleme hatası yalnızca ilgili testte değil
ondan SONRAKİ TÜM testlerde (aynı test ikili dosyasında art arda) görünür.

## `testWidgets()` fake-async — çıplak `Future.delayed` YASAK

`testWidgets()` gövdesi Flutter'ın fake-async ortamında çalışır. Çıplak
`await Future<void>.delayed(Duration.zero)` (düz `test()` bloklarında güvenli olan desen) burada
**SONSUZA KADAR hanglenir** (10 dk timeout). Çözüm: önce `tester.pump()`/`pumpAndSettle()`'ın yetip
yetmediğine bak; GERÇEKTEN gerekiyorsa `tester.runAsync(() => Future.delayed(...))` içine sar.

## Sık tekrarlayan gotcha'lar

- **`GridView.count` + `shrinkWrap: true` + `IndexedStack`** → `tester.tap()` koordinat hit-test uyuşmazlığı. Çözüm: `tester.widget<FilledButton>(finder).onPressed!()` ile doğrudan çağır.
- **Düz `ListView(children:)`** viewport-dışı öğeleri geç inşa eder → `tester.scrollUntilVisible()`.
- **`scrollUntilVisible()` YALNIZCA TEK YÖNDE kaydırır** — bir listedeki birden fazla satırı ziyaret eden test satırları EKRANDAKİ GERÇEK sırayla (yukarıdan aşağı) ziyaret etmeli. Geriye dönük sıra "içerik tek ekrana sığdığı için" tesadüfen geçiyor olabilir, yeni içerik eklenince sessizce kırılır.
- **`scrollable:` parametresi** için `find.byType(Scrollable).last` bir `TextField`'ın iç `EditableText`'ini seçebilir → `find.descendant(of: find.byType(XScreen), ...).first` ile açıkça daralt.
- **`Timer.periodic`'li widget** `isActive` koruması taşımalı (`IndexedStack` dispose etmez → "pending timer" hatası).
- **`pumpAndSettle(Duration(seconds:N))`** bir ekranın KENDİ `Timer.periodic(Nsn)`'iyle TAM ÇAKIŞIRSA resonance → asla "settle" olmaz. Farklı, tam-kat-olmayan `pump()` çağrılarına böl.
- **`WidgetTester.pageBack()`** güvenilmez → `find.byTooltip('Geri')`.
- **`RenderRepaintBoundary.toImage()`** (paylaşım kartı) gerçek raster işi — `pumpAndSettle` beklemez → `tester.runAsync()` + sonucu gerçek-zamanlı yokla (sahte servisin çağrıldığını kontrol et).
- **`Image.asset()`** `pumpAndSettle` sonrası bile yükseklik=0 raporlayabilir (codec decode fake-time penceresi dışında) → `tap()` yanlış hedefi vurur. Çözüm: `pumpAndSettle()` → `await tester.runAsync(() => Future.delayed(Duration(milliseconds: 100)))` → `pumpAndSettle()`.
- **`Semantics(label:)`** görünür `Text`/`Icon` sarıyorsa `excludeSemantics: true` ekle — yoksa iç metin dış label'la birleşir, `find.bySemanticsLabel` tam eşleşme bulamaz. Alt bar / gün kutucuğu / trigger butonları bu deseni kullanır. Testler bilerek semantics üzerinden gider (kısa görünür metin değil, uzun `l10n.tabX` değeri).
- **`late final AnimationController = AnimationController(...)`** alan başlatıcısı, yalnızca koşullu erişilen bir controller'da `dispose()` içinde "deactivated widget's ancestor" çökmesi verir → `initState()`'te KOŞULSUZ oluştur. (`AnimatedThemeOverlay`, `BadgeCelebrationOverlay`, `WheelScreen`, `LevelCelebrationOverlay` bu düzeltmeye sahip.)
- **`context.read<T>()` `dispose()` İÇİNDE ÇAĞRILAMAZ** ("deactivated widget's ancestor is unsafe") → referansı `initState`'te oku, alanda sakla, `dispose`'ta o alanı kullan.
- **`enterText()` kendi başına frame pump'lamaz** — bir `TextEditingController`'a bağlı buton enabled/disabled'ı test edilecekse araya açık `await tester.pump()` koy.
- **`find.text(x)` hem `Text` hem `EditableText` eşler** — bir alan hem yazılıp hem sonuç olarak başka yerde göründüğünde `findsOneWidget` DEĞİL `findsWidgets`.
- **`find.byType(X, skipOffstage: false)`** — bir widget'ın üstüne başka route push edildiğinde (offstage ama mount) onu bulmak için.
- **`SharedPreferences.setMockInitialValues({})`** — `ThemeProvider` / `CloudStateStore` kullanan her testin `setUp`'ında.
- **Paylaşılan global sinyaller** (`isHomeTabActive`, `switchToUid`, `pendingLevelUp`, `AdFreePromoTrigger` sayacı, `pendingBadgePopup`) `setUp`'ta sıfırlanmalı — testler arası sızıntı.
- **`fake_cloud_firestore` transaction'da `set(..., SetOptions(merge: true))`'i SESSİZCE yok sayar** (tam overwrite). Transaction içinde `tx.update`/`tx.set` arasında dokümanın var olup olmamasına göre elle dallan.
- **`GoogleFonts.config.allowRuntimeFetching = false`** — paylaşım kartı font testlerinde.

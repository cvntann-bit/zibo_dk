import 'package:flutter/material.dart';

import '../data/costume_poses.dart';

/// Zibo'yu, giyili kostüme göre birden fazla statik poz arasında hafif bir
/// "fade" (crossfade) geçişiyle değiştirerek gösterir — Akinatör tarzı poz
/// döngüsü. [costumeId] `null` ise kostümsüz varsayılan poz seti
/// ([defaultZiboPoses]) kullanılır; belirli bir kostüm id'si verilip
/// [costumePoses]'ta karşılığı YOKSA (henüz o kostüm için poz seti
/// eklenmemişse) [fallbackImage] tek başına, döngüsüz gösterilir — hata
/// fırlatmaz, sessizce eski (tek görsellik) davranışa düşer.
///
/// **2026 güncellemesi — artık İÇSEL bir zamanlayıcısı YOK.** Hangi pozun
/// gösterileceği tamamen DIŞARIDAN, [poseStep] parametresiyle kontrol
/// ediliyor (`poses[poseStep % poses.length]`) — kullanıcı geri
/// bildirimiyle ("poz döngüsü çok hızlı", "diğer sayfalarda ana sayfadaki
/// poz ne ise o olsun") otomatik döngü tamamen kaldırıldı; [poseStep]
/// artık `ZiboPoseProvider`'dan (bkz. o sınıfın dokümantasyonu) geliyor —
/// yalnızca Ana Sayfa'da Zibo'ya dokunuldukça (5-10 dokunuşta bir) ilerler,
/// diğer yedi ekran bu SAYACI salt-okunur izler.
///
/// **2026 güncellemesi — `width` yerine `height`.** Poz PNG'leri
/// `tool/crop_pose_content.dart` ile karakterin gerçek sınır kutusuna sıkı
/// kırpıldı (bkz. CLAUDE.md "Zibo Poz/Animasyon Sistemi") — bir SETİN
/// içindeki tüm pozlar artık BİREBİR aynı YÜKSEKLİĞE (genişlik pozdan poza
/// doğal olarak farklı, ör. kollar açık/kapalı) sahip. Yalnızca `height`
/// vermek (width'i görselin kendi en-boy oranına bırakmak) bu yüzden İKİ
/// şeyi birden garantiliyor: (1) pozlar arasında geçişte Column'daki
/// dikey yerleşim ASLA sıçramıyor (yükseklik sabit), (2) karakter artık
/// büyük, çoğunlukla şeffaf bir kanvasın küçük bir köşesinde değil,
/// verilen `height` kutusunu neredeyse TAMAMEN dolduruyor — eskiden
/// `width` verilip kanvasın (1408x768, içeriğin yalnızca ~%30-40'ını
/// kapladığı) TAMAMI o genişliğe göre ölçeklendiğinde, görünen karakterin
/// kendisi kutunun çok altında kalıyordu (kullanıcının "widget'ı
/// büyüttüm ama karakter hâlâ küçük görünüyor" diye bildirdiği tam
/// olarak buydu).
///
/// Ekranın Zibo görselini bulup test eden mevcut widget testleri
/// (`find.byKey(...)` + `tester.widget<Image>(...)`) hâlâ çalışsın diye
/// [imageKey], TEK ve SABİT bir `Image` örneğine uygulanıyor — poz
/// değişince `Image.image` (asset yolu) yerinde güncellenir, widget'ın
/// kendisi/`key`'i asla değişmez. Crossfade bu yüzden `AnimatedSwitcher`'ın
/// örtük key-tabanlı çocuk değişimiyle DEĞİL, elle yönetilen bir
/// `AnimationController` (`FadeTransition`) ile yapılıyor: [poseStep]
/// (veya [costumeId]) değiştiğinde önce mevcut poz 0'a solduruluyor,
/// `setState` ile GÖSTERİLEN asset değiştiriliyor, sonra yeni poz 1'e geri
/// soluyor — `build()`'in HER ZAMAN `widget.poseStep`'in en güncel değerini
/// ANINDA yansıtması gerekseydi (ör. `_currentAsset` doğrudan build'de
/// hesaplansaydı) crossfade'in "eski pozu göstermeye devam ederken sol"
/// adımı imkânsız olurdu — bu yüzden gösterilen asset ayrı bir `_displayed`
/// state alanında tutuluyor, `widget.poseStep`'i DEĞİL.
class ZiboAnimatedImage extends StatefulWidget {
  const ZiboAnimatedImage({
    super.key,
    this.imageKey,
    required this.costumeId,
    required this.poseStep,
    required this.fallbackImage,
    required this.height,
    this.semanticLabel,
    this.crossfadeDuration = const Duration(milliseconds: 250),
  });

  /// `Image` widget'ının kendi `Key`'i — poz döngüsü boyunca DEĞİŞMEZ (bkz.
  /// sınıf dokümantasyonu).
  final Key? imageKey;

  /// `CostumeProvider.equippedId` — `null` ise kostümsüz varsayılan poz seti.
  final String? costumeId;

  /// `ZiboPoseProvider.poseStep` — TÜM ekranlarda AYNI, paylaşılan sayaç.
  final int poseStep;

  /// [costumeId] için `costume_poses.dart`'ta bir poz seti YOKSA (veya
  /// [costumeId] `costumes.dart`'ta bulunamayan bir id ise) gösterilecek tek
  /// statik görsel — genelde çağıran ekranın zaten hesapladığı
  /// `equippedImageAsset` (kostümün kendi `imageAsset`'i ya da
  /// [defaultZiboImage]).
  final String fallbackImage;

  final double height;
  final String? semanticLabel;

  /// Solma/geri-solma geçişinin HER YARISININ (poz gizlenirken VEYA
  /// gösterilirken) süresi — toplam geçiş süresi bunun iki katı.
  final Duration crossfadeDuration;

  @override
  State<ZiboAnimatedImage> createState() => _ZiboAnimatedImageState();
}

class _ZiboAnimatedImageState extends State<ZiboAnimatedImage>
    with SingleTickerProviderStateMixin {
  late final _fadeController = AnimationController(
    vsync: this,
    duration: widget.crossfadeDuration,
    value: 1.0,
  );

  late String _displayedAsset = _resolveAsset(widget);
  bool _disposed = false;

  static String _resolveAsset(ZiboAnimatedImage w) {
    final poses = posesForCostume(w.costumeId);
    if (poses == null || poses.isEmpty) return w.fallbackImage;
    return poses[w.poseStep % poses.length];
  }

  @override
  void didUpdateWidget(covariant ZiboAnimatedImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final target = _resolveAsset(widget);
    if (target == _displayedAsset) return;
    if (oldWidget.costumeId != widget.costumeId) {
      // Kostüm değişti — [poseStep] TÜM kostümler arasında paylaşılan TEK
      // bir sayaç olduğu için (bkz. ZiboPoseProvider) "sıfırlanmıyor",
      // yalnızca yeni kostümün KENDİ poz listesine `% length` ile
      // eşleniyor. Görünüm ANINDA değişir (fade'e gerek yok) — iki farklı
      // kostümün sanatı arasında çapraz solma yapmak (biri yavaşça
      // diğerine dönüşüyormuş gibi) görsel olarak yanlış/kafa karıştırıcı
      // olurdu; olası bir yarım kalmış geçiş de burada iptal edilir.
      _fadeController.value = 1.0;
      setState(() => _displayedAsset = target);
      return;
    }
    _crossfadeTo(target);
  }

  Future<void> _crossfadeTo(String target) async {
    await _fadeController.reverse();
    if (_disposed) return;
    setState(() => _displayedAsset = target);
    if (_disposed) return;
    await _fadeController.forward();
  }

  @override
  void dispose() {
    _disposed = true;
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeController,
      child: Image.asset(
        _displayedAsset,
        key: widget.imageKey,
        height: widget.height,
        semanticLabel: widget.semanticLabel,
      ),
    );
  }
}

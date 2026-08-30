// Tek seferlik görsel işleme betiği (uygulamaya dahil değil, `remove_bg.dart`/
// `generate_founder_badge_placeholder.dart` ile AYNI desen, GEREKTİĞİNDE
// YENİDEN ÇALIŞTIRILABİLİR) — beş ana ekran widget'ının HER BİRİ için
// KENDİ temasına özgü, arka planda yavaşça dönen bir "sahne" seti üretir
// (bkz. CLAUDE.md "Ana Ekran Widget'ları" bölümü, kullanıcı isteği: "su
// takibine dalgalar, para ve birikime Zibo logolu yeşil banknot, günlük
// giriş ödüllerine hediye kutuları, Zibo'nun sözüne ampul, istatistiklere
// yükselen çubuk grafik — her widget'in kendi animasyonu olsun").
//
// **Mimari — `ViewFlipper` + önceden çizilmiş SAHNELER, TEK bir "canlı"
// çizim DEĞİL.** RemoteViews per-frame/canvas çizime izin vermiyor
// (bkz. bu dosyanın kardeşi `generate_widget_z_pattern.dart`'ın — artık
// silinmiş — AYNI kısıtlama notu); bu yüzden her widget için [_frameCount]
// (4) STATİK PNG üretiliyor, native tarafta (`ZiboBaseWidgetProvider`/
// `ZiboMotivationWidgetProvider`/`ZiboProfileStatsWidgetProvider`) bir
// `ViewFlipper` bunları `RemoteViews.addView(...)` ile sırayla ekleyip
// mevcut `widget_page_in`/`widget_page_out` (kayma+solma) geçişiyle
// döndürüyor — "gerçek fizik" değil ama birkaç saniyede bir sahne
// değişince "canlı" bir arka plan hissi veriyor.
//
// **Opaklık — BİLEREK DÜŞÜK VE AZ ELEMANLI.** Önceki "Z deseni" arka
// planı kullanıcı tarafından "çok kötü/amatörce" diye REDDEDİLMİŞTİ (bkz.
// `widget_background.xml`'deki geri alma notu) — o denemenin dersi
// alınıp burada HER sahnede yalnızca 2-4 eleman, düşük alfa (bkz. her
// fonksiyonun kendi `alpha` sabiti) kullanılıyor; gerçek verinin (6/8,
// 1.250 TL vb.) ÜSTÜNE binmeyecek kadar geride kalıyor.
//
// **Tek tema seti (açık/koyu AYRI DEĞİL) — Z deseninden BİLİNÇLİ bir
// SAPMA.** Z deseni neredeyse-görünmez, zeminle KARIŞAN bir nötr doku
// olduğu için açık/koyu ayrımı GEREKtiriyordu; buradaki motifler
// widget'ın KENDİ doygun accent rengini (mavi/yeşil/altın/mor) taşıyor —
// bu renkler hem krem hem neredeyse-siyah zeminde (düşük alfada bile)
// yeterince ayırt edilebilir kaldığı için tek bir set yeterli.
//
// Kullanım: dart run tool/generate_widget_bg_animations.dart

import 'dart:io';
import 'dart:math';

import 'package:image/image.dart' as img;

const _size = 400;
const _frameCount = 4;
const _outDir = 'android/app/src/main/res/drawable-nodpi';

img.ColorRgba8 _c(int rgb, int alpha) => img.ColorRgba8(
  (rgb >> 16) & 0xFF,
  (rgb >> 8) & 0xFF,
  rgb & 0xFF,
  alpha,
);

void _save(String name, img.Image image) {
  File('$_outDir/$name.png').writeAsBytesSync(img.encodePng(image));
  stdout.writeln('Üretildi: $_outDir/$name.png');
}

img.Image _blank() => img.Image(width: _size, height: _size, numChannels: 4);

/// Bir dizi noktayı ("polyline") kalın bir çizgi olarak çiziyor —
/// `drawLine`'ın tek segment sınırını aşıp yumuşak eğriler (dalga, ampul
/// parlaması vb.) çizebilmek için.
void _polyline(img.Image image, List<List<double>> points, img.Color color, int thickness) {
  for (var i = 0; i < points.length - 1; i++) {
    img.drawLine(
      image,
      x1: points[i][0].round(),
      y1: points[i][1].round(),
      x2: points[i + 1][0].round(),
      y2: points[i + 1][1].round(),
      color: color,
      thickness: thickness,
      antialias: true,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// 1) Su Takibi — dalgalar. İki katmanlı, alt kenardan yükselen sinüs bandı;
//    kareler arasında faz kayarak "su hareket ediyor" izlenimi veriyor.
// ─────────────────────────────────────────────────────────────────────────
void _generateWater() {
  const color = 0xFF2F7FBF;
  for (var f = 0; f < _frameCount; f++) {
    final image = _blank();
    final phase = (f / _frameCount) * 2 * pi;
    void wave(double baseY, double amp, double freq, double phaseOffset, int alpha) {
      final points = <List<double>>[];
      for (var x = 0; x <= _size; x += 8) {
        final y = baseY + sin((x / _size) * freq * 2 * pi + phase + phaseOffset) * amp;
        points.add([x.toDouble(), y]);
      }
      // Dalganın ALTINI (kanvasın altına kadar) dolduran bir "su" siluetine
      // çeviriyoruz — yalnızca bir çizgi değil, alçak bir dolgu.
      final poly = [...points, [_size.toDouble(), _size.toDouble()], [0.0, _size.toDouble()]];
      img.fillPolygon(image, vertices: poly.map((p) => img.Point(p[0], p[1])).toList(), color: _c(color, alpha));
    }

    wave(_size * 0.82, 10, 1.4, 0, 68);
    wave(_size * 0.88, 8, 1.8, pi / 2, 95);
    _save('widget_bg_water_${f + 1}', image);
  }
}

// ─────────────────────────────────────────────────────────────────────────
// 2) Para ve Birikim — Zibo logolu yeşil banknot silüetleri. Dikdörtgen
//    çerçeve + ortada küçük bir "mühür" dairesi + köşede minik bir "Z" —
//    kareler arasında konum/açı değişiyor.
// ─────────────────────────────────────────────────────────────────────────
void _drawBanknote(img.Image image, double cx, double cy, double w, double angleDeg, img.Color color) {
  final angle = angleDeg * pi / 180;
  final h = w * 0.5;
  final local = [
    [-w / 2, -h / 2],
    [w / 2, -h / 2],
    [w / 2, h / 2],
    [-w / 2, h / 2],
    [-w / 2, -h / 2],
  ];
  final cosA = cos(angle);
  final sinA = sin(angle);
  final pts = local
      .map((p) => [cx + p[0] * cosA - p[1] * sinA, cy + p[0] * sinA + p[1] * cosA])
      .toList();
  _polyline(image, pts, color, 3);

  // Ortada küçük bir "mühür" dairesi.
  final sealR = w * 0.12;
  img.drawCircle(image, x: cx.round(), y: cy.round(), radius: sealR.round(), color: color, antialias: true);

  // Sol-üst köşede minik bir "Z" (üç çizgi, eski Z-desenindeki AYNI saf
  // geometri — font'a gerek yok).
  final zx = cx - w * 0.32;
  final zy = cy - h * 0.05;
  final zs = w * 0.1;
  final zLocal = [
    [-zs / 2, -zs / 2],
    [zs / 2, -zs / 2],
    [-zs / 2, zs / 2],
    [zs / 2, zs / 2],
  ];
  final zPts = zLocal
      .map((p) => [zx + p[0] * cosA - p[1] * sinA, zy + p[0] * sinA + p[1] * cosA])
      .toList();
  _polyline(image, [zPts[0], zPts[1]], color, 2);
  _polyline(image, [zPts[1], zPts[2]], color, 2);
  _polyline(image, [zPts[2], zPts[3]], color, 2);
}

void _generateMoney() {
  const color = 0xFF2E8B57; // yeşil (banknot rengi — kullanıcının isteği)
  final random = Random(11);
  final notes = List.generate(
    3,
    (i) => (
      cx: random.nextDouble() * _size,
      cy: random.nextDouble() * _size,
      w: 90.0 + random.nextDouble() * 40,
      angle: random.nextDouble() * 40 - 20,
    ),
  );
  for (var f = 0; f < _frameCount; f++) {
    final image = _blank();
    final drift = f * 14.0;
    for (final n in notes) {
      _drawBanknote(
        image,
        (n.cx + drift) % (_size + 60) - 30,
        n.cy,
        n.w,
        n.angle + f * 4,
        _c(color, 100),
      );
    }
    _save('widget_bg_money_${f + 1}', image);
  }
}

// ─────────────────────────────────────────────────────────────────────────
// 3) Günlük Giriş Ödülleri — hediye kutuları. Kare kutu + çapraz kurdele +
//    üstte küçük bir fiyonk.
// ─────────────────────────────────────────────────────────────────────────
void _drawGiftBox(img.Image image, double cx, double cy, double size, img.Color color) {
  final half = size / 2;
  final corners = [
    [cx - half, cy - half],
    [cx + half, cy - half],
    [cx + half, cy + half],
    [cx - half, cy + half],
    [cx - half, cy - half],
  ];
  _polyline(image, corners, color, 3);
  _polyline(image, [[cx, cy - half], [cx, cy + half]], color, 3);
  _polyline(image, [[cx - half, cy], [cx + half, cy]], color, 3);
  // Fiyonk — iki küçük üçgen.
  img.fillPolygon(
    image,
    vertices: [
      img.Point(cx, cy - half),
      img.Point(cx - half * 0.4, cy - half * 1.35),
      img.Point(cx, cy - half * 1.1),
    ],
    color: color,
  );
  img.fillPolygon(
    image,
    vertices: [
      img.Point(cx, cy - half),
      img.Point(cx + half * 0.4, cy - half * 1.35),
      img.Point(cx, cy - half * 1.1),
    ],
    color: color,
  );
}

void _generateDailyRewards() {
  const color = 0xFFC79A3D;
  final random = Random(23);
  final boxes = List.generate(
    3,
    (i) => (
      cx: random.nextDouble() * _size,
      cy: 60.0 + random.nextDouble() * (_size - 120),
      size: 40.0 + random.nextDouble() * 30,
    ),
  );
  for (var f = 0; f < _frameCount; f++) {
    final image = _blank();
    final bob = sin((f / _frameCount) * 2 * pi) * 10;
    for (final b in boxes) {
      _drawGiftBox(image, b.cx, b.cy + bob, b.size, _c(color, 90));
    }
    _save('widget_bg_daily_rewards_${f + 1}', image);
  }
}

// ─────────────────────────────────────────────────────────────────────────
// 4) Zibo'nun Sözü — ampul/fikir. Daire (ampul başı) + trapez (duy) + birkaç
//    kısa parlama çizgisi — sağdaki metin alanının arkasında, köşede.
// ─────────────────────────────────────────────────────────────────────────
void _drawBulb(img.Image image, double cx, double cy, double r, double glowPhase, img.Color color) {
  img.drawCircle(image, x: cx.round(), y: cy.round(), radius: r.round(), color: color, antialias: true);
  // Duy (taban) — küçük bir dikdörtgen.
  final baseW = r * 0.7;
  final baseH = r * 0.5;
  _polyline(image, [
    [cx - baseW / 2, cy + r * 0.85],
    [cx + baseW / 2, cy + r * 0.85],
    [cx + baseW / 2, cy + r * 0.85 + baseH],
    [cx - baseW / 2, cy + r * 0.85 + baseH],
  ], color, 2);
  // Parlama çizgileri — sabit 5 adet, faz ile uzunlukları hafifçe değişiyor.
  for (var i = 0; i < 5; i++) {
    final angle = (-pi / 2) + (i - 2) * 0.5;
    final len = r * (0.5 + 0.15 * sin(glowPhase + i));
    final x1 = cx + cos(angle) * r * 1.25;
    final y1 = cy + sin(angle) * r * 1.25;
    final x2 = cx + cos(angle) * (r * 1.25 + len);
    final y2 = cy + sin(angle) * (r * 1.25 + len);
    img.drawLine(image, x1: x1.round(), y1: y1.round(), x2: x2.round(), y2: y2.round(), color: color, thickness: 2, antialias: true);
  }
}

void _generateMotivation() {
  const color = 0xFFD9A94A;
  for (var f = 0; f < _frameCount; f++) {
    final image = _blank();
    final glowPhase = (f / _frameCount) * 2 * pi;
    // Sağ-üst köşeye yakın, TEK bir ampul — metinle çakışmasın diye az ve
    // köşeye yakın tutuldu.
    _drawBulb(image, _size * 0.82, _size * 0.22, _size * 0.09, glowPhase, _c(color, 100));
    _save('widget_bg_motivation_${f + 1}', image);
  }
}

// ─────────────────────────────────────────────────────────────────────────
// 5) İstatistiklerim — yükselen çubuk grafik. 4 çubuk, artan yükseklik,
//    kareler arasında yükseklikler hafifçe "nefes alıyor".
// ─────────────────────────────────────────────────────────────────────────
void _generateProfileStats() {
  const color = 0xFF8E24AA;
  final baseHeights = [0.18, 0.30, 0.44, 0.60];
  for (var f = 0; f < _frameCount; f++) {
    final image = _blank();
    final wobble = sin((f / _frameCount) * 2 * pi) * 0.04;
    final baseY = _size * 0.78;
    final barW = _size * 0.045;
    final gap = _size * 0.03;
    final startX = _size * 0.68;
    for (var i = 0; i < baseHeights.length; i++) {
      final h = _size * (baseHeights[i] + wobble * (i.isEven ? 1 : -1));
      final x = startX + i * (barW + gap);
      img.fillRect(
        image,
        x1: x.round(),
        y1: (baseY - h).round(),
        x2: (x + barW).round(),
        y2: baseY.round(),
        color: _c(color, 95),
        radius: 3,
      );
    }
    _save('widget_bg_profile_stats_${f + 1}', image);
  }
}

void main() {
  Directory(_outDir).createSync(recursive: true);
  _generateWater();
  _generateMoney();
  _generateDailyRewards();
  _generateMotivation();
  _generateProfileStats();
}

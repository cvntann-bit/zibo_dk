// Alternatif giriş noktası, GEREKTİĞİNDE YENİDEN ÇALIŞTIRILABİLEN bir üretim
// aracı (uygulamanın normal giriş noktası DEĞİL — `main.dart`'ı hiç
// etkilemiyor, hiçbir yerden referans edilmiyor, normal derlemeye dahil
// OLMUYOR) — beş ana ekran widget'ının `android:previewImage` PNG'lerini
// (bkz. CLAUDE.md "Ana Ekran Widget'ları" bölümü) GERÇEK cihazda (gerçek
// Roboto fontu + gerçek emoji glifleriyle) üretmek için.
//
// **Neden `dart run`/`flutter test` DEĞİL, gerçek cihaz:** `flutter_test`'in
// kendi render motoru, GERÇEK bir font/emoji glifi YÜKLENMEDİĞİ sürece tüm
// karakterleri tofu/boş dikdörtgen olarak çiziyor — `google_fonts`'un ağdan
// gerçek bir font indirmesi de bu ortamın test-sandbox'ında ASILI KALDI
// (denenip TERK EDİLDİ). Gerçek cihazda ikisi de sorunsuz, native olarak
// mevcut.
//
// **Bu widget'ın kendisi `dart:io`'yla PROJE KLASÖRÜNE erişemediği için**
// (cihaz kendi izole dosya sistemine sahip) Zibo logosu BURADA eklenmiyor
// — yalnızca düz gradyan + gerçek metin/ikon/karakter render ediliyor;
// logo `tool/compose_widget_previews.dart` ile MASAÜSTÜNDE, çıktı
// dosyalarının ÜZERİNE ayrıca bindiriliyor. (Bir Z-doku katmanı da
// BİR ARA vardı — kullanıcı gerçek cihazda görüp reddetti, bkz.
// `widget_background.xml`'deki geri alma notu — artık YOK.)
//
// Widget tasarımı ileride DEĞİŞİRSE, önizlemeleri güncellemek için:
// 1. `flutter build apk --debug -t lib/widget_preview_generator_main.dart`
// 2. `adb install -r <apk>` + uygulamayı aç — açılışta OTOMATİK 10 PNG'yi
//    (5 widget × açık/koyu tema) kendi belge dizinine yazıp ekranda
//    "Bitti — N dosya yazıldı: <yol>" gösteriyor.
// 3. `adb exec-out run-as com.dijitalkanka.dijital_kanka cat <yol>/<dosya>`
//    ile (debug build'ler `run-as` erişimine sahip) her PNG'yi çekip
//    `android/app/src/main/res/drawable(-night)-nodpi/`'ye taşı.
// 4. `dart run tool/compose_widget_previews.dart` ile logoyu bindir.

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const _PreviewGeneratorApp());
}

class _Palette {
  const _Palette({
    required this.name,
    required this.gradientStart,
    required this.gradientEnd,
    required this.primaryText,
    required this.secondaryText,
  });

  final String name;
  final Color gradientStart;
  final Color gradientEnd;
  final Color primaryText;
  final Color secondaryText;

  static const light = _Palette(
    name: '',
    gradientStart: Color(0xFFFBF2D6),
    gradientEnd: Color(0xFFEFDCAE),
    primaryText: Color(0xFF4A3620),
    secondaryText: Color(0xFF7A5C34),
  );

  static const dark = _Palette(
    name: '-night',
    gradientStart: Color(0xFF2A251D),
    gradientEnd: Color(0xFF1B1712),
    primaryText: Color(0xFFE3C179),
    secondaryText: Color(0xFFB89A5E),
  );
}

const _compactSize = Size(300, 300);
const _bigSize = Size(600, 300);

class _PreviewGeneratorApp extends StatefulWidget {
  const _PreviewGeneratorApp();

  @override
  State<_PreviewGeneratorApp> createState() => _PreviewGeneratorAppState();
}

class _PreviewGeneratorAppState extends State<_PreviewGeneratorApp> {
  String _status = 'Hazırlanıyor…';
  final Map<String, GlobalKey> _keys = {};

  List<(String, Widget, Size)> _specs(_Palette p) {
    return [
      (
        'widget_preview_water${p.name}',
        _compactPreview(
          palette: p,
          icon: Icons.water_drop_rounded,
          accent: const Color(0xFF2F7FBF),
          title: 'Su Takibi',
          primary: '6/8',
          secondary: 'bardak · bugün',
          progress: 0.75,
        ),
        _compactSize,
      ),
      (
        'widget_preview_money${p.name}',
        _compactPreview(
          palette: p,
          icon: Icons.savings_rounded,
          accent: const Color(0xFF1E88E5),
          title: 'Para ve Birikim',
          primary: '1.250,00 ₺',
          secondary: 'bu ay net',
        ),
        _compactSize,
      ),
      (
        'widget_preview_daily_rewards${p.name}',
        _compactPreview(
          palette: p,
          icon: Icons.card_giftcard_rounded,
          accent: const Color(0xFFC79A3D),
          title: 'Günlük Giriş Ödülleri',
          primary: 'Gün 3',
          secondary: 'bugün alınabilir',
          progress: 0.43,
        ),
        _compactSize,
      ),
      (
        'widget_preview_motivation${p.name}',
        _bigPreview(
          palette: p,
          accent: const Color(0xFFA9711F),
          title: 'Zibo\'nun Sözü',
          content: Text(
            'Zor günler geçer, sen kalıcısın.',
            maxLines: 3,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: p.primaryText,
            ),
          ),
        ),
        _bigSize,
      ),
      (
        'widget_preview_profile_stats${p.name}',
        _bigPreview(
          palette: p,
          accent: const Color(0xFF8E24AA),
          title: 'İstatistiklerim',
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Para Yönetimi',
                style: TextStyle(fontSize: 15, color: p.secondaryText),
              ),
              const SizedBox(height: 3),
              Text(
                '7,5 / 10',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: p.primaryText,
                ),
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: 0.75,
                  minHeight: 8,
                  backgroundColor: const Color(
                    0xFF8E24AA,
                  ).withValues(alpha: 0.18),
                  valueColor: const AlwaysStoppedAnimation(Color(0xFF8E24AA)),
                ),
              ),
            ],
          ),
        ),
        _bigSize,
      ),
    ];
  }

  Widget _cardChrome(_Palette palette, Size size, Widget child) {
    return SizedBox(
      width: size.width,
      height: size.height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size.height * 0.13),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [palette.gradientStart, palette.gradientEnd],
          ),
        ),
        // Zibo logosu BİLEREK burada YOK — cihazda (`dart:io` proje
        // klasörüne erişemediği için) eklenemiyor, bunun yerine
        // masaüstünde `tool/compose_widget_previews.dart` ile (bkz. o
        // betik) BU çıktının ÜZERİNE ayrıca bindiriliyor.
        child: ClipRRect(
          borderRadius: BorderRadius.circular(size.height * 0.13),
          child: child,
        ),
      ),
    );
  }

  Widget _compactPreview({
    required _Palette palette,
    required IconData icon,
    required Color accent,
    required String title,
    required String primary,
    required String secondary,
    double? progress,
  }) {
    return _cardChrome(
      palette,
      _compactSize,
      Padding(
        padding: const EdgeInsets.all(26),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent.withValues(alpha: 0.16),
                  ),
                  child: Center(
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accent,
                      ),
                      child: Center(
                        child: Icon(icon, color: Colors.white, size: 19),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      color: palette.secondaryText,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(width: 38, height: 4, color: accent),
            const SizedBox(height: 12),
            Text(
              primary,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: palette.primaryText,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              secondary,
              style: TextStyle(fontSize: 15, color: palette.secondaryText),
            ),
            if (progress != null) ...[
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: accent.withValues(alpha: 0.18),
                  valueColor: AlwaysStoppedAnimation(accent),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _bigPreview({
    required _Palette palette,
    required Color accent,
    required String title,
    required Widget content,
  }) {
    return _cardChrome(
      palette,
      _bigSize,
      Padding(
        padding: const EdgeInsets.all(28),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Image.asset('assets/images/zibo_yeni.png', height: 220),
            const SizedBox(width: 22),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      color: palette.secondaryText,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(width: 38, height: 4, color: accent),
                  const SizedBox(height: 14),
                  content,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _captureAll() async {
    final dir = await getApplicationDocumentsDirectory();
    var count = 0;
    for (final palette in [_Palette.light, _Palette.dark]) {
      for (final (name, _, _) in _specs(palette)) {
        final key = _keys[name]!;
        final boundary =
            key.currentContext!.findRenderObject() as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 3.0);
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        final file = File('${dir.path}/$name.png');
        await file.writeAsBytes(byteData!.buffer.asUint8List());
        count++;
      }
    }
    setState(() => _status = 'Bitti — $count dosya yazıldı: ${dir.path}');
  }

  @override
  void initState() {
    super.initState();
    for (final palette in [_Palette.light, _Palette.dark]) {
      for (final (name, _, _) in _specs(palette)) {
        _keys[name] = GlobalKey();
      }
    }
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 400));
      await _captureAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Column(
            children: [
              Padding(padding: const EdgeInsets.all(12), child: Text(_status)),
              Expanded(
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final palette in [_Palette.light, _Palette.dark])
                        for (final (name, widget, _) in _specs(palette))
                          RepaintBoundary(key: _keys[name], child: widget),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

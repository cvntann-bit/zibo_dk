// Alternatif giriş noktası, GEREKTİĞİNDE YENİDEN ÇALIŞTIRILABİLEN bir üretim
// aracı (`widget_preview_generator_main.dart` ile AYNI desen — normal
// `main.dart`'ı hiç etkilemiyor, normal derlemeye dahil OLMUYOR) — Play
// Store mağaza girişinin telefon + tablet ekran görüntülerini VE Özellik
// grafiğini İngilizce/İspanyolca için ÜRETMEK için (bkz. CLAUDE.md "Play
// Store ASO/localization" notları).
//
// Türkçe orijinalleri Play Console'da ZATEN var (kullanıcının kendi tasarım
// ekibi/aracıyla üretilmiş) — bu betik onları BİREBİR piksel kopyalamıyor,
// aynı görsel şablonu (ZibO logosu + rozet + kostümlü Zibo + iki satırlık
// başlık + alt metin + ekrana özel küçük bir arayüz aksanı) GERÇEK Flutter
// widget'ları ve GERÇEK proje asset'leriyle yeniden üretiyor.
//
// **Neden `dart run`/`flutter test` DEĞİL, gerçek cihaz:** `widget_preview_
// generator_main.dart`'taki AYNI gerekçe — `flutter_test`'in render motoru
// gerçek bir font/emoji glifi olmadan karakterleri tofu kutusu çiziyor;
// gerçek cihazda hem Roboto hem emoji hem de `assets/images/`'teki TÜM Zibo
// görselleri (logo dahil, bu betik `Image.asset(...)` kullandığı için proje
// klasörüne HİÇ dokunmadan, derlenmiş APK'nın kendi asset bundle'ından)
// sorunsuz çalışıyor.
//
// Yeniden üretmek/güncellemek için:
// 1. `flutter build apk --debug -t lib/store_screenshot_generator_main.dart`
// 2. `adb install -r <apk>` + uygulamayı aç — açılışta OTOMATİK 34 PNG'yi
//    (8 ekran × EN/ES telefon dikey + AYNI 8 ekran × EN/ES tablet yatay +
//    Özellik grafiği × EN/ES, bkz. `_RenderItem`/`_renderItems`) kendi
//    belge dizinine yazıp ekranda "Bitti — N dosya yazıldı: <yol>"
//    gösteriyor.
// 3. `adb exec-out run-as com.dijitalkanka.dijital_kanka cat <yol>/<dosya>`
//    ile (debug build'ler `run-as` erişimine sahip) her PNG'yi çekip
//    masaüstüne kaydet.
// 4. Play Console > Mağaza girişleri > ilgili dil sekmesi > Telefon/Tablet
//    ekran görüntüleri VE Özellik grafiği alanlarına yükle.

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const _StoreShotGeneratorApp());
}

// Mağaza girişindeki mevcut Türkçe ekran görüntülerinden BİREBİR okunan
// palet (bkz. CLAUDE.md notları — main.dart'taki _cream/_espresso ile aynı
// aile, yalnızca bu şablona özgü sıcak gradyan uçları eklendi).
const _bgStart = Color(0xFFFFFBF0);
const _bgEnd = Color(0xFFF3D98A);
const _primaryText = Color(0xFF4A3620); // espresso
const _secondaryText = Color(0xFF7A5C34); // espressoSoft
const _accentGold = Color(0xFFC9821E); // başlıktaki vurgulu kelime rengi
const _badgeBg = Color(0xE6FFFDF5); // rozet arka planı, neredeyse opak beyaz

const _canvasSize = Size(1080, 1920);
// 16:9 yatay tuval — 7 inç VE 10 inç tablet slotlarının İKİSİ de (Play
// Console'da mevcut Türkçe girişte doğrulandı) AYNI 8 görseli paylaşıyor,
// bu yüzden tek bir yatay şablon yeterli.
const _tabletCanvasSize = Size(1920, 1080);
// Play Console'un "Özellik grafiği" alanı için sabit, değiştirilemez boyut.
const _featureGraphicSize = Size(1024, 500);

/// Başlık metninde `*...*` ile işaretlenmiş kısımlar [_accentGold] rengiyle,
/// geri kalanı [_primaryText] ile çiziliyor — küçük, bu dosyaya özel bir
/// mini-markdown, ayrı bir pakete gerek duyulmadan.
List<InlineSpan> _headlineSpans(String marked, TextStyle base) {
  final spans = <InlineSpan>[];
  final pattern = RegExp(r'\*(.+?)\*');
  var last = 0;
  for (final match in pattern.allMatches(marked)) {
    if (match.start > last) {
      spans.add(TextSpan(text: marked.substring(last, match.start)));
    }
    spans.add(
      TextSpan(
        text: match.group(1),
        style: base.copyWith(color: _accentGold),
      ),
    );
    last = match.end;
  }
  if (last < marked.length) {
    spans.add(TextSpan(text: marked.substring(last)));
  }
  return spans;
}

class _ScreenshotSpec {
  const _ScreenshotSpec({
    required this.fileName,
    required this.badgeEmoji,
    required this.badgeLabel,
    required this.headline,
    required this.subtext,
    required this.characterAsset,
    required this.accentBuilder,
  });

  final String fileName;
  final String badgeEmoji;
  final String badgeLabel;
  final String headline; // '*...*' vurgulu kelimeleri işaretler
  final String subtext;
  final String characterAsset;
  final Widget Function() accentBuilder;
}

Widget _pill(String text, {Color? bg, Color? fg, FontWeight? weight}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
    decoration: BoxDecoration(
      color: bg ?? _badgeBg,
      borderRadius: BorderRadius.circular(40),
    ),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 26,
        fontWeight: weight ?? FontWeight.w600,
        color: fg ?? _primaryText,
      ),
    ),
  );
}

Widget _moodRow(int highlightedIndex) {
  const moods = [
    ('😢', Color(0xFFE53935)),
    ('🙁', Color(0xFFFB8C00)),
    ('😐', Color(0xFFFDD835)),
    ('🙂', Color(0xFF9CCC65)),
    ('😄', Color(0xFF43A047)),
  ];
  return Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      for (var i = 0; i < moods.length; i++) ...[
        if (i > 0) const SizedBox(width: 18),
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: i == highlightedIndex
                ? moods[i].$2
                : moods[i].$2.withValues(alpha: 0.16),
            border: i == highlightedIndex
                ? Border.all(color: Colors.white, width: 4)
                : null,
          ),
          alignment: Alignment.center,
          child: Text(moods[i].$1, style: const TextStyle(fontSize: 44)),
        ),
      ],
    ],
  );
}

Widget _checklistCard(List<String> items) {
  return Container(
    width: 780,
    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
    decoration: BoxDecoration(
      color: _badgeBg,
      borderRadius: BorderRadius.circular(32),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(height: 18),
          Row(
            children: [
              const Text(
                '✓',
                style: TextStyle(
                  fontSize: 30,
                  color: Color(0xFF43A047),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  items[i],
                  style: const TextStyle(fontSize: 28, color: _primaryText),
                ),
              ),
            ],
          ),
        ],
      ],
    ),
  );
}

Widget _waterAccent(String statLabel) {
  return Column(
    children: [
      Text(
        statLabel,
        style: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: _secondaryText,
        ),
      ),
      const SizedBox(height: 22),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < 8; i++) ...[
            if (i > 0) const SizedBox(width: 10),
            Icon(
              Icons.water_drop_rounded,
              size: 46,
              color: i < 5
                  ? const Color(0xFF2F7FBF)
                  : const Color(0xFF2F7FBF).withValues(alpha: 0.22),
            ),
          ],
        ],
      ),
    ],
  );
}

Widget _manifestCard(String quote) {
  return Container(
    width: 780,
    padding: const EdgeInsets.all(36),
    decoration: BoxDecoration(
      color: _badgeBg,
      borderRadius: BorderRadius.circular(32),
    ),
    child: Column(
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            color: const Color(0xFFE8B44A),
            borderRadius: BorderRadius.circular(20),
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.photo_camera_rounded,
            color: Colors.white,
            size: 44,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          '"$quote"',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 26,
            fontStyle: FontStyle.italic,
            color: _secondaryText,
          ),
        ),
      ],
    ),
  );
}

Widget _goalDaysRow(String statLabel, int filledCount) {
  return Column(
    children: [
      Text(
        statLabel,
        style: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: _secondaryText,
        ),
      ),
      const SizedBox(height: 22),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 1; i <= 7; i++) ...[
            if (i > 1) const SizedBox(width: 12),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i <= filledCount
                    ? const Color(0xFFE8B44A)
                    : Colors.white,
                border: Border.all(
                  color: i <= filledCount
                      ? Colors.transparent
                      : const Color(0xFFE0D0A8),
                  width: 2,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                '$i',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: i <= filledCount ? Colors.white : _secondaryText,
                ),
              ),
            ),
          ],
        ],
      ),
    ],
  );
}

Widget _pillWrap(List<String> labels) {
  return Wrap(
    alignment: WrapAlignment.center,
    spacing: 16,
    runSpacing: 16,
    children: [for (final l in labels) _pill(l)],
  );
}

Widget _storeAccent(List<String> pills, String buttonLabel) {
  return Column(
    children: [
      _pillWrap(pills),
      const SizedBox(height: 24),
      _pill(buttonLabel, bg: _primaryText, fg: Colors.white),
    ],
  );
}

Widget _profileAccent(String score, String streakLabel) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Container(
        width: 110,
        height: 110,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE8B44A), width: 6),
        ),
        alignment: Alignment.center,
        child: Text(
          score,
          style: const TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.bold,
            color: _primaryText,
          ),
        ),
      ),
      const SizedBox(width: 20),
      _pill('🔥 $streakLabel'),
    ],
  );
}

List<_ScreenshotSpec> _specsFor(String lang) {
  final t = _copy[lang]!;
  return [
    _ScreenshotSpec(
      fileName: '1_mood_$lang',
      badgeEmoji: '😊',
      badgeLabel: t['mood_badge']!,
      headline: t['mood_headline']!,
      subtext: t['mood_subtext']!,
      characterAsset: 'assets/images/zibo_yeni.png',
      accentBuilder: () => _moodRow(3),
    ),
    _ScreenshotSpec(
      fileName: '2_gratitude_$lang',
      badgeEmoji: '🙏',
      badgeLabel: t['gratitude_badge']!,
      headline: t['gratitude_headline']!,
      subtext: t['gratitude_subtext']!,
      characterAsset: 'assets/images/zibo_hoca.png',
      accentBuilder: () => _checklistCard([
        t['gratitude_item1']!,
        t['gratitude_item2']!,
        t['gratitude_item3']!,
      ]),
    ),
    _ScreenshotSpec(
      fileName: '3_water_$lang',
      badgeEmoji: '💧',
      badgeLabel: t['water_badge']!,
      headline: t['water_headline']!,
      subtext: t['water_subtext']!,
      characterAsset: 'assets/images/zibo_hippi.png',
      accentBuilder: () => _waterAccent(t['water_stat']!),
    ),
    _ScreenshotSpec(
      fileName: '4_manifest_$lang',
      badgeEmoji: '✨',
      badgeLabel: t['manifest_badge']!,
      headline: t['manifest_headline']!,
      subtext: t['manifest_subtext']!,
      characterAsset: 'assets/images/zibo_astronot.png',
      accentBuilder: () => _manifestCard(t['manifest_quote']!),
    ),
    _ScreenshotSpec(
      fileName: '5_goals_$lang',
      badgeEmoji: '🎯',
      badgeLabel: t['goals_badge']!,
      headline: t['goals_headline']!,
      subtext: t['goals_subtext']!,
      characterAsset: 'assets/images/zibo_sporcu.png',
      accentBuilder: () => _goalDaysRow(t['goals_stat']!, 3),
    ),
    _ScreenshotSpec(
      fileName: '6_overview_$lang',
      badgeEmoji: '🐾',
      badgeLabel: t['overview_badge']!,
      headline: t['overview_headline']!,
      subtext: t['overview_subtext']!,
      characterAsset: 'assets/images/zibo_yeni.png',
      accentBuilder: () => _pillWrap([
        t['overview_pill1']!,
        t['overview_pill2']!,
        t['overview_pill3']!,
        t['overview_pill4']!,
      ]),
    ),
    _ScreenshotSpec(
      fileName: '7_store_$lang',
      badgeEmoji: '🪙',
      badgeLabel: t['store_badge']!,
      headline: t['store_headline']!,
      subtext: t['store_subtext']!,
      characterAsset: 'assets/images/zibo_altin.png',
      accentBuilder: () => _storeAccent(
        [t['store_pill1']!, t['store_pill2']!, t['store_pill3']!],
        t['store_button']!,
      ),
    ),
    _ScreenshotSpec(
      fileName: '8_profile_$lang',
      badgeEmoji: '👤',
      badgeLabel: t['profile_badge']!,
      headline: t['profile_headline']!,
      subtext: t['profile_subtext']!,
      characterAsset: 'assets/images/zibo_gentleman.png',
      accentBuilder: () => _profileAccent('8.5', t['profile_streak']!),
    ),
  ];
}

// Play Console'daki mevcut Türkçe metinlerin İngilizce/İspanyolca
// uyarlaması — kelimesi kelimesine çeviri DEĞİL, aynı sıcak/samimi ton
// korunarak (bkz. motivation_pools.dart'taki AYNI felsefe).
const _copy = <String, Map<String, String>>{
  'en': {
    'mood_badge': 'Mood Tracking',
    'mood_headline': 'How Are You *Feeling* Today?',
    'mood_subtext':
        'Log your mood with a single tap and see your weekly changes. '
        'The easiest way to get to know yourself better.',
    'gratitude_badge': 'Gratitude Journal',
    'gratitude_headline': 'Start Your Day With Small *Thanks*',
    'gratitude_subtext':
        "Write three things you're grateful for every day. Over time, "
        'these lines become a reminder that lifts you up on hard days.',
    'gratitude_item1': 'A warm cup of coffee',
    'gratitude_item2': "My family's support",
    'gratitude_item3': 'My little smile today',
    'water_badge': 'Water Tracking',
    'water_headline': "Don't *Forget* Your Water, Zibo Reminds You",
    'water_subtext':
        'Set your daily water goal in your own units (glasses or bottles) '
        'and mark every sip. Your body will thank you.',
    'water_stat': '5/8 glasses · 1250 ml',
    'manifest_badge': 'Manifestation Journal',
    'manifest_headline': '*Visualize* Your Dreams',
    'manifest_subtext':
        'Save your intention with a photo and a few sentences. Build your '
        'own vision board over time and get closer to your dreams every day.',
    'manifest_quote': 'I wake up every morning in peace.',
    'goals_badge': 'Goal Tracking',
    'goals_headline': 'Progress With Your *7-Day Cycle*',
    'goals_subtext':
        'Set your own goals and check them off every day. Zibo is by your '
        'side to grow your streak — complete a week and a little '
        'celebration awaits.',
    'goals_stat': '3/7 days',
    'overview_badge': 'Your Digital Friend',
    'overview_headline': 'Get a Little Better *Every Day* With Zibo',
    'overview_subtext':
        'Your digital friend by your side in every part of your life — '
        'from your goals to your mood, your little journals to your savings.',
    'overview_pill1': '🎯 Goals',
    'overview_pill2': '💧 Water',
    'overview_pill3': '📓 Journals',
    'overview_pill4': '🪙 Zibo Coin',
    'store_badge': 'Zibo Coin',
    'store_headline': 'Earn, *Spend*, Dress Up Zibo',
    'store_subtext':
        'Collect Zibo Coins through daily tasks, goals, and ads. Spend '
        'them on costumes, animated themes, and the Lucky Wheel.',
    'store_pill1': 'Coin',
    'store_pill2': 'Costumes',
    'store_pill3': 'Themes',
    'store_button': '🎡 Spin the Lucky Wheel',
    'profile_badge': 'Your Profile',
    'profile_headline': 'Strengthen Your *Bond* With Zibo',
    'profile_subtext':
        'Your bond with Zibo grows stronger every day. Track your stats, '
        'your longest streak, and your bond level in your profile.',
    'profile_streak': '12-day streak',
  },
  'es': {
    'mood_badge': 'Seguimiento del Ánimo',
    'mood_headline': '¿Cómo Te *Sientes* Hoy?',
    'mood_subtext':
        'Registra tu estado de ánimo con un toque y observa tu cambio '
        'semanal. La forma más fácil de conocerte mejor.',
    'gratitude_badge': 'Diario de Gratitud',
    'gratitude_headline': 'Empieza el Día con Pequeñas *Gracias*',
    'gratitude_subtext':
        'Escribe cada día tres cosas por las que estás agradecido. Con el '
        'tiempo, estas líneas se convierten en un recordatorio que te '
        'anima en los días difíciles.',
    'gratitude_item1': 'Una taza de café calentito',
    'gratitude_item2': 'El apoyo de mi familia',
    'gratitude_item3': 'Mi pequeña sonrisa de hoy',
    'water_badge': 'Seguimiento de Agua',
    'water_headline': 'No *Olvides* Tu Agua, Zibo Te Recuerda',
    'water_subtext':
        'Define tu meta diaria de agua en tus propias unidades (vasos o '
        'botellas) y marca cada sorbo. Tu cuerpo te lo agradecerá.',
    'water_stat': '5/8 vasos · 1250 ml',
    'manifest_badge': 'Diario de Manifestación',
    'manifest_headline': '*Visualiza* Tus Sueños',
    'manifest_subtext':
        'Guarda tu intención con una foto y unas frases. Crea con el '
        'tiempo tu propio tablero de visión y acércate cada día un poco '
        'más a tus sueños.',
    'manifest_quote': 'Cada mañana despierto en paz.',
    'goals_badge': 'Seguimiento de Metas',
    'goals_headline': 'Avanza con tu *Ciclo de 7 Días*',
    'goals_subtext':
        'Define tus propias metas y márcalas cada día. Zibo está a tu '
        'lado para hacer crecer tu racha: completa una semana y una '
        'pequeña celebración te espera.',
    'goals_stat': '3/7 días',
    'overview_badge': 'Tu Amigo Digital',
    'overview_headline': 'Sé un Poco Mejor *Cada Día* con Zibo',
    'overview_subtext':
        'Tu amigo digital a tu lado en cada parte de tu vida: desde tus '
        'metas hasta tu ánimo, tus pequeños diarios y tus ahorros.',
    'overview_pill1': '🎯 Metas',
    'overview_pill2': '💧 Agua',
    'overview_pill3': '📓 Diarios',
    'overview_pill4': '🪙 Zibo Coin',
    'store_badge': 'Zibo Coin',
    'store_headline': 'Gana, *Gasta*, Viste a Zibo',
    'store_subtext':
        'Acumula Zibo Coins con tareas diarias, metas y anuncios. '
        'Gástalas en trajes, temas animados y la Rueda de la Suerte.',
    'store_pill1': 'Monedas',
    'store_pill2': 'Trajes',
    'store_pill3': 'Temas',
    'store_button': '🎡 Gira la Rueda de la Suerte',
    'profile_badge': 'Tu Perfil',
    'profile_headline': 'Fortalece Tu *Vínculo* con Zibo',
    'profile_subtext':
        'Tu vínculo con Zibo se fortalece día a día. Sigue tus '
        'estadísticas, tu racha más larga y tu nivel de vínculo en tu perfil.',
    'profile_streak': 'racha de 12 días',
  },
};

// Play Console'daki mevcut Türkçe "Özellik grafiği"nin (1024x500) BİREBİR
// aynı yapısı: solda logo + 3 satırlık başlık (son satır vurgulu) + 3 rozet,
// sağda varsayılan Zibo. Telefon/tablet ekran görüntülerinden AYRI, kendi
// küçük veri seti — yalnızca İKİ dil için tek satır gerektiği için ayrı bir
// `_ScreenshotSpec`/`_copy` girdisine gerek duyulmadı.
const _featureGraphicCopy = <String, ({List<String> lines, List<String> pills})>{
  'en': (
    lines: ['Reach your goals,', 'build habits,', 'get a little better each day.'],
    pills: ['🎯 Goal Tracking', '📓 Journals', '💧 Water Tracking'],
  ),
  'es': (
    lines: ['Alcanza tus metas,', 'crea hábitos,', 'sé un poco mejor cada día.'],
    pills: ['🎯 Seguimiento de Metas', '📓 Diarios', '💧 Seguimiento de Agua'],
  ),
};

/// [_featureGraphicCard] için küçük, kompakt bir pill — [_pill]'in tam
/// boyutu (padding 26/14, fontSize 26) 500px yüksekliğindeki Özellik
/// grafiği tuvaline göre orantısız büyük kalıyor, bu yüzden ayrı bir
/// mini varyant.
Widget _featureGraphicPill(String text) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    decoration: BoxDecoration(
      color: _badgeBg,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: _primaryText,
      ),
    ),
  );
}

/// Bir render hedefini (dosya adı + tuval boyutu + hazır widget) taşıyan
/// jenerik kayıt — telefon/tablet/Özellik grafiği ÜÇÜ de farklı tuval
/// boyutu ve farklı bir kart oluşturucu kullandığı için, [_ScreenshotSpec]
/// listesinin üzerine TEK bir birleşik yapı kuruluyor (capture/preview
/// döngüsü tek bir listeyi dolaşabilsin diye).
class _RenderItem {
  const _RenderItem({
    required this.fileName,
    required this.size,
    required this.child,
  });

  final String fileName;
  final Size size;
  final Widget child;
}

class _StoreShotGeneratorApp extends StatefulWidget {
  const _StoreShotGeneratorApp();

  @override
  State<_StoreShotGeneratorApp> createState() =>
      _StoreShotGeneratorAppState();
}

class _StoreShotGeneratorAppState extends State<_StoreShotGeneratorApp> {
  String _status = 'Hazırlanıyor…';
  final Map<String, GlobalKey> _keys = {};

  List<_ScreenshotSpec> get _all => [
    ..._specsFor('en'),
    ..._specsFor('es'),
  ];

  /// Tüm render hedeflerinin (16 telefon + 16 tablet + 2 Özellik grafiği =
  /// 34) birleşik listesi — capture/preview döngüsünün tek bir kaynaktan
  /// beslenmesi için. Tablet slotları (7 inç/10 inç) Play Console'da AYNI
  /// 8 görseli paylaştığı için (bkz. dosya başındaki not) yalnızca TEK bir
  /// yatay set üretiliyor, dosya adına `_tablet` eki eklenerek telefon
  /// setinden ayırt ediliyor.
  List<_RenderItem> get _renderItems {
    final items = <_RenderItem>[
      for (final spec in _all)
        _RenderItem(fileName: spec.fileName, size: _canvasSize, child: _card(spec)),
      for (final spec in _all)
        _RenderItem(
          fileName: '${spec.fileName}_tablet',
          size: _tabletCanvasSize,
          child: _tabletCard(spec),
        ),
      for (final lang in ['en', 'es'])
        _RenderItem(
          fileName: 'feature_graphic_$lang',
          size: _featureGraphicSize,
          child: _featureGraphicCard(lang),
        ),
    ];
    return items;
  }

  Widget _card(_ScreenshotSpec spec) {
    return SizedBox(
      width: _canvasSize.width,
      height: _canvasSize.height,
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_bgStart, _bgEnd],
                ),
              ),
            ),
          ),
          // Sağ üstteki soluk "parlama" — orijinal ekran görüntülerindeki
          // AYNI yumuşak radyal ışık lekesi.
          Positioned(
            top: -120,
            right: -120,
            child: Container(
              width: 480,
              height: 480,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.55),
                    Colors.white.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 70),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                Image.asset('assets/images/zibo_logo_new.png', height: 96),
                const SizedBox(height: 30),
                _pill('${spec.badgeEmoji} ${spec.badgeLabel}'),
                const SizedBox(height: 44),
                Image.asset(spec.characterAsset, height: 460),
                const SizedBox(height: 40),
                Text.rich(
                  TextSpan(
                    children: _headlineSpans(
                      spec.headline,
                      const TextStyle(color: _primaryText),
                    ),
                  ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 54,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                    color: _primaryText,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  spec.subtext,
                  textAlign: TextAlign.center,
                  maxLines: 4,
                  style: const TextStyle(
                    fontSize: 29,
                    height: 1.4,
                    color: _secondaryText,
                  ),
                ),
                  const SizedBox(height: 52),
                  spec.accentBuilder(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 1920×1080 yatay şablon — karakter solda büyük, sağda logo/rozet/SOLA
  /// hizalı başlık+alt metin+aksan sütunu. Türkçe orijinaldeki (bkz. dosya
  /// başındaki keşif notu) yerleşimle aynı, `_ScreenshotSpec`'in AYNI
  /// verisini yeniden kullanıyor — tablet için ayrı bir metin/çeviri veri
  /// seti GEREKMEDİ.
  Widget _tabletCard(_ScreenshotSpec spec) {
    return SizedBox(
      width: _tabletCanvasSize.width,
      height: _tabletCanvasSize.height,
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_bgStart, _bgEnd],
                ),
              ),
            ),
          ),
          Positioned(
            top: -140,
            right: -140,
            child: Container(
              width: 560,
              height: 560,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.55),
                    Colors.white.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 90, vertical: 60),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    flex: 5,
                    child: Center(
                      child: Image.asset(
                        spec.characterAsset,
                        height: 840,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(width: 40),
                  Expanded(
                    flex: 6,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset('assets/images/zibo_logo_new.png', height: 72),
                        const SizedBox(height: 24),
                        _pill('${spec.badgeEmoji} ${spec.badgeLabel}'),
                        const SizedBox(height: 32),
                        Text.rich(
                          TextSpan(
                            children: _headlineSpans(
                              spec.headline,
                              const TextStyle(color: _primaryText),
                            ),
                          ),
                          textAlign: TextAlign.left,
                          style: const TextStyle(
                            fontSize: 46,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                            color: _primaryText,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          spec.subtext,
                          textAlign: TextAlign.left,
                          maxLines: 4,
                          style: const TextStyle(
                            fontSize: 25,
                            height: 1.4,
                            color: _secondaryText,
                          ),
                        ),
                        const SizedBox(height: 34),
                        spec.accentBuilder(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 1024×500 sabit tuval — Play Console'un "Özellik grafiği" alanı için.
  /// Türkçe orijinalin (bkz. dosya başındaki keşif notu) BİREBİR aynı
  /// yapısı: solda logo + 3 satırlık başlık (son satır vurgulu) + rozet
  /// pilleri, sağda varsayılan (kostümsüz) Zibo.
  Widget _featureGraphicCard(String lang) {
    final copy = _featureGraphicCopy[lang]!;
    return SizedBox(
      width: _featureGraphicSize.width,
      height: _featureGraphicSize.height,
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_bgStart, _bgEnd],
                ),
              ),
            ),
          ),
          Positioned(
            top: -60,
            right: -40,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.5),
                    Colors.white.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    flex: 6,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset('assets/images/zibo_logo_new.png', height: 38),
                        const SizedBox(height: 12),
                        for (var i = 0; i < copy.lines.length; i++)
                          Text(
                            copy.lines[i],
                            style: TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                              height: 1.18,
                              color: i == copy.lines.length - 1
                                  ? _accentGold
                                  : _primaryText,
                            ),
                          ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final label in copy.pills)
                              _featureGraphicPill(label),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 4,
                    child: Align(
                      alignment: Alignment.bottomRight,
                      child: Image.asset(
                        'assets/images/zibo_yeni.png',
                        height: 420,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _captureAll() async {
    final dir = await getApplicationDocumentsDirectory();
    var count = 0;
    for (final item in _renderItems) {
      final key = _keys[item.fileName]!;
      final boundary =
          key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 1.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('${dir.path}/${item.fileName}.png');
      await file.writeAsBytes(byteData!.buffer.asUint8List());
      count++;
    }
    setState(() => _status = 'Bitti — $count dosya yazıldı: ${dir.path}');
  }

  @override
  void initState() {
    super.initState();
    for (final item in _renderItems) {
      _keys[item.fileName] = GlobalKey();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      await _captureAll();
    });
  }

  // Önizleme şeridindeki her kartın hedef GENİŞLİĞİ — telefon/tablet/
  // Özellik grafiği üçünün tuval boyutu birbirinden çok farklı olduğu için
  // (bkz. `_RenderItem.size`), sabit bir ölçek yerine her öğe kendi
  // en-boy oranını koruyarak BU genişliğe küçültülüyor.
  static const _previewWidth = 220.0;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(_status, style: const TextStyle(fontSize: 12)),
              ),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final item in _renderItems)
                        Padding(
                          padding: const EdgeInsets.all(4),
                          child: Transform.scale(
                            scale: _previewWidth / item.size.width,
                            alignment: Alignment.topLeft,
                            child: SizedBox(
                              width: _previewWidth,
                              height:
                                  item.size.height *
                                  (_previewWidth / item.size.width),
                              child: OverflowBox(
                                minWidth: item.size.width,
                                maxWidth: item.size.width,
                                minHeight: item.size.height,
                                maxHeight: item.size.height,
                                alignment: Alignment.topLeft,
                                child: RepaintBoundary(
                                  key: _keys[item.fileName],
                                  child: item.child,
                                ),
                              ),
                            ),
                          ),
                        ),
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

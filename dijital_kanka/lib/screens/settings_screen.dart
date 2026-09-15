import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/legal_texts.dart';
import '../l10n/app_localizations.dart';
import '../providers/auth_link_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/sound_effects_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/google_link_action.dart';
import '../utils/info_dialog.dart';
import '../widgets/dot_grid_background.dart';
import '../widgets/founder_badge_promo_card.dart';
import '../widgets/language_flag_circle.dart';
import '../widgets/rate_us_sheet.dart';
import '../widgets/sticker_style.dart';
import 'legal_placeholder_screen.dart';
import 'widgets_screen.dart';

/// Destek e-postası — Ayarlar > Destek > "Bize Ulaşın" satırında hem
/// görünen metin hem `mailto:` hedefi olarak kullanılıyor.
const _contactEmail = 'contact@getzibo.com';

/// Web sitesi — Ayarlar > Hakkında > "Web Sitesi" satırında hem görünen
/// metin hem `https://` hedefi olarak kullanılıyor.
const _websiteHost = 'getzibo.com';

/// [uri]'yi açmayı dener; cihazda uygun bir uygulama yoksa (ör. hiç mail
/// istemcisi kurulu değilse) sessizce başarısız olmak yerine kullanıcıya
/// kısa bir hata mesajı gösterir.
Future<void> _launchOrShowError(BuildContext context, Uri uri) async {
  final l10n = AppLocalizations.of(context)!;
  final launched = await launchUrl(uri).catchError((_) => false);
  if (!launched && context.mounted) {
    showInfoDialog(context, l10n.settingsCouldNotOpenLink);
  }
}

/// Ayarlar sayfası. Başlık çubuğundaki dişli ikonundan push edilir; alt
/// gezinme çubuğunda bir sekme değildir, bu yüzden kendi Scaffold/AppBar'ını
/// (geri butonu dahil) taşır. **2026 "Çizgi Roman Çıkartması" restyle'ı**
/// (bkz. `docs/theme_new.md` "Onaylanan: Ayarlar ekranı") — bu ekranın
/// AppBar'ı, diğer tüm sekmelerin paylaştığı `RootScreen` AppBar'ından
/// BİLEREK FARKLI: kendi düz "geri oku + başlık" çubuğu var (mockup notu:
/// "bu bir push ekranı"). Bölümler (Genel/Destek/Uygulama Hakkında) TEK bir
/// [_SettingsGroupCard] içinde ince çizgilerle ayrılmış satırlardan oluşuyor
/// — Profil'in satır-başına-ayrı-kart deseninden (`StickerRowCard`) BİLEREK
/// FARKLI, gerçek kodun `Card`+`Divider` yapısıyla birebir uyumlu.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  /// **2026 güncellemesi** — eski koyu/açık `SwitchListTile`'ının yerini
  /// aldı (bkz. `ThemeProvider` dokümantasyonu). `_showLanguagePicker` ile
  /// BİREBİR AYNI görsel desen ([_SettingsPickerSheet] — başlık + seçenek
  /// listesi + seçili olana ✓) — kullanıcı zaten bu deseni Dil satırından
  /// tanıyor.
  Future<void> _showThemeModePicker(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final themeProvider = context.read<ThemeProvider>();
    final options = {
      ThemeMode.light: l10n.settingsThemeModeLight,
      ThemeMode.dark: l10n.settingsThemeModeDark,
      ThemeMode.system: l10n.settingsThemeModeSystem,
    };

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => _SettingsPickerSheet(
        title: l10n.settingsAppearance,
        children: [
          for (final entry in options.entries)
            _SheetOptionRow(
              label: entry.value,
              selected: themeProvider.themeMode == entry.key,
              onTap: () {
                themeProvider.setThemeMode(entry.key);
                Navigator.of(sheetContext).pop();
              },
            ),
        ],
      ),
    );
  }

  Future<void> _showLanguagePicker(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final localeProvider = context.read<LocaleProvider>();

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => _SettingsPickerSheet(
        title: l10n.settingsLanguage,
        children: [
          for (final code in supportedLanguageCodes)
            _SheetOptionRow(
              leading: LanguageFlagCircle(languageCode: code, size: 22),
              label: languageAutonym(code),
              selected: localeProvider.locale.languageCode == code,
              onTap: () {
                localeProvider.setLocale(Locale(code));
                Navigator.of(sheetContext).pop();
              },
            ),
        ],
      ),
    );
  }

  String _themeModeLabel(AppLocalizations l10n, ThemeMode mode) => switch (mode) {
    ThemeMode.light => l10n.settingsThemeModeLight,
    ThemeMode.dark => l10n.settingsThemeModeDark,
    ThemeMode.system => l10n.settingsThemeModeSystem,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final themeMode = context.watch<ThemeProvider>().themeMode;
    final soundEffectsEnabled = context.watch<SoundEffectsProvider>().enabled;
    final currentLanguageCode = context.watch<LocaleProvider>().locale.languageCode;
    final authLink = context.watch<AuthLinkProvider>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: colorScheme.surfaceContainerLowest,
        leadingWidth: 62,
        titleSpacing: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: StickerIconButton(
              icon: Icons.arrow_back_rounded,
              onPressed: () => Navigator.of(context).maybePop(),
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              backgroundColor: colorScheme.surfaceContainerLowest,
              iconColor: kStickerOutline,
              size: 34,
              iconSize: 16,
              borderRadius: null,
            ),
          ),
        ),
        title: Text(
          l10n.tabSettings,
          style: const TextStyle(
            fontFamily: 'Baloo2',
            fontVariations: [FontVariation('wght', 800)],
            fontSize: 18,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: Container(height: 3, color: kStickerOutline),
        ),
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: DotGridBackground()),
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              // --- Genel: koyu tema + dil + (varsa) bildirimler — kullanıcının
              // uygulama genelinde nasıl davrandığını belirlediği tercihler.
              _SectionEyebrow(l10n.settingsSectionGeneral),
              const SizedBox(height: 8),
              _SettingsGroupCard(
                children: [
                  _SettingsRow(
                    iconContent: const Text('🌗', style: TextStyle(fontSize: 15, height: 1)),
                    title: l10n.settingsAppearance,
                    trailingValue: _themeModeLabel(l10n, themeMode),
                    onTap: () => _showThemeModePicker(context),
                  ),
                  _groupDivider(context),
                  // 2026 yeni özellik — uygulama içi kısa ses efektlerini
                  // (şimdilik yalnızca Zibo dokunma sesi, bkz.
                  // SoundEffectsService) açıp kapatır.
                  _SettingsRow(
                    iconContent: const Text('🔊', style: TextStyle(fontSize: 15, height: 1)),
                    title: l10n.settingsSoundEffects,
                    trailingChild: _StickerSwitch(
                      value: soundEffectsEnabled,
                      onChanged: (value) =>
                          context.read<SoundEffectsProvider>().setEnabled(value),
                    ),
                    // Mockup notu (docs/theme_new.md "Onaylanan: Ayarlar
                    // ekranı"): "satırın HERHANGİ bir yerine dokunmak
                    // açar/kapatır" — yalnızca anahtarın kendisi değil.
                    onTap: () => context
                        .read<SoundEffectsProvider>()
                        .setEnabled(!soundEffectsEnabled),
                  ),
                  _groupDivider(context),
                  // Dil satırı: seçili dilin küçük yuvarlak bayrağı + adı
                  // trailing alanında görünür, dokununca üç dilli (TR/EN/ES)
                  // bir seçim sheet'i açılır (bkz. LocaleProvider).
                  _SettingsRow(
                    iconContent: const Text('🌐', style: TextStyle(fontSize: 15, height: 1)),
                    title: l10n.settingsLanguage,
                    trailingChild: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        LanguageFlagCircle(languageCode: currentLanguageCode, size: 20),
                        const SizedBox(width: 6),
                        Text(
                          languageAutonym(currentLanguageCode),
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const _RowChevron(),
                      ],
                    ),
                    onTap: () => _showLanguagePicker(context),
                  ),
                  _groupDivider(context),
                  // 2026 yeni özellik — sekiz modülün ana ekran widget'larını
                  // (bkz. CLAUDE.md "Ana Ekran Widget'ları" bölümü) listeleyen
                  // ayrı bir ekrana götürür.
                  _SettingsRow(
                    iconContent: const Text('🧩', style: TextStyle(fontSize: 15, height: 1)),
                    title: l10n.widgetsScreenTitle,
                    subtitle: l10n.settingsWidgetsRowSubtitle,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => const WidgetsScreen()),
                    ),
                  ),
                  // 2026 yeni özellik — Kurucu Üye rozeti kontenjanı hâlâ
                  // doluysa VE hesap henüz bağlı değilse, hemen aşağıdaki
                  // Google satırının ÜSTÜNE küçük bir teşvik kartı ekler
                  // (bkz. FounderBadgePromoCard dokümantasyonu — kart kendi
                  // içinde koşulları kontrol edip gerekmiyorsa hiçbir yer
                  // kaplamıyor, bu yüzden burada ekstra bir `if` GEREKMEDİ).
                  const Padding(
                    padding: EdgeInsets.fromLTRB(12, 12, 12, 0),
                    child: FounderBadgePromoCard(),
                  ),
                  // 2026 yeni özellik — mevcut (anonim) hesabı Google'a
                  // bağlayıp cihaz değişikliğinde veri kaybını önler (bkz.
                  // AuthLinkProvider/utils/google_link_action.dart). Profil
                  // sayfasındaki "Zibo ile Bağın" satırıyla AYNI onTap
                  // mantığı.
                  _SettingsRow(
                    // Bağlıyken bağlı hesabın kendi Google logosuyla (SVG,
                    // kullanıcının sağladığı `Google__G__logo.svg`) gösterilir
                    // — bağlı DEĞİLKEN jenerik "link" ikonuna geri düşülür
                    // (logo yalnızca GERÇEKTEN bağlı bir hesabı temsil etmeli).
                    // İkon dairesi mockup'taki gibi BEYAZ zeminli (`iconBackground`)
                    // — diğer satırların altın zemininden BİLEREK farklı.
                    iconContent: authLink.isLinked
                        ? SvgPicture.asset(
                            'assets/images/Google__G__logo.svg',
                            width: 20,
                            height: 20,
                          )
                        : const Icon(Icons.link_rounded, size: 18),
                    iconBackground: colorScheme.surfaceContainerLowest,
                    title: authLink.isLinked
                        ? l10n.googleLinkRowTitleLinked
                        : l10n.googleLinkRowTitleUnlinked,
                    subtitle: authLink.isLinked
                        ? (authLink.linkedEmail ?? '')
                        : l10n.googleLinkRowSubtitle,
                    onTap: () => handleGoogleLinkTap(context),
                  ),
                  // 2026 güncellemesi — hesap ZATEN bağlıyken "Çıkış Yap"/
                  // "Hesap Değiştir" butonları. Bilerek yalnızca `isLinked`
                  // iken gösteriliyor: SAF anonim (bağlanmamış) bir hesapta
                  // "çıkış yapmak", o hesaba bir daha ASLA geri dönülemeyeceği
                  // (anonim kimlik bilgileri taşınabilir/tekrar
                  // kullanılabilir DEĞİL) için verinin GERİ DÖNÜŞSÜZ
                  // terkedilmesi anlamına gelirdi — bkz. CLAUDE.md "Google
                  // Hesap Bağlama" bölümü.
                  if (authLink.isLinked) ...[
                    _groupDivider(context),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                      child: authLink.isLinking
                          ? const Center(
                              child: SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(strokeWidth: 2.5),
                              ),
                            )
                          : Row(
                              children: [
                                _AccountActionButton(
                                  icon: Icons.logout_rounded,
                                  label: l10n.googleSignOutButton,
                                  onPressed: () => handleSignOutTap(context),
                                ),
                                const SizedBox(width: 10),
                                _AccountActionButton(
                                  icon: Icons.swap_horiz_rounded,
                                  label: l10n.googleSwitchAccountButton,
                                  onPressed: () => handleSwitchAccountTap(context),
                                ),
                              ],
                            ),
                    ),
                  ],
                ],
              ),
              if (notificationsFeatureEnabled) ...[
                const SizedBox(height: 12),
                const _NotificationSettingsCard(),
              ],

              // --- Destek: kullanıcının bir sorun/soru için bize ulaşabileceği
              // kanal.
              const SizedBox(height: 24),
              _SectionEyebrow(l10n.settingsSectionSupport),
              const SizedBox(height: 8),
              _SettingsGroupCard(
                children: [
                  _SettingsRow(
                    iconContent: const Text('✉️', style: TextStyle(fontSize: 15, height: 1)),
                    title: l10n.settingsContactUs,
                    subtitle: _contactEmail,
                    onTap: () => _launchOrShowError(
                      context,
                      Uri(scheme: 'mailto', path: _contactEmail),
                    ),
                  ),
                  _groupDivider(context),
                  // 2026 yeni özellik — test geri bildirim raporunun "Uygulama
                  // İçi Puanlama İstemi" önerisine karşılık; düz bir metin
                  // yerine Zibo görseli + 5 yıldızlık dokunmatik seçim
                  // (bkz. `rate_us_sheet.dart`).
                  _SettingsRow(
                    iconContent: const Text('⭐', style: TextStyle(fontSize: 15, height: 1)),
                    title: l10n.settingsRateUs,
                    subtitle: l10n.settingsRateUsSubtitle,
                    onTap: () => showRateUsSheet(context),
                  ),
                ],
              ),

              // --- Hakkında: sürüm bilgisi + hukuki/kurumsal linkler.
              const SizedBox(height: 24),
              _SectionEyebrow(l10n.settingsAbout),
              const SizedBox(height: 8),
              _SettingsGroupCard(
                children: [
                  const _AppVersionRow(),
                  _groupDivider(context),
                  _SettingsRow(
                    iconContent: const Text('🌍', style: TextStyle(fontSize: 15, height: 1)),
                    title: l10n.settingsWebsite,
                    subtitle: _websiteHost,
                    onTap: () => _launchOrShowError(
                      context,
                      Uri.https(_websiteHost),
                    ),
                  ),
                  _groupDivider(context),
                  _SettingsRow(
                    iconContent: const Text('🛡️', style: TextStyle(fontSize: 15, height: 1)),
                    title: l10n.settingsPrivacyPolicy,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => LegalPlaceholderScreen(
                          title: l10n.settingsPrivacyPolicy,
                          // **2026 güncellemesi** — artık uygulama dili
                          // hangisiyse (bkz. `LocaleProvider`) o dilde
                          // gösteriliyor, eskiden HER ZAMAN Türkçe idi (bkz.
                          // `legal_texts.dart`'ın dosya başındaki notu).
                          body: privacyPolicyForLocale(Localizations.localeOf(context)),
                        ),
                      ),
                    ),
                  ),
                  _groupDivider(context),
                  _SettingsRow(
                    iconContent: const Text('📄', style: TextStyle(fontSize: 15, height: 1)),
                    title: l10n.settingsTermsOfService,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => LegalPlaceholderScreen(
                          title: l10n.settingsTermsOfService,
                          body: termsOfServiceForLocale(Localizations.localeOf(context)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              if (notificationsFeatureEnabled) ...[
                const SizedBox(height: 24),
                const _NotificationDebugPanel(),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

Widget _groupDivider(BuildContext context) {
  return Container(height: 2, color: Theme.of(context).colorScheme.outlineVariant);
}

/// Ayarlar'ın "Genel"/"Destek"/"Uygulama Hakkında" bölüm başlığı — mockup'ın
/// `.section-eyebrow` (küçük, kalın, hafif harf aralıklı). Mockup BÜYÜK HARF
/// gösteriyor, ama `widget_test.dart` bu başlıkları `find.text('Genel')` gibi
/// TAM eşleşmeyle (orijinal l10n metniyle, büyütülmemiş) arıyor — bu yüzden
/// [String.toUpperCase] KASITLI olarak uygulanmıyor, testler kırılır.
class _SectionEyebrow extends StatelessWidget {
  const _SectionEyebrow(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: 'Baloo2',
        fontVariations: const [FontVariation('wght', 800)],
        fontSize: 12.5,
        letterSpacing: 0.6,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}

/// Bir bölümün TÜM satırlarını TEK bir kalın-kontur/düz-gölge kartın içine
/// alan sarmalayıcı — mockup'ın `.group-card` (bkz. `docs/theme_new.md`
/// "Onaylanan: Ayarlar ekranı" notu: "satır-başına-ayrı-kart DEĞİL").
/// Satırlar arasındaki ince çizgiler ([_groupDivider]) çağıran taraftan
/// (ör. koşullu Google satırı/butonları için) ELLE eklenir — bu yüzden
/// burada otomatik araya-ekleme YOK.
class _SettingsGroupCard extends StatelessWidget {
  const _SettingsGroupCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: stickerDecoration(
        fill: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
      ),
      // İçerideki `ListTile`lar en yakın `Material` ATASINA göre kendi
      // arka planını/ink splash'ini çiziyor — bu Container'ın KENDİ opak
      // dolgusu (yukarıdaki `decoration`) araya girip o efekti
      // GİZLEMESİN diye şeffaf bir `Material` buraya EKLENİYOR (bkz.
      // Flutter'ın "ListTile background color or ink splashes may be
      // invisible" uyarısı — `docs/theme_new.md`'deki "ink görünürlüğü"
      // dersiyle AYNI kök neden, farklı belirti).
      child: Material(
        color: Colors.transparent,
        child: Column(mainAxisSize: MainAxisSize.min, children: children),
      ),
    );
  }
}

/// [_SettingsGroupCard] içindeki tek bir satır — solda emoji/ikon dairesi,
/// ortada başlık(+alt metin), sağda değer metni/özel widget ve/veya köşeli
/// ok. Gerçek bir [ListTile] olarak KALIYOR — hem `trailing` alanı farklı
/// türde içerik (switch, değer metni) taşıyabilsin hem de
/// `widget_test.dart`'ın "Görünüm"/"Gizlilik Politikası"/"Kullanım
/// Koşulları" satırlarını `find.byType(ListTile)` ile bulup `.onTap!()`'i
/// DOĞRUDAN çağıran testleri BOZULMASIN diye (bkz. o dosyadaki ilgili
/// testler).
class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.iconContent,
    required this.title,
    this.subtitle,
    this.trailingValue,
    this.trailingChild,
    this.iconBackground,
    this.onTap,
  });

  final Widget iconContent;
  final String title;
  final String? subtitle;
  final String? trailingValue;
  final Widget? trailingChild;
  final Color? iconBackground;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    Widget? trailing;
    if (trailingChild != null) {
      trailing = trailingChild;
    } else if (trailingValue != null || onTap != null) {
      trailing = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailingValue != null) ...[
            Text(
              trailingValue!,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 6),
          ],
          if (onTap != null) const _RowChevron(),
        ],
      );
    }

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      minVerticalPadding: 12,
      leading: DecoratedBox(
        decoration: stickerCircleDecoration(
          fill: iconBackground ?? colorScheme.primary,
          borderWidth: 2.5,
        ),
        child: SizedBox(width: 36, height: 36, child: Center(child: iconContent)),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 13.5,
          color: colorScheme.onSurface,
        ),
      ),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 11.5,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
      trailing: trailing,
      onTap: onTap,
    );
  }
}

/// [StickerRowCard]'ın köşeli ">" okuyla AYNI görsel — burada [_SettingsRow]
/// gerçek `StickerRowCard` DEĞİL (tek-satır-tek-kart yerine gruplu kart
/// kullandığı için) bu yüzden aynı görsel ayrıca burada tanımlı.
class _RowChevron extends StatelessWidget {
  const _RowChevron();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(color: kStickerOutline, width: 2),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        '›',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: Theme.of(context).colorScheme.onSurface,
          height: 1,
        ),
      ),
    );
  }
}

/// "Ses Efektleri" satırının anahtarı — mockup'ın `.switch-track` (kalın
/// kontur + düz beyaz/altın dolgu), gerçek Material [Switch]'in pill/gölge
/// görünümünden BİLEREK farklı, diğer sticker kontrollerle (bkz.
/// `StickerStatusPill`) AYNI dilde.
class _StickerSwitch extends StatelessWidget {
  const _StickerSwitch({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 42,
        height: 24,
        padding: const EdgeInsets.all(1.5),
        decoration: BoxDecoration(
          color: value ? colorScheme.primary : colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: kStickerOutline, width: 2.5),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 15,
            height: 15,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLowest,
              shape: BoxShape.circle,
              border: Border.all(color: kStickerOutline, width: 2),
            ),
          ),
        ),
      ),
    );
  }
}

/// Mockup'ın "acct-btn" — dolgulu altın CTA'lardan ([stickerFilledButtonStyle])
/// FARKLI olarak açık zeminli/koyu konturlu bir ikincil buton. Gerçek
/// [OutlinedButton] olarak kalıyor (davranışsal değişiklik yok, yalnızca
/// stil).
class _AccountActionButton extends StatelessWidget {
  const _AccountActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Expanded(
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          backgroundColor: colorScheme.surfaceContainerLowest,
          foregroundColor: colorScheme.onSurface,
          side: const BorderSide(color: kStickerOutline, width: 2.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
        ),
        onPressed: onPressed,
        icon: Icon(icon, size: 17),
        label: Text(label, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}

/// "Görünüm"/"Dil" satırlarının açtığı seçim sheet'i — mockup'ın mini-telefon
/// illüstrasyonundaki `.sheet` (başlık + seçenek listesi, bkz.
/// `docs/theme_new.md` notu "4"). İki çağıran da BİREBİR aynı bu iskeleti
/// kullanır, yalnızca [children] farklıdır (Dil'de bayrak rozeti var,
/// Görünüm'de yok).
class _SettingsPickerSheet extends StatelessWidget {
  const _SettingsPickerSheet({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Baloo2',
                fontVariations: [FontVariation('wght', 800)],
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) Container(height: 2, color: colorScheme.outlineVariant),
              children[i],
            ],
          ],
        ),
      ),
    );
  }
}

/// [_SettingsPickerSheet] içindeki tek bir seçenek satırı — düz metin +
/// (varsa) sol rozet + seçiliyse altın ✓ (mockup'ın `.sheet-row`/
/// `.sheet-check`).
class _SheetOptionRow extends StatelessWidget {
  const _SheetOptionRow({
    required this.label,
    required this.selected,
    required this.onTap,
    this.leading,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 10)],
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
            if (selected)
              Text(
                '✓',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: colorScheme.primary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Uygulama sürümünü ("1.0.0" gibi görünen ad, derleme numarası olmadan)
/// gösteren satır — `package_info_plus` ile derleme zamanında gömülen
/// `pubspec.yaml`'daki `version:` alanını platformdan okur, elle
/// senkronize tutulan bir sabit YOK (sürüm her değiştiğinde tek bir yerde
/// — pubspec'te — güncellenmesi yeterli).
class _AppVersionRow extends StatefulWidget {
  const _AppVersionRow();

  @override
  State<_AppVersionRow> createState() => _AppVersionRowState();
}

class _AppVersionRowState extends State<_AppVersionRow> {
  String? _version;

  @override
  void initState() {
    super.initState();
    // `flutter_test` ortamında platform channel'ı yok — `NotificationService`
    // ile AYNI desen: platforma dokunan çağrı try/catch ile sarılı, hata
    // durumunda sessizce "—" göstermeye devam eder, test/widget çökmez.
    PackageInfo.fromPlatform()
        .then((info) {
          if (mounted) setState(() => _version = info.version);
        })
        .catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _SettingsRow(
      iconContent: const Text('🏷️', style: TextStyle(fontSize: 15, height: 1)),
      title: l10n.settingsVersion,
      trailingChild: Text(
        _version ?? '—',
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 12,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// GEÇİCİ: Bildirim izninin gerçekten açık olup olmadığını gösteren ve
/// gerçek zamanlama mekanizmasını (AlarmManager) saatler değil dakikalar
/// içinde test etmeyi sağlayan debug paneli — bkz. CLAUDE.md "Bildirimler"
/// bölümündeki MIUI tanısı. Bildirim sistemi gerçek cihazlarda kararlı
/// çalıştığı doğrulandıktan sonra tamamen kaldırılacak.
class _NotificationDebugPanel extends StatefulWidget {
  const _NotificationDebugPanel();

  @override
  State<_NotificationDebugPanel> createState() =>
      _NotificationDebugPanelState();
}

class _NotificationDebugPanelState extends State<_NotificationDebugPanel> {
  bool? _hasPermission;
  String? _lastActionMessage;

  @override
  void initState() {
    super.initState();
    _refreshPermission();
  }

  Future<void> _refreshPermission() async {
    final granted = await context.read<NotificationProvider>().hasPermission();
    if (mounted) setState(() => _hasPermission = granted);
  }

  Future<void> _showNow() async {
    await context.read<NotificationProvider>().showTestNotificationNow();
    if (mounted) {
      setState(
        () => _lastActionMessage =
            'Hemen gönderildi — bildirim çubuğunu kontrol et.',
      );
    }
  }

  Future<void> _scheduleIn5Seconds() async {
    await context.read<NotificationProvider>().scheduleTestNotificationIn(
      const Duration(seconds: 5),
    );
    if (mounted) {
      setState(
        () => _lastActionMessage =
            '5 saniye sonra gelecek şekilde planlandı (üretimdeki AlarmManager '
            'mekanizmasıyla aynı) — uygulamayı arka plana at ve bekle.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bildirim Test Paneli (geçici)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  _hasPermission == true
                      ? Icons.check_circle_outline
                      : Icons.cancel_outlined,
                  color: _hasPermission == true
                      ? colorScheme.primary
                      : colorScheme.error,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _hasPermission == null
                        ? 'Bildirim izni kontrol ediliyor...'
                        : _hasPermission!
                        ? 'Bildirim izni: Verildi'
                        : 'Bildirim izni: Verilmedi',
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Durumu yenile',
                  onPressed: _refreshPermission,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  onPressed: _showNow,
                  child: const Text('Hemen Test Bildirimi Göster'),
                ),
                OutlinedButton(
                  onPressed: _scheduleIn5Seconds,
                  child: const Text('5sn Sonra Planlanmış Bildirim'),
                ),
              ],
            ),
            if (_lastActionMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                _lastActionMessage!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Bildirim sıklığı (Kapalı/Günde 1/Günde 3) ve üç sabit zaman diliminin
/// (Sabah/Öğlen/Akşam) saatini ayarlayan kart. Her değişiklik
/// [NotificationProvider] üzerinden hemen kalıcı hale gelir ve bildirimler
/// yeniden planlanır. Ayrıca, MIUI/EMUI/ColorOS gibi agresif Android
/// varyantlarının bildirim tetiklemesini engelleyebilen pil optimizasyonu/
/// otomatik başlatma kısıtlamalarını gidermek için bir "güvenilirlik"
/// bölümü içerir (bkz. CLAUDE.md "Bildirimler" bölümündeki tanı).
class _NotificationSettingsCard extends StatefulWidget {
  const _NotificationSettingsCard();

  @override
  State<_NotificationSettingsCard> createState() =>
      _NotificationSettingsCardState();
}

class _NotificationSettingsCardState extends State<_NotificationSettingsCard>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Kullanıcı pil optimizasyonu/otomatik başlatma ayarını sistem
    // ayarlarından değiştirip uygulamaya geri dönmüş olabilir.
    if (state == AppLifecycleState.resumed) {
      context.read<NotificationProvider>().refreshBatteryOptimizationStatus();
    }
  }

  Future<void> _pickTime(
    BuildContext context,
    NotificationProvider provider,
    int slotIndex,
  ) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: provider.times[slotIndex],
    );
    if (picked != null && context.mounted) {
      provider.setTime(slotIndex, picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<NotificationProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    final slotLabels = [
      l10n.notificationSlotMorning,
      l10n.notificationSlotNoon,
      l10n.notificationSlotEvening,
    ];
    final activeSlots = switch (provider.frequency) {
      NotificationFrequency.off => const <int>{},
      NotificationFrequency.once => const {NotificationProvider.onceSlotIndex},
      NotificationFrequency.thrice => const {0, 1, 2},
    };

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.notifications_outlined),
                const SizedBox(width: 12),
                Text(
                  l10n.notificationsSectionTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            SegmentedButton<NotificationFrequency>(
              segments: [
                ButtonSegment(
                  value: NotificationFrequency.off,
                  label: Text(l10n.notificationFrequencyOff),
                ),
                ButtonSegment(
                  value: NotificationFrequency.once,
                  label: Text(l10n.notificationFrequencyOnce),
                ),
                ButtonSegment(
                  value: NotificationFrequency.thrice,
                  label: Text(l10n.notificationFrequencyThrice),
                ),
              ],
              selected: {provider.frequency},
              onSelectionChanged: (selection) =>
                  context.read<NotificationProvider>().setFrequency(
                    selection.first,
                  ),
            ),
            for (var slot = 0; slot < 3; slot++)
              Opacity(
                opacity: activeSlots.contains(slot) ? 1 : 0.4,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(slotLabels[slot]),
                  trailing: TextButton(
                    onPressed: activeSlots.isEmpty
                        ? null
                        : () => _pickTime(context, provider, slot),
                    child: Text(
                      provider.times[slot].format(context),
                      style: TextStyle(color: colorScheme.primary),
                    ),
                  ),
                ),
              ),
            const Divider(height: 24),
            Text(
              l10n.notificationReliabilityTitle,
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 4),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                provider.isBatteryOptimizationIgnored
                    ? Icons.check_circle_outline
                    : Icons.battery_alert_outlined,
                color: provider.isBatteryOptimizationIgnored
                    ? colorScheme.primary
                    : colorScheme.error,
              ),
              title: Text(
                provider.isBatteryOptimizationIgnored
                    ? l10n.notificationBatteryOptimizationOk
                    : l10n.notificationBatteryOptimizationWarning,
              ),
              trailing: provider.isBatteryOptimizationIgnored
                  ? null
                  : TextButton(
                      onPressed: () => context
                          .read<NotificationProvider>()
                          .requestIgnoreBatteryOptimizations(),
                      child: Text(l10n.notificationBatteryOptimizationButton),
                    ),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.rocket_launch_outlined),
              title: Text(l10n.notificationAutostartDescription),
              trailing: TextButton(
                onPressed: () => context
                    .read<NotificationProvider>()
                    .openAutostartOrAppSettings(),
                child: Text(l10n.notificationAutostartButton),
              ),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.bedtime_outlined),
              title: Text(l10n.notificationUnusedAppsDescription),
              trailing: TextButton(
                onPressed: () => context
                    .read<NotificationProvider>()
                    .openUnusedAppsSettings(),
                child: Text(l10n.notificationUnusedAppsButton),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

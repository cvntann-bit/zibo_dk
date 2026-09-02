import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/legal_texts.dart';
import '../l10n/app_localizations.dart';
import '../providers/auth_link_provider.dart';
import '../providers/badge_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/sound_effects_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/google_link_action.dart';
import '../widgets/founder_badge_promo_card.dart';
import '../widgets/language_flag_circle.dart';
import '../widgets/rate_us_sheet.dart';
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
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.settingsCouldNotOpenLink)));
  }
}

/// Ayarlar sayfası. Başlık çubuğundaki dişli ikonundan push edilir; alt
/// gezinme çubuğunda bir sekme değildir, bu yüzden kendi Scaffold/AppBar'ını
/// (geri butonu dahil) taşır.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  /// **2026 güncellemesi** — eski koyu/açık `SwitchListTile`'ının yerini
  /// aldı (bkz. `ThemeProvider` dokümantasyonu). `_showLanguagePicker` ile
  /// BİREBİR AYNI görsel desen (sheet başlığı + `ListTile` satırları + seçili
  /// olana onay ikonu) — kullanıcı zaten bu deseni Dil satırından tanıyor.
  Future<void> _showThemeModePicker(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final themeProvider = context.read<ThemeProvider>();

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  l10n.settingsAppearance,
                  style: Theme.of(sheetContext).textTheme.titleMedium,
                ),
              ),
            ),
            for (final entry in {
              ThemeMode.light: (Icons.light_mode_outlined, l10n.settingsThemeModeLight),
              ThemeMode.dark: (Icons.dark_mode_outlined, l10n.settingsThemeModeDark),
              ThemeMode.system: (Icons.brightness_auto_outlined, l10n.settingsThemeModeSystem),
            }.entries)
              ListTile(
                leading: Icon(entry.value.$1),
                title: Text(entry.value.$2),
                trailing: themeProvider.themeMode == entry.key
                    ? Icon(Icons.check, color: Theme.of(sheetContext).colorScheme.primary)
                    : null,
                onTap: () {
                  themeProvider.setThemeMode(entry.key);
                  Navigator.of(sheetContext).pop();
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _showLanguagePicker(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final localeProvider = context.read<LocaleProvider>();

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  l10n.settingsLanguage,
                  style: Theme.of(sheetContext).textTheme.titleMedium,
                ),
              ),
            ),
            for (final code in supportedLanguageCodes)
              ListTile(
                leading: LanguageFlagCircle(languageCode: code, size: 30),
                title: Text(languageAutonym(code)),
                trailing: localeProvider.locale.languageCode == code
                    ? Icon(
                        Icons.check,
                        color: Theme.of(sheetContext).colorScheme.primary,
                      )
                    : null,
                onTap: () {
                  localeProvider.setLocale(Locale(code));
                  Navigator.of(sheetContext).pop();
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
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
    final themeMode = context.watch<ThemeProvider>().themeMode;
    final soundEffectsEnabled = context.watch<SoundEffectsProvider>().enabled;
    final currentLanguageCode = context.watch<LocaleProvider>().locale.languageCode;
    final authLink = context.watch<AuthLinkProvider>();
    final sectionTitleStyle = Theme.of(context).textTheme.labelLarge?.copyWith(
      color: Theme.of(context).colorScheme.primary,
      fontWeight: FontWeight.bold,
      letterSpacing: 0.2,
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.tabSettings)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        children: [
          // --- Genel: koyu tema + dil + (varsa) bildirimler — kullanıcının
          // uygulama genelinde nasıl davrandığını belirlediği tercihler.
          Text(l10n.settingsSectionGeneral, style: sectionTitleStyle),
          const SizedBox(height: 8),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.brightness_6_outlined),
                  title: Text(l10n.settingsAppearance),
                  subtitle: Text(_themeModeLabel(l10n, themeMode)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showThemeModePicker(context),
                ),
                const Divider(height: 1),
                // 2026 yeni özellik — uygulama içi kısa ses efektlerini
                // (şimdilik yalnızca Zibo dokunma sesi, bkz.
                // SoundEffectsService) açıp kapatır.
                SwitchListTile(
                  secondary: const Icon(Icons.volume_up_outlined),
                  title: Text(l10n.settingsSoundEffects),
                  value: soundEffectsEnabled,
                  onChanged: (value) =>
                      context.read<SoundEffectsProvider>().setEnabled(value),
                ),
                const Divider(height: 1),
                // Dil satırı: seçili dilin küçük yuvarlak bayrağı trailing'de
                // görünür, dokununca üç dilli (TR/EN/ES) bir seçim sheet'i
                // açılır (bkz. LocaleProvider).
                ListTile(
                  leading: const Icon(Icons.language_outlined),
                  title: Text(l10n.settingsLanguage),
                  subtitle: Text(languageAutonym(currentLanguageCode)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      LanguageFlagCircle(languageCode: currentLanguageCode),
                      const SizedBox(width: 6),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                  onTap: () => _showLanguagePicker(context),
                ),
                const Divider(height: 1),
                // 2026 yeni özellik — sekiz modülün ana ekran widget'larını
                // (bkz. CLAUDE.md "Ana Ekran Widget'ları" bölümü) listeleyen
                // ayrı bir ekrana götürür.
                ListTile(
                  leading: const Icon(Icons.widgets_outlined),
                  title: Text(l10n.widgetsScreenTitle),
                  subtitle: Text(l10n.settingsWidgetsRowSubtitle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const WidgetsScreen()),
                  ),
                ),
                const Divider(height: 1),
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
                ListTile(
                  // Bağlıyken bağlı hesabın kendi Google logosuyla (SVG,
                  // kullanıcının sağladığı `Google__G__logo.svg`) gösterilir
                  // — bağlı DEĞİLKEN jenerik "link" ikonuna geri düşülür
                  // (logo yalnızca GERÇEKTEN bağlı bir hesabı temsil etmeli).
                  leading: authLink.isLinked
                      ? SvgPicture.asset(
                          'assets/images/Google__G__logo.svg',
                          width: 24,
                          height: 24,
                        )
                      : const Icon(Icons.link_rounded),
                  title: Text(
                    authLink.isLinked
                        ? l10n.googleLinkRowTitleLinked
                        : l10n.googleLinkRowTitleUnlinked,
                  ),
                  subtitle: Text(
                    authLink.isLinked
                        ? (authLink.linkedEmail ?? '')
                        : l10n.googleLinkRowSubtitle,
                  ),
                  trailing: const Icon(Icons.chevron_right),
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
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
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
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => handleSignOutTap(context),
                                  icon: const Icon(Icons.logout_rounded, size: 18),
                                  label: Text(
                                    l10n.googleSignOutButton,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () =>
                                      handleSwitchAccountTap(context),
                                  icon: const Icon(
                                    Icons.swap_horiz_rounded,
                                    size: 18,
                                  ),
                                  label: Text(
                                    l10n.googleSwitchAccountButton,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                ],
              ],
            ),
          ),
          if (notificationsFeatureEnabled) ...[
            const SizedBox(height: 12),
            const _NotificationSettingsCard(),
          ],

          // --- Destek: kullanıcının bir sorun/soru için bize ulaşabileceği
          // kanal.
          const SizedBox(height: 24),
          Text(l10n.settingsSectionSupport, style: sectionTitleStyle),
          const SizedBox(height: 8),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.mail_outline),
                  title: Text(l10n.settingsContactUs),
                  subtitle: const Text(_contactEmail),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _launchOrShowError(
                    context,
                    Uri(scheme: 'mailto', path: _contactEmail),
                  ),
                ),
                const Divider(height: 1),
                // 2026 yeni özellik — test geri bildirim raporunun "Uygulama
                // İçi Puanlama İstemi" önerisine karşılık; düz bir metin
                // yerine Zibo görseli + 5 yıldızlık dokunmatik seçim
                // (bkz. `rate_us_sheet.dart`).
                ListTile(
                  leading: const Icon(Icons.star_outline_rounded),
                  title: Text(l10n.settingsRateUs),
                  subtitle: Text(l10n.settingsRateUsSubtitle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => showRateUsSheet(context),
                ),
              ],
            ),
          ),

          // --- Hakkında: sürüm bilgisi + hukuki/kurumsal linkler.
          const SizedBox(height: 24),
          Text(l10n.settingsAbout, style: sectionTitleStyle),
          const SizedBox(height: 8),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                const _AppVersionRow(),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.public),
                  title: Text(l10n.settingsWebsite),
                  subtitle: const Text(_websiteHost),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _launchOrShowError(
                    context,
                    Uri.https(_websiteHost),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: Text(l10n.settingsPrivacyPolicy),
                  trailing: const Icon(Icons.chevron_right),
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
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: Text(l10n.settingsTermsOfService),
                  trailing: const Icon(Icons.chevron_right),
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
          ),

          if (notificationsFeatureEnabled) ...[
            const SizedBox(height: 24),
            const _NotificationDebugPanel(),
          ],

          // GEÇİCİ: rastgele bir rozet kazandırıp gerçek kazanma akışını
          // (konfeti + kutlama popup'ı) test etmeyi sağlıyor — bkz.
          // CLAUDE.md "Rozet Sistemi" bölümü. `_CoinTestPanel`'in AYNI
          // deseni (açıkça "geçici" işaretli, izole widget, kolayca
          // kaldırılabilir); rozet sistemi gerçek cihazda doğrulandıktan
          // sonra tamamen kaldırılacak.
          const SizedBox(height: 24),
          const _BadgeTestPanel(),
        ],
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
    return ListTile(
      leading: const Icon(Icons.tag_outlined),
      title: Text(l10n.settingsVersion),
      trailing: Text(
        _version ?? '—',
        style: Theme.of(context).textTheme.bodyMedium,
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

/// GEÇİCİ: rastgele bir rozet kazandırıp gerçek kazanma akışını (kutlama
/// popup'ı + uygulama genelindeki konfeti animasyonu) hızlıca test etmeyi
/// sağlayan debug düğmesi — bkz. CLAUDE.md "Rozet Sistemi" bölümü. Rozet
/// sistemi gerçek cihazda doğrulandıktan sonra tamamen kaldırılacak.
class _BadgeTestPanel extends StatelessWidget {
  const _BadgeTestPanel();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rozet Test Paneli (geçici)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Rastgele, henüz kazanılmamış bir rozeti kazandırır — gerçek '
              "kazanma akışıyla (konfeti + kutlama popup'ı) birebir aynı.",
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () {
                final badge = context
                    .read<BadgeProvider>()
                    .debugGrantRandomBadge();
                if (badge == null) {
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      const SnackBar(
                        content: Text('Tüm rozetler zaten kazanılmış.'),
                      ),
                    );
                }
              },
              child: const Text('Rastgele Rozet Kazan'),
            ),
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

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/locale_provider.dart';
import '../../providers/onboarding_provider.dart';
import '../../providers/profile_provider.dart';
import '../../services/notification_service.dart';
import '../../services/onboarding_analytics.dart';
import '../../services/push_permission_preference.dart';
import '../../widgets/language_flag_circle.dart';
import 'intro_flow_screen.dart';

/// Uygulamanın İLK açılışında gösterilen tanıtım akışı (bkz. docs/onboarding_story.md): **dil seçimi** →
/// tam ekran Zibo akışı ([IntroFlowScreen]: hikâye → isim → bildirim izni → final). Bitince girilen isim
/// Profil'e + hitap tercihine yazılır ve `OnboardingProvider.completeOnboarding()` çağrılır. Yalnızca
/// `OnboardingProvider.isCompleted == false` iken gösterilir (bkz. main.dart `_AppStartupGate`) — mevcut
/// kullanıcılar bu akışı GÖRMEZ. (2026-10: eski 8 modül tanıtım sayfası kaldırıldı; öğretici Ana Sayfa
/// ipuçlarına taşınacak.)
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, this.requestNotificationPermission});

  /// Bildirim izninin GERÇEK isteği (Android 13+ sistem penceresi). `null` ise `LocalNotificationService`
  /// kullanılır (platform kanalı try/catch'li — kullanılamazsa `false`). Test enjeksiyonu için.
  final Future<bool> Function()? requestNotificationPermission;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  Locale? _selectedLocale;
  bool _starting = false;

  void _selectLanguage(Locale locale) {
    setState(() => _selectedLocale = locale);
    // Seçimle ANINDA uygula — hikâye ve sonraki adımlar yeni dilde görünsün diye "Devam Et"e basmayı
    // beklemiyoruz.
    context.read<LocaleProvider>().setLocale(locale);
  }

  Future<bool> _askNotificationPermission() =>
      widget.requestNotificationPermission?.call() ??
      LocalNotificationService().requestPermission();

  Future<void> _start() async {
    if (_selectedLocale == null || _starting) return;
    setState(() => _starting = true);
    final result = await Navigator.of(context).push<IntroResult>(
      MaterialPageRoute<IntroResult>(
        builder: (_) => IntroFlowScreen(
          requestNotificationPermission: _askNotificationPermission,
        ),
      ),
    );
    if (!mounted) return;
    setState(() => _starting = false);
    // Geri tuşuyla çıkıldıysa dil sayfasında kal (isim zorunlu).
    if (result == null) return;
    final profile = context.read<ProfileProvider>();
    profile.setName(result.name);
    // Girilen isim, hitap tercihine de VARSAYILAN olarak yazılır (sonra Profil > Hitap Tercihi'nden değişir).
    profile.setAddressTerm(result.name);
    // "Şimdi Değil"/reddedilen izin: açılıştaki FCM izin isteği bu seçime saygı göstersin (bkz. PushNotificationService).
    await PushPermissionPreference.setDeclined(!result.notificationsGranted);
    OnboardingAnalytics.log('onboarding_completed', {
      'notif': result.notificationsGranted ? 1 : 0,
    });
    if (!mounted) return;
    context.read<OnboardingProvider>().completeOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _LanguageStep(
                selected: _selectedLocale,
                onSelect: _selectLanguage,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: (_selectedLocale == null || _starting)
                      ? null
                      : _start,
                  child: Text(l10n.onboardingContinueButton),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageStep extends StatelessWidget {
  const _LanguageStep({required this.selected, required this.onSelect});

  final Locale? selected;
  final ValueChanged<Locale> onSelect;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('assets/images/zibo_logo_new.webp', height: 56),
          const SizedBox(height: 32),
          Text(
            l10n.onboardingLanguageStepTitle,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.onboardingLanguageStepSubtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 28),
          for (final code in supportedLanguageCodes) ...[
            _LanguageOptionCard(
              code: code,
              isSelected: selected?.languageCode == code,
              onTap: () => onSelect(Locale(code)),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _LanguageOptionCard extends StatelessWidget {
  const _LanguageOptionCard({
    required this.code,
    required this.isSelected,
    required this.onTap,
  });

  final String code;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: isSelected
          ? colorScheme.primaryContainer
          : colorScheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              LanguageFlagCircle(languageCode: code, size: 28),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  languageAutonym(code),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: isSelected ? colorScheme.onPrimaryContainer : null,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
              if (isSelected)
                Icon(Icons.check_circle, color: colorScheme.onPrimaryContainer),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/locale_provider.dart';
import '../../providers/onboarding_provider.dart';
import '../../providers/profile_provider.dart';
import '../../widgets/language_flag_circle.dart';

class _ModuleIntro {
  const _ModuleIntro({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String Function(AppLocalizations l10n) title;
  final String Function(AppLocalizations l10n) description;
}

/// Hedef Takibi/Su Takibi/Şükran/Ruh Hali/**Rüya Günlüğü**/Manifest/Mağaza/
/// Profil — bkz. kullanıcının istediği tanıtım sırası. Başlıklar için ayrı
/// bir onboarding-özel ARB anahtarı AÇILMADI — her modülün zaten var olan
/// ekran başlığı (`l10n.tabGoalTracking`, `l10n.waterScreenTitle` vb.)
/// yeniden kullanıldı, yalnızca açıklama cümleleri onboarding'e özel yeni
/// anahtarlar. **2026 güncellemesi — Rüya Günlüğü EKLENDİ** (kullanıcı
/// isteği: her modülün "neden var olduğunu" tek cümlede netleştir; Rüya
/// Günlüğü'nü kendi örneği olarak verdi ama bu modül onboarding'de HİÇ
/// yoktu) — Ruh Hali Takibi'nin HEMEN ardına, Manifest'ten ÖNCE eklendi
/// (ikisi de "iç dünya" temalı, Feature 2'deki Rüya↔Ruh Hali korelasyonuyla
/// da tematik olarak örtüşüyor); AYNI turda 7 mevcut açıklama da kullanıcının
/// istediği "tek cümlelik, net 'bu ne işe yarıyor'" tonuna göre yeniden
/// yazıldı (bkz. ARB — eski ton "ne yap + ne kazanırsın" idi).
const _moduleIntros = <_ModuleIntro>[
  _ModuleIntro(
    icon: Icons.flag_rounded,
    title: _goalsTitle,
    description: _goalsDescription,
  ),
  _ModuleIntro(
    icon: Icons.water_drop_outlined,
    title: _waterTitle,
    description: _waterDescription,
  ),
  _ModuleIntro(
    icon: Icons.favorite_outline,
    title: _gratitudeTitle,
    description: _gratitudeDescription,
  ),
  _ModuleIntro(
    icon: Icons.mood_outlined,
    title: _moodTitle,
    description: _moodDescription,
  ),
  _ModuleIntro(
    icon: Icons.nights_stay_outlined,
    title: _dreamJournalTitle,
    description: _dreamJournalDescription,
  ),
  _ModuleIntro(
    icon: Icons.auto_awesome_outlined,
    title: _manifestTitle,
    description: _manifestDescription,
  ),
  _ModuleIntro(
    icon: Icons.storefront_rounded,
    title: _storeTitle,
    description: _storeDescription,
  ),
  _ModuleIntro(
    icon: Icons.account_circle_rounded,
    title: _profileTitle,
    description: _profileDescription,
  ),
];

String _goalsTitle(AppLocalizations l10n) => l10n.tabGoalTracking;
String _goalsDescription(AppLocalizations l10n) => l10n.onboardingGoalsDescription;
String _waterTitle(AppLocalizations l10n) => l10n.waterScreenTitle;
String _waterDescription(AppLocalizations l10n) => l10n.onboardingWaterDescription;
String _gratitudeTitle(AppLocalizations l10n) => l10n.gratitudeScreenTitle;
String _gratitudeDescription(AppLocalizations l10n) => l10n.onboardingGratitudeDescription;
String _moodTitle(AppLocalizations l10n) => l10n.moodScreenTitle;
String _moodDescription(AppLocalizations l10n) => l10n.onboardingMoodDescription;
String _dreamJournalTitle(AppLocalizations l10n) => l10n.dreamJournalTitle;
String _dreamJournalDescription(AppLocalizations l10n) =>
    l10n.onboardingDreamJournalDescription;
String _manifestTitle(AppLocalizations l10n) => l10n.manifestScreenTitle;
String _manifestDescription(AppLocalizations l10n) => l10n.onboardingManifestDescription;
String _storeTitle(AppLocalizations l10n) => l10n.storeTitle;
String _storeDescription(AppLocalizations l10n) => l10n.onboardingStoreDescription;
String _profileTitle(AppLocalizations l10n) => l10n.profileScreenTitle;
String _profileDescription(AppLocalizations l10n) => l10n.onboardingProfileDescription;

/// Uygulamanın İLK açılışında gösterilen tanıtım akışı: (a) isim sorma,
/// (b) isim otomatik olarak Profil'e VE hitap tercihine varsayılan olarak
/// yazılır, (c) ana modülleri tanıtan adım adım ekranlar, (d) Zibo'nun
/// ağzından motive edici bir kapanış mesajı. Yalnızca `OnboardingProvider.
/// isCompleted == false` iken gösterilir (bkz. main.dart `_AppStartupGate`).
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  final _nameController = TextEditingController();
  int _pageIndex = 0;
  Locale? _selectedLocale;

  // Dart'ta `List.length` const bir bağlamda kullanılamıyor (const bir
  // listede bile) — bu yüzden elle sabitlendi: 1 (dil) + 1 (isim) + 8 (modül
  // tanıtımları — 2026 güncellemesi: Rüya Günlüğü eklendi, eskiden 7'ydi) +
  // 1 (kapanış) = 11. `_moduleIntros` listesine yeni bir modül eklenirse bu
  // sayı da güncellenmeli.
  static const _totalPages = 11;
  bool get _isLanguagePage => _pageIndex == 0;
  bool get _isNamePage => _pageIndex == 1;
  bool get _isClosingPage => _pageIndex == _totalPages - 1;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _finish() {
    context.read<OnboardingProvider>().completeOnboarding();
  }

  void _selectLanguage(Locale locale) {
    setState(() => _selectedLocale = locale);
    // Seçimle ANINDA uygula — kalan onboarding adımları (modül tanıtımları,
    // kapanış mesajı) da yeni dilde görünsün diye "Devam Et"e basmayı
    // beklemiyoruz.
    context.read<LocaleProvider>().setLocale(locale);
  }

  void _goNext() {
    if (_isLanguagePage && _selectedLocale == null) return;
    if (_isNamePage) {
      final name = _nameController.text.trim();
      if (name.isEmpty) return;
      final profile = context.read<ProfileProvider>();
      profile.setName(name);
      // Kullanıcı isteği: girilen isim, hitap tercihine de VARSAYILAN
      // olarak yazılsın — istersen sonra Profil > Hitap Tercihi'nden ayrı
      // bir şeyle değiştirebilir.
      profile.setAddressTerm(name);
    }
    if (_isClosingPage) {
      _finish();
      return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 48,
              child: (_isLanguagePage || _isNamePage)
                  ? null
                  : Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _finish,
                        child: Text(l10n.onboardingSkipButton),
                      ),
                    ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) => setState(() => _pageIndex = index),
                children: [
                  _LanguageStep(selected: _selectedLocale, onSelect: _selectLanguage),
                  _NameStep(controller: _nameController),
                  for (final module in _moduleIntros)
                    _ModuleIntroStep(module: module),
                  const _ClosingStep(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < _totalPages; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: i == _pageIndex ? 20 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: i == _pageIndex
                            ? colorScheme.primary
                            : colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _nameController,
                  builder: (context, value, _) {
                    final nameEmpty = _isNamePage && value.text.trim().isEmpty;
                    final languageUnset = _isLanguagePage && _selectedLocale == null;
                    return FilledButton(
                      onPressed: (nameEmpty || languageUnset) ? null : _goNext,
                      child: Text(
                        _isClosingPage
                            ? l10n.onboardingStartButton
                            : ((_isNamePage || _isLanguagePage)
                                  ? l10n.onboardingContinueButton
                                  : l10n.onboardingNextButton),
                      ),
                    );
                  },
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
          Image.asset('assets/images/zibo_logo_new.png', height: 56),
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
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
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
      color: isSelected ? colorScheme.primaryContainer : colorScheme.surfaceContainerHigh,
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

class _NameStep extends StatelessWidget {
  const _NameStep({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('assets/images/zibo_logo_new.png', height: 56),
          const SizedBox(height: 32),
          Text(
            l10n.onboardingNameStepTitle,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.onboardingNameStepSubtitle,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 28),
          TextField(
            controller: controller,
            textAlign: TextAlign.center,
            textInputAction: TextInputAction.done,
            autofocus: true,
            style: Theme.of(context).textTheme.titleLarge,
            decoration: InputDecoration(
              hintText: l10n.profileNameHint,
              border: const OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModuleIntroStep extends StatelessWidget {
  const _ModuleIntroStep({required this.module});

  final _ModuleIntro module;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 48,
            backgroundColor: colorScheme.primaryContainer,
            foregroundColor: colorScheme.onPrimaryContainer,
            child: Icon(module.icon, size: 44),
          ),
          const SizedBox(height: 28),
          Text(
            module.title(l10n),
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Text(
            module.description(l10n),
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _ClosingStep extends StatelessWidget {
  const _ClosingStep();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final name = context.watch<ProfileProvider>().name;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('assets/images/zibo_yeni.png', height: 140),
          const SizedBox(height: 24),
          Text(
            l10n.onboardingClosingTitle,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.onboardingClosingMessage(name),
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

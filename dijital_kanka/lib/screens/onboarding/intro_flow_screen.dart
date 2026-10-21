import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../services/onboarding_analytics.dart';
import '../../widgets/zibo_bubble.dart';
import 'story_intro_screen.dart';

/// Intro akışının sonucu: kullanıcının yazdığı isim ve bildirim iznine verdiği yanıt.
class IntroResult {
  const IntroResult({required this.name, required this.notificationsGranted});

  final String name;
  final bool notificationsGranted;
}

enum _Phase { story, name, notif, finale }

/// Zibo'nun intro akışı (bkz. docs/onboarding_story.md): hikâye (5 slayt) → "Sana ne diye hitap edeyim?"
/// (isim) → "Tanıştığıma memnun oldum, X!" + bildirim izni (Zibo konuşma balonuyla ister) → "Hadi başlayalım!".
/// Hepsi TEK tam ekran rota; bitince [IntroResult] ile pop eder. Bildirim izninin GERÇEK isteği
/// [requestNotificationPermission] ile dışarıdan verilir (uygulamada `NotificationService.requestPermission`,
/// önizlemede sahte) — bu ekran platform kanalına dokunmaz.
class IntroFlowScreen extends StatefulWidget {
  const IntroFlowScreen({
    super.key,
    required this.requestNotificationPermission,
  });

  final Future<bool> Function() requestNotificationPermission;

  @override
  State<IntroFlowScreen> createState() => _IntroFlowScreenState();
}

class _IntroFlowScreenState extends State<IntroFlowScreen> {
  _Phase _phase = _Phase.story;
  final _nameController = TextEditingController();
  bool _granted = false;
  bool _asking = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _toName() => setState(() => _phase = _Phase.name);

  void _submitName() {
    if (_nameController.text.trim().isEmpty) return;
    OnboardingAnalytics.log('onboarding_name_done');
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _phase = _Phase.notif);
  }

  Future<void> _allow() async {
    if (_asking) return;
    setState(() => _asking = true);
    var granted = false;
    try {
      granted = await widget.requestNotificationPermission();
    } catch (_) {
      granted = false;
    }
    if (!mounted) return;
    OnboardingAnalytics.log('onboarding_notif_result', {
      'granted': granted ? 1 : 0,
    });
    setState(() {
      _granted = granted;
      _asking = false;
      _phase = _Phase.finale;
    });
  }

  void _later() {
    OnboardingAnalytics.log('onboarding_notif_result', {'granted': 0});
    setState(() {
      _granted = false;
      _phase = _Phase.finale;
    });
  }

  void _finish() {
    Navigator.of(context).pop(
      IntroResult(
        name: _nameController.text.trim(),
        notificationsGranted: _granted,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_phase == _Phase.story) {
      return StorySlides(onFinished: _toName, onSkip: _toName);
    }
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    final name = _nameController.text.trim();

    final (String zibo, Widget bubble, Widget actions) = switch (_phase) {
      _Phase.name => (
        'assets/images/zibo_df_pose3.webp',
        ZiboBubble(text: l10n.onboardingNameBubble),
        _NameActions(
          controller: _nameController,
          hint: l10n.profileNameHint,
          label: l10n.onboardingContinueButton,
          onSubmit: _submitName,
        ),
      ),
      _Phase.notif => (
        'assets/images/zibo_df_pose1.webp',
        ZiboBubble(
          title: l10n.onboardingMeetTitle(name),
          text: l10n.onboardingNotifBody,
        ),
        Column(
          children: [
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                key: const Key('introNotifAllow'),
                onPressed: _asking ? null : _allow,
                child: Text(l10n.onboardingNotifAllow),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              key: const Key('introNotifLater'),
              onPressed: _asking ? null : _later,
              child: Text(l10n.onboardingNotifLater),
            ),
          ],
        ),
      ),
      _ => (
        'assets/images/zibo_df_pose4.webp',
        ZiboBubble(
          text: _granted
              ? l10n.onboardingFinaleAllowed
              : l10n.onboardingFinaleDeclined,
        ),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton(
            key: const Key('introFinish'),
            onPressed: _finish,
            child: Text(l10n.onboardingStartButton),
          ),
        ),
      ),
    };

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, c) => SingleChildScrollView(
            key: ValueKey(_phase), // adım değişince kaydırma konumu sıfırlansın
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: c.maxHeight),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      child: Image.asset(
                        zibo,
                        key: ValueKey(zibo),
                        // Küçük ekranlarda Zibo kırpılmasın: yüksekliğe göre ölçekle (klavye açıkken küçük).
                        height: keyboardOpen
                            ? 140
                            : (c.maxHeight * 0.34).clamp(150.0, 300.0),
                      ),
                    ),
                    const SizedBox(height: 20),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      child: KeyedSubtree(key: ValueKey(_phase), child: bubble),
                    ),
                    const SizedBox(height: 24),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      child: KeyedSubtree(
                        key: ValueKey('a$_phase'),
                        child: actions,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NameActions extends StatelessWidget {
  const _NameActions({
    required this.controller,
    required this.hint,
    required this.label,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final String hint;
  final String label;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          key: const Key('introNameField'),
          controller: controller,
          autofocus: true,
          maxLength: 24,
          textAlign: TextAlign.center,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => onSubmit(),
          style: Theme.of(context).textTheme.titleLarge,
          decoration: InputDecoration(
            hintText: hint,
            counterText: '',
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (context, value, _) => SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              key: const Key('introNameContinue'),
              onPressed: value.text.trim().isEmpty ? null : onSubmit,
              child: Text(label),
            ),
          ),
        ),
      ],
    );
  }
}

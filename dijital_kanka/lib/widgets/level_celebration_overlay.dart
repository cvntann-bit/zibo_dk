import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/sound_effects_provider.dart';
import '../services/sound_effects_service.dart';
import '../utils/level_up_signal.dart';
import 'goal_confetti_burst.dart';

/// Bir kullanıcı seviye atladığında uygulamanın HER YERİNDE (hangi ekranda
/// olursa olsun) konfeti + kutlama kartı gösteren, `MaterialApp.builder`
/// SEVİYESİNDE (`BadgeCelebrationOverlay` ile AYNI konum — bkz. `main.dart`)
/// mount edilen global bir overlay — bkz. CLAUDE.md "Level/XP Sistemi"
/// bölümü.
///
/// **`home:` İÇİNE DEĞİL, `builder:` seviyesine yerleştirilmesinin nedeni**
/// `BadgeCelebrationOverlay`'deki AYNI gerekçe: `home:` içindeki içerik başka
/// bir rota push edilince artık boyanmıyor, "HER YERDE" görünürlük yalnızca
/// bu seviyede garanti edilebiliyor. Aynı kısıtlama nedeniyle bu seviyenin
/// `context`'i Navigator'ın ATASI DEĞİL — "Paylaş" butonu bu yüzden doğrudan
/// `showModalBottomSheet` ÇAĞIRMIYOR, `pendingLevelShareMessage` sinyaliyle
/// `RootScreen`'e (Navigator'ın altındaki bir context'e) devrediyor (bkz. o
/// sinyalin dokümantasyonu).
class LevelCelebrationOverlay extends StatefulWidget {
  const LevelCelebrationOverlay({
    super.key,
    required this.child,
    this.soundEffectsService,
  });

  final Widget child;

  /// Testte gerçek `audioplayers` platform kanalına dokunmadan sahte bir
  /// implementasyon enjekte edebilmek için — `BadgeCelebrationOverlay` ile
  /// AYNI desen. `null` ise gerçek `AudioPlayersSoundEffectsService()`
  /// kullanılır.
  final SoundEffectsService? soundEffectsService;

  @override
  State<LevelCelebrationOverlay> createState() =>
      _LevelCelebrationOverlayState();
}

class _LevelCelebrationOverlayState extends State<LevelCelebrationOverlay>
    with SingleTickerProviderStateMixin {
  // `late final` alan başlatıcısı YERİNE `initState()`'te KOŞULSUZ, erkenden
  // oluşturuluyor — `BadgeCelebrationOverlay`'deki AYNI dokümante edilmiş
  // gotcha (bir seviye atlama HİÇ gerçekleşmeden bu widget dispose edilirse,
  // `late final`'in tembel başlatıcısı ilk erişimi `dispose()`'a denk
  // getirip "Looking up a deactivated widget's ancestor is unsafe" hatasıyla
  // çökerdi).
  late final AnimationController _confettiController;

  late final SoundEffectsService _soundEffectsService =
      widget.soundEffectsService ?? AudioPlayersSoundEffectsService();

  int? _level;

  @override
  void initState() {
    super.initState();
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    pendingLevelUp.addListener(_onPendingLevelChanged);
  }

  void _onPendingLevelChanged() {
    final level = pendingLevelUp.value;
    if (level == null) return;
    setState(() => _level = level);
    _confettiController.forward(from: 0);
    if (mounted && context.read<SoundEffectsProvider>().enabled) {
      _soundEffectsService.playBadgeWin();
    }
  }

  @override
  void dispose() {
    pendingLevelUp.removeListener(_onPendingLevelChanged);
    _confettiController.dispose();
    _soundEffectsService.dispose();
    super.dispose();
  }

  void _dismiss() {
    setState(() => _level = null);
    pendingLevelUp.value = null;
  }

  void _share() {
    final level = _level;
    if (level == null) return;
    final l10n = AppLocalizations.of(context)!;
    final message = l10n.levelUpShareMessage(level);
    _dismiss();
    pendingLevelShareMessage.value = message;
  }

  @override
  Widget build(BuildContext context) {
    final level = _level;
    return Stack(
      children: [
        widget.child,
        if (level != null) ...[
          Positioned.fill(
            child: IgnorePointer(
              child: GoalConfettiBurst(progress: _confettiController),
            ),
          ),
          Positioned.fill(
            child: ModalBarrier(
              dismissible: false,
              color: Theme.of(
                context,
              ).colorScheme.scrim.withValues(alpha: 0.55),
            ),
          ),
          Align(
            alignment: const Alignment(0, -0.45),
            child: _LevelUpCard(
              level: level,
              onShare: _share,
              onClose: _dismiss,
            ),
          ),
        ],
      ],
    );
  }
}

class _LevelUpCard extends StatelessWidget {
  const _LevelUpCard({
    required this.level,
    required this.onShare,
    required this.onClose,
  });

  final int level;
  final VoidCallback onShare;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Material(
        color: colorScheme.surface,
        elevation: 8,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/images/zibo_yeni.webp', width: 132, height: 132),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  l10n.levelUpCelebrationTitle(level),
                  textAlign: TextAlign.center,
                  style: textTheme.titleLarge?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                l10n.levelUpCelebrationBody,
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      key: const Key('levelUpCloseButton'),
                      onPressed: onClose,
                      child: Text(l10n.levelUpCloseButton),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: onShare,
                      icon: const Icon(Icons.ios_share),
                      label: Text(l10n.levelUpShareButton),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

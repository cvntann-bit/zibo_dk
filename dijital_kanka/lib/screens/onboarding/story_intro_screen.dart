import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../services/onboarding_analytics.dart';
import '../../widgets/zibo_bubble.dart';

/// Zibo'nun intro hikâyesi (bkz. docs/onboarding_story.md): 5 slayt, tam ekran, DOKUNARAK ilerler.
/// S1 dağınık/soluk oda (A) → S2 ara sahne (A karartılmış, metin ortada) → S3 aynı oda ama Zibo parlıyor (B)
/// → S4 güneşli, düzenli oda (C) → S5 yalnızca Zibo. A/B/C aynı kadraj olduğu için aralarındaki geçiş
/// çapraz solma (crossfade). "Geç" her slaytta var. Bittiğinde / atlandığında `Navigator.pop` → onboarding
/// isim adımına geçer.
class StoryIntroScreen extends StatelessWidget {
  const StoryIntroScreen({super.key});

  @override
  Widget build(BuildContext context) => StorySlides(
    onFinished: () => Navigator.of(context).pop(),
    onSkip: () => Navigator.of(context).pop(),
  );
}

/// Hikâye slaytlarının kendisi (tam ekran Scaffold) — [StoryIntroScreen] rotası ve [IntroFlowScreen]
/// (hikâye → isim → bildirim izni) bunu kullanır. Bitince [onFinished], "Geç" ile [onSkip] çağrılır.
class StorySlides extends StatefulWidget {
  const StorySlides({
    super.key,
    required this.onFinished,
    required this.onSkip,
  });

  final VoidCallback onFinished;
  final VoidCallback onSkip;

  @override
  State<StorySlides> createState() => _StorySlidesState();
}

class _StorySlidesState extends State<StorySlides> {
  static const _slideCount = 5;
  static const _fade = Duration(milliseconds: 900);
  static const _roomA = 'assets/images/onboarding/story_a.webp';
  static const _roomB = 'assets/images/onboarding/story_b.webp';
  static const _roomC = 'assets/images/onboarding/story_c.webp';
  static const _zibo = 'assets/images/zibo_df_pose2.webp';

  int _index = 0;
  bool _imagesPrecached = false;

  @override
  void initState() {
    super.initState();
    OnboardingAnalytics.log('onboarding_story_step', {'step': 0});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_imagesPrecached) return;
    _imagesPrecached = true;
    // Geçişlerde kasma/boş kare olmasın diye üç oda görselini baştan belleğe al.
    for (final asset in const [_roomA, _roomB, _roomC, _zibo]) {
      precacheImage(AssetImage(asset), context);
    }
  }

  void _next() {
    if (_index >= _slideCount - 1) {
      OnboardingAnalytics.log('onboarding_story_done');
      widget.onFinished();
      return;
    }
    setState(() => _index++);
    OnboardingAnalytics.log('onboarding_story_step', {'step': _index});
  }

  void _skip() {
    OnboardingAnalytics.log('onboarding_story_skipped', {'step': _index});
    widget.onSkip();
  }

  String _text(AppLocalizations l10n) => switch (_index) {
    0 => l10n.onboardingStory1,
    1 => l10n.onboardingStory2,
    2 => l10n.onboardingStory3,
    3 => l10n.onboardingStory4,
    _ => l10n.onboardingStory5,
  };

  Widget _layer(String asset, {required bool visible}) => AnimatedOpacity(
    duration: _fade,
    curve: Curves.easeInOut,
    opacity: visible ? 1 : 0,
    child: SizedBox.expand(
      child: Image.asset(
        asset,
        fit: BoxFit.cover,
        alignment: Alignment.center,
        gaplessPlayback: true,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final text = _text(l10n);
    final isInterlude = _index == 1;
    final isFinal = _index == _slideCount - 1;

    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        body: GestureDetector(
          key: const Key('storyStage'),
          behavior: HitTestBehavior.opaque,
          onTap: _next,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Son slayt: oda yok, düz zemin + Zibo.
              AnimatedOpacity(
                duration: _fade,
                opacity: isFinal ? 1 : 0,
                child: Container(
                  color: colorScheme.surface,
                  alignment: const Alignment(0, -0.25),
                  child: Image.asset(_zibo, height: 360),
                ),
              ),
              _layer(_roomC, visible: _index == 3),
              _layer(_roomB, visible: _index == 2),
              _layer(_roomA, visible: _index <= 1),
              // S2 ara sahne: odayı karart, metin ortada.
              AnimatedOpacity(
                duration: _fade,
                opacity: isInterlude ? 1 : 0,
                child: Container(color: Colors.black.withValues(alpha: 0.72)),
              ),
              SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
                      child: Row(
                        children: [
                          const SizedBox(width: 64),
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                for (var i = 0; i < _slideCount; i++)
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 250),
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 3,
                                    ),
                                    width: i == _index ? 20 : 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: i == _index
                                          ? (isFinal
                                                ? colorScheme.primary
                                                : Colors.white)
                                          : (isFinal
                                                ? colorScheme.outlineVariant
                                                : Colors.white54),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: 64,
                            child: TextButton(
                              key: const Key('storySkip'),
                              onPressed: _skip,
                              style: TextButton.styleFrom(
                                foregroundColor: isFinal
                                    ? colorScheme.primary
                                    : Colors.white,
                                padding: EdgeInsets.zero,
                              ),
                              child: Text(l10n.onboardingSkipButton),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: isInterlude
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 36,
                                ),
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 500),
                                  child: Text(
                                    text,
                                    key: ValueKey('story$_index'),
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          height: 1.35,
                                        ),
                                  ),
                                ),
                              ),
                            )
                          : Align(
                              alignment: Alignment.bottomCenter,
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  0,
                                  20,
                                  28,
                                ),
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 500),
                                  child: ZiboBubble(
                                    key: ValueKey('story$_index'),
                                    text: text,
                                    hint: _index == 0
                                        ? l10n.onboardingStoryTapHint
                                        : null,
                                  ),
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

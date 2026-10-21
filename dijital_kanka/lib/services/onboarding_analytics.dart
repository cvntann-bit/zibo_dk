import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// İntro/onboarding adım olayları (2026-10, bkz. docs/onboarding_story.md): ilk açılışta hangi
/// adımda kaç kişi kalıyor/atlıyor → retention çalışması için ÖLÇÜLEN veri.
///
/// Olaylar: `onboarding_story_step` {step: 0..4} — hikâye slaytı gösterildi · `onboarding_story_skipped`
/// {step} — "Geç" ile hikâye atlandı (step = atlanan slayt) · `onboarding_story_done` — 5 slayt bitti ·
/// `onboarding_name_done` — isim girildi · `onboarding_completed` — uygulamaya girildi.
///
/// Firebase başlatılmamışsa (testler, web önizlemesi) hiçbir şey yapmaz; analitik ASLA akışı bozmaz.
class OnboardingAnalytics {
  const OnboardingAnalytics._();

  static void log(String name, [Map<String, Object> params = const {}]) {
    if (Firebase.apps.isEmpty) return;
    unawaited(
      FirebaseAnalytics.instance
          .logEvent(name: name, parameters: params)
          .catchError((Object e) {
            debugPrint('OnboardingAnalytics $name gönderilemedi: $e');
          }),
    );
  }
}

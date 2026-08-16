// OnboardingProvider'ın tamamlanma durumunu ve kalıcılığını doğrudan
// (widget pump'lamadan) test eder.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dijital_kanka/providers/onboarding_provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('Yeni provider tamamlanmamış olarak başlar', () async {
    final provider = OnboardingProvider();
    await Future<void>.delayed(Duration.zero);

    expect(provider.isCompleted, isFalse);
  });

  test('completeOnboarding tamamlandı olarak işaretler ve kalıcı olur', () async {
    final provider = OnboardingProvider();
    await Future<void>.delayed(Duration.zero);

    await provider.completeOnboarding();
    expect(provider.isCompleted, isTrue);

    final reloaded = OnboardingProvider();
    await Future<void>.delayed(Duration.zero);
    expect(reloaded.isCompleted, isTrue);
  });
}

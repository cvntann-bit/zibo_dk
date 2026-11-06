// Tablet eşikleri (docs/tablet_optimization.md): yan menü Google'ın Expanded
// sınıfında (≥ 840 dp) açılır; iki bölmeli Ana Sayfa 1000 dp'de kalır.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dijital_kanka/utils/adaptive.dart';

void main() {
  Future<bool> sideNavAt(WidgetTester tester, double width) async {
    late bool result;
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(size: Size(width, 1200)),
        child: Builder(
          builder: (context) {
            result = Adaptive.useSideNav(context);
            return const SizedBox();
          },
        ),
      ),
    );
    return result;
  }

  testWidgets('yan menü 840 dp ve üstünde açılır', (tester) async {
    expect(await sideNavAt(tester, 412), isFalse);
    expect(await sideNavAt(tester, 800), isFalse);
    expect(await sideNavAt(tester, 839), isFalse);
    expect(await sideNavAt(tester, 840), isTrue);
    expect(await sideNavAt(tester, 1280), isTrue);
    expect(Adaptive.homeTwoPaneMinWidth, greaterThan(Adaptive.sideNavMinWidth));
  });
}

// CustomMessagesScreen'in ekleme akışını GERÇEK widget ağacıyla (provider
// testinden FARKLI olarak) test eder — Faz 6 KRİTİK bug düzeltmesinin
// regresyon testi. Kök neden: diyalogdaki `TextField`in `autofocus: true`
// ile aldığı odağı diyalog kapanırken kaybetmesi bir `FocusManager`
// mikrogörevi zamanlıyordu (`EditableTextState._handleFocusChanged` →
// `controller.clearComposing()`); `_showAddDialog`'un `finally` bloğu
// `controller.dispose()`'u HEMEN/SENKRON çağırdığı için bu mikrogörev
// SONRA çalışıp "TextEditingController was used after being disposed"
// fırlatıyordu — bu da widget ağacını yarım güncellenmiş bırakıp
// SONRAKİ herhangi bir etkileşimde (`_dependents.isEmpty`/"Duplicate
// GlobalKeys" gibi) İKİNCİL assertion'lara yol açıyordu. Yalnızca
// `CustomMessagesProvider`'ı doğrudan (widget pump'lamadan) test eden
// `custom_messages_provider_test.dart` bu GERÇEK dialog/focus/dispose
// yarışını hiç egzersiz etmiyordu.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dijital_kanka/l10n/app_localizations.dart';
import 'package:dijital_kanka/providers/custom_messages_provider.dart';
import 'package:dijital_kanka/screens/custom_messages_screen.dart';

Widget _buildTestApp() {
  return MultiProvider(
    providers: [ChangeNotifierProvider(create: (_) => CustomMessagesProvider())],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: const Locale('tr'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: const CustomMessagesScreen(),
    ),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
    'Yeni mesaj eklemek (diyalog açılıp kapanması) HİÇBİR assertion '
    'fırlatmadan tamamlanır ve mesaj listeye eklenir',
    (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Yeni Mesaj Ekle'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Yeni özel mesajım');
      await tester.pump();

      await tester.tap(find.text('Kaydet'));
      // Diyalogun kapanış animasyonu + `finally` bloğunun ertelenmiş
      // `controller.dispose()`'u için birkaç açık pump — asıl regresyon
      // TAM BU noktada (dialog pop + odak kaybı mikrogörevi + dispose
      // arasındaki yarışta) tetikleniyordu.
      await tester.pump();
      await tester.pump();
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Yeni özel mesajım'), findsOneWidget);

      final provider = Provider.of<CustomMessagesProvider>(
        tester.element(find.byType(CustomMessagesScreen)),
        listen: false,
      );
      expect(provider.messages, ['Yeni özel mesajım']);
    },
  );
}

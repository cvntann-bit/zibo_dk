// YALNIZCA ÖNİZLEME: Zibo intro akışını (hikâye → isim → bildirim izni → final, bkz. docs/onboarding_story.md)
// uygulamanın onboarding'ine BAĞLAMADAN tarayıcıda göstermek için ayrı giriş noktası. Normal `main.dart`'ı etkilemiyor.
// Bildirim izni burada SAHTE (Android sistem penceresini taklit eden bir diyalog) — gerçek izin istenmez.
// Çalıştırma: flutter run -d web-server --web-port 8791 -t lib/story_preview_main.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'l10n/app_localizations.dart';
import 'screens/onboarding/intro_flow_screen.dart';

void main() => runApp(const _PreviewApp());

class _PreviewApp extends StatefulWidget {
  const _PreviewApp();

  @override
  State<_PreviewApp> createState() => _PreviewAppState();
}

class _PreviewAppState extends State<_PreviewApp> {
  Locale _locale = const Locale('tr');

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: const Color(0xFFF2B33D)),
      locale: _locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: _Host(
        locale: _locale,
        onLocale: (l) => setState(() => _locale = l),
      ),
    );
  }
}

class _Host extends StatefulWidget {
  const _Host({required this.locale, required this.onLocale});

  final Locale locale;
  final ValueChanged<Locale> onLocale;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  IntroResult? _result;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _play());
  }

  /// Android 13+ "bildirim göndermesine izin verilsin mi?" sistem penceresini taklit eder (yalnızca önizleme).
  Future<bool> _fakeSystemPermission() async {
    final allow = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text(
          'Zibo uygulamasının sana bildirim göndermesine izin verilsin mi?',
        ),
        content: const Text('(Önizleme — gerçek sistem penceresi değil)'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İzin verme'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('İzin ver'),
          ),
        ],
      ),
    );
    return allow ?? false;
  }

  Future<void> _play() async {
    final result = await Navigator.of(context).push<IntroResult>(
      MaterialPageRoute<IntroResult>(
        builder: (_) => IntroFlowScreen(
          requestNotificationPermission: _fakeSystemPermission,
        ),
      ),
    );
    if (mounted) setState(() => _result = result);
  }

  @override
  Widget build(BuildContext context) {
    final r = _result;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Akış bitti',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            if (r != null) ...[
              const SizedBox(height: 8),
              Text(
                'İsim: ${r.name} · Bildirim: ${r.notificationsGranted ? 'izin verildi' : 'verilmedi'}',
              ),
            ],
            const SizedBox(height: 16),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'tr', label: Text('TR')),
                ButtonSegment(value: 'en', label: Text('EN')),
                ButtonSegment(value: 'es', label: Text('ES')),
              ],
              selected: {widget.locale.languageCode},
              onSelectionChanged: (s) => widget.onLocale(Locale(s.first)),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: _play, child: const Text('Tekrar izle')),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../admin_auth.dart';
import 'admin_log_screen.dart';
import 'broadcast_screen.dart';
import 'games_config_screen.dart';
import 'placeholder_screen.dart';
import 'user_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 1;

  static const _tabs = [
    (icon: Icons.insights_outlined, label: 'Özet'),
    (icon: Icons.tune, label: 'Ayarlar'),
    (icon: Icons.campaign_outlined, label: 'Duyuru'),
    (icon: Icons.person_search_outlined, label: 'Kullanıcı'),
    (icon: Icons.receipt_long_outlined, label: 'Kayıt'),
  ];

  Widget _body() => switch (_index) {
    0 => const PlaceholderScreen(step: 'A6', text: 'Günlük özet (stats/daily) saatlik işle gelecek.'),
    1 => const GamesConfigScreen(),
    2 => const BroadcastScreen(),
    3 => const UserScreen(),
    _ => const AdminLogScreen(),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_tabs[_index].label),
        actions: [
          IconButton(tooltip: 'Çıkış', icon: const Icon(Icons.logout), onPressed: AdminAuth.signOut),
        ],
      ),
      body: _body(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [for (final t in _tabs) NavigationDestination(icon: Icon(t.icon), label: t.label)],
      ),
    );
  }
}

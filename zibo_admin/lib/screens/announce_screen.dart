import 'package:flutter/material.dart';

import 'broadcast_screen.dart';
import 'in_app_message_screen.dart';

/// Duyuru sekmesi: push bildirimi (`broadcasts`) ya da uygulama içi mesaj kartı (`inAppMessages`).
class AnnounceScreen extends StatefulWidget {
  const AnnounceScreen({super.key});

  @override
  State<AnnounceScreen> createState() => _AnnounceScreenState();
}

class _AnnounceScreenState extends State<AnnounceScreen> {
  bool _inApp = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: SizedBox(
            width: double.infinity,
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, icon: Icon(Icons.notifications_active_outlined), label: Text('Bildirim')),
                ButtonSegment(value: true, icon: Icon(Icons.chat_bubble_outline), label: Text('Uygulama içi')),
              ],
              selected: {_inApp},
              onSelectionChanged: (s) => setState(() => _inApp = s.first),
            ),
          ),
        ),
        // İki ekran da durumunu korusun (yazılan taslak sekme değişince silinmesin).
        Expanded(
          child: IndexedStack(
            index: _inApp ? 1 : 0,
            children: const [BroadcastScreen(), InAppMessageScreen()],
          ),
        ),
      ],
    );
  }
}

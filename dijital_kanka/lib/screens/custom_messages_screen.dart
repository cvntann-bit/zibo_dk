import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/custom_messages_provider.dart';

/// Kullanıcının Ana Sayfa'daki konuşma balonu için kendi yazdığı özel
/// mesajları yönettiği sayfa — `FavoriteQuotesScreen` ile aynı basit liste
/// deseni, ama burada kullanıcı hem EKLEYEBİLİYOR hem SİLEBİLİYOR (favoriler
/// yalnızca silinebiliyordu, ekleme Ana Sayfa'daki kalp ikonundan geliyordu).
class CustomMessagesScreen extends StatelessWidget {
  const CustomMessagesScreen({super.key});

  Future<void> _showAddDialog(BuildContext context) async {
    final provider = context.read<CustomMessagesProvider>();
    final text = await showDialog<String>(
      context: context,
      builder: (_) => const _AddMessageDialog(),
    );
    if (text != null && text.trim().isNotEmpty) provider.addMessage(text);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final provider = context.watch<CustomMessagesProvider>();
    final messages = provider.messages;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.customMessagesScreenTitle)),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Text(
                l10n.customMessagesSubtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: messages.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(
                          l10n.customMessagesEmpty,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: messages.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        return Card(
                          child: ListTile(
                            title: Text(message),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline),
                              tooltip: l10n.customMessagesDeleteTooltip,
                              onPressed: () => provider.removeMessage(message),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showAddDialog(context),
                  icon: const Icon(Icons.add),
                  label: Text(l10n.customMessagesAddButton),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Yeni mesaj" diyaloğu. `TextEditingController`'ın ömrü diyaloğun KENDİ
/// `State`'ine bağlı — `dispose()` yalnızca diyalog (kapanış animasyonu
/// dahil) ağaçtan tamamen çıkınca çalışır.
///
/// Eskiden controller `showDialog` Future'ı dönünce (önce hemen, sonra
/// "bir sonraki kare"de) dispose ediliyordu; ama `TextField` kapanış
/// animasyonu boyunca (birkaç kare) hâlâ ağaçtaydı ve odak kaybı bildirimi
/// dispose edilmiş controller'ı kullanıyordu → Crashlytics'te "A
/// TextEditingController was used after being disposed ... dispatching
/// notifications for FocusNode" + ikincil "Duplicate GlobalKeys" /
/// "wrong build scope" (test/CLAUDE.md'deki AYNI ders).
class _AddMessageDialog extends StatefulWidget {
  const _AddMessageDialog();

  @override
  State<_AddMessageDialog> createState() => _AddMessageDialogState();
}

class _AddMessageDialogState extends State<_AddMessageDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.customMessagesAddButton),
      content: TextField(
        controller: _controller,
        autofocus: true,
        minLines: 1,
        maxLines: 3,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(hintText: l10n.customMessagesFieldHint),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.customMessagesCancelButton),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: Text(l10n.customMessagesSaveButton),
        ),
      ],
    );
  }
}

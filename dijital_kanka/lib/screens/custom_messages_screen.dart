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
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    final provider = context.read<CustomMessagesProvider>();
    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(l10n.customMessagesAddButton),
          content: TextField(
            controller: controller,
            autofocus: true,
            minLines: 1,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(hintText: l10n.customMessagesFieldHint),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l10n.customMessagesCancelButton),
            ),
            FilledButton(
              onPressed: () {
                provider.addMessage(controller.text);
                Navigator.of(dialogContext).pop();
              },
              child: Text(l10n.customMessagesSaveButton),
            ),
          ],
        ),
      );
    } finally {
      // Faz 6 KRİTİK bug düzeltmesi — Crashlytics'te "yeni mesaj eklerken
      // çöküyor" olarak bildirilen, `_dependents.isEmpty`/"Duplicate
      // GlobalKeys" gibi İKİNCİL assertion'lara da yol açan gerçek kök
      // neden: `TextField`'ın `autofocus: true` ile aldığı odağı, diyalog
      // kapanırken (route pop) KAYBETMESİ bir `FocusManager` MİKROGÖREVİ
      // ZAMANLIYOR (`EditableTextState._handleFocusChanged` →
      // `controller.clearComposing()`). Bu mikrogörev, `showDialog`
      // Future'ı tamamlandığı AN çalışan bu `finally` bloğuyla YARIŞIYOR —
      // `controller.dispose()` HEMEN/SENKRON çağrılırsa mikrogörev SONRA
      // çalışıp "TextEditingController was used after being disposed"
      // fırlatıyor; bu istisna bir frame'in ORTASINDA (widget ağacı
      // "kilitliyken") oluştuğu için ağacı YARIM GÜNCELLENMİŞ bırakıyor —
      // SONRAKİ herhangi bir etkileşim (ör. tema değiştirme) o bozuk ağaç
      // yüzünden AYRI/İLGİSİZ görünen assertion'larla çöküyor. **Çözüm:**
      // disposal'ı bir SONRAKİ frame'e ertelemek — o mikrogörev bu ANDA
      // ZATEN tamamlanmış oluyor, yarış ortadan kalkıyor.
      WidgetsBinding.instance.addPostFrameCallback((_) => controller.dispose());
    }
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

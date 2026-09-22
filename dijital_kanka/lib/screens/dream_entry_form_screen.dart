import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/dream_entry.dart';
import '../providers/dream_journal_provider.dart';
import '../widgets/dot_grid_background.dart';
import '../widgets/sticker_style.dart';

/// Yeni rüya ekleme VE var olan bir rüyayı düzenleme için ortak form ekranı.
/// [existing] verilmezse "ekle" modunda açılır; verilirse alanlar önceden
/// doldurulur ve AppBar'a bir silme butonu eklenir — bu tek ekran, rüyanın
/// tam metnini görme/düzenleme/silme ihtiyacının hepsini karşılar.
class DreamEntryFormScreen extends StatefulWidget {
  const DreamEntryFormScreen({super.key, this.existing});

  final DreamEntry? existing;

  @override
  State<DreamEntryFormScreen> createState() => _DreamEntryFormScreenState();
}

class _DreamEntryFormScreenState extends State<DreamEntryFormScreen> {
  late final _titleController = TextEditingController(
    text: widget.existing?.title ?? '',
  );
  late final _textController = TextEditingController(
    text: widget.existing?.text ?? '',
  );
  bool _canSave = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _canSave = _computeCanSave();
    _titleController.addListener(_onFieldsChanged);
    _textController.addListener(_onFieldsChanged);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _textController.dispose();
    super.dispose();
  }

  bool _computeCanSave() =>
      _titleController.text.trim().isNotEmpty &&
      _textController.text.trim().isNotEmpty;

  void _onFieldsChanged() {
    final canSave = _computeCanSave();
    if (canSave != _canSave) setState(() => _canSave = canSave);
  }

  void _save() {
    if (!_canSave) return;
    final provider = context.read<DreamJournalProvider>();
    if (_isEditing) {
      provider.updateDream(
        widget.existing!.id,
        title: _titleController.text,
        text: _textController.text,
      );
    } else {
      provider.addDream(
        title: _titleController.text,
        text: _textController.text,
      );
    }
    Navigator.of(context).pop();
  }

  Future<void> _confirmDelete() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.dreamDeleteConfirmTitle),
        content: Text(l10n.dreamDeleteConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              MaterialLocalizations.of(dialogContext).cancelButtonLabel,
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.dreamDeleteConfirmButton),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      context.read<DreamJournalProvider>().removeDream(widget.existing!.id);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: plainStickerAppBar(
        context,
        title: _isEditing ? l10n.dreamEditEntryTitle : l10n.dreamNewEntryTitle,
        actions: [
          if (_isEditing)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: StickerIconButton(
                icon: Icons.delete_outline,
                onPressed: _confirmDelete,
                tooltip: l10n.dreamDeleteEntryTooltip,
                backgroundColor: colorScheme.surfaceContainerLowest,
                iconColor: colorScheme.onSurface,
                size: 34,
                iconSize: 16,
                borderRadius: null,
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: DotGridBackground()),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              children: [
                _DreamFieldCard(
                  label: l10n.dreamTitleHint,
                  child: TextField(
                    controller: _titleController,
                    autofocus: !_isEditing,
                    textCapitalization: TextCapitalization.sentences,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                      color: colorScheme.onSurface,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      // Global `InputDecorationTheme` (bkz. main.dart)
                      // `filled:true, fillColor: colorScheme.surfaceContainer`
                      // veriyor — bu sarımsı dolgu, kartın kendi konturu
                      // İÇİNDE ikinci bir dolgu gibi göründüğü için burada
                      // AÇIKÇA kapatılıyor (kartın kendi arka planı yeterli).
                      filled: false,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _DreamFieldCard(
                  label: l10n.dreamTextHint,
                  child: TextField(
                    controller: _textController,
                    minLines: 6,
                    maxLines: 12,
                    textCapitalization: TextCapitalization.sentences,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                      height: 1.5,
                      color: colorScheme.onSurface,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      // Global `InputDecorationTheme` (bkz. main.dart)
                      // `filled:true, fillColor: colorScheme.surfaceContainer`
                      // veriyor — bu sarımsı dolgu, kartın kendi konturu
                      // İÇİNDE ikinci bir dolgu gibi göründüğü için burada
                      // AÇIKÇA kapatılıyor (kartın kendi arka planı yeterli).
                      filled: false,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                stickerButtonShadow(
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: stickerFilledButtonStyle(context, fontSize: 14),
                      onPressed: _canSave ? _save : null,
                      child: Text(l10n.dreamSaveButton),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Rüya formunun "Başlık"/"Rüyanı anlat..." alanlarını saran sticker kartı
/// — mockup'ın `.field-card` (küçük büyük-harf etiket + kalın değer metni).
/// İçindeki [child] gerçek bir [TextField] KALIYOR (yalnızca görünümü
/// `InputBorder.none` ile sıfırlanıp bu kartın kendi konturu/gölgesi
/// devralıyor) — `widget_test.dart`'ın `find.byType(TextField).at(0/1)` ile
/// bu iki alana yazdığı testler BOZULMASIN diye.
class _DreamFieldCard extends StatelessWidget {
  const _DreamFieldCard({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: stickerDecoration(
        fill: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 10.5,
              letterSpacing: 0.5,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 5),
          child,
        ],
      ),
    );
  }
}

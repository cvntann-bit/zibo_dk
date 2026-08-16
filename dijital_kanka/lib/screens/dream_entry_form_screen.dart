import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/dream_entry.dart';
import '../providers/dream_journal_provider.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? l10n.dreamEditEntryTitle : l10n.dreamNewEntryTitle,
        ),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: l10n.dreamDeleteEntryTooltip,
              onPressed: _confirmDelete,
            ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: [
            TextField(
              controller: _titleController,
              autofocus: !_isEditing,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(labelText: l10n.dreamTitleHint),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _textController,
              minLines: 6,
              maxLines: 12,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: l10n.dreamTextHint,
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _canSave ? _save : null,
              child: Text(l10n.dreamSaveButton),
            ),
          ],
        ),
      ),
    );
  }
}

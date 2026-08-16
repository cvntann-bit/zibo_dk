import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/profile_provider.dart';

/// "Hitap Tercihi" satırının açtığı sayfa — kullanıcı Zibo'nun kendisine
/// nasıl hitap edeceğini SERBESTÇE yazar (kullanıcı isteğiyle 2026
/// güncellemesinde hazır seçeneklerden — Kanka/Abi-Abla/Patron/Reis —
/// serbest bir metin kutusuna çevrildi). Odak kaybında/gönderiminde
/// kaydedilir (`ProfileScreen`'in isim alanıyla AYNI desen — her tuş
/// vuruşunda değil). Seçili terim, söz havuzlarındaki sabit "kanka"
/// kelimesinin yerini alır (bkz. `applyAddressTerm`, 8 modül ekranına
/// uygulanmış durumda).
class AddressTermScreen extends StatefulWidget {
  const AddressTermScreen({super.key});

  @override
  State<AddressTermScreen> createState() => _AddressTermScreenState();
}

class _AddressTermScreenState extends State<AddressTermScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        context.read<ProfileProvider>().setAddressTerm(_controller.text);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final addressTerm = context.watch<ProfileProvider>().addressTerm;
    if (!_focusNode.hasFocus && _controller.text != addressTerm) {
      _controller.text = addressTerm;
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.addressTermScreenTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              l10n.addressTermScreenDescription,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _controller,
              focusNode: _focusNode,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                hintText: l10n.addressTermFieldHint,
                border: const OutlineInputBorder(),
              ),
              onSubmitted: (value) =>
                  context.read<ProfileProvider>().setAddressTerm(value),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/coin_economy.dart';
import '../providers/referral_provider.dart';
import '../services/share_service.dart';
import '../utils/info_dialog.dart';

/// "Arkadaşını Davet Et" satırının açtığı ekran (bkz. `ProfileScreen`) —
/// kullanıcının kendi davet kodunu (uid'i) gösterip paylaşmasını VE
/// (henüz kullanmadıysa) başkasının kodunu girip kullanmasını sağlar. Bkz.
/// `ReferralProvider` dokümantasyonu — kredi ANINDA değil, arka planda bir
/// sonraki `processReferralRewards.js` çalıştırmasında işlenir.
class ReferralScreen extends StatefulWidget {
  const ReferralScreen({super.key, this.shareService = const SharePlusService()});

  /// `AdService`/`PurchaseService` ile AYNI "gerçek varsayılan, testte
  /// enjekte edilebilir" deseni.
  final ShareService shareService;

  @override
  State<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends State<ReferralScreen> {
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _copyCode(BuildContext context, String code) {
    Clipboard.setData(ClipboardData(text: code));
    final l10n = AppLocalizations.of(context)!;
    showInfoDialog(context, l10n.referralCodeCopiedMessage);
  }

  Future<void> _shareCode(BuildContext context, String code) async {
    final l10n = AppLocalizations.of(context)!;
    await widget.shareService.shareText(
      l10n.referralShareMessage(code, CoinEconomy.referral),
    );
  }

  Future<void> _redeem(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final referral = context.read<ReferralProvider>();
    final result = await referral.redeemCode(_codeController.text);
    if (!context.mounted) return;
    final message = switch (result) {
      ReferralRedeemResult.success => l10n.referralRedeemSuccessMessage,
      ReferralRedeemResult.selfCode => l10n.referralRedeemSelfCodeError,
      ReferralRedeemResult.invalidCode => l10n.referralRedeemInvalidCodeError,
      ReferralRedeemResult.alreadyRedeemed => l10n.referralAlreadyRedeemedStatus,
      ReferralRedeemResult.unavailable ||
      ReferralRedeemResult.networkError => l10n.referralUnavailableMessage,
    };
    showInfoDialog(context, message);
    if (result == ReferralRedeemResult.success) _codeController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final referral = context.watch<ReferralProvider>();
    final code = referral.referralCode;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.referralScreenTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.referralCodeLabel,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (code == null)
                      Text(l10n.referralUnavailableMessage)
                    else ...[
                      SelectableText(
                        code,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _copyCode(context, code),
                              icon: const Icon(Icons.copy_rounded),
                              label: Text(l10n.referralCopyButton),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () => _shareCode(context, code),
                              icon: const Icon(Icons.share_rounded),
                              label: Text(l10n.referralShareButton),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (referral.hasRedeemed)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_rounded, color: colorScheme.primary),
                      const SizedBox(width: 12),
                      Expanded(child: Text(l10n.referralAlreadyRedeemedStatus)),
                    ],
                  ),
                ),
              )
            else
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.referralRedeemFieldLabel,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _codeController,
                        decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          hintText: l10n.referralCodeLabel,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: referral.isRedeeming
                              ? null
                              : () => _redeem(context),
                          child: referral.isRedeeming
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Text(l10n.referralRedeemButton),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

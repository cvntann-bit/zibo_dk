import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'sticker_style.dart';

/// Uygulamanın alt gezinme çubuğu — tamamen standart Flutter widget'larıyla
/// (`BottomAppBar` + `CircularNotchedRectangle`) çizilir, hiçbir özel görsel
/// varlığa bağımlı DEĞİLDİR. Ortadaki [ZFloatingButton] (ayrı dosya,
/// RootScreen'in `Scaffold.floatingActionButton`'ına
/// `FloatingActionButtonLocation.centerDocked` ile bağlanıyor) bu bar'ın
/// "çentiğine" Flutter'ın kendi Scaffold geometrisiyle otomatik oturur.
///
/// **Tarihçe:** İlk sürüm, kullanıcının verdiği `alt_bar.png` tasarımından
/// piksel-piksel kırpılıp işlenen özel PNG katmanlarına (açık/koyu tema için
/// ayrı görseller, Z coin için ayrı bir görsel, elle ölçülen onlarca oran
/// sabiti) dayanıyordu. Kullanıcı, ileride bu alanı değiştirirken bu
/// görsel-işleme/piksel-eşleştirme karmaşasıyla tekrar uğraşmak
/// istemediğini belirtip TAMAMEN kod-tabanlı bir alternatif istedi — bu
/// widget bunun yerine geçti. Artık renkler tema (`ColorScheme`) üzerinden
/// geliyor, ikonlar Material `Icon`'ları, aktif sekme vurgusu basit bir
/// `AnimatedContainer` — hiçbiri yeni bir görsel gerektirmeden
/// değiştirilebilir (bkz. CLAUDE.md "Alt Gezinme Çubuğu" bölümü).
class MainBottomBar extends StatelessWidget {
  const MainBottomBar({
    super.key,
    required this.selectedIndex,
    required this.onHomeTap,
    required this.onGoalsTap,
    required this.onProfileTap,
    required this.onStoreTap,
  });

  /// RootScreen'in kendi sekme indeksiyle BİREBİR aynı: 0=Ana Sayfa,
  /// 1=Hedefler, 2=Profil, 3=Mağaza. (Birikim artık burada değil — Z
  /// butonunun modül menüsüne taşındı, bkz. CLAUDE.md "Alt Gezinme Çubuğu"
  /// bölümündeki güncelleme notu.)
  final int selectedIndex;
  final VoidCallback onHomeTap;
  final VoidCallback onGoalsTap;
  final VoidCallback onProfileTap;
  final VoidCallback onStoreTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: kStickerOutline, width: 3)),
      ),
      child: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        color: colorScheme.surfaceContainer,
        padding: EdgeInsets.zero,
        elevation: 0,
        child: Row(
          children: [
            _NavItem(
              icon: Icons.home_rounded,
              visibleLabel: l10n.tabHome,
              semanticLabel: l10n.tabHome,
              selected: selectedIndex == 0,
              onTap: onHomeTap,
            ),
            _NavItem(
              icon: Icons.flag_rounded,
              visibleLabel: l10n.bottomBarGoalsLabel,
              semanticLabel: l10n.tabGoalTracking,
              selected: selectedIndex == 1,
              onTap: onGoalsTap,
            ),
            // Z butonu için boşluk — CircularNotchedRectangle'ın çentiği bu
            // alanı görsel olarak zaten oyuyor, bu Expanded yalnızca 5 eşit
            // sütunluk (diğer 4 öğeyle simetrik) yatay boşluğu ayırıyor.
            const Expanded(child: SizedBox.shrink()),
            _NavItem(
              icon: Icons.account_circle_rounded,
              visibleLabel: l10n.profileScreenTitle,
              semanticLabel: l10n.profileScreenTitle,
              selected: selectedIndex == 2,
              onTap: onProfileTap,
            ),
            _NavItem(
              icon: Icons.storefront_rounded,
              visibleLabel: l10n.storeTitle,
              semanticLabel: l10n.storeTitle,
              selected: selectedIndex == 3,
              onTap: onStoreTap,
            ),
          ],
        ),
      ),
    );
  }
}

/// Tek bir sekme: ikon + kısa etiket. Seçiliyken ikonun arkasında
/// `colorScheme.primary` renginde kayan/beliren bir "hap" (pill) belirir —
/// eskiden bir PNG'ye gömülü olan "aktif sekme" vurgusunun yerini alıyor,
/// ama artık `AnimatedContainer` ile HERHANGİ bir sekmenin altına
/// sorunsuzca taşınabiliyor.
class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.visibleLabel,
    required this.semanticLabel,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String visibleLabel;
  final String semanticLabel;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final iconColor = selected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant;
    final textColor = selected ? colorScheme.primary : colorScheme.onSurfaceVariant;

    return Expanded(
      child: Semantics(
        label: semanticLabel,
        button: true,
        selected: selected,
        // İçerideki Icon/Text kendi otomatik semantics etiketlerini
        // üretiyor; bu, dışarıdaki `label`le birleşip "Hedef Takibi\n
        // Hedefler" gibi BİRLEŞİK bir etikete yol açıyordu (find.
        // bySemanticsLabel(exact) eşleşmeyi bu yüzden bulamıyordu).
        // excludeSemantics, alt ağacın kendi semantics düğümlerini
        // tamamen bastırıp yalnızca burada tanımlanan `label`i kullanır.
        excludeSemantics: true,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: selected
                      ? stickerDecoration(
                          fill: colorScheme.primary,
                          borderRadius: BorderRadius.circular(20),
                          borderWidth: 2,
                          shadowOffset: const Offset(2, 2),
                        )
                      : const BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.all(Radius.circular(20)),
                        ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                const SizedBox(height: 2),
                Text(
                  visibleLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

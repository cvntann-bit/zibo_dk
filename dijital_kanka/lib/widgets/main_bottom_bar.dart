import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'sticker_style.dart';

/// Uygulamanın alt gezinme çubuğu — tamamen standart Flutter widget'larıyla
/// (`BottomAppBar`, DÜZ — çentik YOK, bkz. aşağıdaki not) çizilir, hiçbir
/// özel görsel varlığa bağımlı DEĞİLDİR. Ortadaki [ZFloatingButton] (ayrı
/// dosya, RootScreen'in `Scaffold.floatingActionButton`'ına
/// `FloatingActionButtonLocation.centerDocked` ile bağlanıyor) bu bar'ın
/// üstüne, mockup'taki gibi bir "çentik" OLMADAN, doğrudan z-index ile biner.
///
/// **Tarihçe:** İlk sürüm, kullanıcının verdiği `alt_bar.png` tasarımından
/// piksel-piksel kırpılıp işlenen özel PNG katmanlarına (açık/koyu tema için
/// ayrı görseller, Z coin için ayrı bir görsel, elle ölçülen onlarca oran
/// sabiti) dayanıyordu. Kullanıcı, ileride bu alanı değiştirirken bu
/// görsel-işleme/piksel-eşleştirme karmaşasıyla tekrar uğraşmak
/// istemediğini belirtip TAMAMEN kod-tabanlı bir alternatif istedi — bu
/// widget bunun yerine geçti. Artık renkler tema (`ColorScheme`) üzerinden
/// geliyor, ikonlar mockup'la BİREBİR aynı emoji, aktif sekme vurgusu basit
/// bir `AnimatedContainer` — hiçbiri yeni bir görsel gerektirmeden
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
      // Mockup'ın `.navbar`'ı DÜZ bir bar — hiçbir "çentik" (notch) YOK, Z
      // butonu üstüne yalnızca z-index ile biniyor. Önceki `BottomAppBar(
      // shape: CircularNotchedRectangle())` sürümü FAB'ın (kalın kontur +
      // düz gölge eklenmiş özel dekorasyonu) gerçek görsel boyutuyla notch
      // hesaplamasının varsaydığı çıplak daireyi TAM örtüşTÜRMÜYORDU — üstteki
      // 3px kontur çizgisinin ucu, çentiğin eğrisiyle FAB'ın arasında kısa,
      // "alakasız" duran bir çizgi parçası olarak kalıyordu (kullanıcı
      // raporu). Düz bar + Z butonu üstte serbestçe binen bir öğe olunca bu
      // artefakt tamamen ortadan kalkıyor — `centerDocked` konumlandırması
      // (RootScreen) çentik OLMADAN da aynı şekilde çalışmaya devam ediyor.
      child: BottomAppBar(
        color: colorScheme.surfaceContainerLowest,
        padding: EdgeInsets.zero,
        elevation: 0,
        child: Row(
          children: [
            _NavItem(
              emoji: '🏠',
              visibleLabel: l10n.tabHome,
              semanticLabel: l10n.tabHome,
              selected: selectedIndex == 0,
              onTap: onHomeTap,
            ),
            _NavItem(
              emoji: '🚩',
              visibleLabel: l10n.bottomBarGoalsLabel,
              semanticLabel: l10n.tabGoalTracking,
              selected: selectedIndex == 1,
              onTap: onGoalsTap,
            ),
            // Z butonu için boşluk — mockup'ta `.nav-gap{width:64px;flex:
            // none;}` SABİT genişlikte (diğer 4 öğe gibi esnek DEĞİL).
            const SizedBox(width: 64),
            _NavItem(
              emoji: '👤',
              visibleLabel: l10n.profileScreenTitle,
              semanticLabel: l10n.profileScreenTitle,
              selected: selectedIndex == 2,
              onTap: onProfileTap,
            ),
            _NavItem(
              emoji: '🛍️',
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
    required this.emoji,
    required this.visibleLabel,
    required this.semanticLabel,
    required this.selected,
    required this.onTap,
  });

  final String emoji;
  final String visibleLabel;
  final String semanticLabel;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
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
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: selected
                      ? stickerDecoration(
                          fill: colorScheme.primary,
                          borderRadius: BorderRadius.circular(10),
                          borderWidth: 2.5,
                          shadowOffset: const Offset(2, 2),
                        )
                      : BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.transparent, width: 2.5),
                        ),
                  child: Text(emoji, style: const TextStyle(fontSize: 16, height: 1)),
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

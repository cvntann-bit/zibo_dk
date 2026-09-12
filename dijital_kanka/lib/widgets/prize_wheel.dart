import 'package:flutter/material.dart';

/// Şans Çarkı'nın büyük, döndürülebilir görseli. İki katmandan oluşur:
/// - `zibo_cark_disk.png`: yalnızca ödül dilimlerinin olduğu iç halka, döner.
/// - `zibo_cark_frame.png`: dış süslü çerçeve + üstteki ok işaretçi + merkez
///   "Reklam İzle ve Çevir" hub'ı — sabit, dönmez.
///
/// İki katman da tek parça `zibo_cark.png` görselinden
/// `tool/split_wheel_layers.dart` ile merkeze olan uzaklığa (yarıçap) göre
/// üretildi (bkz. CLAUDE.md "Şans Çarkı" bölümü) — bu yüzden ikisi de aynı
/// piksel boyutunda ve mükemmel hizalı; frame'in iç/dış kenarları disk'in
/// görünür alanının biraz içine taşıyor ki disk hangi açıya dönerse dönsün
/// (bir dairenin kendi merkezi etrafında dönüşü kendi siluetini
/// değiştirmediği için) asla boşluk/seam görünmesin.
class PrizeWheel extends StatelessWidget {
  const PrizeWheel({super.key, required this.size, required this.rotation});

  final double size;

  /// Radyan cinsinden dönüş açısı; 0 iken dilim 0'ın ortası saat 12
  /// hizasında (ok işaretçisinin altında) başlar.
  final double rotation;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.rotate(
            angle: rotation,
            child: Image.asset(
              'assets/images/zibo_cark_disk.webp',
              width: size,
              height: size,
            ),
          ),
          Image.asset(
            'assets/images/zibo_cark_frame.webp',
            width: size,
            height: size,
          ),
        ],
      ),
    );
  }
}

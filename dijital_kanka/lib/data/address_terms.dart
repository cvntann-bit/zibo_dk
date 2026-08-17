/// "Hitap Tercihi" özelliğinin varsayılan değeri — kullanıcı kendi hitap
/// şeklini serbestçe yazana kadar (bkz. `AddressTermScreen`, artık sabit
/// seçenekler DEĞİL, bir metin kutusu) `ProfileProvider.addressTerm` bu
/// değerde kalır. Değer BİLEREK Türkçe ("Kanka") — bu, `applyAddressTerm`'in
/// "kullanıcı hiç özelleştirmedi" durumunu tespit ettiği TEK karşılaştırma
/// noktası, hangi arayüz dilinde olursa olsun (bkz. o fonksiyondaki 2026
/// güncellemesi notu — artık üç dilde de çalışıyor, yalnızca hangi kelimenin
/// DEĞİŞTİRİLECEĞİ dile göre değişiyor: TR "Kanka", EN "Buddy", ES "Amigo").
const defaultAddressTerm = 'Kanka';

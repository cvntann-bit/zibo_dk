/// "Hitap Tercihi" özelliğinin varsayılan değeri — kullanıcı kendi hitap
/// şeklini serbestçe yazana kadar (bkz. `AddressTermScreen`, artık sabit
/// seçenekler DEĞİL, bir metin kutusu) `ProfileProvider.addressTerm` bu
/// değerde kalır. Bilerek yalnızca Türkçe — bu tercih yalnızca Türkçe söz
/// havuzlarındaki sabit "kanka" kelimesini değiştirmek için var (bkz.
/// `applyAddressTerm`), uygulama İngilizce/İspanyolca iken zaten görünür bir
/// etkisi yok ("buddy"/"amigo" ayrı, sabit çevirilerdir).
const defaultAddressTerm = 'Kanka';

# Zibo Eşya Kütüphanesi

Zibo'nun Evi için hazır eşya görselleri. **Uygulamaya dahil DEĞİL:** `pubspec.yaml` bu klasörü görmez, AAB boyutu değişmez.
Bir eşya kullanılacağında buradan `dijital_kanka/assets/images/` altına kopyalanır, pubspec ve kaynak kaydı eklenir.

- `webp/<kategori>/`: stil hattından geçmiş görseller (kalın kontur + sert gölge, en uzun kenar 256 px).
- `catalog.json`: her eşyanın kimliği, adı, kategorisi, kaynağı, lisansı ve boyutu.
- `katalog.html`: arama ve süzgeçli katalog (görseller içine gömülü, tek dosya).
- `LICENSES.md`, `LICENSE-fluent-emoji.txt`: lisans kaydı.

## Yeniden üretmek
Ham paketler repoda yok (~250 MB). `LICENSES.md`'deki adreslerden bir klasöre indirilir:
`kenney/pack.zip`, `quat/pack.zip`, `oga/<paket>/pack.zip`, `fluentrepo/` (fluentui-emoji reposu). Sonra `dijital_kanka/` içinde:

```bash
python tool/build_asset_library.py <ham_klasör> ../asset_library
```

## Yeni kaynak eklerken
- Yalnızca CC0, MIT ya da ticari kullanımı doğrulanmış lisans. Lisans `LICENSES.md`'ye yazılır.
- Poly Pizza betikle erişimi engelliyor, ticari API'si ücretli: model gerekirse elle, CC0 olduğunu görerek alınır.
- Kenney'nin sitesi de otomatik indirmeyi reddediyor; paketler OpenGameArt'tan alındı.
- Telifli karakter veya marka içeren görsel eklenmez.

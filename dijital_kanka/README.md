# Zibo (`dijital_kanka`)

Kişisel gelişim / "dijital kanka" Flutter uygulaması. Yalnızca Android, TR/EN/ES.

## Dokümantasyon

- **`CLAUDE.md`** — proje haritası, kritik contract'lar, global kurallar (küçük — buradan başla).
- **`docs/CURRENT_STATE.md`** — projenin şu anki durumu (aktif sistemler, release, bilinen sorunlar).
- **`docs/ARCHITECTURE.md`** — sistem nasıl çalışıyor.
- **`docs/decisions/`** — kalıcı mimari kararlar ve gerekçeleri.
- **`docs/history/`** — geliştirme geçmişi arşivi (yalnızca gerektiğinde okunur — `docs/history/README.md`).
- Alt-dizin `CLAUDE.md`'leri (`lib/providers/`, `lib/l10n/`, `lib/services/`, `test/`, `android/`, `tool/`) o alana özgü kurallar.

## Komutlar

```bash
export PATH="$PATH:/c/flutter/bin"
flutter test                        # flutter analyze BU MAKİNEDE ÇÖKÜYOR — kullanma
flutter build appbundle --release   # → build/app/outputs/bundle/release/app-release.aab
```

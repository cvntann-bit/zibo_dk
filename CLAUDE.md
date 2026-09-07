# Zibo — repo kökü

Bu repo iki parça içerir:

- **`dijital_kanka/`** — Flutter uygulaması (asıl proje). **Proje haritası ve tüm kurallar: [`dijital_kanka/CLAUDE.md`](dijital_kanka/CLAUDE.md).** Çalışmaya oradan başla.
- **`notification-scripts/`** — sunucu tarafı zamanlanmış işler (Node + firebase-admin, GitHub Actions'tan). Kuralları: [`notification-scripts/CLAUDE.md`](notification-scripts/CLAUDE.md).
- `.github/workflows/` — yukarıdaki betiklerin cron'ları.

Dokümantasyon mimarisi `dijital_kanka/docs/` altında (`CURRENT_STATE.md`, `ARCHITECTURE.md`,
`decisions/`, `history/`). **`docs/history/` görev açıkça geçmiş bağlam gerektirmedikçe okunmaz.**

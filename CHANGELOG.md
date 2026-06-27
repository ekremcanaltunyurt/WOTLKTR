# Değişiklik Günlüğü

Bu projedeki önemli değişiklikler burada listelenir.
Biçim [Keep a Changelog](https://keepachangelog.com/tr/) esinlidir; sürümleme [SemVer](https://semver.org/lang/tr/) uyumludur.

## [0.1.0-beta] — 2026-06-28

İlk genel beta sürümü.

### Eklendi
- **Görevler** — başlık, açıklama, hedef ve ödül çevirisi (görev günlüğü + verme/teslim pencereleri).
- **NPC Konuşmaları (Gossip)** — diyalog menüleri ve metinleri.
- **Konuşma Baloncukları** — NPC baş üstü / say / yell konuşmaları.
- **Sinematik Altyazılar** — film ve cinematic altyazıları.
- **Kitaplar** — oyun içi kitap, mektup ve tomarlar (EN ↔ TR geçişli).
- **İpuçları (Tutorials)** — oyun öğretici pencereleri.
- **Yetenekler** — talent, büyü ve glyph tooltip açıklamaları. Talent eşleştirme şablon (templatize)
  tabanlı: her rank/değer yakalanır. Sayılar oyundan canlı alınıp yerine konur; teçhizat/spell power
  ile değişen değerler doğru gösterilir. Glyph hem çantada (eşya) hem Yetenek ekranında (yuva) çevrilir.
- Tanılama: giriş yükleme özeti, `/wtr` durum/debug, `pcall` çökme koruması.
- Türkçe karakter destekli fontlar.
- Ayarlar: `Esc → Arayüz → AddOns → WotLK TR` (Görevler / Baloncuklar / Kitaplar / Yetenekler).

### Notlar
- Beta: eksik/hatalı çeviriler olabilir. Çevrilmemiş içerik orijinal (İngilizce) biçimde görünür.
- Sınıf, ırk ve özel adlar (büyü adları, yer/kişi adları) İngilizce gösterilir.

[0.1.0-beta]: https://github.com/ekremcanaltunyurt/WOTLKTR/releases/tag/v0.1.0-beta

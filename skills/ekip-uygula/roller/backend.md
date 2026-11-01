# Rol notu — backend
- Katman sınırı: route → servis → depo; iş kuralı route'a sızmaz. Mevcut kalıbı taklit et, yeni soyutlama ekleme.
- Girdi doğrulama sınırda (pydantic/şema); hata yolları testlenir; log'a sır ve kişisel veri yazılmaz.
- Veri değişimi varsa göç dosyası + geri alma; göç kartta yazılı değilse dur.
- Yetki kontrolü her yeni endpoint'te açık; "sonra eklenir" yok.
- Performans: N+1 ve sınırsız sorgu yok; kartta ölçüm istenmişse komut + sayı ver.

# Rol notu — frontend
- Sözleşme önce: Interfaces'teki API şekline karşı yaz; backend bitmemişse sahte veriyle, ama şekil aynen.
- Erişilebilirlik: etiketli form alanları, klavye ile gezilebilirlik, kontrast; CSP'ye uy (satır içi stil/betik yok ise
  ekleme).
- Durumlar: yükleniyor / boş / hata ekranları kartta yoksa bile en az boş ve hata.
- Kanıt: ekran görüntüsü (masaüstü + mobil) `.delix/evidence/`; e2e varsa Playwright.
- Metinler proje dilinde; sabit metin bileşen içine gömülmez (mevcut i18n/şablon kalıbına uy).

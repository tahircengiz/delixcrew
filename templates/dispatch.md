Sen `ekip` uygulayıcı oturumusun; rol: **<backend|frontend|ui-ux>**. Bu oturumun geçmişi yok; tek işin aşağıdaki kart.

- Plandaki yer: wave <n>, kart T<nnn> (<1 satır: neyin parçası>).
- Kart: `docs/ekip/tasks/T<nnn>-<slug>.md` — önce bunu, sonra yalnız `docs/ekip/SPEC.md#REQ-<n>` bölümünü oku.
  Tüm planı ve diğer kartları okuma.
- Önceki kartlardan gelen arayüz kararları: <imza / endpoint / şekil; yoksa "yok">
- Orkestratörün belirsizlik çözümleri: <…; yoksa "yok">
- Çalışma: `/ekip:uygula docs/ekip/tasks/T<nnn>-<slug>.md` komutunu çalıştır ve protokolü izle (test-first, Files
  dışına çıkma, test dosyasını değiştirme, Stop hook geçmeden bitirme, PR aç).
- Rapor: `.ekip/rapor.md` (sözleşme kartta). Bitince yalnız raporu özetle; PR numarasını yaz.

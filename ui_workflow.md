# 🧱 UI Implementation Workflow

Bu doküman, tasarım ekibinden (Stitch) gelen ekranların koda dökülme sürecindeki standart iş akışını (workflow) tanımlar.

## İş Akışı Adımları

1. **Ekran Spesifikasyonunu Bekle (Wait for the next screen spec):** Bir sonraki ekranın tasarım detaylarının ve özellik gereksinimlerinin gelmesini bekle.
2. **Tasarımı Bileşenlere Ayır (Map Stitch design to components):** 
   - Stitch tasarımındaki layout'u (düzeni) incele.
   - Hangi kısımların tekrar kullanılabilir (reusable) `design_system` bileşeni olacağına karar ver.
3. **UI Kodunu Oluştur (Create UI code):**
   - İlgili özelliğin `presentation` katmanına ekran kodunu yaz.
   - Tasarımı modüler ve test edilebilir şekilde kodla.
4. **ViewModel ile Bağla (Connect to view model):**
   - Sayfanın state (durum) yönetimini MVVM standartlarına uygun şekilde ilgili ViewModel'a bağla.
5. **Lokalizasyon Anahtarlarını Ekle (Add localization keys):**
   - Ekranda görünen metinleri NEVER hardcode etme. Her yeni UI metni için `tr.json`, `en.json`, `de.json`, `fr.json`, `es.json`, `pt.json` dosyalarının TÜMÜNE eş zamanlı olarak key'leri ekle.
6. **Navigasyon Entegrasyonunu Sağla (Ensure navigation integration):**
   - Yeni ekranı `navigation` modülündeki iskelete entegre et.

*Not: AI (IDE) bu iş akışını takip edecek ve kullanıcıdan ekranların spesifikasyonlarını teker teker alacaktır.*

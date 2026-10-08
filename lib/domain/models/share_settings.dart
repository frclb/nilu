/// Partnerle neyin paylaşılacağını belirleyen tercih.
///
/// Eskiden dört ayrı anahtar vardı: faz bilgisi, semptom detayları, ruh
/// hali ve tahminler. Hiçbiri bir şey kontrol etmiyordu — partnere giden
/// tek veri yakınlık durumu (istek + sevgi ihtiyaçları) ve o da dördünden
/// hiçbiri değil. Dördü birden kapatıldığında paylaşım tümden duruyordu,
/// yani anahtarların **toplamı** çalışıyor ama etiketleri yanlış şeyi
/// anlatıyordu.
///
/// Gizlilik ekranının kontrol etmediği bir şeyi kontrol ediyormuş gibi
/// göstermesi, güvenli yönde bile olsa yanlış: "faz bilgisi paylaşılıyor"
/// yazısını okuyan kullanıcı paylaştığını sanıyordu, "semptom detaylarını"
/// kapatan da hiç başlamamış bir akışı durdurduğunu.
class ShareSettings {
  /// Yakınlık durumu partnerle paylaşılsın mı?
  ///
  /// Uygulamanın partnere gönderdiği tek veri bu. **Varsayılan kapalı** ve
  /// ancak açık rızayla açılıyor (bkz. `ShareSettingsRepository`): cinsel
  /// yaşamla ilgili veri KVKK'da özel nitelikli. Önceden varsayılan açıktı;
  /// partnerini onaylayan kullanıcı ayrıca hiçbir şey sorulmadan paylaşıma
  /// başlamış sayılıyordu.
  final bool intimacyStatus;

  const ShareSettings({this.intimacyStatus = false});

  /// Hiçbir şeyin paylaşılmadığı ayar.
  static const ShareSettings none = ShareSettings(intimacyStatus: false);

  bool get sharesAnything => intimacyStatus;

  ShareSettings copyWith({bool? intimacyStatus}) =>
      ShareSettings(intimacyStatus: intimacyStatus ?? this.intimacyStatus);

  @override
  bool operator ==(Object other) =>
      other is ShareSettings && other.intimacyStatus == intimacyStatus;

  @override
  int get hashCode => intimacyStatus.hashCode;
}

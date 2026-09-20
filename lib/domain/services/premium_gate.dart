import 'insights_service.dart';

/// Premium'un neyi açtığı.
///
/// Kurallar saf bir yerde toplandı: ekranlar `isPremium` bayrağını tek tek
/// yorumlarsa sınırlar zamanla birbirinden ayrışır ve paywall'da yazan ile
/// uygulamada olan tutmaz.
///
/// Öncesinde `isPremium` uygulamada **hiçbir yerde** okunmuyordu; abone olan
/// kullanıcı hiçbir değişiklik görmüyordu.
class PremiumGate {
  const PremiumGate._();

  /// Ücretsiz sürümde gösterilen döngü sayısı.
  ///
  /// Üç döngü, kullanıcının uygulamanın işe yaradığını görmesine yeter;
  /// trend ve düzenlilik ise daha uzun geçmiş ister.
  static const int freeCycleHistory = 3;

  /// Trend grafiğinde gösterilecek döngü sayısı.
  static int cycleHistoryLimit({required bool isPremium}) =>
      isPremium ? 12 : freeCycleHistory;

  /// Geçmişin kırpılıp kırpılmadığı — ekran "daha fazlası var" diyebilsin.
  static bool historyIsTrimmed({
    required bool isPremium,
    required int observedCycles,
  }) => !isPremium && observedCycles > freeCycleHistory;

  /// Belirtilerin döngü evresine göre kırılımı.
  static bool canSeePhaseBreakdown({required bool isPremium}) => isPremium;

  /// Reklam gösterilsin mi?
  ///
  /// Ücretsiz katman reklamla, ödeyen kullanıcı reklamsız. Reklamlar
  /// kişiselleştirilmiyor (`nonPersonalizedAds`): reklam kimliği kullanılmıyor,
  /// izleme izni istenmiyor. Bir regl uygulamasında davranış verisiyle hedefli
  /// reklam, uygulamanın kullanıcıya verdiği gizlilik sözüyle çelişirdi.
  static bool showsAds({required bool isPremium}) => !isPremium;

  /// Geri yüklenebilir yedek (JSON) alma.
  ///
  /// Herkese açık. Verinin makine-okunur bir kopyasını almak KVKK ve
  /// GDPR'da bir **hak**; ücrete bağlanamaz. Ayrıca veri cihazda
  /// duruyor: yedek alamayan bir kullanıcı telefonunu kaybettiğinde
  /// sağlık geçmişinin tamamını kaybederdi.
  static bool canExportBackup() => true;

  /// Hekime götürülebilecek özet ve tablo (TXT + CSV).
  ///
  /// Bunlar hak değil kolaylık: veri zaten yedekte eksiksiz duruyor,
  /// bu dosyalar onu okunabilir ve tablolanabilir hâle getiriyor.
  static bool canExportReports({required bool isPremium}) => isPremium;

  /// Trend için yeterli veri var mı (ücretsiz sınır dahil).
  static bool hasEnoughForTrend({
    required bool isPremium,
    required int observedCycles,
  }) => observedCycles >= 2;

  /// Ücretsiz kullanıcıya gösterilecek döngü noktaları.
  static List<CycleLengthPoint> visibleCycles(
    List<CycleLengthPoint> all, {
    required bool isPremium,
  }) {
    final limit = cycleHistoryLimit(isPremium: isPremium);
    if (all.length <= limit) return all;
    return all.sublist(all.length - limit);
  }
}

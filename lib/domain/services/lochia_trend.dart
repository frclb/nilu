import '../models/daily_log.dart';
import '../models/log_vocabulary.dart';

/// Lohia seyrinin rehberdeki tehlike örüntüsüne uyup uymadığı.
enum LochiaConcern {
  none,

  /// Azaldıktan sonra yeniden orta ya da çok kanamaya dönüş.
  reIncrease,

  /// Azalmıyor, üst üste artıyor.
  rising,
}

/// Lohia (doğum sonu kanama) seyrini değerlendirir.
///
/// T.C. Sağlık Bakanlığı Doğum Sonu Bakım Yönetim Rehberi, acil başvuru
/// gerektiren tehlike işaretleri arasında sayıyor: "kanamanın azalmasının
/// devamında tekrar kanamalı akıntının ortaya çıkması; kanamanın azalmayarak
/// artması". Tehlike tek bir günde değil gidişatta; lohia bu yüzden regl
/// olarak değil, seyri izlenecek biçimde kaydediliyor (bkz. `LifeStage`).
///
/// Teşhis koymuyor. Kural bilerek dar: küçük dalgalanmada (lekelenmeden aza)
/// alarm vermek kullanıcıyı uyarıya karşı duyarsızlaştırır. Rehberdeki diğer
/// işaretler (20–30 dakikada 2–3 ped, pıhtı, parlak kırmızı renk, kötü koku)
/// kaydedilmiyor; onlar tehlike işaretleri ekranında anlatılıyor.
class LochiaTrend {
  const LochiaTrend._();

  /// "Orta" kademesi: yeniden artışın alarm sayıldığı alt sınır.
  static final int _orta = LogVocabulary.flowIntensities.indexOf('medium');

  static LochiaConcern evaluate(
    List<DailyLog> logs, {
    required DateTime birth,
    required DateTime today,
  }) {
    final dogum = _day(birth);
    final bugun = _day(today);

    // Doğum günü hariç (ilk 24 saat hastanede); bugünden sonrası hariç.
    final seviyeler = <(DateTime, int)>[];
    for (final l in logs) {
      final gun = _day(l.date);
      if (!gun.isAfter(dogum) || gun.isAfter(bugun)) continue;
      final seviye = LogVocabulary.flowIntensities.indexOf(
        l.flowIntensity ?? '',
      );
      if (seviye < 0) continue;
      seviyeler.add((gun, seviye));
    }
    if (seviyeler.length < 2) return LochiaConcern.none;
    seviyeler.sort((a, b) => a.$1.compareTo(b.$1));

    final son = seviyeler.last.$2;
    final birOnceki = seviyeler[seviyeler.length - 2].$2;

    // Kanama orta ya da çok kademesine **çıktıysa** endişe. Rehber ve NHS
    // doğum sonu tavsiyesi aynı yönde: kanama azalmak yerine artarsa haber
    // ver. Lekelenmeden aza geçmek gibi küçük dalgalanmalar (orta altı)
    // alarm sayılmıyor — her artışta alarm, uyarıya karşı duyarsızlaştırır.
    if (son < _orta || son <= birOnceki) return LochiaConcern.none;

    // Öncesinde bir azalma olduysa rehberdeki ilk işaret ("azalmasının
    // devamında tekrar kanamalı akıntı"), yoksa ikincisi ("azalmayarak
    // artması"). İkisi de aynı yönlendirmeyi gerektiriyor; ayrım yalnızca
    // kullanıcıya ne gördüğümüzü doğru söylemek için.
    for (var i = 0; i < seviyeler.length - 1; i++) {
      for (var j = i + 1; j < seviyeler.length - 1; j++) {
        if (seviyeler[j].$2 < seviyeler[i].$2) return LochiaConcern.reIncrease;
      }
    }
    return LochiaConcern.rising;
  }

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);
}

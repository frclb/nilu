import 'package:flutter_test/flutter_test.dart';
import 'package:period_tracker/domain/models/daily_log.dart';
import 'package:period_tracker/domain/services/lochia_trend.dart';

/// Lohia (doğum sonu kanama) seyri.
///
/// Kaynak: T.C. Sağlık Bakanlığı Doğum Sonu Bakım Yönetim Rehberi, acil
/// başvuru gerektiren tehlike işaretleri: "kanamanın azalmasının devamında
/// tekrar kanamalı akıntının ortaya çıkması; kanamanın azalmayarak artması".
///
/// Tehlike işareti tek bir günde değil **gidişatta**. Uygulama teşhis
/// koymuyor; yalnızca rehberdeki örüntüyü görünce yönlendiriyor.
void main() {
  final dogum = DateTime(2026, 9, 1);
  final bugun = DateTime(2026, 9, 20);

  List<DailyLog> seyir(List<String> akislar, {int ilkGun = 1}) => [
    for (var i = 0; i < akislar.length; i++)
      DailyLog(
        date: dogum.add(Duration(days: ilkGun + i)),
        flowIntensity: akislar[i],
      ),
  ];

  LochiaConcern degerlendir(List<DailyLog> l) =>
      LochiaTrend.evaluate(l, birth: dogum, today: bugun);

  test('olağan seyir: azalarak sürüyor', () {
    expect(
      degerlendir(seyir(['heavy', 'heavy', 'medium', 'light', 'spotting', 'none'])),
      LochiaConcern.none,
    );
  });

  test('azaldıktan sonra yeniden artma', () {
    expect(
      degerlendir(seyir(['medium', 'light', 'spotting', 'medium'])),
      LochiaConcern.reIncrease,
    );
  });

  test('kayıt sırası tarih sırası olmak zorunda değil', () {
    // Günlük kayıtlar ekleme sırasıyla tutuluyor: dünü sonradan giren
    // kullanıcının kaydı listenin sonuna düşer. Değerlendirme son *eklenen*
    // değil son *gün* üzerinden yapılmalı.
    final olagan = seyir([
      'heavy',
      'medium',
      'light',
      'spotting',
    ]).reversed.toList();
    expect(
      degerlendir(olagan),
      LochiaConcern.none,
      reason:
          'Olağan azalan seyir ters sırayla girildi. Son eklenen kayda '
          'bakılırsa ilk günün çok kanaması "artış" sanılır — yanlış alarm.',
    );
  });

  test('lekelenmeden çok kanamaya dönüş', () {
    expect(
      degerlendir(seyir(['light', 'spotting', 'none', 'heavy'])),
      LochiaConcern.reIncrease,
    );
  });

  test('küçük dalgalanma alarm değil', () {
    // Lekelenmeden aza geçmek olağan bir dalgalanma; her artışta alarm
    // vermek kullanıcıyı uyarıya karşı duyarsızlaştırır.
    expect(
      degerlendir(seyir(['medium', 'light', 'spotting', 'light'])),
      LochiaConcern.none,
    );
  });

  test('azalmayarak artma', () {
    expect(
      degerlendir(seyir(['light', 'medium', 'heavy'])),
      LochiaConcern.rising,
    );
    // NHS: kanama azalmak yerine artarsa ebene haber ver — orta kademeye
    // tek bir artış da yeterli.
    expect(degerlendir(seyir(['light', 'medium'])), LochiaConcern.rising);
    expect(
      degerlendir(seyir(['medium', 'medium', 'heavy'])),
      LochiaConcern.rising,
    );
  });

  test('artış yoksa endişe yok — orta kanama sürse bile', () {
    expect(degerlendir(seyir(['medium', 'medium'])), LochiaConcern.none);
    expect(degerlendir(seyir(['heavy', 'medium'])), LochiaConcern.none);
  });

  test('tek kayıtla değerlendirme yok', () {
    expect(degerlendir(seyir(['heavy'])), LochiaConcern.none);
  });

  test('doğum günü kaydı sayılmıyor', () {
    // İlk 24 saat hastanede, izlem orada. O günün çok kanaması sonraki
    // azalmanın "başlangıcı" olarak bile alınmamalı ki bir sonraki günün
    // orta kanaması "yeniden artış" görünmesin.
    final l = [
      DailyLog(date: dogum, flowIntensity: 'spotting'),
      ...seyir(['medium']),
    ];
    expect(degerlendir(l), LochiaConcern.none);
  });

  test('doğumdan önceki kayıt yok sayılıyor', () {
    final l = [
      DailyLog(
        date: dogum.subtract(const Duration(days: 3)),
        flowIntensity: 'spotting',
      ),
      ...seyir(['heavy']),
    ];
    expect(degerlendir(l), LochiaConcern.none);
  });

  test('gelecek tarihli kayıt yok sayılıyor', () {
    // Saati yanlış bir cihaz ya da elle düzenlenmiş yedek: bugünden sonraki
    // bir "çok kanama" bugünkü seyri değerlendirmeye girmemeli.
    final l = [
      ...seyir(['spotting']),
      DailyLog(
        date: bugun.add(const Duration(days: 2)),
        flowIntensity: 'heavy',
      ),
    ];
    expect(degerlendir(l), LochiaConcern.none);
  });

  test('akış girilmemiş günler araya girmiyor', () {
    final l = [
      ...seyir(['medium', 'spotting']),
      DailyLog(date: dogum.add(const Duration(days: 3)), symptoms: const ['x']),
      DailyLog(
        date: dogum.add(const Duration(days: 4)),
        flowIntensity: 'medium',
      ),
    ];
    expect(degerlendir(l), LochiaConcern.reIncrease);
  });
}

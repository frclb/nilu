import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:period_tracker/data/repositories/cycle_settings_repository.dart';
import 'package:period_tracker/data/repositories/period_repository.dart';
import 'package:period_tracker/data/repositories/profile_repository.dart';
import 'package:period_tracker/localization/app_localizations.dart';
import 'package:period_tracker/domain/models/daily_log.dart';
import 'package:period_tracker/domain/models/period_log.dart';
import 'package:period_tracker/presentation/calendar/calendar_screen.dart';
import 'package:period_tracker/presentation/home/home_screen.dart';
import 'package:period_tracker/presentation/insights/insights_screen.dart';
import 'package:period_tracker/presentation/partner_match/partner_dashboard_screen.dart';
import 'package:period_tracker/presentation/profile/profile_settings_screen.dart';

import 'screen_harness.dart';

/// Veri **varken** ekranlar çiziliyor mu?
///
/// `every_screen_test` her ekranı boş depoyla çiziyor — yani yalnızca yeni
/// kurulmuş bir uygulamayı sınıyor. Geri dönen kullanıcının gördüğü ekran
/// başka: listeler doluyor, grafikler nokta kazanıyor, kartlar uzuyor. Bu
/// oturumda bulunan hataların ikisi (halka regl aralığı, döngü ayarları
/// çökmesi) yalnızca belirli veriyle ortaya çıkıyordu; boş depo ikisini de
/// görmüyordu.
///
/// Profiller kasten uçlarda: düzensiz döngüler, en uzun regl, bitmemiş regl.

/// Bir veri kurgusu.
class _Profile {
  final String name;
  final List<PeriodLog> periods;
  final List<DailyLog> daily;
  final int cycleLength;
  final int periodLength;

  const _Profile(
    this.name, {
    required this.periods,
    this.daily = const [],
    this.cycleLength = 28,
    this.periodLength = 5,
  });
}

/// Testin bugüne göre sabit kalması için tarihleri geriye doğru üretiyoruz.
DateTime _ago(int days) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day).subtract(Duration(days: days));
}

PeriodLog _log(String id, int startAgo, int? length) => PeriodLog(
  id: id,
  startDate: _ago(startAgo),
  endDate: length == null ? null : _ago(startAgo - (length - 1)),
);

/// Döngü başlangıçlarını verilen aralıklardan kuruyor.
List<PeriodLog> _cycles(List<int> gaps, {int periodLength = 5}) {
  final logs = <PeriodLog>[];
  var offset = 0;
  for (var i = 0; i < gaps.length; i++) {
    offset += gaps[i];
    logs.add(_log('c$i', offset, periodLength));
  }
  return logs;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(mockMissingPlatformChannels);

  final profiles = <_Profile>[
    // İlk döngüsünü yeni girmiş kullanıcı: ortalama hesaplayacak geçmiş yok.
    _Profile('tek döngü', periods: [_log('tek', 10, 5)]),

    // Geçmiş yokken döngü uzunluğu **ayardan** okunuyor. Varsayılan dışı bir
    // uzunlukla tek kayıt: ayarın ekrana ulaştığını yalnızca bu profil
    // sınayabiliyor — ötekilerde ortalama kayıtlardan hesaplandığı için
    // ayar hiç kullanılmıyor.
    _Profile(
      'tek döngü · uzun ayar',
      periods: [_log('uzun', 6, 5)],
      cycleLength: 35,
    ),

    // Düzenli geçmiş: beklenen durum.
    _Profile('düzenli 6 döngü', periods: _cycles([5, 28, 28, 28, 28, 28])),

    // Düzensiz: aralıklar 21 ile 45 arasında savruluyor. Eğilim grafiği ve
    // "döngün düzensiz" uyarısı burada devreye giriyor.
    _Profile(
      'düzensiz döngüler',
      periods: _cycles([3, 45, 21, 38, 24, 45, 21]),
      cycleLength: 45,
    ),

    // En uzun regl (ayarlardaki üst sınır).
    _Profile(
      'on günlük regl',
      periods: _cycles([8, 30, 30], periodLength: 10),
      periodLength: 10,
    ),

    // Süregelen regl: bitiş tarihi yok. Halka ve takvim bunu ayrı ele alıyor.
    _Profile(
      'süregelen regl',
      periods: [
        ..._cycles([30, 28, 28]),
        _log('acik', 2, null),
      ],
    ),

    // Bol semptom: en uzun içerik, taşma için en elverişli zemin.
    _Profile(
      'bol semptom',
      periods: _cycles([4, 28, 28, 28]),
      daily: [
        for (var i = 0; i < 40; i++)
          DailyLog(
            date: _ago(i),
            symptoms: const [
              'cramps',
              'headache',
              'bloating',
              'fatigue',
              'acne',
              'backache',
              'nausea',
              'breast_tenderness',
            ],
            moods: const ['happy', 'anxious', 'irritable', 'calm'],
            flowIntensity: i.isEven ? 'heavy' : 'light',
            notes: 'Uzun bir not: ' * 12,
          ),
      ],
    ),
  ];

  final screens = <String, Widget Function()>{
    'home': () => const HomeScreen(),
    'calendar': () => const CalendarScreen(),
    'insights': () => const InsightsScreen(),
    'profile_settings': () => const ProfileSettingsScreen(),
    'partner_dashboard': () => const PartnerDashboardScreen(),
  };

  for (final profile in profiles) {
    for (final screen in screens.entries) {
      for (final size in screenSizes.entries) {
        testWidgets('${profile.name} · ${screen.key} — ${size.key}', (
          tester,
        ) async {
          FlutterSecureStorage.setMockInitialValues({});
          SharedPreferences.setMockInitialValues({'onboarding_complete': true});

          // Döngü ayarları da **şifreli** depoda (bkz.
          // `SecureStore.sensitiveKeys`). Bunları `SharedPreferences`'a
          // yazıyordum ve uygulama oradan okumadığı için profillerin
          // uzunlukları hiç etki etmiyordu: "düzensiz döngüler" ile
          // "on günlük regl" profilleri aslında varsayılan ayarlarla
          // koşuyordu.
          await CycleSettingsRepository().saveCycleSettings(
            cycleLength: profile.cycleLength,
            periodLength: profile.periodLength,
          );

          // Veriyi deponun ham biçimini taklit etmek yerine repository
          // üzerinden yazıyoruz: serileştirme uygulamadaki ile aynı olsun.
          // Ad hassas veri: şifreli depoda tutuluyor. Önce bunu
          // `SharedPreferences`'a yazıyordum; uygulama oradan okumadığı için
          // adlı selamlama yolu hiç sınanmıyordu.
          await const ProfileRepository().save(name: 'Deniz');

          final repo = const PeriodRepository();
          await repo.savePeriodLogs(profile.periods);
          if (profile.daily.isNotEmpty) {
            await repo.saveDailyLogs(profile.daily);
          }

          final widget = screen.value();
          await pumpScreen(tester, widget, size: size.value);

          // Boş ağaçta `takeException` da null döner; ekranın gerçekten
          // çizildiğini önce doğrulamak gerekiyor.
          expect(
            find.byWidget(widget),
            findsOneWidget,
            reason: '${screen.key}: ekran çizilmedi — iddia boşa gider',
          );
          expect(
            tester.takeException(),
            isNull,
            reason:
                '${profile.name} · ${screen.key} · ${size.key}: düzen hatası',
          );

          // Verinin ekrana **ulaştığı**. Bu iddia olmadan tarama, veriyi
          // hiç okumayan bir ekranda da geçerdi: depo anahtarı değişse ya
          // da yükleme sessizce başarısız olsa 90 test yine yeşil kalır,
          // kullanıcı ise dolu bir kaydın üstünde "Henüz kayıt yok"
          // görürdü. Metinler ekranın kendi bağlamından okunuyor, böylece
          // kopya değiştiğinde test kırılmıyor.
          final context = tester.element(find.byWidget(widget));

          if (screen.key == 'home') {
            // Geçmiş yokken döngü uzunluğu **ayardan** geliyor; birden çok
            // kayıt varsa ortalama kayıtlardan hesaplandığı için ayarı
            // yalnızca burada doğrulayabiliyoruz. Bu iddia olmadan
            // profillerin `cycleLength` değeri hiçbir şeyi etkilemiyordu:
            // ayarları okumayı tamamen bozsam da tarama yeşil kalıyordu.
            if (profile.periods.length == 1) {
              expect(
                find.text(
                  context.tr(
                    'home_ring_cycle_length',
                    params: {'n': '${profile.cycleLength}'},
                  ),
                ),
                findsOneWidget,
                reason:
                    '${profile.name}: halka ${profile.cycleLength} günlük '
                    'döngü yazmalı — ayar ekrana ulaşmıyor',
              );
            }
            expect(
              find.text('Deniz'),
              findsOneWidget,
              reason:
                  'Profilde ad kayıtlı; ana ekran yine de nötr hitap '
                  'gösteriyor — ad ekrana ulaşmıyor',
            );
            expect(
              find.text(context.tr('home_headline_no_data')),
              findsNothing,
              reason:
                  '${profile.name}: kayıt varken ana ekran boş durum '
                  'gösteriyor — veri ekrana ulaşmıyor',
            );
          }

          if (screen.key == 'insights') {
            // En az iki regl başlangıcı varsa eğilim çizilebilir.
            if (profile.periods.length >= 2) {
              expect(
                find.text(context.tr('insights_trend_empty')),
                findsNothing,
                reason:
                    '${profile.name}: ${profile.periods.length} regl '
                    'başlangıcı var, eğilim yine de boş',
              );
            }
            // Belirti kaydı yalnızca bir profilde var; ötekilerde boş
            // durum **doğru** olan, o yüzden koşullu.
            if (profile.daily.isNotEmpty) {
              expect(
                find.text(context.tr('insights_symptoms_empty')),
                findsNothing,
                reason:
                    '${profile.name}: ${profile.daily.length} günlük kayıt '
                    'var, belirti analizi yine de boş',
              );
            }
          }
        });
      }
    }
  }
}

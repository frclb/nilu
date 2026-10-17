import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:period_tracker/data/repositories/conception_repository.dart';
import 'package:period_tracker/data/repositories/period_repository.dart';
import 'package:period_tracker/data/repositories/pregnancy_repository.dart';
import 'package:period_tracker/data/repositories/privacy_settings_repository.dart';
import 'package:period_tracker/domain/models/pregnancy.dart';
import 'package:period_tracker/localization/app_localizations.dart';
import 'package:period_tracker/main.dart' as app;
import 'package:period_tracker/presentation/appearance/appearance_screen.dart';
import 'package:period_tracker/presentation/calendar/view_models/calendar_view_model.dart';
import 'package:period_tracker/presentation/insights/prediction_info_screen.dart';
import 'package:period_tracker/presentation/log_entry/log_entry_screen.dart';
import 'package:period_tracker/presentation/onboarding_welcome/onboarding_goal_screen.dart';
import 'package:period_tracker/presentation/onboarding_welcome/onboarding_success_screen.dart';
import 'package:period_tracker/presentation/onboarding_welcome/onboarding_welcome_screen.dart';
import 'package:period_tracker/presentation/pregnancy/postpartum_home_screen.dart';
import 'package:period_tracker/presentation/profile/privacy_security_screen.dart';

/// Uçtan uca akışlar: gerçek uygulama, gerçek Anahtar Zinciri, gerçek iOS
/// kanalları.
///
/// Birim ve ekran testleri platform eklentilerini taklit ediyor; burada
/// hiçbiri taklit değil. Testler cihazdaki uygulama verisini **siler** —
/// yalnızca bu iş için ayrılmış bir simülatörde koşulmalı (bkz.
/// `TESTING.md`).
///
/// Çalıştırma:
///   `flutter test integration_test -d SIMÜLATÖR_KİMLİĞİ`
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Iska geçen dokunuş uyarı değil hata: yanlış yere dokunup sonraki adımda
  // anlamsız bir zaman aşımıyla düşmesin.
  WidgetController.hitTestWarningShouldBeFatal = true;

  /// Temiz kurulum: tercihler ve Anahtar Zinciri boş.
  Future<void> temizle() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await const FlutterSecureStorage().deleteAll();
  }

  /// Sabit sayıda kare: bazı ekranlarda süreğen animasyon var,
  /// `pumpAndSettle` zaman aşımına düşüyor.
  Future<void> bekle(WidgetTester tester, {int kare = 20}) async {
    for (var i = 0; i < kare; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  /// [bulucu] görünene kadar (en fazla [saniye]) bekler.
  Future<void> gorunene(
    WidgetTester tester,
    Finder bulucu, {
    int saniye = 15,
  }) async {
    for (var i = 0; i < saniye * 10; i++) {
      if (bulucu.evaluate().isNotEmpty) return;
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(bulucu, findsWidgets, reason: 'Zaman aşımı: $bulucu');
  }

  /// Öğeyi ekranın ortasına kaydırıp dokunur.
  ///
  /// `ensureVisible` öğeyi kaydırılabilir alanın en üstüne getiriyor; ana
  /// ekranda orası sabit başlığın altı ve dokunuş başlığa gidiyordu.
  Future<void> dokun(WidgetTester tester, Finder bulucu) async {
    await gorunene(tester, bulucu);
    final hedef = bulucu.first;
    if (Scrollable.maybeOf(tester.element(hedef)) != null) {
      unawaited(
        Scrollable.ensureVisible(tester.element(hedef), alignment: 0.5),
      );
      await bekle(tester, kare: 6);
    }
    // Sayfa geçişi sürerken öğe görünür ama dokunuş üstteki katmana gider;
    // gerçekten dokunulabilir olana kadar bekle.
    await gorunene(tester, hedef.hitTestable());
    await tester.tap(hedef.hitTestable().first);
    await bekle(tester);
  }

  /// O an ekrandaki dilde metin.
  String tr(WidgetTester tester, String key) =>
      tester.element(find.byType(Scaffold).last).tr(key);

  /// Geri düğmesi, cihazın dilinde.
  Future<void> geri(WidgetTester tester) async {
    final ctx = tester.element(find.byType(Scaffold).last);
    await dokun(
      tester,
      find.byTooltip(MaterialLocalizations.of(ctx).backButtonTooltip).last,
    );
  }

  /// Hatırlatıcı gerekçe kutusu çıktıysa "Şimdi değil": sistem izin
  /// istemine Flutter testinden dokunulamıyor.
  Future<void> izinKutusunuGec(WidgetTester tester) async {
    await bekle(tester, kare: 30);
    final later = find.text(tr(tester, 'reminder_permission_later'));
    if (later.evaluate().isNotEmpty) {
      await tester.tap(later.first);
      await bekle(tester);
    }
  }

  Future<void> uygulamayiAc(WidgetTester tester) async {
    await temizle();
    // Uygulama kendi hata yakalayıcısını kuruyor; test çerçevesininki geri
    // konmazsa hatalar teste ulaşmıyor ve çerçeve testi geçersiz sayıyor.
    final cerceve = FlutterError.onError;
    app.main();
    await bekle(tester, kare: 2);
    FlutterError.onError = cerceve;
    await gorunene(tester, find.byType(OnboardingWelcomeScreen));
    await dokun(tester, find.text(tr(tester, 'onboarding_skip')));
    await gorunene(tester, find.byType(OnboardingGoalScreen));
  }

  testWidgets('"Bebek istiyorum" kurulumu, tahmin açıklaması, kayıt, '
      'gizlilik ve sade simge', (tester) async {
    await uygulamayiAc(tester);

    // ── Kurulum: bebek istiyorum → yeni başlıyorum → döngü soruları ──
    await dokun(tester, find.byKey(const Key('onboarding_goal_ttc')));
    await dokun(tester, find.byKey(const Key('onboarding_ttc_now')));
    await dokun(tester, find.text(tr(tester, 'onb_continue')));
    await dokun(tester, find.text(tr(tester, 'onb_continue')));
    await dokun(tester, find.text(tr(tester, 'onb_finish_setup')));
    await gorunene(tester, find.byType(OnboardingSuccessScreen));
    expect(
      find.text(tr(tester, 'onboarding_success_desc_conception')),
      findsOneWidget,
    );
    await dokun(tester, find.text(tr(tester, 'onboarding_success_cta')));
    await izinKutusunuGec(tester);

    // Gerçek Anahtar Zinciri: kayıt ve niyet yazıldı.
    expect(await const PeriodRepository().getPeriodLogs(), hasLength(1));
    expect(await const ConceptionRepository().get(), isNotNull);

    // ── Tahmin aralığı ve açıklaması ──
    await dokun(tester, find.byKey(const Key('home_prediction_how')));
    await gorunene(tester, find.byType(PredictionInfoScreen));
    expect(find.byKey(const Key('prediction_info_next')), findsOneWidget);
    await geri(tester);

    // ── Kayıt: "+" → belirti → kaydet ──
    await dokun(tester, find.byKey(const Key('log_entry_fab')));
    await gorunene(tester, find.byType(LogEntryScreen));
    await dokun(tester, find.text(tr(tester, 'log_symptom_cramp')));
    await dokun(tester, find.text(tr(tester, 'log_save_button')));
    await bekle(tester, kare: 20);
    final takvim = tester
        .element(find.byType(Scaffold).first)
        .read<CalendarViewModel>();
    final bugun = DateTime.now();
    expect(
      takvim.getDailyLogForDate(bugun).symptoms,
      contains('cramp'),
      reason: 'Kayıt kaydedilmedi',
    );

    // ── Profil → Gizlilik: cinsel aktivite alanı ──
    await dokun(tester, find.text(tr(tester, 'nav_profile')));
    await dokun(tester, find.text(tr(tester, 'profile_privacy_security')));
    await gorunene(tester, find.byType(PrivacySecurityScreen));
    await dokun(tester, find.byKey(const Key('privacy_sexual_log')));
    expect(
      await const PrivacySettingsRepository().getSexualActivityLogging(),
      isTrue,
    );
    await geri(tester);

    // ── Görünüm → sade simge (gerçek iOS kanalı) ──
    await dokun(tester, find.text(tr(tester, 'appearance_title')));
    await gorunene(tester, find.byType(AppearanceScreen));
    await gorunene(tester, find.byKey(const Key('appearance_icon_section')));
    await dokun(tester, find.byKey(const Key('appearance_icon_neutral')));
    await bekle(tester, kare: 30);
    expect(
      find.text(tr(tester, 'appearance_icon_failed')),
      findsNothing,
      reason: 'iOS sade simgeyi kabul etmedi',
    );
    await dokun(tester, find.byKey(const Key('appearance_icon_standard')));
    await bekle(tester, kare: 30);
    expect(find.text(tr(tester, 'appearance_icon_failed')), findsNothing);
  });

  testWidgets('"Yakın zamanda doğum yaptım" kurulumu lohusa panosuna '
      'varıyor', (tester) async {
    await uygulamayiAc(tester);

    await dokun(tester, find.byKey(const Key('onboarding_goal_postpartum')));
    await dokun(tester, find.byKey(const Key('onboarding_birth_continue')));
    await gorunene(tester, find.byType(OnboardingSuccessScreen));
    await dokun(tester, find.text(tr(tester, 'onboarding_success_cta')));
    await izinKutusunuGec(tester);
    await gorunene(tester, find.byType(PostpartumHomeScreen));

    final g = (await const PregnancyRepository().getAll()).single;
    expect(g.outcome, PregnancyOutcome.birth);
    expect(await const PeriodRepository().getPeriodLogs(), isEmpty);
  });
}

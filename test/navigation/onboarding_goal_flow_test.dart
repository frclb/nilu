import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:period_tracker/core/navigation/app_router.dart';
import 'package:period_tracker/data/repositories/conception_repository.dart';
import 'package:period_tracker/data/repositories/cycle_settings_repository.dart';
import 'package:period_tracker/data/repositories/period_repository.dart';
import 'package:period_tracker/data/repositories/pregnancy_repository.dart';
import 'package:period_tracker/domain/models/life_stage.dart';
import 'package:period_tracker/domain/models/pregnancy.dart';
import 'package:period_tracker/domain/view_models/user_view_model.dart';
import 'package:period_tracker/localization/app_localizations.dart';
import 'package:period_tracker/presentation/onboarding_welcome/onboarding_birth_screen.dart';
import 'package:period_tracker/presentation/onboarding_welcome/onboarding_conception_screen.dart';
import 'package:period_tracker/presentation/onboarding_welcome/onboarding_goal_screen.dart';
import 'package:period_tracker/presentation/onboarding_welcome/onboarding_last_period_screen.dart';
import 'package:period_tracker/presentation/onboarding_welcome/onboarding_success_screen.dart';
import 'package:period_tracker/presentation/onboarding_welcome/onboarding_welcome_screen.dart';
import 'package:period_tracker/presentation/pregnancy/postpartum_home_screen.dart';
import 'package:period_tracker/presentation/pregnancy/pregnancy_home_screen.dart';
import 'package:period_tracker/presentation/pregnancy/pregnancy_setup_screen.dart';

import '../presentation/pregnancy_fixtures.dart';
import '../presentation/screen_harness.dart';

/// Kurulumda yol ayrımı.
///
/// Uygulamayı hamileyken indiren kullanıcı önce üç regl sorusundan geçip
/// sonra Profil'den gebeliğini işaretlemek zorundaydı. Artık tanıtımdan
/// sonra soruluyor: "Hamileyim" diyen regl sorularını görmeden gebelik
/// panosuna varıyor.
///
/// Uygulamanın **gerçek** yönlendiricisiyle: yeni adımlar onboarding
/// tamamlanmadan açılabilmeli (`preOnboardingPaths`), yoksa yönlendirme
/// kullanıcıyı sessizce karşılama ekranına geri atar.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(mockMissingPlatformChannels);
  setUp(() => resetStores(onboarded: false));

  late UserViewModel kullanici;

  Future<void> ac(WidgetTester tester) async {
    await tester.runAsync(() async {
      kullanici = UserViewModel();
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    await pumpRouter(
      tester,
      routes: const [],
      router: createAppRouter(kullanici),
      userViewModel: kullanici,
    );
    await settleAsync(tester, rounds: 6);
  }

  /// Çeviri, o an ağaçta olan bir iskeletten: ekranlar değiştikçe eski
  /// bağlam ağaçtan çıkıyor.
  String tr(WidgetTester tester, String key, {Map<String, String>? params}) =>
      tester.element(find.byType(Scaffold).last).tr(key, params: params);

  Future<void> dokun(WidgetTester tester, Finder f) async {
    await tester.ensureVisible(f);
    await tester.tap(f);
    await settleAsync(tester);
  }

  /// Karşılamadan hedef adımına: "Atla" tanıtım sayfalarını atlıyor, yol
  /// seçimini değil.
  Future<void> hedefeGit(WidgetTester tester) async {
    expect(find.byType(OnboardingWelcomeScreen), findsOneWidget);
    await dokun(tester, find.text(tr(tester, 'onboarding_skip')));
    expect(find.byType(OnboardingGoalScreen), findsOneWidget);
  }

  testWidgets('"Hamileyim": regl sorusu yok, gebelik panosuyla bitiyor; '
      'uydurma döngü verisi yazılmıyor', (tester) async {
    await ac(tester);
    await hedefeGit(tester);

    await dokun(tester, find.byKey(const Key('onboarding_goal_pregnancy')));
    expect(find.byType(OnboardingLastPeriodScreen), findsNothing);
    final kurulum = tester.widget<PregnancySetupScreen>(
      find.byType(PregnancySetupScreen),
    );
    expect(kurulum.fromOnboarding, isTrue);

    // Uygulama yeni: değişecek bir tahmin yok.
    final ekran = tester.element(find.byType(PregnancySetupScreen));
    expect(
      find.text(ekran.upper(tr(tester, 'preg_setup_good_to_know'))),
      findsOneWidget,
    );
    expect(
      find.text(tr(tester, 'preg_setup_change_predictions')),
      findsNothing,
    );
    expect(find.text(tr(tester, 'preg_setup_change_bleeding')), findsOneWidget);

    // Son adet tarihi: seçici bugünle açılıyor, onaylamak bugünü seçer.
    await tester.tap(find.byKey(const Key('preg_setup_pick_date')));
    await tester.pumpAndSettle();
    final tamam = MaterialLocalizations.of(
      tester.element(find.byType(PregnancySetupScreen)),
    ).okButtonLabel;
    await tester.tap(find.text(tamam));
    await tester.pumpAndSettle();

    // Döngüsü sorulmadı: hesap 28 günle ve ekran bunu varsayım diye söylüyor.
    expect(
      find.text(
        tr(tester, 'preg_setup_due_method_lmp_assumed', params: {'n': '28'}),
      ),
      findsOneWidget,
    );
    expect(
      find.text(tr(tester, 'preg_setup_due_method_lmp', params: {'n': '28'})),
      findsNothing,
      reason: 'Kullanıcının söylemediği 28 "senin döngün" diye sunuldu',
    );

    await dokun(tester, find.byKey(const Key('preg_setup_start')));
    expect(find.byType(OnboardingSuccessScreen), findsOneWidget);
    expect(
      find.text(tr(tester, 'onboarding_success_desc_pregnancy')),
      findsOneWidget,
    );
    expect(
      find.text(tr(tester, 'onboarding_success_desc')),
      findsNothing,
      reason: '"Döngün ayarlandı" — ayarlanan bir döngü yok',
    );
    expect(kullanici.onboardingComplete, isFalse, reason: 'Henüz son ekran');

    await dokun(tester, find.text(tr(tester, 'onboarding_success_cta')));
    expect(find.byType(PregnancyHomeScreen), findsOneWidget);
    expect(kullanici.onboardingComplete, isTrue);

    await tester.runAsync(() async {
      expect(await const PeriodRepository().getPeriodLogs(), isEmpty);
      expect(
        await const CycleSettingsRepository().hasCycleLength(),
        isFalse,
        reason: 'Sorulmayan döngü süresi kaydedildi',
      );
      expect(await const PregnancyRepository().getAll(), hasLength(1));
    });
  });

  testWidgets('"Döngümü takip etmek istiyorum": eskisi gibi regl soruları; '
      'geri dönülebiliyor', (tester) async {
    await ac(tester);
    await hedefeGit(tester);

    await dokun(tester, find.byKey(const Key('onboarding_goal_cycle')));
    expect(find.byType(OnboardingLastPeriodScreen), findsOneWidget);

    await dokun(tester, find.byIcon(Icons.arrow_back));
    expect(find.byType(OnboardingGoalScreen), findsOneWidget);

    await dokun(tester, find.byIcon(Icons.arrow_back));
    expect(find.byType(OnboardingWelcomeScreen), findsOneWidget);
  });

  testWidgets('gebelik zaten kayıtlıysa (yarıda kalan kurulum) tarih yeniden '
      'sorulmuyor', (tester) async {
    await seedPregnancy();
    await ac(tester);
    await hedefeGit(tester);

    await dokun(tester, find.byKey(const Key('onboarding_goal_pregnancy')));
    expect(
      find.byType(PregnancySetupScreen),
      findsNothing,
      reason: 'Girilecek tarihler yok sayılırdı: ikinci gebelik açılmıyor',
    );
    expect(find.byType(OnboardingSuccessScreen), findsOneWidget);

    await dokun(tester, find.text(tr(tester, 'onboarding_success_cta')));
    expect(find.byType(PregnancyHomeScreen), findsOneWidget);
    await tester.runAsync(() async {
      expect(await const PregnancyRepository().getAll(), hasLength(1));
    });
  });

  testWidgets('"Yakın zamanda doğum yaptım": gebelik ve regl sorusu yok, '
      'lohusa panosuyla bitiyor', (tester) async {
    await ac(tester);
    await hedefeGit(tester);

    await dokun(tester, find.byKey(const Key('onboarding_goal_postpartum')));
    expect(find.byType(OnboardingBirthScreen), findsOneWidget);
    expect(find.byType(PregnancySetupScreen), findsNothing);
    expect(find.byType(OnboardingLastPeriodScreen), findsNothing);

    // Seçim lohusalık süresiyle sınırlı: daha eski bir doğumla evre hiç
    // başlamazdı.
    final takvim = tester.widget<CalendarDatePicker>(
      find.byKey(const Key('onboarding_birth_calendar')),
    );
    final bugun = DateTime(today.year, today.month, today.day);
    expect(takvim.lastDate, bugun);
    expect(
      takvim.firstDate,
      DateTime(
        bugun.year,
        bugun.month,
        bugun.day - LifeStage.postpartumDays + 1,
      ),
    );

    await dokun(tester, find.byKey(const Key('onboarding_birth_continue')));
    expect(find.byType(OnboardingSuccessScreen), findsOneWidget);
    expect(
      find.text(tr(tester, 'onboarding_success_desc_postpartum')),
      findsOneWidget,
    );
    expect(find.text(tr(tester, 'onboarding_success_desc')), findsNothing);

    await dokun(tester, find.text(tr(tester, 'onboarding_success_cta')));
    expect(find.byType(PostpartumHomeScreen), findsOneWidget);
    expect(kullanici.onboardingComplete, isTrue);

    await tester.runAsync(() async {
      final g = (await const PregnancyRepository().getAll()).single;
      expect(g.outcome, PregnancyOutcome.birth);
      expect(g.endedAt, bugun);
      expect(await const PeriodRepository().getPeriodLogs(), isEmpty);
      expect(await const CycleSettingsRepository().hasCycleLength(), isFalse);
    });
  });

  testWidgets('"Bebek istiyorum" → "Yeni başlıyorum": niyet bugünle, sonra '
      'regl soruları; geri dönüp döngüyü seçince niyet kalkıyor', (
    tester,
  ) async {
    await ac(tester);
    await hedefeGit(tester);

    await dokun(tester, find.byKey(const Key('onboarding_goal_ttc')));
    expect(find.byType(OnboardingConceptionScreen), findsOneWidget);

    await dokun(tester, find.byKey(const Key('onboarding_ttc_now')));
    expect(find.byType(OnboardingLastPeriodScreen), findsOneWidget);
    await tester.runAsync(() async {
      expect(
        (await const ConceptionRepository().get())?.since,
        DateTime(today.year, today.month, today.day),
      );
    });

    // Geri: önce niyet ekranı, sonra hedef.
    await dokun(tester, find.byIcon(Icons.arrow_back));
    expect(find.byType(OnboardingConceptionScreen), findsOneWidget);
    await dokun(tester, find.byIcon(Icons.arrow_back));
    expect(find.byType(OnboardingGoalScreen), findsOneWidget);

    await dokun(tester, find.byKey(const Key('onboarding_goal_cycle')));
    expect(find.byType(OnboardingLastPeriodScreen), findsOneWidget);
    await tester.runAsync(() async {
      expect(
        await const ConceptionRepository().get(),
        isNull,
        reason: 'İstenmeyen folik asit hatırlatması kurulurdu',
      );
    });
  });

  testWidgets('"Bebek istiyorum" → "Bir süredir": seçilen tarih saklanıyor, '
      'kurulum döngüyle bitiyor', (tester) async {
    await ac(tester);
    await hedefeGit(tester);

    await dokun(tester, find.byKey(const Key('onboarding_goal_ttc')));
    await tester.tap(find.byKey(const Key('onboarding_ttc_since')));
    await tester.pumpAndSettle();

    // Takvim yerine elle giriş: tarih bugüne göre değişiyor.
    final baslangic = daysAgo(200);
    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();
    String iki(int n) => n.toString().padLeft(2, '0');
    await tester.enterText(
      find.byType(TextField),
      '${iki(baslangic.day)}.${iki(baslangic.month)}.${baslangic.year}',
    );
    final tamam = MaterialLocalizations.of(
      tester.element(find.byType(OnboardingConceptionScreen)),
    ).okButtonLabel;
    await tester.tap(find.text(tamam));
    await settleAsync(tester);

    expect(find.byType(OnboardingLastPeriodScreen), findsOneWidget);
    await tester.runAsync(() async {
      expect(
        (await const ConceptionRepository().get())?.since,
        DateTime(baslangic.year, baslangic.month, baslangic.day),
      );
    });

    // Döngü soruları: son regl (bugün), süre ve uzunluk varsayılanla.
    await dokun(tester, find.text(tr(tester, 'onb_continue')));
    await dokun(tester, find.text(tr(tester, 'onb_continue')));
    await dokun(tester, find.text(tr(tester, 'onb_finish_setup')));

    expect(find.byType(OnboardingSuccessScreen), findsOneWidget);
    expect(
      find.text(tr(tester, 'onboarding_success_desc_conception')),
      findsOneWidget,
    );
    await tester.runAsync(() async {
      expect(await const PeriodRepository().getPeriodLogs(), hasLength(1));
      expect(await const PregnancyRepository().getAll(), isEmpty);
    });
  });
}

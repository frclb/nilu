import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:period_tracker/data/repositories/period_repository.dart';
import 'package:period_tracker/design_system/app_flavor.dart';
import 'package:period_tracker/design_system/app_theme.dart';
import 'package:period_tracker/domain/models/daily_log.dart';
import 'package:period_tracker/domain/models/period_log.dart';
import 'package:period_tracker/domain/services/premium_gate.dart';
import 'package:period_tracker/domain/view_models/subscription_view_model.dart';
import 'package:period_tracker/localization/app_localizations.dart';
import 'package:period_tracker/presentation/calendar/view_models/calendar_view_model.dart';
import 'package:period_tracker/presentation/insights/widgets/cycle_trend_card.dart';
import 'package:period_tracker/presentation/insights/widgets/symptom_analysis_card.dart';

/// Premium kapısının **ekranda uygulandığı**.
///
/// `PremiumGate` kuralları ayrıca test ediliyor ama kuralı çağırmak
/// ekranların sorumluluğu. `PremiumGate.visibleCycles` çağrısı silinse
/// hiçbir test düşmezdi: ücretsiz kullanıcı bütün geçmişi görürdü.
/// Paywall'da satılan şey buydu.
///
/// Kritik yön ücretsiz taraf: ödemeyen kullanıcı ödenen içeriği
/// görmemeli.
class _Abone extends SubscriptionViewModel {
  _Abone({required this.premium});
  final bool premium;

  @override
  bool get isPremium => premium;

  @override
  bool get isLoading => false;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final sozluk =
      jsonDecode(File('lib/localization/tr.json').readAsStringSync())
          as Map<String, dynamic>;

  Future<void> kartiAc(
    WidgetTester tester,
    Widget kart, {
    required bool premium,
  }) async {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.runAsync(() async {
      // Altı tamamlanmış döngü: ücretsiz sınır (3) aşılsın.
      await const PeriodRepository().savePeriodLogs([
        for (var i = 0; i < 7; i++)
          PeriodLog(
            id: 'p$i',
            startDate: DateTime(2026, 1, 1).add(Duration(days: i * 28)),
            endDate: DateTime(2026, 1, 5).add(Duration(days: i * 28)),
          ),
      ]);
      // Belirti kaydı: evre kırılımı bölümü ancak veriyle çiziliyor.
      await const PeriodRepository().saveDailyLogs([
        for (var i = 0; i < 12; i++)
          DailyLog(
            date: DateTime(2026, 1, 2).add(Duration(days: i * 14)),
            symptoms: const ['cramp'],
          ),
      ]);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(AppFlavor.plum),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('tr')],
          locale: const Locale('tr'),
          home: Scaffold(
            body: SingleChildScrollView(
              child: MultiProvider(
                providers: [
                  ChangeNotifierProvider(create: (_) => CalendarViewModel()),
                  ChangeNotifierProvider<SubscriptionViewModel>(
                    create: (_) => _Abone(premium: premium),
                  ),
                ],
                child: kart,
              ),
            ),
          ),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 500));
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  /// Yer tutucular arasındaki **en uzun sabit parça**.
  ///
  /// Ön eki almak yetmiyordu: `insights_symptom_phase` metni `{symptom}`
  /// ile başlıyor, ön ek boş string çıkıyor ve `textContaining('')` her
  /// şeyi eşleştiriyordu — test boş yere geçerdi.
  String sabitParca(String key) {
    final parcalar = (sozluk[key] as String)
        .split(RegExp(r'\{[a-zA-Z]+\}'))
        .map((p) => p.trim())
        .where((p) => p.length > 3)
        .toList();
    expect(parcalar, isNotEmpty, reason: '$key yalnızca yer tutucudan oluşuyor');
    parcalar.sort((a, b) => b.length.compareTo(a.length));
    return parcalar.first;
  }

  group('döngü geçmişi', () {
    // Kartın alt başlığı kaç döngünün **gösterildiğini** yazıyor. Asıl
    // sınanması gereken bu: kilit uyarısı `historyIsTrimmed`ten geliyor,
    // grafiğin verisi ise `visibleCycles`tan. İlk yazışta yalnızca uyarı
    // sınanmıştı ve kırpmayı kaldırdığımda test geçmeye devam etti —
    // ücretsiz kullanıcı yedi döngüyü görüp üstüne "premium al" yazısı
    // okuyabilirdi.
    testWidgets('ücretsizde yalnızca son 3 döngü gösteriliyor', (tester) async {
      await kartiAc(tester, const CycleTrendCard(), premium: false);
      expect(
        find.text('Son ${PremiumGate.freeCycleHistory} döngü'),
        findsOneWidget,
        reason: 'ücretsiz kullanıcı sınırdan fazla döngü görüyor',
      );
    });

    testWidgets('premiumda tüm geçmiş gösteriliyor', (tester) async {
      await kartiAc(tester, const CycleTrendCard(), premium: true);
      // Yedi kayıttan altı tamamlanmış aralık çıkıyor.
      expect(find.text('Son 6 döngü'), findsOneWidget);
    });

    testWidgets('ücretsizde kilit uyarısı görünür', (tester) async {
      await kartiAc(tester, const CycleTrendCard(), premium: false);
      expect(
        find.textContaining(sabitParca('insights_history_locked')),
        findsOneWidget,
        reason: 'ücretsiz kullanıcıya geçmişin kırpıldığı söylenmiyor',
      );
    });

    testWidgets('premiumda kilit uyarısı yok', (tester) async {
      await kartiAc(tester, const CycleTrendCard(), premium: true);
      expect(
        find.textContaining(sabitParca('insights_history_locked')),
        findsNothing,
        reason: 'abone olan kullanıcıya hâlâ kilit gösteriliyor',
      );
    });
  });

  group('belirti–evre analizi', () {
    testWidgets('ücretsizde kilitli', (tester) async {
      await kartiAc(tester, const SymptomAnalysisCard(), premium: false);
      expect(
        find.text(sozluk['insights_phase_locked'] as String),
        findsOneWidget,
        reason: 'ücretsiz kullanıcıda evre kırılımı kilidi yok',
      );
      expect(
        find.textContaining(sabitParca('insights_symptom_phase')),
        findsNothing,
        reason: 'ücretsiz kullanıcı ödenen analizi görüyor',
      );
    });

    testWidgets('premiumda kilit kalkıyor', (tester) async {
      await kartiAc(tester, const SymptomAnalysisCard(), premium: true);
      expect(
        find.text(sozluk['insights_phase_locked'] as String),
        findsNothing,
        reason: 'abone olan kullanıcıya hâlâ kilit gösteriliyor',
      );
    });
  });

  test('paywall vaadi kuralın kendisinden besleniyor', () {
    expect(PremiumGate.freeCycleHistory, 3);
    // Metin sayıyı sabit yazmıyor, `{free}` ile kuraldan alıyor. Sabit
    // yazsaydı sınır değiştiğinde paywall eski sayıyı söylemeye devam
    // ederdi.
    expect(
      (sozluk['premium_feature_history_desc'] as String).contains('{free}'),
      isTrue,
      reason: 'paywall metni ücretsiz sınırı sabit yazıyor; kuralla ayrışır',
    );
  });
}

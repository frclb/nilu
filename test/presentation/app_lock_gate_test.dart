import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:period_tracker/domain/services/app_lock_service.dart';
import 'package:period_tracker/presentation/lock/app_lock_gate.dart';

/// Gerçek biyometri yerine sayaç: kaç kez doğrulama istendiğini görmek,
/// kilidin ne zaman devreye girdiğini anlamanın en doğrudan yolu.
class _FakeLockService extends AppLockService {
  _FakeLockService({
    required this.enabled,
    this.succeeds = true,
    this.manual = false,
  });

  final bool enabled;
  bool succeeds;

  /// true ise doğrulama [completeAuth] çağrılana kadar askıda kalır —
  /// gerçek hayatta sistem istemi ekranda dururken geçen süreyi temsil eder.
  final bool manual;

  int authenticateCalls = 0;
  Completer<bool>? _pending;

  /// Ekranda bir sistem istemi var mı. Gerçekte bunu servis kendi tutuyor;
  /// testte sahneyi kurabilmek için dışarıdan ayarlanıyor.
  bool promptActive = false;

  @override
  bool get isSystemPromptActive => promptActive;

  @override
  Future<bool> isEnabled() async => enabled;

  @override
  Future<bool> authenticate({required String reason}) {
    authenticateCalls++;
    if (!manual) return Future.value(succeeds);
    final completer = Completer<bool>();
    _pending = completer;
    return completer.future;
  }

  void completeAuth(bool result) => _pending!.complete(result);
}

/// İleri sarılabilir saat: tolerans süresi zamana bağlı, gerçek saatle
/// 30 saniyelik senaryo widget testinde hiç oluşmaz.
class _FakeClock {
  DateTime _now = DateTime(2026, 8, 18, 12);

  DateTime call() => _now;

  void advance(Duration by) => _now = _now.add(by);
}

/// Test uygulaması bilerek `AppLocalizations` **kullanmıyor**.
///
/// Sözlük varlık dosyasından asenkron yükleniyor; widget testinde bu yükleme
/// `pumpAndSettle` içinde tamamlanmıyor ve `MaterialApp` içeriğini hiç
/// kurmuyor — sınanan kapı da hiç oluşmuyordu. Delegate olmadığında
/// `context.tr` anahtarın kendisini döndürüyor, ki burada sınanan şey zaten
/// metin değil kilidin ne zaman devreye girdiği.
Widget _app(AppLockService service, {_FakeClock? clock}) => MaterialApp(
  home: const Scaffold(body: Text('gizli sağlık verisi')),
  builder: (context, child) => AppLockGate(
    service: service,
    clock: (clock ?? _FakeClock()).call,
    child: child ?? const SizedBox.shrink(),
  ),
);

/// Kilit ekranı başlığının lokalizasyon anahtarı.
const _lockTitle = 'lock_title';

void main() {
  // Yaşam döngüsü durumu test bağlayıcısında global: bir önceki test
  // uygulamayı "paused" bırakırsa sonraki testte kare üretilmez ve asenkron
  // akış hiç ilerlemez. Her test taze başlamalı.
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized()
        .handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  });

  Future<void> lifecycle(WidgetTester tester, AppLifecycleState state) async {
    tester.binding.handleAppLifecycleStateChanged(state);
    await tester.pump();
  }

  group('kilit kapalıyken', () {
    testWidgets('doğrulama istenmez', (tester) async {
      final service = _FakeLockService(enabled: false);
      await tester.pumpWidget(_app(service));
      await tester.pumpAndSettle();

      expect(service.authenticateCalls, 0);
      expect(find.text('gizli sağlık verisi'), findsOneWidget);
    });

    testWidgets('kilit ekranı hiç görünmez', (tester) async {
      // Regresyon: kilidi hiç açmamış kullanıcıya da her açılışta kilit
      // ekranı yanıp sönüyordu.
      final service = _FakeLockService(enabled: false);
      await tester.pumpWidget(_app(service));

      // Ayar okunurken içerik örtülü ama "Uygulama kilitli" yazmıyor.
      expect(find.text(_lockTitle), findsNothing);

      await tester.pumpAndSettle();
      expect(find.text(_lockTitle), findsNothing);
    });

    testWidgets('arka plandan dönüş kilit getirmez', (tester) async {
      final service = _FakeLockService(enabled: false);
      await tester.pumpWidget(_app(service));
      await tester.pumpAndSettle();

      await lifecycle(tester, AppLifecycleState.paused);
      await lifecycle(tester, AppLifecycleState.resumed);
      await tester.pumpAndSettle();

      expect(service.authenticateCalls, 0);
    });
  });

  group('kilit açıkken', () {
    testWidgets('açılışta bir kez doğrulama istenir', (tester) async {
      final service = _FakeLockService(enabled: true);
      await tester.pumpWidget(_app(service));
      await tester.pumpAndSettle();

      expect(service.authenticateCalls, 1);
      expect(find.text('gizli sağlık verisi'), findsOneWidget);
    });

    testWidgets('doğrulama başarısızsa içerik gösterilmez', (tester) async {
      final service = _FakeLockService(enabled: true, succeeds: false);
      await tester.pumpWidget(_app(service));
      await tester.pumpAndSettle();

      expect(find.text(_lockTitle), findsOneWidget);
    });

    testWidgets('kısa süreli arka plan yeniden doğrulama istemez', (
      tester,
    ) async {
      final service = _FakeLockService(enabled: true);
      await tester.pumpWidget(_app(service));
      await tester.pumpAndSettle();
      expect(service.authenticateCalls, 1);

      await lifecycle(tester, AppLifecycleState.paused);
      await lifecycle(tester, AppLifecycleState.resumed);
      await tester.pumpAndSettle();

      // Tolerans içinde: QR taramak için kameraya geçmek her seferinde
      // kilit getirseydi özellik kullanılamaz olurdu.
      expect(service.authenticateCalls, 1);
    });

    testWidgets('tolerans aşılırsa yeniden doğrulama istenir', (tester) async {
      final service = _FakeLockService(enabled: true);
      final clock = _FakeClock();
      await tester.pumpWidget(_app(service, clock: clock));
      await tester.pumpAndSettle();

      await lifecycle(tester, AppLifecycleState.paused);
      clock.advance(AppLockService.graceperiod + const Duration(seconds: 1));
      await lifecycle(tester, AppLifecycleState.resumed);
      await tester.pumpAndSettle();

      expect(service.authenticateCalls, 2);
    });

    testWidgets('kısa arka plandan sonraki inactive kilit getirmez', (
      tester,
    ) async {
      // Regresyon: tolerans içinde dönülünce arka plan damgası
      // temizlenmiyordu. Kullanıcı bir süre uygulamayı kullandıktan sonra
      // Denetim Merkezi'ni açıp kapatmak (yalnızca inactive → resumed)
      // eski damgayla karşılaştırılıp kilit getiriyordu.
      final service = _FakeLockService(enabled: true);
      final clock = _FakeClock();
      await tester.pumpWidget(_app(service, clock: clock));
      await tester.pumpAndSettle();

      // Kısa arka plan: tolerans içinde dönülüyor, kilit gelmiyor.
      await lifecycle(tester, AppLifecycleState.paused);
      clock.advance(const Duration(seconds: 5));
      await lifecycle(tester, AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(service.authenticateCalls, 1);

      // Kullanıcı bir süre uygulamayı kullanıyor.
      clock.advance(const Duration(minutes: 5));

      // Ardından yalnızca Denetim Merkezi açılıp kapanıyor: `paused` yok,
      // yani arka plana çıkılmadı. Kilit gelmemeli.
      await lifecycle(tester, AppLifecycleState.inactive);
      await lifecycle(tester, AppLifecycleState.resumed);
      await tester.pumpAndSettle();

      expect(
        service.authenticateCalls,
        1,
        reason: 'arka plana çıkılmadan kilit gelmemeli',
      );
    });

    testWidgets('ayar ekranındaki doğrulama kapıyı tetiklemez', (tester) async {
      // Regresyon: Gizlilik ekranındaki anahtar da sistem istemini açıyor.
      // İstem uygulamayı örttüğü için kapı bunu "arka plana çıkıldı" sayıp,
      // kullanıcı anahtarı değiştirir değiştirmez ikinci bir Face ID istemi
      // gösteriyordu.
      final service = _FakeLockService(enabled: true);
      final clock = _FakeClock();
      await tester.pumpWidget(_app(service, clock: clock));
      await tester.pumpAndSettle();
      expect(service.authenticateCalls, 1);

      // Ayar ekranı kendi doğrulamasını başlatıyor.
      service.promptActive = true;
      await lifecycle(tester, AppLifecycleState.hidden);
      clock.advance(const Duration(seconds: 40));
      service.promptActive = false;
      await lifecycle(tester, AppLifecycleState.resumed);
      await tester.pumpAndSettle();

      expect(
        service.authenticateCalls,
        1,
        reason: 'kapı, ayar ekranının istemini arka plan sanmamalı',
      );
    });

    testWidgets('doğrulama sırasındaki yaşam döngüsü ikinci istem açmaz', (
      tester,
    ) async {
      // Regresyon: Face ID istemi uygulamayı inactive/hidden yapıyor.
      // 'hidden' dalı arka plan damgası yazınca, doğrulama biter bitmez
      // ikinci bir istem tetiklenebiliyordu.
      final service = _FakeLockService(enabled: true, manual: true);
      final clock = _FakeClock();
      await tester.pumpWidget(_app(service, clock: clock));
      await tester.pump();

      // İstem ekranda: doğrulama henüz bitmedi.
      expect(service.authenticateCalls, 1);

      // Sistem istemi uygulamayı inactive/hidden yapar. Kullanıcı yüzünü
      // okutmakta gecikse bile bu "arka plana çıkıldı" sayılmamalı.
      await lifecycle(tester, AppLifecycleState.inactive);
      await lifecycle(tester, AppLifecycleState.hidden);
      clock.advance(const Duration(minutes: 2));
      await lifecycle(tester, AppLifecycleState.resumed);

      service.completeAuth(true);
      await tester.pumpAndSettle();

      expect(
        service.authenticateCalls,
        1,
        reason: 'istemin kendisi ikinci bir istem doğurmamalı',
      );
      expect(find.text('gizli sağlık verisi'), findsOneWidget);
    });
  });
}

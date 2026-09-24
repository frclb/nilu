import 'package:flutter_test/flutter_test.dart';
import 'package:period_tracker/data/datasources/ad_consent.dart';

/// Rıza akışının sahtesi.
///
/// Gerçek UMP'yi çağırmadan **sırayı** sınar: formun ne zaman çıktığı, kaç kez
/// tazelendiği, hata hâlinde ne olduğu. Kırılan yer burası.
class _FakePort implements ConsentPort {
  _FakePort({
    this.updateSucceeds = true,
    this.canRequestBeforeForm = false,
    this.canRequestAfterForm = true,
    this.optionsRequired = false,
  });

  final bool updateSucceeds;
  final bool canRequestBeforeForm;
  final bool canRequestAfterForm;
  final bool optionsRequired;

  int updates = 0;
  int forms = 0;
  int optionsOpened = 0;
  bool _formShown = false;

  @override
  Future<bool> requestUpdate() async {
    updates++;
    return updateSucceeds;
  }

  @override
  Future<bool> canRequestAds() async =>
      _formShown ? canRequestAfterForm : canRequestBeforeForm;

  @override
  Future<bool> privacyOptionsRequired() async => optionsRequired;

  @override
  Future<void> showFormIfRequired() async {
    forms++;
    _formShown = true;
  }

  @override
  Future<void> showPrivacyOptions() async => optionsOpened++;
}

void main() {
  tearDown(AdConsent.resetForTest);

  test('AEA dışında form hiç gösterilmez', () async {
    final port = _FakePort(canRequestBeforeForm: true);
    AdConsent.resetForTest(port);

    expect(await AdConsent.resolve(mayShowForm: true), isTrue);
    expect(
      port.forms,
      0,
      reason: 'rıza gerekmiyorken kullanıcıya bir şey çıkmamalı',
    );
  });

  test(
    'rıza gerekirken form gösterilmeye izin yoksa reklam istenmez',
    () async {
      final port = _FakePort();
      AdConsent.resetForTest(port);

      expect(await AdConsent.resolve(mayShowForm: false), isFalse);
      expect(port.forms, 0);
    },
  );

  test('form gösterilir ve kabul edilirse reklam istenebilir', () async {
    final port = _FakePort(canRequestAfterForm: true);
    AdConsent.resetForTest(port);

    expect(await AdConsent.resolve(mayShowForm: true), isTrue);
    expect(port.forms, 1);
  });

  test('form reddedilirse reklam istenmez', () async {
    final port = _FakePort(canRequestAfterForm: false);
    AdConsent.resetForTest(port);

    expect(await AdConsent.resolve(mayShowForm: true), isFalse);
    expect(port.forms, 1);
  });

  test('durum bir kez tazelenir', () async {
    final port = _FakePort(canRequestBeforeForm: true);
    AdConsent.resetForTest(port);

    await AdConsent.resolve(mayShowForm: false);
    await AdConsent.resolve(mayShowForm: false);
    await AdConsent.privacyOptionsRequired();

    expect(port.updates, 1);
  });

  test(
    'tazeleme başarısızsa önbelleğe alınmaz, sonraki çağrı yeniden dener',
    () async {
      final port = _FakePort(updateSucceeds: false, canRequestBeforeForm: true);
      AdConsent.resetForTest(port);

      await AdConsent.resolve(mayShowForm: false);
      await AdConsent.resolve(mayShowForm: false);

      expect(
        port.updates,
        2,
        reason: 'çevrimdışı açılan oturum, ağ gelince yeniden denemeli',
      );
    },
  );

  test('eşzamanlı çağrılar tek tazeleme yapar', () async {
    final port = _FakePort(canRequestBeforeForm: true);
    AdConsent.resetForTest(port);

    await Future.wait([
      AdConsent.resolve(mayShowForm: false),
      AdConsent.resolve(mayShowForm: false),
      AdConsent.resolve(mayShowForm: false),
    ]);

    expect(port.updates, 1);
  });

  test('tercih girişi yalnızca gerekliyken bildirilir', () async {
    AdConsent.resetForTest(_FakePort(optionsRequired: false));
    expect(await AdConsent.privacyOptionsRequired(), isFalse);

    AdConsent.resetForTest(_FakePort(optionsRequired: true));
    expect(await AdConsent.privacyOptionsRequired(), isTrue);
  });
}

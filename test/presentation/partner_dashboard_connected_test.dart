import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:period_tracker/data/datasources/remote/firestore_datasource.dart';
import 'package:period_tracker/domain/view_models/partner_view_model.dart';
import 'package:period_tracker/localization/app_localizations.dart';
import 'package:period_tracker/presentation/partner_match/partner_dashboard_screen.dart';

import 'screen_harness.dart';

/// Ağ yanıt vermeden partner panosu ne yazıyor?
///
/// `snapshots()` ilk anlık görüntüyü ağ turu bitince veriyor. O ana kadar akış
/// sessiz. Bu sahte kaynak o pencereyi sonsuza uzatıyor, böylece yavaş
/// bağlantıdaki eşleşmiş kullanıcının gördüğü ekran sınanabiliyor.
class _SessizKaynak extends FirestoreDataSource {
  @override
  Stream<DocumentSnapshot<Map<String, dynamic>>> intimacyStatusStream(
    String partnerUid,
  ) => StreamController<DocumentSnapshot<Map<String, dynamic>>>().stream;
}

/// Verilen anlık görüntüleri sırayla yayan kaynak.
class _YayinKaynagi extends FirestoreDataSource {
  _YayinKaynagi(this.kayitlar);

  final List<Map<String, dynamic>?> kayitlar;

  @override
  Stream<DocumentSnapshot<Map<String, dynamic>>> intimacyStatusStream(
    String partnerUid,
  ) => Stream.fromIterable(kayitlar.map(_Anlik.new));
}

// `DocumentSnapshot` mühürlü; sahtelemek için bilinçli olarak yok sayılıyor.
// `fake_cloud_firestore` paketi de aynısını yapıyor.
// ignore: subtype_of_sealed_class
/// `PartnerViewModel` anlık görüntüden yalnızca `exists` ve `data()` okuyor;
/// `noSuchMethod` geri kalan arayüzü karşılıyor.
class _Anlik implements DocumentSnapshot<Map<String, dynamic>> {
  _Anlik(this._veri);

  final Map<String, dynamic>? _veri;

  @override
  bool get exists => _veri != null;

  @override
  Map<String, dynamic>? data() => _veri;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Paylaşılmış bir durum kaydı.
Map<String, dynamic> _durum({
  required String desire,
  List<String> needs = const ['quality_time', 'physical_touch'],
  bool isShared = true,
  Duration age = Duration.zero,
}) => {
  'sexualDesire': desire,
  'affectionNeeds': needs,
  'isShared': isShared,
  'timestamp': DateTime.now().subtract(age).toIso8601String(),
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(mockMissingPlatformChannels);

  testWidgets('ağ sessizken eşleşmiş kullanıcıya "bağlantı yok" denmiyor', (
    tester,
  ) async {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({
      'onboarding_complete': true,
      'partnerId': 'partner-uuid-1',
      'hasPartner': true,
    });

    const screen = PartnerDashboardScreen();
    await pumpScreen(
      tester,
      screen,
      size: const Size(390, 844),
      partnerViewModel: PartnerViewModel(firestore: _SessizKaynak()),
    );

    final context = tester.element(find.byWidget(screen));

    expect(
      find.text(context.tr('pv_no_connection_title')),
      findsNothing,
      reason:
          'Kullanıcı eşleşmiş durumda. İlk anlık görüntü gecikirken ekran '
          '"Bağlantı Yok" deyip yeniden eşleşmeye davet ediyorsa, kullanıcı '
          'çalışan bağlantısını bozmaya yönlendirilmiş olur.',
    );
    expect(tester.takeException(), isNull);
  });

  // Durum geldiğinde panonun ana içeriği çiziliyor: durum kartı, öneriler ve
  // geçmiş listesi. Bunların hiçbiri daha önce hiçbir testte çizilmemişti —
  // pano yalnızca dönen çarkı gösterirken "geçiyor" sayılıyordu.
  for (final size in screenSizes.entries) {
    testWidgets('paylaşılan durum çiziliyor — ${size.key}', (tester) async {
      FlutterSecureStorage.setMockInitialValues({});
      SharedPreferences.setMockInitialValues({
        'onboarding_complete': true,
        'partnerId': 'partner-uuid-1',
        'hasPartner': true,
      });

      // Beş kayıt: geçmiş listesi üst sınırında çiziliyor.
      const screen = PartnerDashboardScreen();
      await pumpScreen(
        tester,
        screen,
        size: size.value,
        partnerViewModel: PartnerViewModel(
          firestore: _YayinKaynagi([
            for (var i = 5; i > 0; i--)
              _durum(desire: 'passionate', age: Duration(hours: i)),
          ]),
        ),
      );

      final context = tester.element(find.byWidget(screen));

      expect(
        find.text(context.tr('pv_no_connection_title')),
        findsNothing,
        reason: 'Eşleşmiş kullanıcıya bağlantı yok denmemeli',
      );
      expect(
        find.text(context.tr('pv_empty_title')),
        findsNothing,
        reason:
            'Partner durumunu paylaştı; pano yine de "Henüz Veri Yok" '
            'gösteriyorsa akıştan gelen kayıt ekrana ulaşmıyor',
      );
      expect(
        find.text(context.tr('pv_desire_passionate')),
        findsWidgets,
        reason: 'Paylaşılan durum kullanıcıya okunur biçimde yazılmalı',
      );
      expect(
        tester.takeException(),
        isNull,
        reason: '${size.key}: düzen hatası',
      );
    });
  }

  testWidgets('partner paylaşımı kapattığında ayrı metin gösteriliyor', (
    tester,
  ) async {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({
      'onboarding_complete': true,
      'partnerId': 'partner-uuid-1',
      'hasPartner': true,
    });

    const screen = PartnerDashboardScreen();
    await pumpScreen(
      tester,
      screen,
      size: const Size(390, 844),
      partnerViewModel: PartnerViewModel(
        firestore: _YayinKaynagi([
          _durum(desire: 'passionate', isShared: false),
        ]),
      ),
    );

    final context = tester.element(find.byWidget(screen));

    expect(
      find.text(context.tr('pv_sharing_disabled_title')),
      findsOneWidget,
      reason:
          'Paylaşımı kapatmak ile hiç veri göndermemek ayrı durumlar; '
          'kullanıcı hangisi olduğunu bilmeli',
    );
    expect(
      find.text(context.tr('pv_desire_passionate')),
      findsNothing,
      reason:
          'Paylaşım kapalıyken eski durum ekranda kalırsa partnerin '
          'gizlilik tercihi yok sayılmış olur',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('partner kimliği kullanıcıya gösterilmiyor', (tester) async {
    FlutterSecureStorage.setMockInitialValues({});
    // Gerçek bir Firebase anonim UID'si bu biçimde: 28 karakter, rastgele.
    const uid = 'k3Jd9QzLm2Xp7Rt4Vb8Nc1Ys6Ae0';
    SharedPreferences.setMockInitialValues({
      'onboarding_complete': true,
      'partnerId': uid,
      'hasPartner': true,
    });

    const screen = PartnerDashboardScreen();
    await pumpScreen(
      tester,
      screen,
      size: const Size(390, 844),
      partnerViewModel: PartnerViewModel(
        firestore: _YayinKaynagi([_durum(desire: 'passionate')]),
      ),
    );

    final context = tester.element(find.byWidget(screen));

    expect(
      find.textContaining(uid),
      findsNothing,
      reason:
          'Partnerin adı hiçbir yerde saklanmıyor ve yerine `partnerId` '
          'yazılıyordu: kullanıcı avatarın altında ham bir UID görüyor. Aynı '
          'hata uygulama çubuğu başlığında bulunup düzeltilmiş, başlık '
          'bloğunda kalmış (bkz. `_buildHeader`).',
    );
    expect(
      find.text(context.tr('partner_label')),
      findsWidgets,
      reason: 'Ad alanı eklenene kadar genel etiket kullanılmalı',
    );
    expect(tester.takeException(), isNull);
  });
}

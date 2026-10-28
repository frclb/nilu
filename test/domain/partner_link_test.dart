import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:period_tracker/data/datasources/remote/firebase_auth_datasource.dart';
import 'package:period_tracker/data/repositories/intimacy_repository.dart';
import 'package:period_tracker/data/repositories/pairing_repository.dart';
import 'package:period_tracker/data/repositories/share_settings_repository.dart';
import 'package:period_tracker/domain/services/intimacy_share_service.dart';
import 'package:period_tracker/domain/view_models/intimacy_view_model.dart';
import 'package:period_tracker/domain/view_models/partner_view_model.dart';
import 'package:period_tracker/domain/view_models/user_view_model.dart';

import '../support/fake_partner_remote.dart';

/// Partner bağlantısının sunucudaki karşılığı.
///
/// Önceden: onboarding herkes için anonim kimlik ve sunucu profili
/// açıyordu; ikinci partner onaylanınca ilki listede kalıyordu; erişimi
/// kaldırmak paylaşılmış durumu silmiyordu; partner tarafındaki "Bağlantıyı
/// Kes" sunucuda hiçbir şey değiştirmiyordu; paylaşım varsayılan açıktı ve
/// rıza sorulmuyordu; onay bekleyen partnerin dinleyicisi bir kez reddedilip
/// bir daha açılmıyordu.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakePartnerRemote remote;

  setUp(() {
    remote = FakePartnerRemote();
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.resetStatic();
  });

  /// Kayıtlı `myId` aynı zamanda giriş yapılmış hesabın uid'si: eşleşme
  /// hesap istiyor.
  Future<UserViewModel> kullanici(Map<String, Object> prefs) async {
    SharedPreferences.setMockInitialValues(prefs);
    final vm = UserViewModel(
      auth: _Hesap(prefs['myId'] as String?),
      firestore: remote,
      pairing: PairingRepository(remote: remote),
    );
    while (!vm.isLoaded) {
      await Future<void>.delayed(Duration.zero);
    }
    return vm;
  }

  group('kimlik ve onboarding', () {
    test('onboarding sunucuya hiçbir şey yazmıyor', () async {
      final vm = await kullanici({});
      await vm.completeOnboarding();
      expect(vm.onboardingComplete, isTrue);
      expect(remote.calls, isEmpty);
    });
  });

  group('hesap', () {
    test('hesap yoksa eşleşme kurulmuyor, sunucuya gidilmiyor', () async {
      final vm = await kullanici({});
      expect(vm.needsAccountForPairing, isTrue);
      expect(await vm.ensureMyId(), isNull);
      expect(
        await vm.requestPartnerAccess(token: 'TOK', ownerUid: 'sahip'),
        isFalse,
      );
      expect(await vm.approvePartnerRequest('yeni', token: 'TOK'), isFalse);
      expect(remote.calls, isEmpty);
      expect(vm.isPartner, isFalse);
      expect(vm.hasPartner, isFalse);
    });

    test('hesapla giriş yapılmışsa kimlik hesabın uid\'si', () async {
      final vm = await kullanici({'myId': 'sahip'});
      expect(vm.needsAccountForPairing, isFalse);
      expect(await vm.ensureMyId(), 'sahip');
    });
  });

  group('sahip', () {
    test(
      'onay tek partner: öncekinin erişimi ve paylaşılan durum gider',
      () async {
        final vm = await kullanici({
          'onboarding_complete': true,
          'myId': 'sahip',
          'partnerId': 'eski',
          'hasPartner': true,
        });
        remote.partners['sahip'] = ['eski'];
        remote.intimacy['sahip'] = {'sexualDesire': 'passionate'};
        remote.requests['TOK'] = {'yeni'};

        expect(await vm.approvePartnerRequest('yeni', token: 'TOK'), isTrue);
        expect(remote.partners['sahip'], ['yeni']);
        expect(
          remote.intimacy,
          isNot(contains('sahip')),
          reason: 'Yeni partner öncekine gönderilmiş durumu görmemeli',
        );
        expect(remote.requests['TOK'], isEmpty);
        expect(vm.partnerId, 'yeni');
        expect(vm.hasPartner, isTrue);
      },
    );

    test('sunucuya yazılamazsa onay sayılmıyor', () async {
      final vm = await kullanici({'myId': 'sahip'});
      remote.writesSucceed = false;
      expect(await vm.approvePartnerRequest('yeni', token: 'TOK'), isFalse);
      expect(vm.hasPartner, isFalse);
      expect(vm.partnerId, isNull);
    });

    test('erişimi kaldırmak durumu siliyor ve kodu yeniliyor', () async {
      final vm = await kullanici({
        'myId': 'sahip',
        'partnerId': 'partner',
        'hasPartner': true,
      });
      final eskiKod = await PairingRepository(
        remote: remote,
      ).currentToken('sahip');
      remote.partners['sahip'] = ['partner'];
      remote.intimacy['sahip'] = {'sexualDesire': 'passionate'};

      expect(await vm.removePartnerAccess(), isTrue);
      expect(remote.partners['sahip'], isEmpty);
      expect(remote.intimacy, isNot(contains('sahip')));
      expect(remote.tokens, isNot(contains(eskiKod)), reason: 'Eski QR');
      expect(remote.tokens.values, contains('sahip'));
      expect(vm.hasPartner, isFalse);
    });

    test('kaldırılamazsa bağlı kalıyor', () async {
      final vm = await kullanici({
        'myId': 'sahip',
        'partnerId': 'partner',
        'hasPartner': true,
      });
      remote.writesSucceed = false;
      expect(await vm.removePartnerAccess(), isFalse);
      expect(vm.hasPartner, isTrue);
    });
  });

  group('partner', () {
    test('istek gönderilemezse partner moduna geçilmiyor', () async {
      final vm = await kullanici({'myId': 'partner'});
      remote.writesSucceed = false;
      expect(
        await vm.requestPartnerAccess(token: 'TOK', ownerUid: 'sahip'),
        isFalse,
      );
      expect(vm.isPartner, isFalse);
      expect(vm.onboardingComplete, isFalse);
    });

    test(
      'ayrılmak sahibin listesinden çıkarıyor, isteği geri çekiyor',
      () async {
        final vm = await kullanici({'myId': 'partner'});
        expect(
          await vm.requestPartnerAccess(token: 'TOK', ownerUid: 'sahip'),
          isTrue,
        );
        expect(vm.isPartner, isTrue);
        expect(remote.requests['TOK'], {'partner'});
        remote.partners['sahip'] = ['partner'];

        expect(await vm.leavePartnerRole(), isTrue);
        expect(remote.partners['sahip'], isEmpty);
        expect(remote.requests['TOK'], isEmpty);
        expect(vm.isPartner, isFalse);
        expect(
          vm.onboardingComplete,
          isFalse,
          reason: 'Bu cihaz kendi takibi için hiç kurulmadı',
        );
      },
    );

    test('sunucuya ulaşılamazsa ayrılmış sayılmıyor', () async {
      final vm = await kullanici({
        'myId': 'partner',
        'isPartner': true,
        'partnerId': 'sahip',
        'hasPartner': true,
        'onboarding_complete': true,
      });
      remote.writesSucceed = false;
      expect(await vm.leavePartnerRole(), isFalse);
      expect(vm.isPartner, isTrue);
    });
  });

  group('paylaşım', () {
    Future<IntimacyViewModel> yakinlik({bool partner = true}) async {
      SharedPreferences.setMockInitialValues({});
      final vm = IntimacyViewModel(
        repository: const IntimacyRepository(),
        shareService: IntimacyShareService(firestore: remote),
        shareSettings: const ShareSettingsRepository(),
      );
      while (!vm.isLoaded) {
        await Future<void>.delayed(Duration.zero);
      }
      vm.init('sahip', hasPartner: partner);
      await vm.selectSexualDesire('passionate');
      return vm;
    }

    test('varsayılan kapalı: rıza yokken hiçbir şey gönderilmiyor', () async {
      final vm = await yakinlik();
      expect(vm.sharingOn, isFalse);
      await vm.manualShare();
      expect(vm.shareError, 'sharing_disabled');
      expect(remote.intimacy, isEmpty);
    });

    test('partner yokken gönderilmiyor', () async {
      final vm = await yakinlik(partner: false);
      await vm.startSharing();
      await vm.manualShare();
      expect(vm.shareError, 'no_partner');
      expect(remote.intimacy, isEmpty);
    });

    test('rızayla gönderiliyor; kapatınca sunucudan siliniyor', () async {
      final vm = await yakinlik();
      await vm.startSharing();
      expect(await const ShareSettingsRepository().consentedAt(), isNotNull);
      await vm.manualShare();
      expect(remote.intimacy['sahip']?['sexualDesire'], 'passionate');

      expect(await vm.stopSharing(), isTrue);
      expect(remote.intimacy, isEmpty);
      expect(await const ShareSettingsRepository().consentedAt(), isNull);
    });

    test('sunucu yazmazsa "gönderildi" denmiyor', () async {
      final vm = await yakinlik();
      await vm.startSharing();
      remote.writesSucceed = false;
      await vm.manualShare();
      expect(vm.shareError, 'share_failed');
      expect(vm.lastSharedAt, isNull);
    });

    test('silinemeyen durum sonraki açılışta yeniden siliniyor', () async {
      final vm = await yakinlik();
      await vm.startSharing();
      await vm.manualShare();
      remote.writesSucceed = false;
      expect(await vm.stopSharing(), isFalse);
      expect(remote.intimacy, contains('sahip'));

      remote.writesSucceed = true;
      final yeni = IntimacyViewModel(
        shareService: IntimacyShareService(firestore: remote),
      );
      while (!yeni.isLoaded) {
        await Future<void>.delayed(Duration.zero);
      }
      yeni.init('sahip', hasPartner: true);
      await pumpEventQueue();
      expect(remote.intimacy, isEmpty);
    });

    test('rıza yokken kuyruktaki durum gönderilmiyor', () async {
      // Eski sürümden kalmış kuyruk: paylaşım o zaman varsayılan açıktı ve
      // kuyruk ayara bakmadan gönderiliyordu.
      SharedPreferences.setMockInitialValues({});
      await const IntimacyRepository().saveOfflineQueue(
        '{"sexualDesire":"passionate","affectionNeeds":[],'
        '"timestamp":"2026-10-01T10:00:00.000","isShared":true}',
      );
      final yeni = IntimacyViewModel(
        shareService: IntimacyShareService(firestore: remote),
      );
      while (!yeni.isLoaded) {
        await Future<void>.delayed(Duration.zero);
      }
      yeni.init('sahip', hasPartner: true);
      await pumpEventQueue();
      expect(remote.calls, isNot(contains('updateIntimacyStatus')));
      expect(await const IntimacyRepository().getOfflineQueue(), isNull);
    });
  });

  group('partnerin dinleyicisi', () {
    test('sunucu yoksa abone olmuyor, bunu söylüyor', () {
      remote.available = false;
      final vm = PartnerViewModel(firestore: remote);
      vm.init('sahip');
      expect(vm.state, PartnerLinkState.unavailable);
      expect(vm.isLoaded, isTrue);
      expect(remote.subscriptions, 0);
    });

    test('onay beklerken reddedilince yeniden deniyor', () async {
      var deneme = 0;
      final denied = FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
      );
      remote.statusStream = (_) {
        deneme++;
        return deneme == 1
            ? Stream<DocumentSnapshot<Map<String, dynamic>>>.error(denied)
            : Stream.value(
                FakeSnapshot({
                  'sexualDesire': 'feel_closer',
                  'affectionNeeds': ['hug'],
                  'timestamp': Timestamp.now(),
                  'isShared': true,
                }),
              );
      };
      final vm = PartnerViewModel(
        firestore: remote,
        retryInterval: const Duration(milliseconds: 10),
      );
      vm.init('sahip');
      await pumpEventQueue();
      expect(vm.state, PartnerLinkState.awaitingApproval);
      expect(vm.hasData, isFalse);

      await Future<void>.delayed(const Duration(milliseconds: 30));
      await pumpEventQueue();
      expect(deneme, 2, reason: 'Onaydan sonra dinleyici yeniden açılmadı');
      expect(vm.state, PartnerLinkState.connected);
      expect(vm.currentStatus?.sexualDesire, 'feel_closer');
      vm.dispose();
    });
  });
}

/// Apple ya da Google ile giriş yapılmış (ya da yapılmamış) oturum.
class _Hesap extends FirebaseAuthDataSource {
  _Hesap(this.uid);

  final String? uid;

  @override
  String? get accountUid => uid;
}

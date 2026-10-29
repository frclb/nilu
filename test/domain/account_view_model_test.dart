import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:period_tracker/data/datasources/remote/account_auth.dart';
import 'package:period_tracker/domain/models/period_log.dart';
import 'package:period_tracker/domain/models/sync_snapshot.dart';
import 'package:period_tracker/domain/services/sync_engine.dart';
import 'package:period_tracker/domain/view_models/account_view_model.dart';

import '../support/fake_sync.dart';

/// Hesap ve eşitleme akışları: rıza olmadan hiçbir sağlık verisi gitmiyor,
/// rıza geri çekilince buluttaki kopya siliniyor, hesap silme yeniden
/// doğrulama olmadan hiçbir şeye dokunmuyor.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeAccountAuth auth;
  late FakeRemote bulut;
  late FakeDevice cihaz;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    auth = FakeAccountAuth();
    bulut = FakeRemote();
    cihaz = FakeDevice(
      SyncSnapshot(
        periodLogs: [
          PeriodLog(
            id: 'p1',
            startDate: DateTime(2026, 9, 1),
            endDate: DateTime(2026, 9, 5),
          ),
        ],
      ),
    );
  });

  Future<AccountViewModel> vm() async {
    final v = AccountViewModel(
      auth: auth,
      remote: bulut,
      local: cihaz,
      stateStore: cihaz,
      debounce: Duration.zero,
    );
    await pumpEventQueue();
    return v;
  }

  test('giriş tek başına hiçbir veri göndermiyor', () async {
    final v = await vm();
    final sonuc = await v.signIn(AccountProvider.apple);

    expect(sonuc.status, SignInStatus.signedIn);
    expect(v.isSignedIn, isTrue);
    expect(v.syncEnabled, isFalse, reason: 'Rıza alınmadı');
    v.scheduleSync(immediately: true);
    await pumpEventQueue();
    expect(bulut.uploads, 0);
  });

  test('rızayla eşitleme başlıyor ve kalıcı', () async {
    final v = await vm();
    await v.signIn(AccountProvider.google);
    expect(await v.enableSync(), SyncOutcome.uploaded);
    expect(bulut.uploads, 1);
    expect(v.lastSyncAt, isNotNull);

    final yeniden = await vm();
    expect(yeniden.syncEnabled, isTrue, reason: 'Rıza hesaba bağlı saklandı');
  });

  test('rıza hesaba bağlı: başka hesaba geçince eşitleme kapalı', () async {
    final v = await vm();
    await v.signIn(AccountProvider.google);
    await v.enableSync();
    await v.signOut();

    auth.nextUid = 'baska-hesap';
    await v.signIn(AccountProvider.apple);
    expect(v.syncEnabled, isFalse);
  });

  test('cihazdaki değişiklik bekleyip tek seferde yükleniyor', () async {
    final v = await vm();
    await v.signIn(AccountProvider.apple);
    await v.enableSync();

    cihaz.snapshot = SyncSnapshot(
      periodLogs: [
        ...cihaz.snapshot.periodLogs,
        PeriodLog(
          id: 'p2',
          startDate: DateTime(2026, 9, 29),
          endDate: DateTime(2026, 10, 2),
        ),
      ],
    );
    v.scheduleSync();
    v.scheduleSync();
    v.scheduleSync();
    await pumpEventQueue();
    expect(bulut.uploads, 2, reason: 'İlk yükleme + tek bir değişiklik');
  });

  test('değişiklik yoksa bildirim sunucuya gitmiyor', () async {
    final v = await vm();
    await v.signIn(AccountProvider.apple);
    await v.enableSync();
    final okuma = bulut.metaReads;

    v.scheduleSync();
    await pumpEventQueue();
    expect(bulut.metaReads, okuma, reason: 'Ekran bildirimi, veri aynı');

    v.scheduleSync(immediately: true);
    await pumpEventQueue();
    expect(bulut.metaReads, okuma + 1, reason: 'Öne gelince bulut soruluyor');
  });

  test('buluttan inince bellekteki kopyalar yenileniyor', () async {
    // Başka cihaz yüklemiş; bu cihaz boş.
    await bulut.upload('hesap-1', cihaz.snapshot.encode(), cihaz.snapshot.hash);
    cihaz.snapshot = SyncSnapshot();
    var yenilendi = 0;
    final v = await vm();
    v.onRemoteApplied = () async => yenilendi++;
    await v.signIn(AccountProvider.apple);

    expect(await v.enableSync(), SyncOutcome.downloaded);
    expect(yenilendi, 1);
    expect(cihaz.snapshot.periodLogs, hasLength(1));
  });

  test(
    'rızayı geri çekmek buluttaki kopyayı siliyor, cihazdakini değil',
    () async {
      final v = await vm();
      await v.signIn(AccountProvider.apple);
      await v.enableSync();

      expect(await v.disableSync(), isTrue);
      expect(bulut.data['hesap-1']!.$1.disabled, isTrue);
      expect(
        bulut.data['hesap-1']!.$2,
        isEmpty,
        reason: 'Sağlık verisi kalmadı',
      );
      expect(v.syncEnabled, isFalse);
      expect(cihaz.snapshot.periodLogs, hasLength(1));
    },
  );

  test('silinemezse "kapattım" denmiyor, eşitleme açık kalıyor', () async {
    final v = await vm();
    await v.signIn(AccountProvider.apple);
    await v.enableSync();
    bulut.offline = true;

    expect(await v.disableSync(), isFalse);
    expect(v.syncEnabled, isTrue);
  });

  test('başka cihazda kapatılınca bu cihaz da duruyor ve söylüyor', () async {
    final v = await vm();
    await v.signIn(AccountProvider.apple);
    await v.enableSync();
    await bulut.delete('hesap-1', keepDisabledMarker: true);

    expect(await v.syncNow(), SyncOutcome.disabledRemotely);
    expect(v.syncEnabled, isFalse);
    expect(v.stoppedRemotely, isTrue);
  });

  test('çevrimdışı: durum "başarısız", veri kaybı yok', () async {
    final v = await vm();
    await v.signIn(AccountProvider.apple);
    bulut.offline = true;
    await v.enableSync();
    expect(v.status, SyncStatus.failed);
    expect(cihaz.snapshot.periodLogs, hasLength(1));
  });

  test('çıkış: eşitleme durur, cihazdaki kayıtlar kalır', () async {
    final v = await vm();
    await v.signIn(AccountProvider.google);
    await v.enableSync();
    await v.signOut();

    expect(v.isSignedIn, isFalse);
    expect(v.syncEnabled, isFalse);
    expect(cihaz.snapshot.periodLogs, hasLength(1));
    expect(bulut.data.containsKey('hesap-1'), isTrue, reason: 'Kopya duruyor');
  });

  group('hesap silme', () {
    test('doğrulamadan vazgeçilirse hiçbir şey silinmiyor', () async {
      var kimlikSilindi = false;
      final v = await vm();
      v.deleteIdentityAndPartnerData = () async => kimlikSilindi = true;
      await v.signIn(AccountProvider.apple);
      await v.enableSync();
      auth.reauthOk = false;

      expect(await v.deleteAccount(), AccountDeleteResult.cancelled);
      expect(bulut.data.containsKey('hesap-1'), isTrue);
      expect(kimlikSilindi, isFalse);
      expect(v.isSignedIn, isTrue);
    });

    test('bulut kopyası, partner verisi ve kimlik siliniyor', () async {
      var kimlikSilindi = false;
      final v = await vm();
      v.deleteIdentityAndPartnerData = () async => kimlikSilindi = true;
      await v.signIn(AccountProvider.apple);
      await v.enableSync();

      expect(await v.deleteAccount(), AccountDeleteResult.deleted);
      expect(auth.reauthCalls, 1, reason: 'Apple jetonu iptali için');
      expect(bulut.data.containsKey('hesap-1'), isFalse);
      expect(kimlikSilindi, isTrue);
      expect(v.isSignedIn, isFalse);
      expect(cihaz.snapshot.periodLogs, hasLength(1), reason: 'Cihaz ayrı');
    });

    test('kimlik silinemezse başarı denmiyor', () async {
      final v = await vm();
      v.deleteIdentityAndPartnerData = () async => false;
      await v.signIn(AccountProvider.google);

      expect(await v.deleteAccount(), AccountDeleteResult.failed);
    });
  });

  group('e-posta', () {
    test(
      'giriş hesabı e-posta sağlayıcısıyla açıyor, veri göndermiyor',
      () async {
        final v = await vm();
        final sonuc = await v.signInWithEmail(
          'ada@ornek.com',
          'gizli-sifre',
          create: true,
          languageCode: 'tr',
        );

        expect(sonuc.status, SignInStatus.signedIn);
        expect(v.account?.provider, AccountProvider.email);
        expect(auth.emailSignIns.single.create, isTrue);
        expect(auth.emailSignIns.single.lang, 'tr');
        expect(v.syncEnabled, isFalse, reason: 'Rıza alınmadı');
        expect(bulut.uploads, 0);
      },
    );

    test('yanlış şifrede giriş yok, sebep dönüyor', () async {
      auth.nextEmailError = EmailAuthError.invalidCredential;
      final v = await vm();
      final sonuc = await v.signInWithEmail(
        'ada@ornek.com',
        'yanlis',
        create: false,
      );

      expect(sonuc.status, SignInStatus.failed);
      expect(sonuc.emailError, EmailAuthError.invalidCredential);
      expect(v.isSignedIn, isFalse);
    });

    test(
      'doğrulanmamış hesap kapıda; doğrulanınca kimlik tazeleniyor',
      () async {
        final v = await vm();
        var tazelendi = 0;
        v.onIdentityChanged = () async => tazelendi++;
        await v.signInWithEmail('ada@ornek.com', 'gizli-sifre', create: true);
        expect(v.needsEmailVerification, isTrue);
        tazelendi = 0;

        expect(await v.checkEmailVerified(), isFalse);
        expect(tazelendi, 0);

        auth.emailVerified = true;
        expect(await v.checkEmailVerified(), isTrue);
        expect(v.needsEmailVerification, isFalse);
        expect(tazelendi, 1, reason: 'yönlendirme doğrulama ekranından çıksın');
      },
    );

    test(
      'Firebase hazır olmadan gelen doğrulama kodu sonra uygulanıyor',
      () async {
        final v = await vm();
        await v.signInWithEmail('ada@ornek.com', 'gizli-sifre', create: true);
        // Bağlantı uygulamayı soğuk başlattı: Firebase henüz hazır değil.
        auth.available = false;
        expect(await v.applyEmailVerification('dogrulama-kodu'), isFalse);
        expect(auth.emailVerified, isFalse);

        auth.available = true;
        await v.refresh();
        expect(auth.emailVerified, isTrue);
        expect(v.needsEmailVerification, isFalse);
      },
    );

    test('şifre yenileme: geçersiz kod, sonra yeni şifreyle giriş', () async {
      final v = await vm();
      expect(
        await v.resetPassword('yok', email: 'ada@ornek.com', newPassword: 'x'),
        PasswordResetResult.invalidLink,
      );
      auth.resetCodes['k1'] = 'ada@ornek.com';
      expect(await v.checkPasswordResetCode('k1'), 'ada@ornek.com');
      expect(
        await v.resetPassword(
          'k1',
          email: 'ada@ornek.com',
          newPassword: 'yeni-gizli-sifre',
        ),
        PasswordResetResult.done,
      );
      expect(v.isSignedIn, isTrue);
      expect(auth.emailSignIns.last.password, 'yeni-gizli-sifre');
    });

    test('hesap silme şifreyi doğrulamaya veriyor', () async {
      final v = await vm();
      await v.signInWithEmail('ada@ornek.com', 'gizli-sifre', create: false);

      expect(
        await v.deleteAccount(password: 'gizli-sifre'),
        AccountDeleteResult.deleted,
      );
      expect(auth.reauthPassword, 'gizli-sifre');
      expect(v.isSignedIn, isFalse);
    });
  });

  test('Firebase yoksa giriş "kullanılamıyor" diyor', () async {
    auth.available = false;
    final v = await vm();
    expect(v.isAvailable, isFalse);
    expect(
      (await v.signIn(AccountProvider.apple)).status,
      SignInStatus.unavailable,
    );
  });
}

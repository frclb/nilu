import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:period_tracker/data/local/secure_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const store = SecureStore();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
  });

  group('tip dönüşümleri', () {
    test('String gidiş-dönüşü', () async {
      await store.setString('k', 'değer');
      expect(await store.getString('k'), 'değer');
    });

    test('int gidiş-dönüşü', () async {
      await store.setInt('k', 28);
      expect(await store.getInt('k'), 28);
    });

    test('bool gidiş-dönüşü', () async {
      await store.setBool('t', true);
      await store.setBool('f', false);
      expect(await store.getBool('t'), isTrue);
      expect(await store.getBool('f'), isFalse);
    });

    test('List<String> gidiş-dönüşü', () async {
      await store.setStringList('k', ['a', 'b', 'c']);
      expect(await store.getStringList('k'), ['a', 'b', 'c']);
    });

    test('boş liste korunur', () async {
      await store.setStringList('k', []);
      expect(await store.getStringList('k'), isEmpty);
    });

    test('JSON içeren string değerler bozulmadan saklanır', () async {
      const payload = '{"id":"1","startDate":"2026-01-01T00:00:00.000"}';
      await store.setStringList('k', [payload]);
      expect(await store.getStringList('k'), [payload]);
    });
  });

  group('eksik ve bozuk veri', () {
    test('olmayan anahtarlar null döner', () async {
      expect(await store.getString('yok'), isNull);
      expect(await store.getInt('yok'), isNull);
      expect(await store.getBool('yok'), isNull);
      expect(await store.getStringList('yok'), isNull);
    });

    test('sayıya çevrilemeyen değer null döner, exception atmaz', () async {
      await store.setString('k', 'sayı-değil');
      expect(await store.getInt('k'), isNull);
    });

    test('bozuk JSON listesi null döner, exception atmaz', () async {
      await store.setString('k', '{bozuk');
      expect(await store.getStringList('k'), isNull);
    });

    test('remove değeri siler', () async {
      await store.setString('k', 'v');
      await store.remove('k');
      expect(await store.getString('k'), isNull);
    });
  });

  group('SharedPreferences migration', () {
    test('her tipi taşır ve kaynaktan siler', () async {
      SharedPreferences.setMockInitialValues({
        'period_logs': <String>['{"id":"1"}'],
        'user_cycle_length': 30,
        'intimacy_auto_share': true,
        'intimacy_sexual_desire': 'passionate',
      });

      await store.migrateFromSharedPreferences(SecureStore.sensitiveKeys);

      expect(await store.getStringList('period_logs'), ['{"id":"1"}']);
      expect(await store.getInt('user_cycle_length'), 30);
      expect(await store.getBool('intimacy_auto_share'), isTrue);
      expect(await store.getString('intimacy_sexual_desire'), 'passionate');

      // Şifresiz kopya geride bırakılmamalı.
      final prefs = await SharedPreferences.getInstance();
      for (final key in SecureStore.sensitiveKeys) {
        expect(prefs.containsKey(key), isFalse, reason: '$key silinmeliydi');
      }
    });

    test('hassas olmayan anahtarlara dokunmaz', () async {
      SharedPreferences.setMockInitialValues({
        'onboarding_complete': true,
        'notif_period_reminders': false,
      });

      await store.migrateFromSharedPreferences(SecureStore.sensitiveKeys);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('onboarding_complete'), isTrue);
      expect(prefs.getBool('notif_period_reminders'), isFalse);
    });

    test('ikinci çağrıda tekrar çalışmaz', () async {
      SharedPreferences.setMockInitialValues({'user_cycle_length': 30});
      await store.migrateFromSharedPreferences(SecureStore.sensitiveKeys);

      // Migration sonrası kullanıcı ayarı değiştirmiş olsun.
      await store.setInt('user_cycle_length', 35);

      // Aynı anahtar SharedPreferences'a yeniden düşse bile üzerine yazmamalı.
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('user_cycle_length', 21);

      await store.migrateFromSharedPreferences(SecureStore.sensitiveKeys);

      expect(await store.getInt('user_cycle_length'), 35);
    });

    test('taşınacak veri yoksa sorunsuz tamamlanır', () async {
      await store.migrateFromSharedPreferences(SecureStore.sensitiveKeys);
      expect(await store.getString(SecureStore.migrationFlagKey), 'true');
    });
  });

  test('clearSensitiveData tüm hassas anahtarları siler', () async {
    await store.setStringList('period_logs', ['x']);
    await store.setInt('user_cycle_length', 30);
    await store.setString('intimacy_sexual_desire', 'passionate');

    await store.clearSensitiveData();

    for (final key in SecureStore.sensitiveKeys) {
      expect(await store.getString(key), isNull, reason: '$key silinmeliydi');
    }
  });

  group('yeniden kurulum', () {
    // iOS'ta Anahtar Zinciri uygulama silinince silinmiyor: yeniden kuran
    // kullanıcı eski regl ve gebelik kayıtlarını geri görüyordu.
    test('taze kurulumda eski şifreli kayıtlar siliniyor', () async {
      FlutterSecureStorage.setMockInitialValues({
        'period_logs': '["eski"]',
        'pregnancies': '["eski"]',
      });
      SharedPreferences.setMockInitialValues({});
      expect(await store.clearIfFreshInstall(), isTrue);
      expect(await store.getString('period_logs'), isNull);
      expect(await store.getString('pregnancies'), isNull);
    });

    test('güncellenen kurulumda (tercihler dolu) silinmiyor', () async {
      FlutterSecureStorage.setMockInitialValues({'period_logs': '["kayit"]'});
      SharedPreferences.setMockInitialValues({'onboarding_complete': true});
      expect(await store.clearIfFreshInstall(), isFalse);
      expect(await store.getString('period_logs'), '["kayit"]');
    });

    test('işaret konunca ikinci açılışta hiçbir şey silinmiyor', () async {
      SharedPreferences.setMockInitialValues({});
      expect(await store.clearIfFreshInstall(), isTrue);
      await store.setString('period_logs', '["yeni"]');
      expect(await store.clearIfFreshInstall(), isFalse);
      expect(await store.getString('period_logs'), '["yeni"]');
    });
  });
}

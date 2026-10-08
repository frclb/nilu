import 'package:flutter_test/flutter_test.dart';
import 'package:period_tracker/data/repositories/favorites_repository.dart';
import 'package:period_tracker/data/repositories/share_settings_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.resetStatic();
    SharedPreferences.setMockInitialValues({});
  });

  group('ShareSettingsRepository', () {
    const repo = ShareSettingsRepository();

    // Yakınlık durumu cinsel yaşamla ilgili özel nitelikli veri: paylaşım
    // varsayılan olarak kapalı ve ancak açık rızayla açılıyor.
    test('kayıt yokken kapalı', () async {
      expect((await repo.load()).intimacyStatus, isFalse);
      expect(await repo.consentedAt(), isNull);
    });

    test('rıza verilince açılıyor ve anı kaydediliyor', () async {
      final an = DateTime(2026, 10, 8, 9, 30);
      await repo.grantConsent(now: an);
      expect((await repo.load()).intimacyStatus, isTrue);
      expect(await repo.consentedAt(), an);
    });

    test('rıza geri alınınca kapalı kalıyor', () async {
      await repo.grantConsent();
      await repo.withdrawConsent();
      expect(
        (await const ShareSettingsRepository().load()).intimacyStatus,
        isFalse,
      );
      expect(await repo.consentedAt(), isNull);
    });

    test('rızasız eski "açık" kaydı kapalı okunuyor', () async {
      // Önceki sürümler paylaşımı varsayılan açık kaydediyordu; eski dört
      // anahtardan biri açık olan kullanıcı da açık sayılıyordu.
      SharedPreferences.setMockInitialValues({
        ShareSettingsRepository.intimacyKey: true,
        ShareSettingsRepository.legacyMoodKey: true,
      });
      expect((await repo.load()).intimacyStatus, isFalse);
    });
  });

  group('FavoritesRepository', () {
    const repo = FavoritesRepository();

    test('başlangıçta boştur', () async {
      expect(await repo.all(), isEmpty);
      expect(await repo.isFavorite('recipe_salmon_quinoa'), isFalse);
    });

    test('toggle ekler ve true döner', () async {
      expect(await repo.toggle('recipe_salmon_quinoa'), isTrue);
      expect(await repo.isFavorite('recipe_salmon_quinoa'), isTrue);
    });

    test('ikinci toggle kaldırır ve false döner', () async {
      await repo.toggle('yoga_gentle_flow');
      expect(await repo.toggle('yoga_gentle_flow'), isFalse);
      expect(await repo.isFavorite('yoga_gentle_flow'), isFalse);
    });

    test('favoriler kalıcıdır (ekran yeniden açılınca durur)', () async {
      await repo.toggle('exercise_light_flow');

      const freshRepo = FavoritesRepository();
      expect(await freshRepo.isFavorite('exercise_light_flow'), isTrue);
    });

    test('birden çok içerik bağımsız tutulur', () async {
      await repo.toggle('recipe_salmon_quinoa');
      await repo.toggle('yoga_gentle_flow');

      expect(await repo.all(), {'recipe_salmon_quinoa', 'yoga_gentle_flow'});

      await repo.toggle('yoga_gentle_flow');
      expect(await repo.all(), {'recipe_salmon_quinoa'});
    });

    test('clear tümünü siler', () async {
      await repo.toggle('a');
      await repo.toggle('b');
      await repo.clear();
      expect(await repo.all(), isEmpty);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:period_tracker/data/repositories/favorites_repository.dart';
import 'package:period_tracker/data/repositories/share_settings_repository.dart';
import 'package:period_tracker/domain/models/share_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.resetStatic();
    SharedPreferences.setMockInitialValues({});
  });

  group('ShareSettingsRepository', () {
    const repo = ShareSettingsRepository();

    test('kayıt yokken varsayılan açık', () async {
      expect((await repo.load()).intimacyStatus, isTrue);
    });

    test('kapatılan ayar kapalı kalır', () async {
      await repo.save(ShareSettings.none);

      // Yeni bir repository örneği = ekranın yeniden açılması.
      const freshRepo = ShareSettingsRepository();
      final loaded = await freshRepo.load();

      expect(loaded.intimacyStatus, isFalse);
      expect(loaded.sharesAnything, isFalse);
    });

    group('eski dört anahtardan göç', () {
      // Eskiden faz/semptom/ruh hali/tahmin diye dört anahtar vardı ve
      // hiçbiri tek başına bir şey kontrol etmiyordu; paylaşımı durduran
      // şey dördünün birden kapalı olmasıydı. Yeni tek anahtar o toplamı
      // devralıyor.

      Future<bool> migrate(Map<String, Object> stored) async {
        SharedPreferences.resetStatic();
        SharedPreferences.setMockInitialValues(stored);
        return (await const ShareSettingsRepository().load()).intimacyStatus;
      }

      test('dördü de kapalıysa kapalı kalıyor', () async {
        // Asıl önemli hâl: paylaşımı bilerek durdurmuş kullanıcının
        // ayarı sessizce geri açılmamalı.
        expect(
          await migrate({
            ShareSettingsRepository.legacyPhaseInfoKey: false,
            ShareSettingsRepository.legacySymptomDetailsKey: false,
            ShareSettingsRepository.legacyMoodKey: false,
            ShareSettingsRepository.legacyPredictionsKey: false,
          }),
          isFalse,
        );
      });

      test('biri bile açıksa açık geliyor', () async {
        expect(
          await migrate({
            ShareSettingsRepository.legacyPhaseInfoKey: false,
            ShareSettingsRepository.legacySymptomDetailsKey: false,
            ShareSettingsRepository.legacyMoodKey: true,
            ShareSettingsRepository.legacyPredictionsKey: false,
          }),
          isTrue,
        );
      });

      test('yeni anahtar varsa eskiler okunmuyor', () async {
        expect(
          await migrate({
            ShareSettingsRepository.intimacyKey: false,
            ShareSettingsRepository.legacyPhaseInfoKey: true,
          }),
          isFalse,
        );
      });
    });

    test('copyWith değeri değiştirir', () {
      expect(
        const ShareSettings().copyWith(intimacyStatus: false).sharesAnything,
        isFalse,
      );
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

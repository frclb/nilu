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

    test('kayıt yokken varsayılanları döner', () async {
      final settings = await repo.load();
      expect(settings.phaseInfo, isTrue);
      expect(settings.symptomDetails, isTrue);
      expect(settings.mood, isFalse);
      expect(settings.predictions, isTrue);
    });

    test('kaydedilen ayarlar geri okunur', () async {
      // Kullanıcı semptom paylaşımını kapatıyor.
      await repo.save(
        const ShareSettings(
          phaseInfo: true,
          symptomDetails: false,
          mood: true,
          predictions: false,
        ),
      );

      final loaded = await repo.load();
      expect(
        loaded.symptomDetails,
        isFalse,
        reason: 'kapatılan alan kapalı kalmalı',
      );
      expect(loaded.mood, isTrue);
      expect(loaded.predictions, isFalse);
    });

    test('ekrandan çıkıp dönünce ayar korunur', () async {
      await repo.save(ShareSettings.none);

      // Yeni bir repository örneği = ekranın yeniden açılması.
      const freshRepo = ShareSettingsRepository();
      final loaded = await freshRepo.load();

      expect(loaded.sharesAnything, isFalse);
    });

    test('sharesAnything en az bir alan açıkken true olur', () {
      expect(ShareSettings.none.sharesAnything, isFalse);
      expect(
        const ShareSettings(
          phaseInfo: false,
          symptomDetails: false,
          mood: true,
          predictions: false,
        ).sharesAnything,
        isTrue,
      );
    });

    test('copyWith yalnızca verilen alanı değiştirir', () {
      const base = ShareSettings();
      final next = base.copyWith(mood: true);

      expect(next.mood, isTrue);
      expect(next.phaseInfo, base.phaseInfo);
      expect(next.symptomDetails, base.symptomDetails);
      expect(next.predictions, base.predictions);
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

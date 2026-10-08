import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:period_tracker/domain/view_models/user_view_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// `_loadState()` asenkron olduğu için hazır olmasını bekler.
Future<UserViewModel> ready() async {
  final vm = UserViewModel();
  while (!vm.isLoaded) {
    await Future<void>.delayed(Duration.zero);
  }
  return vm;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    // Örnek testler arasında önbellekte kalıyor; sıfırlamazsak bir sonraki
    // testin setMockInitialValues çağrısı hiç okunmaz.
    SharedPreferences.resetStatic();
    SharedPreferences.setMockInitialValues({});
  });

  group('yükleme durumu', () {
    test('kurulduğunda isLoaded false, okuma bitince true olur', () async {
      final vm = UserViewModel();
      expect(
        vm.isLoaded,
        isFalse,
        reason: 'router bu aşamada yönlendirme yapmamalı',
      );

      while (!vm.isLoaded) {
        await Future<void>.delayed(Duration.zero);
      }
      expect(vm.isLoaded, isTrue);
    });

    test('dönen kullanıcının onboarding durumu okunur', () async {
      SharedPreferences.resetStatic();
      SharedPreferences.setMockInitialValues({'onboarding_complete': true});
      final vm = await ready();
      expect(vm.onboardingComplete, isTrue);
    });
  });

  group('markOnboardingComplete', () {
    test('hem belleği hem depoyu günceller', () async {
      final vm = await ready();
      expect(vm.onboardingComplete, isFalse);

      await vm.markOnboardingComplete();

      expect(vm.onboardingComplete, isTrue, reason: 'bellek içi durum');
      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getBool('onboarding_complete'),
        isTrue,
        reason: 'kalıcı depo',
      );
    });

    test('dinleyicileri bilgilendirir (router yönlendirmeyi görsün)', () async {
      final vm = await ready();
      var notified = 0;
      vm.addListener(() => notified++);

      await vm.markOnboardingComplete();
      expect(notified, greaterThan(0));
    });
  });

  group('ensureMyId', () {
    test('Firebase yokken yerel kimlik üretir ve saklar', () async {
      final vm = await ready();
      final id = await vm.ensureMyId();

      expect(id, isNotEmpty);
      expect(vm.myId, id);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('myId'), id);
    });

    test('ikinci çağrı aynı kimliği döner', () async {
      final vm = await ready();
      expect(await vm.ensureMyId(), await vm.ensureMyId());
    });
  });
}

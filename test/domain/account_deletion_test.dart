import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Hesap silindiğinde geriye ne kalıyor?
///
/// Gizlilik politikası "hesabınızı sildiğinizde tüm verileriniz kalıcı
/// olarak kaldırılır" diyor. Bu bir söz; tutulmadığında yalnızca bir
/// arayüz kusuru değil, yanlış beyan oluyor.
///
/// Eşleşme kodu tam olarak böyle unutulmuştu: `PairingRepository.revoke()`
/// silme akışı için yazılmış, dokümanına "(hesap silme akışında)" bile
/// yazılmış ama hiçbir yerden çağrılmıyordu. Sunucuda jeton→uid eşlemesi
/// duruyordu.
void main() {
  String source(String path) => File(path).readAsStringSync();

  group('silme akışı her kaynağa dokunuyor', () {
    final deletion = source('lib/domain/view_models/user_view_model.dart');

    test('eşleşme kodu iptal ediliyor', () {
      expect(
        deletion.contains('_pairing.revoke()'),
        isTrue,
        reason: 'jeton→uid eşlemesi sunucuda kalıyor',
      );
    });

    test('uzak kullanıcı verisi siliniyor', () {
      expect(deletion.contains('deleteUserData'), isTrue);
    });

    test('abonelik oturumu kapatılıyor', () {
      expect(deletion.contains('SubscriptionService.logout'), isTrue);
    });

    test('kimlik siliniyor', () {
      expect(deletion.contains('_authDS.deleteAccount()'), isTrue);
    });
  });

  group('iptal edilebilir kaynaklar bağlı', () {
    test('PairingRepository.revoke ölü kod değil', () {
      // Yazılmış ama çağrılmayan bir temizleme yordamı, hiç yazılmamış
      // olmasından kötü: okuyan kişi işin yapıldığını sanıyor.
      final callers = Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .where((f) => !f.path.endsWith('pairing_repository.dart'))
          .where((f) => f.readAsStringSync().contains('.revoke()'));

      expect(callers, isNotEmpty);
    });
  });
}

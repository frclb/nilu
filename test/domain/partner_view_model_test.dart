import 'package:flutter_test/flutter_test.dart';

import 'package:period_tracker/domain/view_models/partner_view_model.dart';

/// Partner panosunun yükleme durumu.
///
/// Pano `isLoaded` false iken dönen bir çark gösteriyor. Firebase
/// yapılandırılmamışken `intimacyStatusStream` **boş** bir akış döndürüyor:
/// hiç veri vermeden kapanıyor, yani ne `onData` ne `onError` çalışıyor.
/// `onDone` ele alınmadığı için `isLoaded` hiç `true` olmuyordu ve partner
/// modunun ana ekranı sonsuza kadar dönüyordu.
///
/// Test ortamında Firebase başlatılmamış olduğu için akış gerçekten boş
/// dönüyor — hatanın koştuğu yolun aynısı.
void main() {
  test('partner kimliği yokken hemen yüklenmiş sayılır', () {
    final vm = PartnerViewModel();

    vm.init(null);

    expect(vm.isLoaded, isTrue);
    expect(vm.isConnected, isFalse);
  });

  test('boş akış kapanınca yükleme biter', () async {
    final vm = PartnerViewModel();

    vm.init('test-partner-uid');
    expect(vm.isConnected, isTrue);

    // Akışın kapanması bir sonraki olay döngüsünde bildirilir.
    await Future<void>.delayed(Duration.zero);

    expect(
      vm.isLoaded,
      isTrue,
      reason: 'veri gelmese bile pano çarkta asılı kalmamalı',
    );
    expect(vm.hasData, isFalse);
  });
}

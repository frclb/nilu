import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:period_tracker/data/datasources/remote/firestore_datasource.dart';
import 'package:period_tracker/domain/view_models/partner_view_model.dart';

/// Firebase yapılandırıldığında `snapshots()` **canlı** bir akış: ilk anlık
/// görüntü ağ turu tamamlanana kadar gelmiyor, yani `onData`, `onError` ve
/// `onDone` üçü de sessiz kalıyor. Bu sahte kaynak tam o durumu kuruyor.
class _SessizKaynak extends FirestoreDataSource {
  int aboneSayisi = 0;

  @override
  Stream<DocumentSnapshot<Map<String, dynamic>>> intimacyStatusStream(
    String partnerUid,
  ) {
    aboneSayisi++;
    // Hiç veri vermeyen, kapanmayan akış.
    return StreamController<DocumentSnapshot<Map<String, dynamic>>>().stream;
  }
}

void main() {
  test('eşleşmiş kimlikle init dinleyicileri uyarır', () {
    final kaynak = _SessizKaynak();
    final vm = PartnerViewModel(firestore: kaynak);
    var uyari = 0;
    vm.addListener(() => uyari++);

    vm.init('partner-1');

    expect(vm.isConnected, isTrue);
    expect(
      uyari,
      greaterThan(0),
      reason:
          'Bağlantı kuruldu ama kimseye söylenmedi. Ekran `isConnected` '
          'değerini `watch` ile okuyor; haber verilmeyince ilk anlık görüntü '
          'gelene kadar eşleşmiş kullanıcıya "Henüz bir partner bağlantısı '
          'kurulmadı" yazıp yeniden davet etmesini öneriyor.',
    );
  });

  test('aynı kimlikle yeniden init yeni abonelik açmaz', () {
    final kaynak = _SessizKaynak();
    final vm = PartnerViewModel(firestore: kaynak);

    // `ChangeNotifierProxyProvider.update` her yeniden çizimde `init`
    // çağırıyor — yani bu üç çağrı uygulamada olağan.
    vm.init('partner-1');
    vm.init('partner-1');
    vm.init('partner-1');

    expect(
      kaynak.aboneSayisi,
      1,
      reason:
          'Her çizimde abonelik kapatılıp yeniden açılıyor. Firestore her '
          'yeni dinleyici için okuma faturalandırıyor ve ilk anlık görüntü '
          'beklemesi de baştan başlıyor.',
    );
  });

  test('kimlik değişirse yeniden abone olur', () {
    final kaynak = _SessizKaynak();
    final vm = PartnerViewModel(firestore: kaynak);

    vm.init('partner-1');
    vm.init('partner-2');

    expect(kaynak.aboneSayisi, 2, reason: 'Yeni partner dinlenmeliydi');
  });
}

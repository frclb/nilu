import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:period_tracker/domain/services/subscription_service.dart';

/// Yapılandırılmamış RevenueCat'e sormak uygulamayı **çökertiyor**.
///
/// PurchasesHybridCommon Swift tarafında `fatalError` atıyor; Dart'taki
/// `try/catch` ona dokunamıyor. Açılışta SDK'lar ilk kareden sonraya alınınca
/// uygulama gerçek cihazda tam da böyle çöktü:
///
///     PurchasesHybridCommon/CommonFunctionality.swift:21: Fatal error:
///     Purchases has not been configured.
///
/// Bu yüzden her giriş noktası önce `_configured` bayrağına bakmak zorunda.
/// Dart testinde eklenti yok, yani çökme burada üretilemiyor — kural kaynak
/// üzerinden doğrulanıyor. Yeni bir metot eklendiğinde korumayı unutmak
/// sessizce çökmeye dönerdi.
void main() {
  test('yapılandırma bitmeden hiçbir şey premium demiyor', () {
    expect(SubscriptionService.isConfigured, isFalse);
  });

  test('her giriş noktası yapılandırma korumasıyla başlıyor', () {
    final source = File(
      'lib/domain/services/subscription_service.dart',
    ).readAsStringSync();

    // `init` ve `ready` hariç: biri yapılandırmayı **yapan**, diğeri
    // yalnızca onu bekleyen.
    const exempt = {'init', 'ready'};

    final methods = RegExp(
      r'static (?:Future<[^>]*>|void|bool) (?:get )?(\w+)\([^)]*\)[^{]*\{([^}]*)',
      dotAll: true,
    ).allMatches(source);

    final unguarded = <String>[];
    for (final m in methods) {
      final name = m.group(1)!;
      if (exempt.contains(name)) continue;
      final head = m.group(2)!.trimLeft();
      if (!head.startsWith('if (!_configured)')) {
        unguarded.add(name);
      }
    }

    expect(
      unguarded,
      isEmpty,
      reason:
          'Bu metotlar yapılandırılmamış SDK\'ya sorabilir ve uygulamayı '
          'çökertir; başına `if (!_configured) return …;` ekleyin: '
          '${unguarded.join(', ')}',
    );
  });
}

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Geri düğmesi olan bir ekrana `go` ile gidilmemeli.
///
/// go_router'da `go` yığına eklemek yerine konumu **değiştiriyor**: geri
/// alınacak bir şey kalmıyor ve `context.pop()` sessizce hiçbir şey yapmıyor.
/// Hata da çökme de olmadığı için bu, ancak düğmeye basınca fark ediliyor —
/// onboarding'in üç adımında aylarca öyle durdu.
///
/// Buradaki kural kaynak üzerinde: `go` yalnızca **bilerek yığını temizleyen**
/// birkaç hedef için serbest. Yeni bir ekrana `go` ile gidilirse test o ekranı
/// adıyla söylüyor.
void main() {
  /// `go` kullanılması doğru olan hedefler ve nedenleri.
  const allowed = <String, String>{
    'home': 'Kurulum bitti; geri tuşuyla soru ekranlarına dönülmemeli.',
    'onboarding': 'Akışın başı; yönlendirme buraya düşürüyor.',
    'onboardingSuccess': 'Kurulumun son adımı; öncesine dönülmemeli.',
    'onboardingGoal':
        'Giriş ekranı yönlendirmeyle tek başına açıldıysa altında dönülecek '
        'bir şey yok; kurulumun geri düğmesi o zaman karşılamaya gidiyor '
        '(`onboardingBack`). Karşılamanın üstüne itildiyse `push` ile.',
    'profile': 'Alt menü sekmesi; kendi geri düğmesi yok.',
    'signIn':
        'Şifre yenileme bağlantısı oturum yokken açıldı; işi bitince ya da '
        'bağlantı geçersizse giriş ekranına dönülüyor, şifre ekranına geri '
        'gelinmemeli.',
  };

  test('yalnızca yığını temizlemesi gereken hedeflere `go` ile gidiliyor', () {
    final pattern = RegExp(r'\bgo(?:Named)?\(\s*RouteNames\.(\w+)');
    final offenders = <String>{};

    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      for (final line in entity.readAsLinesSync()) {
        if (line.trimLeft().startsWith('//')) continue;
        for (final m in pattern.allMatches(line)) {
          final route = m.group(1)!;
          if (!allowed.containsKey(route)) {
            offenders.add('${entity.path}: $route');
          }
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'Bu hedeflere `go` ile gidiliyor; ekranın geri düğmesi varsa ölü '
          'kalır. Yığına eklemek için `push` kullanın:\n  '
          '${offenders.join('\n  ')}',
    );
  });

  test('izin listesindeki her hedefin bir gerekçesi var', () {
    // Liste büyüyüp gerekçesiz hâle gelmesin: yeni bir hedef eklemek,
    // neden yığını temizlemesi gerektiğini yazmayı gerektiriyor.
    for (final entry in allowed.entries) {
      expect(
        entry.value.length,
        greaterThan(20),
        reason: '${entry.key} için gerekçe yazılmamış.',
      );
    }
  });
}

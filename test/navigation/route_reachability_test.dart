import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Rota tablosundaki her ekranın bir kapısı olmalı.
///
/// Üç ekran yazılmış, çevrilmiş, rota tablosuna kaydedilmiş ama hiçbir
/// yerden açılmıyordu: egzersiz detayı, tarif detayı ve ana ekran widget'ı
/// önizlemesi. Kaydedilmiş oldukları için "bağlandı" görünüyorlardı;
/// derleyici de analiz de sessizdi, çünkü teknik olarak eksik bir şey yok —
/// yalnızca kimse oraya gitmiyordu.
///
/// Aynı denetimde günün önerisi kartının, öneri kardiyo da olsa hep yoga
/// ekranını açtığı çıktı: bu ekranların yolu hiç kurulmamıştı.
void main() {
  /// Rota adıyla gidilmeyen, ama başka bir yolla açılan ekranlar.
  const reachedOtherwise = <String, String>{
    'splash': 'Yönlendirme ara ekranı; durum yüklenirken redirect düşürüyor.',
    'signIn': 'Oturum yokken redirect düşürüyor (bkz. `resolveRedirect`).',
    'verifyEmail':
        'E-posta hesabı doğrulanmamışken redirect düşürüyor '
        '(bkz. `resolveRedirect`).',
    'insights': 'Alt menü dalı; sekmeye `branchIndex` ile geçiliyor.',
    'partnerSupport':
        'Partner modunda başka bir sekmenin içine gömülü çiziliyor.',
  };

  test('her rotanın bir giriş noktası var', () {
    final router = File(
      'lib/core/navigation/app_router.dart',
    ).readAsStringSync();
    final registered = RegExp(
      r'name:\s*RouteNames\.(\w+)',
    ).allMatches(router).map((m) => m.group(1)!).toSet();
    expect(registered, isNotEmpty, reason: 'rota tablosu okunamadı');

    // Kayıt satırları (`name: RouteNames.x`) ve yorumlar sayılmıyor:
    // aranan şey oraya **gitmek**.
    final used = <String>{};
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      if (entity.path.endsWith('route_names.dart')) continue;
      for (final line in entity.readAsLinesSync()) {
        final trimmed = line.trimLeft();
        if (trimmed.startsWith('//')) continue;
        if (RegExp(r'name:\s*RouteNames\.').hasMatch(line)) continue;
        used.addAll(
          RegExp(r'RouteNames\.(\w+)').allMatches(line).map((m) => m.group(1)!),
        );
      }
    }

    final orphans = registered.difference(used)
      ..removeWhere(reachedOtherwise.containsKey);

    expect(
      orphans,
      isEmpty,
      reason:
          'Bu ekranlar rota tablosunda var ama hiçbir yerden açılmıyor. '
          'Ya bir giriş noktası bağlayın ya da rotayı kaldırın: '
          '${orphans.join(', ')}',
    );
  });

  test('istisnaların gerekçesi yazılı', () {
    // Liste sessizce büyümesin: bir ekranı "başka yolla açılıyor" saymak
    // nasıl açıldığını yazmayı gerektiriyor.
    for (final entry in reachedOtherwise.entries) {
      expect(
        entry.value.length,
        greaterThan(25),
        reason: '${entry.key} için gerekçe yazılmamış.',
      );
    }
  });
}

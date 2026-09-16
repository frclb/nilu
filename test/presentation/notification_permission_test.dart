import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Bildirim ve izin ayarlarının denetimi.
///
/// Bu dosyadaki iddialar kaynak ve yapılandırma dosyalarını okuyor: ikisi de
/// çalışma anında değil, yalnızca gerçek cihazda ortaya çıkan türden
/// hatalar barındırıyordu.
void main() {
  group('sistem izin metinleri', () {
    const languages = ['tr', 'en', 'de', 'es', 'fr', 'pt'];

    /// `Info.plist` hangi izinleri beyan ediyor?
    Set<String> declaredPermissions() {
      final plist = File('ios/Runner/Info.plist').readAsStringSync();
      return RegExp(
        r'<key>(NS\w*UsageDescription)</key>',
      ).allMatches(plist).map((m) => m.group(1)!).toSet();
    }

    Set<String> localizedPermissions(String language) {
      final file = File('ios/Runner/$language.lproj/InfoPlist.strings');
      return RegExp(
        r'"(NS\w*UsageDescription)"',
      ).allMatches(file.readAsStringSync()).map((m) => m.group(1)!).toSet();
    }

    test('her dil Info.plist ile aynı izinleri karşılıyor', () {
      // Eksik olan izin, sistem isteminde `Info.plist`'teki yedek metinle
      // çıkıyor — ve o metinler Türkçe. Almanca bir cihazda Sağlık izni
      // Türkçe soruluyordu.
      //
      // Fazlalık olan da sorun: `NSPhotoLibraryUsageDescription` bu
      // dosyalarda duruyordu ama izin `Info.plist`'ten kaldırılmıştı.
      // İstemediğin bir izni beyan etmek incelemede soru doğuruyor.
      final declared = declaredPermissions();
      expect(declared, isNotEmpty, reason: 'Info.plist izin beyan etmiyor');

      for (final language in languages) {
        expect(
          localizedPermissions(language),
          declared,
          reason: '$language.lproj/InfoPlist.strings Info.plist ile ayrışmış',
        );
      }
    });

    test('hiçbir metin boş değil', () {
      for (final language in languages) {
        final content = File(
          'ios/Runner/$language.lproj/InfoPlist.strings',
        ).readAsStringSync();

        for (final match in RegExp(
          r'"(NS\w*UsageDescription)"\s*=\s*"([^"]*)"',
        ).allMatches(content)) {
          expect(
            match.group(2)!.trim(),
            isNotEmpty,
            reason: '$language: ${match.group(1)} boş',
          );
        }
      }
    });
  });

  group('bildirim izni yalnızca gerekçeyle isteniyor', () {
    test('FCM sarmalayıcısı izin istemiyor', () {
      // iOS'ta yerel bildirimler ve FCM aynı sistem iznini kullanıyor ve
      // istem bir kez gösteriliyor. FCM açılışta sessizce isteseydi,
      // `ReminderSync` içindeki gerekçe kutusu hiç devreye girmeden karar
      // alınmış olurdu. Firebase yapılandırılmadığı için bugüne kadar
      // görünmedi; yapılandırma dosyası eklendiği gün ortaya çıkardı.
      final source = File(
        'lib/data/datasources/remote/notification_service.dart',
      ).readAsStringSync();

      expect(
        source.contains('requestPermission('),
        isFalse,
        reason:
            'FCM izin istememeli; yalnızca verilmiş izinle jeton kaydetmeli',
      );
      expect(
        source.contains('getNotificationSettings()'),
        isTrue,
        reason: 'mevcut izin durumu okunmalı',
      );
    });
  });
}

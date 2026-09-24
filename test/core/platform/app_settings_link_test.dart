import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:period_tracker/core/platform/app_settings_link.dart';

void main() {
  tearDown(AppSettingsLink.resetForTest);

  test('Apple\'ın belgelediği adres kullanılır', () {
    // `UIApplication.openSettingsURLString` bu. Ayarların bir **bölümüne**
    // derin bağlantı (App-Prefs:...) belgesiz ve incelemede ret sebebi.
    expect(AppSettingsLink.uri, 'app-settings:');
    expect(AppSettingsLink.uri.startsWith('App-Prefs'), isFalse);
  });

  test('desteklenen platformda o adres açılır', () async {
    final opened = <Uri>[];
    AppSettingsLink.launcher = (uri) async {
      opened.add(uri);
      return true;
    };

    final result = await AppSettingsLink.open();

    if (AppSettingsLink.isSupported) {
      expect(result, isTrue);
      expect(opened.single.toString(), 'app-settings:');
    } else {
      // Desteklenmeyen platformda çağrı hiç yapılmamalı; dokunulduğunda
      // hiçbir şey olmayan bir düğme kullanıcıya arıza gibi görünür.
      expect(result, isFalse);
      expect(opened, isEmpty);
    }
  });

  test('destek yalnızca iOS içindir', () {
    expect(AppSettingsLink.isSupported, Platform.isIOS);
  });

  test('açma başarısız olursa çökmez', () async {
    AppSettingsLink.launcher = (uri) async => throw Exception('no handler');

    // Kullanıcı ayarlara gidemese bile ekran ayakta kalmalı.
    expect(await AppSettingsLink.open(), isFalse);
  });

  test('platform hatası da yutulur', () async {
    AppSettingsLink.launcher = (uri) async => throw StateError('boom');

    expect(await AppSettingsLink.open(), isFalse);
  });
}

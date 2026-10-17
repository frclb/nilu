import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:period_tracker/core/platform/app_icon.dart';

/// Sade simge üç yerde adıyla geçiyor: Dart kanalı, asset kataloğu ve Xcode
/// derleme ayarı. Biri değişip diğeri unutulursa iOS "simge bulunamadı"
/// diyor ve seçim sessizce başarısız oluyor — bunu ancak gerçek cihazda
/// görürdük.
void main() {
  const ad = AppIconService.neutralIconName;
  final set = Directory('ios/Runner/Assets.xcassets/$ad.appiconset');

  test('asset kataloğunda set ve 1024 görseli var', () {
    expect(set.existsSync(), isTrue);
    final contents =
        jsonDecode(File('${set.path}/Contents.json').readAsStringSync())
            as Map<String, dynamic>;
    final images = (contents['images'] as List).cast<Map<String, dynamic>>();
    final buyuk = images.singleWhere((i) => i['size'] == '1024x1024');
    final dosya = File('${set.path}/${buyuk['filename']}');
    expect(dosya.existsSync(), isTrue);

    // PNG başlığı: genişlik/yükseklik 1024, renk türü 2 (RGB, saydamlık
    // yok — App Store saydam simgeyi reddediyor).
    final b = dosya.readAsBytesSync();
    int be32(int o) =>
        (b[o] << 24) | (b[o + 1] << 16) | (b[o + 2] << 8) | b[o + 3];
    expect(be32(16), 1024);
    expect(be32(20), 1024);
    expect(b[25], 2, reason: 'Simge saydamlık içermemeli');
  });

  test('Xcode her yapılandırmada alternatif seti pakete koyuyor', () {
    final pbx = File('ios/Runner.xcodeproj/project.pbxproj').readAsStringSync();
    final birincil = 'ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;'
        .allMatches(pbx)
        .length;
    final alternatif = 'ASSETCATALOG_COMPILER_ALTERNATE_APPICON_NAMES = $ad;'
        .allMatches(pbx)
        .length;
    expect(alternatif, birincil);
    expect(alternatif, greaterThan(0));
  });

  test('yerel kanal aynı adı kullanıyor', () {
    final swift = File('ios/Runner/AppDelegate.swift').readAsStringSync();
    expect(swift, contains('"${AppIconService.channelName}"'));
  });

  test('önizlemeler Flutter varlıklarında', () {
    for (final c in AppIconChoice.values) {
      expect(File('assets/icon/previews/${c.name}.png').existsSync(), isTrue);
    }
  });
}

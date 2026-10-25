import 'dart:io';

import 'package:flutter/services.dart';

/// Material simge yazı tipini Flutter SDK'nın kendi kopyasından yükler.
///
/// `flutter test` simgeleri yüklemiyor, her simge boş bir kutu çiziliyor.
/// Düzen testleri için önemsiz; galeride ve mağaza görsellerinde değil.
Future<void> loadMaterialIcons() async {
  // flutter_tester: <flutter>/bin/cache/artifacts/engine/<platform>/…
  final artifacts = File(Platform.resolvedExecutable).parent.parent.parent;
  final candidates = [
    '${artifacts.path}/material_fonts/MaterialIcons-Regular.otf',
    if (Platform.environment['FLUTTER_ROOT'] case final root?)
      '$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  ];
  for (final path in candidates) {
    final file = File(path);
    if (!file.existsSync()) continue;
    final loader = FontLoader('MaterialIcons')
      ..addFont(file.readAsBytes().then(ByteData.sublistView));
    await loader.load();
    return;
  }
  // ignore: avoid_print
  print('Uyarı: MaterialIcons bulunamadı; simgeler kutu olarak çizilecek.');
}

/// macOS'un renkli emoji yazı tipini yükler.
///
/// Ruh hâli seçenekleri emoji; testte emoji yazı tipi olmadığı için her biri
/// boş bir kutu çiziliyordu. Mağaza görselinde kutu kalamaz. Yalnızca
/// macOS'ta var; yoksa kutular kalıyor ve uyarı basılıyor.
Future<void> loadSystemEmoji() async {
  final file = File('/System/Library/Fonts/Apple Color Emoji.ttc');
  if (!file.existsSync()) {
    // ignore: avoid_print
    print(
      'Uyarı: Apple Color Emoji bulunamadı; emojiler kutu olarak çizilecek.',
    );
    return;
  }
  final loader = FontLoader('Apple Color Emoji')
    ..addFont(file.readAsBytes().then(ByteData.sublistView));
  await loader.load();
}

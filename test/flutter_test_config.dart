import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Testlerde uygulamanın **gerçek** yazı tiplerini yükler.
///
/// `flutter test` varsayılan olarak her karakteri aynı genişlikte kutu olarak
/// çizen bir yedek yazı tipi kullanır. Metin gerçekte olduğundan geniş
/// ölçülür ve düzen testleri yalan söyler: cihazda rahat sığan bir başlık
/// testte "96 piksel taştı" der. Yanlış alarm, gerçek taşmayı da gürültüye
/// gömer.
///
/// Bu dosyayı `flutter test` kendiliğinden bulur (`test/` kökünde
/// `flutter_test_config.dart` olması yeterli) ve bütün test dosyalarından
/// önce çalıştırır.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await _loadBundledFonts();
  return testMain();
}

/// `pubspec.yaml`'daki `fonts:` bloğuyla aynı listeyi taşır.
const _families = <String, List<String>>{
  'Inter': [
    'assets/fonts/Inter-Regular.ttf',
    'assets/fonts/Inter-Medium.ttf',
    'assets/fonts/Inter-SemiBold.ttf',
    'assets/fonts/Inter-Bold.ttf',
  ],
  'Fraunces': [
    'assets/fonts/Fraunces-SemiBold.ttf',
    'assets/fonts/Fraunces-Bold.ttf',
  ],
};

Future<void> _loadBundledFonts() async {
  for (final entry in _families.entries) {
    final loader = FontLoader(entry.key);
    for (final path in entry.value) {
      final file = File(path);
      if (!file.existsSync()) {
        // Sessizce yedek yazı tipine düşmek, ölçüm testlerinin neden
        // tuttuğunu anlaşılmaz kılardı.
        throw StateError(
          'Yazı tipi bulunamadı: $path — pubspec.yaml ile test/'
          'flutter_test_config.dart listesi ayrışmış olabilir.',
        );
      }
      loader.addFont(file.readAsBytes().then(ByteData.sublistView));
    }
    await loader.load();
  }
}

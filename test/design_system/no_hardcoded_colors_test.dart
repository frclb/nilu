import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Sunum katmanında sabit renk kalmamalı.
///
/// Premium tema çeşitleri (ocean/forest/graphite) tek bir token katmanından
/// besleniyor. Bir ekran rengi sabit yazdığında o ekran temayı takip etmiyor:
/// kullanıcı ödediği temayı seçiyor ama partner/tarif/yoga ekranları marka
/// pembesinde kalıyordu. Yeni bir sabit renk eklenirse burada yakalansın.
void main() {
  test('sunum katmanında sabit renk yok', () {
    // Video üzerindeki karartma teması takip etmemeli — her temada siyah.
    const allowed = {'lib/presentation/yoga/widgets/yoga_video_player.dart'};

    final pattern = RegExp(r'Color\(0x');
    final offenders = <String>[];

    for (final dir in ['lib/presentation', 'lib/core']) {
      for (final entity in Directory(dir).listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        final path = entity.path;
        if (allowed.contains(path)) continue;

        final lines = entity.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          if (pattern.hasMatch(lines[i])) {
            offenders.add('$path:${i + 1}: ${lines[i].trim()}');
          }
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'Sabit renk yerine context.tokens kullan:\n${offenders.join('\n')}',
    );
  });
}
